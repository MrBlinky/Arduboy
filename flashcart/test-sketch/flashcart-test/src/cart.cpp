#include <Arduboy2.h>
#include "cart.h"

static uint16_t Cart::programDataPage; // program read only data location in flash memory
static uint16_t Cart::programSavePage; // program read and write data location in flash memory

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
 #if defined USE_ARDUBOY2_SPITRANSFER
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
  return write(0);
}

uint16_t Cart::readWord()
{
  uint8_t lsb = read();
  return ((uint16_t)read() << 8) | lsb;
}


void Cart::init()
{
  wakeUp();
}


void Cart::init(uint16_t developmentDataPage)
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


void Cart::init(uint16_t developmentDataPage, uint16_t developmentSavePage)
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


void Cart::seek(uint8_t command, __uint24 pageAddress)
{
  enable();
  write(command);
  write(pageAddress >> 16);
  write(pageAddress >> 8);
  write(pageAddress);
}


void Cart::seekData(__uint24 pageAddress)
{
  seek(SFC_READ, ((__uint24)programDataPage << 8) + pageAddress);
}


void Cart::seekSave(__uint24 pageAddress)
{
  seek(SFC_READ, ((__uint24)programSavePage << 8) + pageAddress);
}


void Cart::readBytes(uint8_t* buffer, size_t length)
{
  for (size_t i = 0; i < length; i++)
  {
    buffer[i] = read();
  }
}


void Cart::readDataBlock(uint8_t* buffer, size_t length, __uint24 pageAddress)
{
  seekData(pageAddress);
  readBytes(buffer, length);
  disable();
}


void Cart::readSaveBlock(uint8_t* buffer, size_t length, __uint24 pageAddress)
{
  seekSave(pageAddress);
  readBytes(buffer, length);
  disable();
}

void  Cart::eraseSaveBlock(uint16_t page)
{
  writeEnable();
  seek(SFC_ERASE, (__uint24)(programSavePage + page) << 8);
  disable();
}


void Cart::writeSavePage(uint16_t page, uint8_t* buffer)
{
  writeEnable();
  seek(SFC_WRITE, (__uint24)(programSavePage + page) << 8);
  uint8_t i = 0;
  do 
  {
    write(buffer[i]);
  }
  while (i++ < 255);
  disable();
}
