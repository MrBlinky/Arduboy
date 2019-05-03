#include "cart.h"

uint16_t Cart::programDataPage; // program read only data location in flash memory
uint16_t Cart::programSavePage; // program read and write data location in flash memory


uint8_t Cart::writeByte(uint8_t data)
{
 #ifdef USE_ARDUBOY2_SPITRANSFER
  return Arduboy2Base::SPItransfer(data);
 #else
  SPDR = data;
  asm volatile("nop");
  wait();
  return SPDR;
 #endif
}


uint8_t Cart::readByte()
{
  return writeByte(0);
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
  writeByte(command);
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
  writeByte(command);
  writeByte(address >> 16);
  writeByte(address >> 8);
  writeByte(address);
}


void Cart::seekData(uint24_t address)
{
 #ifdef ARDUINO_ARCH_AVR
  asm volatile( // assembly optimizer for AVR platform
    "lds  r0, %[page]+0 \n"
    "add  %B[addr], r0  \n"
    "lds  r0, %[page]+1 \n"
    "adc  %C[addr], r0  \n"
    :[addr] "+&r" (address)
    :[page] ""    (&programDataPage)
    :
  );
 #else // C++ version for non AVR platforms
  address += (uint24_t)programDataPage << 8;
 #endif
  seekCommand(SFC_READ, address);
  SPDR = 0;
}


void Cart::seekSave(uint24_t address)
{
 #ifdef ARDUINO_ARCH_AVR
  asm volatile( // assembly optimizer for AVR platform
    "lds  r0, %[page]+0 \n"
    "add  %B[addr], r0  \n"
    "lds  r0, %[page]+1 \n"
    "adc  %C[addr], r0  \n"
    :[addr] "+&r" (address)
    :[page] ""    (&programSavePage)
    :"r24"
  );
 #else // C++ version for non AVR platforms
  address += (uint24_t)programSavePage << 8;
 #endif
  seekCommand(SFC_READ, address);
  SPDR = 0;
}


uint8_t Cart::readPendingUInt8()
{
 #ifdef ARDUINO_ARCH_AVR
  asm volatile("cart_cpp_readPendingUInt8:\n"); // create label for calls in Cart::readPendingUInt16
 #endif
  wait();
  uint8_t result = SPDR;
  SPDR = 0;
  return result;
}


uint16_t Cart::readPendingUInt16()
{
 #ifdef ARDUINO_ARCH_AVR // Assembly implementation for AVR platform
  uint16_t result asm("r24"); // we want result to be assigned to r24,r25
  asm volatile
  ( "cart_cpp_readPendingUInt16:        \n"
    "call cart_cpp_readPendingUInt8     \n" 
    "mov  %B[val], r24                  \n"
    "call cart_cpp_readPendingUInt8     \n"
    : [val] "=&r" (result)
    : "" (readPendingUInt8)
    :
  );
  return result;
 #else //C++ implementation for non AVR platforms
  return ((uint16_t)readPending() << 8) | (uint16_t)readPending();
 #endif
}


uint24_t Cart::readPendingUInt24()
{
 #ifdef ARDUINO_ARCH_AVR // Assembly implementation for AVR platform
  uint24_t result asm("r24"); // we want result to be assigned to r24,r25,r26
  asm volatile
  ( 
    "call cart_cpp_readPendingUInt16    \n" 
    "mov  %C[val], r25                  \n"
    "mov  %B[val], r24                  \n"
    "call cart_cpp_readPendingUInt8     \n"
    : [val] "=&r" (result)
    : "" (readPendingUInt16),
      "" (readPendingUInt8)
    :
  );
  return result;
 #else //C++ implementation for non AVR platforms
  return ((uint24_t)readPendingUInt16() << 8) | readPending();
 #endif
}


uint32_t Cart::readPendingUInt32()
{
 #ifdef ARDUINO_ARCH_AVR //Assembly implementation for AVR platform
  uint32_t result asm("r24"); // we want result to be assigned to r24,r25,r26,r27
  asm volatile
  ( 
    "call cart_cpp_readPendingUInt16    \n" 
    "movw  %C[val], r24                 \n"
    "call cart_cpp_readPendingUInt16    \n" 
    : [val] "=&r" (result)
    : "" (readPendingUInt16)
    : 
  );
  return result;
 #else //C++ implementation for non AVR platforms
  return ((uint32_t)readPendingUInt16() << 16) | readPendingUInt16();
 #endif
}


void Cart::readBytes(uint8_t* buffer, size_t length)
{
  for (size_t i = 0; i < length; i++)
  {
    buffer[i] = readPendingUInt8();
  }
}

