#include <Arduboy2.h>
#include "cart.h"

//only used when Arduboy2 library doesn't return SPDR
uint8_t SPItransfer(uint8_t data)
{
  SPDR = data;
  asm volatile("nop");
  while ((SPSR & _BV(SPIF)) == 0);
  return SPDR;
}

static uint16_t cartDataPage; // location of read only data for this program in flash
static uint16_t cartSavePage; // location of read write data for this program in flash 


void cartInit()
{
  cartWakeUp();
}


void cartInit(uint16_t datapage)
{
  if (pgm_read_word(CART_DATA_VECTOR) == CART_VECTOR_KEY)
  {
    cartDataPage = (pgm_read_byte(CART_DATA_PAGE) << 8) | pgm_read_byte(CART_DATA_PAGE + 1);
  }
  else 
  {
    cartDataPage = datapage;
  }
  cartWakeUp();
}


void cartInit(uint16_t datapage, uint16_t savepage)
{
  if (pgm_read_word(CART_DATA_VECTOR) == CART_VECTOR_KEY)
  {
    cartDataPage = (pgm_read_byte(CART_DATA_PAGE) << 8) | pgm_read_byte(CART_DATA_PAGE + 1);
  }
  else 
  {
    cartDataPage = datapage;
  }
  if (pgm_read_word(CART_SAVE_VECTOR) == CART_VECTOR_KEY)
  {
    cartSavePage = (pgm_read_byte(CART_SAVE_PAGE) << 8) | pgm_read_byte(CART_SAVE_PAGE + 1);
  }
  else 
  {
    cartSavePage = savepage;
  }
  cartWakeUp();
}


void cartWriteCommand(uint8_t command)
{
  cartEnable();
  cartTransfer(command);
  cartDisable();
}


void cartWakeUp()
{
  cartWriteCommand(SFC_RELEASE_POWERDOWN);
}


void cartSleep()
{
  cartWriteCommand(SFC_POWERDOWN);
}


void cartWriteEnable()
{
  cartWriteCommand(SFC_WRITE_ENABLE);
}


void cartSeek(uint8_t command, uint16_t page, uint8_t offset)
{
  cartEnable();
  cartTransfer(command);
  cartTransfer(page >> 8);
  cartTransfer(page);
  cartTransfer(offset);
}


void cartSeekData(uint16_t page, uint8_t offset)
{
  cartSeek(SFC_READ, cartDataPage + page, offset);
}


void cartSeekSave(uint16_t page, uint8_t offset)
{
  cartSeek(SFC_READ, cartSavePage + page, offset);
}


void cartReadBlock(uint8_t* buffer, size_t length)
{
  for (size_t i = 0; i < length; i++)
  {
    buffer[i] = cartTransfer(0);
  }
  cartDisable();
}

void cartReadDataBlock(uint8_t* buffer, size_t length, uint16_t page, uint8_t offset)
{
  cartSeekData(page, offset);
  cartReadBlock(buffer, length);
}


void cartReadSaveBlock(uint8_t* buffer, size_t length, uint16_t page, uint8_t offset)
{
  cartSeekSave(page, offset);
  cartReadBlock(buffer, length);
}


void  cartEraseSaveBlock(uint16_t page)
{
  cartWriteEnable();
  cartSeek(SFC_ERASE, cartSavePage + page, 0);
  cartDisable();
}


void cartWriteSavePage(uint16_t page, uint8_t* buffer)
{
  cartWriteEnable();
  cartSeek(SFC_WRITE, cartSavePage + page, 0);
  for(uint8_t i = 0; i <= 255; i++)
  {
    cartTransfer(buffer[i]);
  }  
  cartDisable();
}
