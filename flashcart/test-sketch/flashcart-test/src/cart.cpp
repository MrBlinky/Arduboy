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
  asm volatile("cart_cpp_read:\n");//create label for calls in Cart::readUInt16
 #endif
  return write(0);
}

uint16_t Cart::readUInt16()
{
  uint16_t value;
 #ifdef ARDUINO_ARCH_AVR //Assembly implementation for AVR platform
  asm volatile
  ( "cart_cpp_readUInt16: \n"
    "call cart_cpp_read   \n" 
    "mov  %B[val], r24    \n"
    "call cart_cpp_read   \n"
    "mov  %A[val], r24    \n"
    : [val] "=&r" (value)
    : "" (read)
    : //not specifying r24 here so r25:r24 can be assigned to value
  );
  return value;
 #else //C++ implementation for non AVR platforms
  value = read();
  return (value << 8) | read();
 #endif
}

uint24_t Cart::readUInt24()
{
  uint24_t value;
 #ifdef ARDUINO_ARCH_AVR //Assembly implementation for AVR platform
  asm volatile
  ( "                         \n"
    "call cart_cpp_readUInt16 \n" 
    "mov  %C[val], r25        \n"
    "mov  %B[val], r24        \n"
    "call cart_cpp_read       \n"
    "mov  %A[val], r24        \n"
    : [val] "=&r" (value)
    : "" (readUInt16),
      "" (read)
    : //not specifying r24:r25 here so r26:r25:r24 can be assigned to value
  );
  return value;
 #else //C++ implementation for non AVR platforms
  value = readUInt16();
  return (value << 8) | read();
 #endif
}

uint32_t Cart::readUInt32()
{
  uint32_t value;
 #ifdef ARDUINO_ARCH_AVR //Assembly implementation for AVR platform
  asm volatile
  ( 
    "call cart_cpp_readUInt16   \n" 
    "movw  %C[val], r24         \n"
    "call cart_cpp_readUInt16   \n" 
    "movw  %A[val], r24         \n"
    : [val] "=&r" (value)
    : "" (readUInt16)
    : //not specifying r24:r25 here so r27:r26:r25:r24 can be assigned to value
  );
  return value;
 #else //C++ implementation for non AVR platforms
  value = read();
  return (value << 8) | read();
 #endif
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


void Cart::seekCommand(uint8_t command, uint24_t pageAddress)
{
  enable();
  write(command);
  write(pageAddress >> 16);
  write(pageAddress >> 8);
  write(pageAddress);
}


void Cart::seekData(uint24_t pageAddress)
{
  seekCommand(SFC_READ, ((uint24_t)programDataPage << 8) + pageAddress);
}


void Cart::seekSave(uint24_t pageAddress)
{
  seekCommand(SFC_READ, ((uint24_t)programSavePage << 8) + pageAddress);
}


void Cart::readBytes(uint8_t* buffer, size_t length)
{
  for (size_t i = 0; i < length; i++)
  {
    buffer[i] = read();
  }
}


void Cart::readDataBlock(uint24_t pageAddress, uint8_t* buffer, size_t length)
{
  seekData(pageAddress);
  readBytes(buffer, length);
  disable();
}


void Cart::readSaveBlock(uint24_t pageAddress, uint8_t* buffer, size_t length)
{
  seekSave(pageAddress);
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