uint8_t Cart::readEnd()
{
  wait();                 // wait for a pending read to complete
  return readUnsafeEnd(); // read last byte and disable flash
}

void Cart::readDataBytes(uint24_t address, uint8_t* buffer, size_t length)
{
  seekData(address);
  readBytes(buffer, length);
  disable();
}


void Cart::readSaveBytes(uint24_t address, uint8_t* buffer, size_t length)
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
    writeByte(buffer[i]);
  }
  while (i++ < 255);
  disable();
}

void Cart::drawBitmap(int16_t x, int16_t y, uint24_t address, uint8_t frame, uint8_t mode)
{
  // read bitmap dimensions from flash
  seekData(address); 
  int16_t width  = readPendingUInt16();
  int16_t height = readPendingUInt16();
  readEnd();
  // return if the bitmap is completely off screen
  if (x + width <= 0 || x >= WIDTH || y + height <= 0 || y >= HEIGHT) return;
  
  // determine render width
  int16_t skipleft = 0;
  uint8_t renderwidth;
  if (x<0)
  {
    skipleft = -x;
    if (width - skipleft < WIDTH) renderwidth = width - skipleft;
    else renderwidth = WIDTH;
  }
  else
  {
    if (x + width > WIDTH) renderwidth = WIDTH - x;
    else renderwidth = width;
  }
  
  //determine render height
  int16_t skiptop;     // pixel to be skipped at the top
  int8_t renderheight; // in pixels
  if (y < 0) 
  {
    skiptop = -y & -8; // optimized -y / 8 * 8
    if (height - skiptop <= HEIGHT) renderheight = height - skiptop;
    else renderheight = HEIGHT + (y & 7);
    skiptop >>= 3;//pixels to displayrows
  }
  else
  {
    skiptop = 0;
    if (y + height > HEIGHT) renderheight = HEIGHT - y;
    else renderheight = height;
  }
  uint24_t offset = (uint24_t)(frame * height + skiptop) * width + skipleft;
  if (mode & dbmMasked)
  {
    offset += offset; // double for masked bitmaps
    width += width;
  } 
  address += offset + 4; // skip non rendered pixels, width, height
  int8_t displayrow = (y >> 3) + skiptop;
  uint16_t displayoffset = displayrow * WIDTH + x + skipleft;
  uint8_t yshift = 1 << (y & 7); //shift by multiply
  uint8_t lastmask = 0xFF >> (height & 7); // mask for bottommost pixels
  do
  {
    seekData(address);
    address += width;
    mode &= ~(_BV(dbfExtraRow));
    if (yshift != 1 && displayrow < (HEIGHT / 8 - 1)) mode |= _BV(dbfExtraRow);
    uint8_t rowmask = 0xFF; 
    if (renderheight < 8) rowmask = lastmask;
    wait();
    for (uint8_t c = 0; c < renderwidth; c++)
    {
      uint8_t bitmapbyte = readUnsafe();
      if (mode & _BV(dbfReverseBlack)) bitmapbyte ^= 0xFF;
      uint8_t maskbyte = rowmask;
      if (mode & _BV(dbfWhiteBlack)) maskbyte = bitmapbyte;
      if (mode & _BV(dbfBlack)) bitmapbyte = 0;
      uint16_t bitmap = multiplyUInt8(bitmapbyte, yshift);
      if (mode & _BV(dbfMasked))
      {
        wait();
        uint8_t tmp = readUnsafe();
        if ((mode & dbfWhiteBlack) == 0) maskbyte = tmp;
      }
      uint16_t mask = multiplyUInt8(maskbyte, yshift);
      if (displayrow >= 0)
      {
        uint8_t pixels = bitmap;
        uint8_t display = Arduboy2Base::sBuffer[displayoffset];
        if ((mode & _BV(dbmInvert)) == 0) pixels ^= display;
        pixels &= mask;
        pixels ^= display;
        Arduboy2Base::sBuffer[displayoffset] = pixels;
      }
      if (mode & _BV(dbfExtraRow))
      {
        uint8_t display = Arduboy2Base::sBuffer[displayoffset + WIDTH];
        uint8_t pixels = bitmap >> 8;
        if ((mode & dbmInvert) == 0) pixels ^= display;
        pixels &= mask >> 8;
        pixels ^= display;
        Arduboy2Base::sBuffer[displayoffset + WIDTH] = pixels;
      }
      displayoffset++;
    }
    displayoffset += WIDTH - renderwidth;
    displayrow ++;
    renderheight -= 8;
    readEnd();
  } while (renderheight > 0);
}
