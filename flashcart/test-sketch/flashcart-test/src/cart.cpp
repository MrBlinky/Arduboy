#include <Arduboy2.h>
#include "cart.h"

uint16_t Cart::programDataPage; // program read only data location in flash memory
uint16_t Cart::programSavePage; // program read and write data location in flash memory

void Cart::enable()
{
  CART_PORT  &= ~(1 << CART_BIT);
}


void Cart::disable()
{
  CART_PORT  |=  (1 << CART_BIT);
}


uint8_t Cart::write(uint8_t data)
{
 #ifdef USE_ARDUBOY2_SPITRANSFER
  return Arduboy2Base::SPItransfer(data);
 #else
  SPDR = data;
  asm volatile("nop");
  while ((SPSR & _BV(SPIF)) == 0);
  return SPDR;
 #endif
}


uint8_t Cart::read()
{
 #ifdef ARDUINO_ARCH_AVR
  asm volatile("cart_cpp_read:\n"); // create label for calls in Cart::readAheadUInt16
 #endif
  return write(0);
}


void Cart::begin()
{
  wakeUp();
}


void Cart::begin(uint16_t developmentDataPage)
{
  if (pgm_read_word(CART_DATA_VECTOR) == CART_VECTOR_KEY)
  {
    programDataPage = (pgm_read_byte(CART_DATA_PAGE) << 8) | pgm_read_byte(CART_DATA_PAGE + 1);
  }
  else
  {
    programDataPage = developmentDataPage;
  }
  wakeUp();
}


void Cart::begin(uint16_t developmentDataPage, uint16_t developmentSavePage)
{
  if (pgm_read_word(CART_DATA_VECTOR) == CART_VECTOR_KEY)
  {
    programDataPage = (pgm_read_byte(CART_DATA_PAGE) << 8) | pgm_read_byte(CART_DATA_PAGE + 1);
  }
  else
  {
    programDataPage = developmentDataPage;
  }
  if (pgm_read_word(CART_SAVE_VECTOR) == CART_VECTOR_KEY)
  {
    programSavePage = (pgm_read_byte(CART_SAVE_PAGE) << 8) | pgm_read_byte(CART_SAVE_PAGE + 1);
  }
  else
  {
    programSavePage = developmentSavePage;
  }
  wakeUp();
}


void Cart::writeCommand(uint8_t command)
{
  enable();
  write(command);
  disable();
}


void Cart::wakeUp()
{
  writeCommand(SFC_RELEASE_POWERDOWN);
}


void Cart::sleep()
{
  writeCommand(SFC_POWERDOWN);
}


void Cart::writeEnable()
{
  writeCommand(SFC_WRITE_ENABLE);
}


void Cart::seekCommand(uint8_t command, uint24_t address)
{
  enable();
  write(command);
  write(address >> 16);
  write(address >> 8);
  write(address);
}


void Cart::seekData(uint24_t address)
{
  seekCommand(SFC_READ, ((uint24_t)programDataPage << 8) + address);
  SPDR = 0;
}


void Cart::seekSave(uint24_t address)
{
  seekCommand(SFC_READ, ((uint24_t)programSavePage << 8) + address);
  SPDR = 0;
}


uint8_t readUnsafe()
{
  uint8_t result = SPDR;
  SPDR = 0;
  return result;
}


uint8_t Cart::readAheadUInt8()
{
 #ifdef ARDUINO_ARCH_AVR
  asm volatile("cart_cpp_readAheadUInt8:\n"); // create label for calls in Cart::readAheadUInt16
 #endif
  while ((SPSR & _BV(SPIF)) == 0);
  uint8_t result = SPDR;
  SPDR = 0;
  return result;
}


uint16_t Cart::readAheadUInt16()
{
 #ifdef xARDUINO_ARCH_AVR // Assembly implementation for AVR platform
  uint16_t result asm("r24"); // we want result to be assigned to r24,r25
  asm volatile
  ( "cart_cpp_readAheadUInt16:      \n"
    "call cart_cpp_readAheadUInt8   \n" 
    "mov  %B[val], r24              \n"
    "call cart_cpp_readAheadUInt8   \n"
    : [val] "=&r" (result)
    : "" (readAheadUInt8)
    :
  );
  return result;
 #else //C++ implementation for non AVR platforms
  return ((uint16_t)read() << 8) | (uint16_t)read();
 #endif
}


uint24_t Cart::readAheadUInt24()
{
 #ifdef ARDUINO_ARCH_AVR // Assembly implementation for AVR platform
  uint24_t result asm("r24"); // we want result to be assigned to r24,r25,r26
  asm volatile
  ( 
    "call cart_cpp_readAheadUInt16  \n" 
    "mov  %C[val], r25              \n"
    "mov  %B[val], r24              \n"
    "call cart_cpp_readAheadUInt8   \n"
    : [val] "=&r" (result)
    : "" (readAheadUInt16),
      "" (readAheadUInt8)
    :
  );
  return result;
 #else //C++ implementation for non AVR platforms
  return ((uint24_t)readAheadUInt16() << 8) | read();
 #endif
}


uint32_t Cart::readAheadUInt32()
{
 #ifdef ARDUINO_ARCH_AVR //Assembly implementation for AVR platform
  uint32_t result asm("r24"); // we want result to be assigned to r24,r25,r26,r27
  asm volatile
  ( 
    "call cart_cpp_readAheadUInt16   \n" 
    "movw  %C[val], r24             \n"
    "call cart_cpp_readAheadUInt16   \n" 
    : [val] "=&r" (result)
    : "" (readAheadUInt16)
    : 
  );
  return result;
 #else //C++ implementation for non AVR platforms
  return ((uint32_t)readAheadUInt16() << 16) | readAheadUInt16();
 #endif
}


void Cart::readBytes(uint8_t* buffer, size_t length)
{
  for (size_t i = 0; i < length; i++)
  {
    buffer[i] = readAheadUInt8();
  }
}

void Cart::readEnd()
{
  while ((SPSR & _BV(SPIF)) == 0); // wait for a pending read to complete
  disable();
}

void Cart::readDataBlock(uint24_t address, uint8_t* buffer, size_t length)
{
  seekData(address);
  readBytes(buffer, length);
  disable();
}


void Cart::readSaveBlock(uint24_t address, uint8_t* buffer, size_t length)
{
  seekSave(address);
  readBytes(buffer, length);
  disable();
}

void  Cart::eraseSaveBlock(uint16_t page)
{
  writeEnable();
  seekCommand(SFC_ERASE, (uint24_t)(programSavePage + page) << 8);
  disable();
}


void Cart::writeSavePage(uint16_t page, uint8_t* buffer)
{
  writeEnable();
  seekCommand(SFC_WRITE, (uint24_t)(programSavePage + page) << 8);
  uint8_t i = 0;
  do
  {
    write(buffer[i]);
  }
  while (i++ < 255);
  disable();
}

void Cart::drawBitmap(int16_t x, int16_t y, uint24_t address, uint8_t frame, uint8_t mode)
{
}