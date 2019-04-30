#ifndef CART_H
#define CART_H

// Required for size_t
#include <stddef.h>

#ifndef CART_PORT
  #define CART_PORT PORTD
  #define CART_BIT PORTD2
#else
  #define USE_ARDUBOY2_SPITRANSFER
#endif

#define disableOLED() CS_PORT    |=  (1 << CS_BIT)
#define enableOLED()  CS_PORT    &= ~(1 << CS_BIT)

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

//drawBitmap modes
constexpr uint8_t dbmBlack   = 0; // black pixels in the bitmap will be black pixels on display.
                                  // white pixels in the bitmap will not change pixels on display
constexpr uint8_t dbmWhite   = 1; // white pixels in the bitmap will be white pixels on display.
                                  // black pixels in the bitmap will not change pixels on display
constexpr uint8_t dbmInvert  = 2; // pixels in the bitmap and on display will be added together.
                                  // Pixels that are both black or both white in the bitmap and 
                                  // on display  will turn black. Other combinations to white.
constexpr uint8_t dbmReverse = 4; // White pixels in bitmap will turn to black pixels on display.
                                  // Black pixels in bitmap will turn into white pixels on display.
constexpr uint8_t dbmNormal  = 5; // White pixels in bitmap will be white pixels on display.
                                  // Black pixels will be black pixels on display.
constexpr uint8_t dbmMasked  = 8; // The bitmap contains a mask that will determine which black
                                  // and white pixels of the bitmap will appear on display.

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
    static inline void enable() __attribute__((always_inline)) // selects external flash memory and allows new commands
    {
      CART_PORT  &= ~(1 << CART_BIT);
    };

    static inline void disable() __attribute__((always_inline)) // deselects external flash memory and ends the last command
    {
      CART_PORT  |=  (1 << CART_BIT);
    };

    static uint8_t writeByte(uint8_t data);

    static uint8_t readByte(); //read a single byte from flash memory

    static void begin(); // Initializes flash memory. Use only when program does not require data and save areas in flash memory

    static void begin(uint16_t programDataPage); // Initializes flash memory. Use when program depends on data in flash memory

    static void begin(uint16_t datapage, uint16_t savepage); // Initializes flash memory. Use when program depends on both data and save data in flash memory

    static void writeCommand(uint8_t command); // write a single byte flash command

    static void wakeUp(); // Wake up flash memory from power down mode

    static void sleep(); // Put flash memory in power down mode for low power

    static void writeEnable();// Puts flash memory in write mode, required prior to any write command

    static void seekCommand(uint8_t command, uint24_t pageAddress);// Write command and selects flash memory address. Required by any read or write command

    static void seekData(uint24_t pageAddress); // selects flashaddress of program data area for reading and starts the first read

    static void seekSave(uint24_t pageAddress); // selects flashaddress of program save area for reading and starts the first read
    
    static inline uint8_t readUnsave() __attribute__((always_inline)) // read flash data without performing any checks and starts the next read.
    {
      uint8_t result = SPDR;
      SPDR = 0;
      return result;
    };
    
    static uint8_t readPendingUInt8() __attribute__ ((noinline));    //read a prefetched byte from the current flash location
    
    static uint16_t readPendingUInt16() __attribute__ ((noinline)); //read a partly prefetched 16-bit word from the current flash location
    
    static uint24_t readPendingUInt24() ; //read a partly prefetched 24-bit word from the current flash location
    
    static uint32_t readPendingUInt32(); //read a partly prefetched a 32-bit word from the current flash location
    
    static void readBytes(uint8_t* buffer, size_t length);// read a number of bytes from the current flash location
    
    static void readEnd();

    static void readDataBytes(uint24_t pageAddress, uint8_t* buffer, size_t length);

    static void readSaveBytes(uint24_t pageAddress, uint8_t* buffer, size_t length);

    static void eraseSaveBlock(uint16_t page);

    static void writeSavePage(uint16_t page, uint8_t* buffer);

    static void drawBitmap(int16_t x, int16_t y, uint24_t pageAddress, uint8_t frame, uint8_t mode);

    static uint16_t programDataPage; // program read only data area in flash memory
    static uint16_t programSavePage; // program read and write data area in flash memory

};
#endif