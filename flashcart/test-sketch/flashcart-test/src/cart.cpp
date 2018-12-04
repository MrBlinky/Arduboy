#include <Arduboy2.h>
#include "cart.h"

//only used when Arduboy2 library doesn't return SPDR
uint8_t SPItransfer(uint8_t data)
{
  SPDR = data;
  asm volatile("nop");
  while ((SPSR & _BV(SPIF)) != 0);
  return SPDR;
}


void cartWakeUp()
{
  enableCart();
  cartTransfer(SFC_RELEASE_POWERDOWN);
  disableCart();
}


void cartReadBlock(uint8_t* buffer, size_t length, uint16_t page)
{
  cartReadBlock(buffer, length, page, 0);
}


void cartReadBlock(uint8_t* buffer, size_t length, uint16_t page, uint8_t offset)
{
  enableCart();
  cartTransfer(SFC_READ);
  cartTransfer(page >> 8);
  cartTransfer(page);
  cartTransfer(offset);
  for (size_t i = 0; i < length; i++)
  {
    buffer[i] = cartTransfer(0);
  }
  disableCart();
}


uint16_t cartGetDataPage()
{
  uint16_t page;
  //page = CART_DEV_DATA_PAGE;
  //if (pgm_read_word(CART_DATA_VECTOR) == CART_VECTOR_KEY) page = (pgm_read_byte(CART_DATA_PAGE) << 8) | (pgm_read_byte(CART_DATA_PAGE + 1));
  asm volatile(
    "   ldi     r30,lo8(%[addr])            \n" 
    "   ldi     r31,hi8(%[addr])            \n"
    "   lpm     %A[page], z+                \n"
    "   lpm     %B[page], z+                \n"
    "   subi    %A[page], lo8(%[key])       \n" //check magic key if page has been set by flasher tool
    "   sbci    %B[page], hi8(%[key])       \n"
    "   ldi     %A[page], lo8(%[devpage])   \n" //page = CART_DEV_DATA_PAGE;
    "   ldi     %B[page], hi8(%[devpage])   \n" 
    "   brne    1f                          \n"
    "   lpm     %B[page], z+                \n" //page = (pgm_read_byte(CART_DATA_PAGE) << 8) | (pgm_read_byte(CART_DATA_PAGE + 1));
    "   lpm     %A[page], z+                \n"
    "1:                                     \n"
    : [page]    "=&d" (page)
    : [devpage] ""    (CART_DEV_DATA_PAGE),
      [addr]    ""    (CART_DATA_VECTOR),
      [key]     ""    (CART_VECTOR_KEY)
    : "r30", "r31"
  );
  return page;
}


uint16_t cartGetSavePage()
{
  uint16_t page;
  //page = CART_DEV_SAVE_PAGE;
  //if (pgm_read_word(CART_SAVE_VECTOR) == CART_VECTOR_KEY) page = (pgm_read_byte(CART_SAVE_PAGE) << 8) | (pgm_read_byte(CART_SAVE_PAGE + 1));
  asm volatile(
    "   ldi     r30,lo8(%[addr])            \n" 
    "   ldi     r31,hi8(%[addr])            \n"
    "   lpm     %A[page], z+                \n"
    "   lpm     %B[page], z+                \n"
    "   subi    %A[page], lo8(%[key])       \n" //check magic key if page has been set by flasher tool
    "   sbci    %B[page], hi8(%[key])       \n"
    "   ldi     %A[page], lo8(%[devpage])   \n" //page = CART_DEV_SAVE_PAGE;
    "   ldi     %B[page], hi8(%[devpage])   \n" 
    "   brne    1f                          \n"
    "   lpm     %B[page], z+                \n" //page = (pgm_read_byte(CART_SAVE_PAGE) << 8) | (pgm_read_byte(CART_SAVE_PAGE + 1));
    "   lpm     %A[page], z+                \n"
    "1:                                     \n"
    : [page]    "=&d" (page)
    : [devpage] ""    (CART_DEV_SAVE_PAGE),
      [addr]    ""    (CART_SAVE_VECTOR),
      [key]     ""    (CART_VECTOR_KEY)
    : "r30", "r31"
  );
  return page;
}
