#ifndef CART_H
#define CART_H

// Required for size_t
#include <stddef.h>

//Default cart space reserved for development
#define CART_DEV_DATA_PAGE (0xFE0000 >> 8) /* 112K space (128K without using save) */
#define CART_DEV_SAVE_PAGE (0xFFC000 >> 8) /* 16K space */

//sketch reserved cart space (page values set by flasher tool)
#define CART_VECTOR_KEY  0x9518 /* RETI instruction used a magic key */
#define CART_DATA_VECTOR 0x0014 /* reserved interrupt vector 5  area */
#define CART_DATA_PAGE   0x0016
#define CART_SAVE_VECTOR 0x0018 /* reserved interrupt vector 6  area */
#define CART_SAVE_PAGE   0x001A

#ifndef CART_PORT
  #define CART_PORT PORTD
  #define CART_BIT PORTD2
  #define cartTransfer SPItransfer
#else
  #define cartTransfer Arduboy2Base::SPItransfer
#endif

#define SFC_JEDEC_ID  	      0x9F
#define SFC_READSTATUS1       0x05
#define SFC_READSTATUS2       0x35
#define SFC_READ              0x03
#define SFC_RELEASE_POWERDOWN 0xAB

struct JedecID {
  uint8_t manufacturer;
  uint8_t device;
  uint8_t size;
};

#define disableOLED() CS_PORT    |=  (1 << CS_BIT)
#define enableOLED()  CS_PORT    &= ~(1 << CS_BIT)
#define enableCart()  CART_PORT  &= ~(1 << CART_BIT)
#define disableCart() CART_PORT  |=  (1 << CART_BIT)

void cartWakeUp();

template< size_t size >
void cartReadBlock(uint8_t (&buffer)[size], uint16_t page)
{
  cartReadBlock(buffer, size, page);
}

template< size_t size >
void cartReadBlock(uint8_t (&buffer)[size], uint16_t page, uint8_t offset)
{
  cartReadBlock(buffer, size, page, offset);
}

void cartReadBlock(uint8_t* buffer, size_t length, uint16_t page);

void cartReadBlock(uint8_t* buffer, size_t length, uint16_t page, uint8_t offset);

uint16_t cartGetDataPage();

uint16_t cartGetSavePage();

#endif