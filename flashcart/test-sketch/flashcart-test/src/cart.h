#ifndef CART_H
#define CART_H

// Required for size_t
#include <stddef.h>
#include <Arduboy2.h>

#ifndef CART_PORT
  #define CART_PORT PORTD
  #define CART_BIT PORTD2
#else
  #define USE_ARDUBOY2_SPITRANSFER
#endif

//sketch data and save cart space pages(set by PC manager tool)
constexpr uint16_t CART_VECTOR_KEY  = 0x9518; /* RETI instruction used a magic key */
constexpr uint16_t CART_DATA_VECTOR = 0x0014; /* reserved interrupt vector 5  area */
constexpr uint16_t CART_DATA_PAGE   = 0x0016;
constexpr uint16_t CART_SAVE_VECTOR = 0x0018; /* reserved interrupt vector 6  area */
constexpr uint16_t CART_SAVE_PAGE   = 0x001A;

//Serial Flash Commands
constexpr uint8_t SFC_JEDEC_ID  	    = 0x9F;
constexpr uint8_t SFC_READSTATUS1       = 0x05;
constexpr uint8_t SFC_READSTATUS2       = 0x35;
constexpr uint8_t SFC_READ              = 0x03;
constexpr uint8_t SFC_WRITE_ENABLE      = 0x06;
constexpr uint8_t SFC_WRITE             = 0x04;
constexpr uint8_t SFC_ERASE             = 0x20;
constexpr uint8_t SFC_RELEASE_POWERDOWN = 0xAB;
constexpr uint8_t SFC_POWERDOWN         = 0xB9;

//drawbitmap bit flags (used by modes below and internally)
constexpr uint8_t dbfWhiteBlack   = 0; // bitmap is used as mask
constexpr uint8_t dbfInvert       = 1; // bitmap is exclusive or-ed with display
constexpr uint8_t dbfBlack        = 2; // bitmap will be blackened
constexpr uint8_t dbfReverseBlack = 3; // reverses bitmap data
constexpr uint8_t dbfMasked       = 4; // bitmap contains mask data
constexpr uint8_t dbfExtraRow     = 7; // ignored (internal use)

//drawBitmap modes with same behaviour as Arduboy library drawBitmap modes
constexpr uint8_t dbmBlack   = _BV(dbfReverseBlack) |   // white pixels in bitmap will be drawn as black pixels on display
                               _BV(dbfBlack) |          // black pixels in bitmap will not change pixels on display
                               _BV(dbfWhiteBlack);      // (same as sprites drawErase)
                                     
constexpr uint8_t dbmWhite   = _BV(dbfWhiteBlack);      // white pixels in bitmap will be drawn as white pixels on display
                                                        // black pixels in bitmap will not change pixels on display
                                                        //(same as sprites drawSelfMasked)
                                     
constexpr uint8_t dbmInvert  = _BV(dbfInvert);          // when a pixel in bitmap has a different color than on display the
                                                        // pixel on display will be drawn as white. In all other cases the
                                                        // pixel will be drawn as black
//additional drawBitmap modes 
constexpr uint8_t dbmNormal     = 0;                    // White pixels in bitmap will be drawn as white pixels on display
constexpr uint8_t dbmOverwrite  = 0;                    // Black pixels in bitmap will be drawn as black pixels on display
                                                        // (Same as sprites drawOverwrite)
                                     
constexpr uint8_t dbmReverse = _BV(dbfReverseBlack);    // White pixels in bitmap will be drawn as black pixels on display
                                                        // Black pixels in bitmap will be drawn as white pixels on display
                                     
constexpr uint8_t dbmMasked  = _BV(dbfMasked);          // The bitmap contains a mask that will determine which pixels are
                                                        // drawn and which will remain 
                                                        // (same as sprites drawPlusMask)
                                     
// Note above modes may be combined like (dbmMasked | dbmReverse)
                                     
using uint24_t = __uint24;

struct JedecID
{
  uint8_t manufacturer;
  uint8_t device;
  uint8_t size;
};

