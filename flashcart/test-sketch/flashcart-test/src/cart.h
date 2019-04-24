#ifndef CART_H
#define CART_H

// Required for size_t
#include <stddef.h>

//Default data and save cart space for development
#define CART_DEV_DATA_PAGE (0xFE0000 >> 8) /* 112K space (128K without using save) */
#define CART_DEV_SAVE_PAGE (0xFFC000 >> 8) /* 16K space */

//sketch data and save cart space (set by PC manager tool)
#define CART_VECTOR_KEY  0x9518 /* RETI instruction used a magic key */
#define CART_DATA_VECTOR 0x0014 /* reserved interrupt vector 5  area */
#define CART_DATA_PAGE   0x0016
#define CART_SAVE_VECTOR 0x0018 /* reserved interrupt vector 6  area */
#define CART_SAVE_PAGE   0x001A

#ifndef CART_PORT
  #define CART_PORT PORTD
  #define CART_BIT PORTD2
#else
  #define USE_ARDUBOY2_SPITRANSFER Arduboy2Base::SPItransfer
#endif

#define SFC_JEDEC_ID  	      0x9F
#define SFC_READSTATUS1       0x05
#define SFC_READSTATUS2       0x35
#define SFC_READ              0x03
#define SFC_WRITE_ENABLE      0x06
#define SFC_WRITE             0x04
#define SFC_ERASE             0x20
#define SFC_RELEASE_POWERDOWN 0xAB
#define SFC_POWERDOWN         0xB9

#ifndef uint24_t
 #define uint24_t __uint24
#endif
 
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


#define disableOLED() CS_PORT    |=  (1 << CS_BIT)
#define enableOLED()  CS_PORT    &= ~(1 << CS_BIT)

class Cart
{
  public:
    static void enable() __attribute__((always_inline)); // selects external flash memory and allows new commands
    
    static void disable() __attribute__((always_inline)); // deselects external flash memory and ends the last command
    
    static uint8_t write(uint8_t data);
    
    static uint8_t read(); //read a byte from the current flash location
    
    static uint16_t readWord(); //read a 16-bit word from the current flash location
    
    static void init(); // Initializes flash memory. Use only when program does not require data and save areas in flash memory
    
    static void init(uint16_t programDataPage); // Initializes flash memory. Use when program depends on data in flash memory
    
    static void init(uint16_t datapage, uint16_t savepage); // Initializes flash memory. Use when program depends on both data and save data in flash memory
    
    static void writeCommand(uint8_t command); // write a single byte flash command
    
    static void wakeUp(); // Wake up flash memory from power down mode
    
    static void sleep(); // Put flash memory in power down mode for low power
    
    static void writeEnable();// Puts flash memory in write mode, required prior to any write command
    
    static void seek(uint8_t command, __uint24 pageAddress);// Write command and selects flash memory address. Required by any read or write command
    
    static void seekData(__uint24 pageAddress); // selects flashaddress of program data area for reading
    
    static void seekSave(__uint24 pageAddress); // selects flashaddress of program save area for reading

    static void readBytes(uint8_t* buffer, size_t length);// read a number of bytes from the current flash location
    
    static void readDataBlock(uint8_t* buffer, size_t length, __uint24 pageAddress);
    
    static void readSaveBlock(uint8_t* buffer, size_t length, __uint24 pageAddress);
    
    static void eraseSaveBlock(uint16_t page);
    
    static void writeSavePage(uint16_t page, uint8_t* buffer);
    
    static uint16_t programDataPage; // program read only data area in flash memory
    static uint16_t programSavePage; // program read and write data area in flash memory
    
};
#endif