struct CartAddress
{
  uint16_t page;
  uint8_t  offset;
};

class Cart
{
  public:
    static inline void enableOLED() __attribute__((always_inline)) // selects OLED display.
    {
      CS_PORT &= ~(1 << CS_BIT);
    };

    static inline void disableOLED() __attribute__((always_inline)) // deselects OLED display.
    {
      CS_PORT |=  (1 << CS_BIT);
    };
    
    static inline void enable() __attribute__((always_inline)) // selects external flash memory and allows new commands
    {
      CART_PORT  &= ~(1 << CART_BIT);
    };

    static inline void disable() __attribute__((always_inline)) // deselects external flash memory and ends the last command
    {
      CART_PORT  |=  (1 << CART_BIT);
    };

    static inline void wait() __attribute__((always_inline)) // wait for a pending flash transfer to complete
    {
      while ((SPSR & _BV(SPIF)) == 0);
    }
    
    static uint8_t writeByte(uint8_t data); // write a single byte to flash memory.

    static uint8_t readByte(); //read a single byte from flash memory

    static void begin(); // Initializes flash memory. Use only when program does not require data and save areas in flash memory

    static void begin(uint16_t programDataPage); // Initializes flash memory. Use when program depends on data in flash memory

    static void begin(uint16_t datapage, uint16_t savepage); // Initializes flash memory. Use when program depends on both data and save data in flash memory

    static void writeCommand(uint8_t command); // write a single byte flash command

    static void wakeUp(); // Wake up flash memory from power down mode

    static void sleep(); // Put flash memory in power down mode for low power

    static void writeEnable();// Puts flash memory in write mode, required prior to any write command

    static void seekCommand(uint8_t command, uint24_t address);// Write command and selects flash memory address. Required by any read or write command

    static void seekData(uint24_t address); // selects flashaddress of program data area for reading and starts the first read

    static void seekSave(uint24_t address); // selects flashaddress of program save area for reading and starts the first read
    
    static inline uint8_t readUnsafe() __attribute__((always_inline)) // read flash data without performing any checks and starts the next read.
    {
      uint8_t result = SPDR;
      SPDR = 0;
      return result;
    };

    static inline uint8_t readUnsafeEnd() __attribute__((always_inline))
    {
      disable();
      return SPDR;
    };
    
    static uint8_t readPendingUInt8() __attribute__ ((noinline));    //read a prefetched byte from the current flash location
    
    static uint16_t readPendingUInt16() __attribute__ ((noinline)); //read a partly prefetched 16-bit word from the current flash location
    
    static uint24_t readPendingUInt24() ; //read a partly prefetched 24-bit word from the current flash location
    
    static uint32_t readPendingUInt32(); //read a partly prefetched a 32-bit word from the current flash location
    
    static void readBytes(uint8_t* buffer, size_t length);// read a number of bytes from the current flash location
    
    static uint8_t readEnd();

    static void readDataBytes(uint24_t address, uint8_t* buffer, size_t length);

    static void readSaveBytes(uint24_t address, uint8_t* buffer, size_t length);

    static void eraseSaveBlock(uint16_t page);

    static void writeSavePage(uint16_t page, uint8_t* buffer);

    static void drawBitmap(int16_t x, int16_t y, uint24_t address, uint8_t frame, uint8_t mode);
    
    static inline uint16_t multiplyUInt8 (uint8_t a, uint8_t b) __attribute__((always_inline))
    {
     #ifdef ARDUINO_ARCH_AVR
      uint16_t result;
      asm volatile(
        "mul    %[a], %[b]      \n"
        "movw   %A[result], r0  \n"
        "clr    r1              \n"
        : [result] "=&r" (result)
        : [a]      "r"   (a),
          [b]      "r"   (b)
        :
      );
      return result;
     #else
      return (a * b);   
     #endif
    }
    
    static uint16_t programDataPage; // program read only data area in flash memory
    static uint16_t programSavePage; // program read and write data area in flash memory

};
#endif