#include "cart.h"
#include <wiring.c>

uint16_t Cart::programDataPage; // program read only data location in flash memory
uint16_t Cart::programSavePage; // program read and write data location in flash memory


uint8_t Cart::writeByte(uint8_t data)
{
 #ifdef USE_ARDUBOY2_SPITRANSFER
  return Arduboy2Base::SPItransfer(data);
 #else
  writeByteBeforeWait(data);
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
  noCartReboot();
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
  noCartReboot();
}


bool Cart::detect()
{
  seekCommand(SFC_READ,0);
  SPDR = 0;
  return readPendingLastUInt16() == 0x4152;
}


void Cart::noCartReboot()
  {
    if (!detect())
    {
      do
      {
        if (*(uint8_t *)&timer0_millis & 0x80) bitSet(PORTB, RED_LED_BIT);
        else bitClear(PORTB, RED_LED_BIT);
      } 
      while (bitRead(DOWN_BUTTON_PORTIN, DOWN_BUTTON_BIT)); // wait for DOWN button to enter bootloader
      Arduboy2Core::exitToBootloader();
    }
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


void Cart::seekDataArray(uint24_t address, uint8_t index, uint8_t offset, uint8_t elementSize)
{
 #ifdef ARDUINO_ARCH_AVR
  asm volatile (
    "   mul     %[index], %[size]   \n"
    "   brne    .+2                 \n" //treat size 0 as size 256
    "   mov     r1, %[index]        \n"
    "   clr     r24                 \n" //use as alternative zero reg
    "   add     r0, %[offset]       \n"
    "   adc     r1, r24             \n"
    "   add     %A[address], r0     \n"
    "   adc     %B[address], r1     \n"
    "   adc     %C[address], r24    \n"
    "   clr     r1                  \n"
    : [address] "+r" (address)
    : [index]   "r"  (index),
      [offset]  "r"  (offset),
      [size]    "r"  (elementSize)
    : "r24"
  );
  #else
   address += size ? index * size + offset : index * 256 + offset;
  #endif
  seekData(address);
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


uint8_t Cart::readPendingLastUInt8()
{
 #ifdef ARDUINO_ARCH_AVR
  asm volatile("cart_cpp_readPendingLastUInt8:\n"); // create label for calls in Cart::readPendingUInt16
 #endif
  return readEnd();
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
  return ((uint16_t)readPendingUInt8() << 8) | (uint16_t)readPendingUInt8();
 #endif
}


uint16_t Cart::readPendingLastUInt16()
{
 #ifdef ARDUINO_ARCH_AVR // Assembly implementation for AVR platform
  uint16_t result asm("r24"); // we want result to be assigned to r24,r25
  asm volatile
  ( "cart_cpp_readPendingLastUInt16:    \n"
    "call cart_cpp_readPendingUInt8     \n"
    "mov  %B[val], r24                  \n"
    "call cart_cpp_readPendingLastUInt8 \n"
    : [val] "=&r" (result)
    : "" (readPendingUInt8),
      "" (readPendingLastUInt8)
    :
  );
  return result;
 #else //C++ implementation for non AVR platforms
  return ((uint16_t)readPendingUint8() << 8) | (uint16_t)readPendingLastUInt8();
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
  return ((uint24_t)readPendingUInt16() << 8) | readPendingUInt8();
 #endif
}


uint24_t Cart::readPendingLastUInt24()
{
 #ifdef ARDUINO_ARCH_AVR // Assembly implementation for AVR platform
  uint24_t result asm("r24"); // we want result to be assigned to r24,r25,r26
  asm volatile
  (
    "call cart_cpp_readPendingUInt16    \n"
    "mov  %C[val], r25                  \n"
    "mov  %B[val], r24                  \n"
    "call cart_cpp_readPendingLastUInt8 \n"
    : [val] "=&r" (result)
    : "" (readPendingUInt16),
      "" (readPendingLastUInt8)
    :
  );
  return result;
 #else //C++ implementation for non AVR platforms
  return ((uint24_t)readPendingUInt16() << 8) | readPendingLastUInt8();
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


uint32_t Cart::readPendingLastUInt32()
{
 #ifdef ARDUINO_ARCH_AVR //Assembly implementation for AVR platform
  uint32_t result asm("r24"); // we want result to be assigned to r24,r25,r26,r27
  asm volatile
  (
    "call cart_cpp_readPendingUInt16    \n"
    "movw  %C[val], r24                 \n"
    "call cart_cpp_readPendingLastUInt16\n"
    : [val] "=&r" (result)
    : "" (readPendingUInt16)
    :
  );
  return result;
 #else //C++ implementation for non AVR platforms
  return ((uint32_t)readPendingUInt16() << 16) | readPendingLastUInt16();
 #endif
}


void Cart::readBytes(uint8_t* buffer, size_t length)
{
  for (size_t i = 0; i < length; i++)
  {
    buffer[i] = readPendingUInt8();
  }
}


void Cart::readBytesEnd(uint8_t* buffer, size_t length)
{
  for (size_t i = 0; i <= length; i++)
  {
    if ((i+1) != length)
    buffer[i] = readPendingUInt8();
    else
    {
      buffer[i] = readEnd();
      break;
    }
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
  readBytesEnd(buffer, length);
}


void Cart::readSaveBytes(uint24_t address, uint8_t* buffer, size_t length)
{
  seekSave(address);
  readBytesEnd(buffer, length);
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
  int16_t height = readPendingLastUInt16();
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
  uint24_t offset = (uint24_t)(frame * ((height+7) / 8) + skiptop) * width + skipleft;
  if (mode & dbmMasked)
  {
    offset += offset; // double for masked bitmaps
    width += width;
  }
  address += offset + 4; // skip non rendered pixels, width, height
  int8_t displayrow = (y >> 3) + skiptop;
  uint16_t displayoffset = displayrow * WIDTH + x + skipleft;
  uint8_t yshift = bitShiftLeftUInt8(y); //shift by multiply
#ifdef ARDUINO_ARCH_AVR
  uint8_t rowmask;
  uint16_t bitmap;
  asm volatile(
    "1: ;render_row:                                \n"
    "   cbi     %[cartport], %[cartbit]             \n"
    "   ldi     r24, %[cmd]                         \n" // writeByte(SFC_READ);
    "   out     %[spdr], r24                        \n"
    "   lds     r24, %[datapage]+0                  \n" // address + programDataPage;
    "   lds     r25, %[datapage]+1                  \n"
    "   add     r24, %B[address]                    \n"
    "   adc     r25, %C[address]                    \n"
    "   in      r0, %[spsr]                         \n" // wait()
    "   sbrs    r0, %[spif]                         \n"
    "   rjmp    .-6                                 \n"
    "   out     %[spdr], r25                        \n" // writeByte(address >> 16);
    "   in      r0, %[spsr]                         \n" // wait()
    "   sbrs    r0, %[spif]                         \n"
    "   rjmp    .-6                                 \n"
    "   out     %[spdr], r24                        \n" // writeByte(address >> 8);
    "   in      r0, %[spsr]                         \n" // wait()
    "   sbrs    r0, %[spif]                         \n"
    "   rjmp    .-6                                 \n"
    "   out     %[spdr], %A[address]                \n" // writeByte(address);
    "                                               \n"
    "   add     %A[address], %A[width]              \n" // address += width;
    "   adc     %B[address], %B[width]              \n"
    "   adc     %C[address], r1                     \n"
    "   in      r0, %[spsr]                         \n" // wait();
    "   sbrs    r0, %[spif]                         \n"
    "   rjmp    .-6                                 \n"
    "   out     %[spdr], r1                         \n" // SPDR = 0;
    "                                               \n"
    "   lsl     %[mode]                             \n" // 'clear' mode dbfExtraRow by shifting into carry
    "   cpi     %[displayrow], %[lastrow]           \n"
    "   brge    .+4                                 \n" // row >= lastrow, clear carry
    "   sec                                         \n" // row < lastrow set carry
    "   sbrc    %[yshift], 0                        \n" // yshift != 1, don't change carry state
    "   clc                                         \n" // yshift == 1, clear carry
    "   ror     %[mode]                             \n" // carry to mode dbfExtraRow
    "                                               \n"
    "   ldi     %[rowmask], 0x02                    \n" // rowmask = 0xFF >> (height & 7);
    "   sbrs    %[height], 1                        \n"
    "   ldi     %[rowmask], 0x08                    \n"
    "   sbrs    %[height], 2                        \n"
    "   swap    %[rowmask]                          \n"
    "   sbrs    %[height], 0                        \n"
    "   lsl     %[rowmask]                          \n"
    "   dec     %[rowmask]                          \n"
    "   cpi     %[renderheight], 8                  \n" // if (renderheight >= 8) rowmask = 0xFF;
    "   brlt    .+2                                 \n"
    "   ldi     %[rowmask], 0xFF                    \n"
    "                                               \n"
    "   mov     r25, %[renderwidth]                 \n" // for (c < renderwidth)
    "2: ;render_column:                             \n"
    "   in      r0, %[spdr]                         \n" // read bitmap data
    "   out     %[spdr], r1                         \n" // start next read
    "                                               \n"
    "   sbrc    %[mode], %[reverseblack]            \n" // test reverse mode
    "   com     r0                                  \n" // reverse bitmap data
    "   mov     r24, %[rowmask]                     \n" // temporary move rowmask
    "   sbrc    %[mode], %[whiteblack]              \n" // for black and white modes:
    "   mov     r24, r0                             \n" // rowmask = bitmap
    "   sbrc    %[mode], %[black]                   \n" // for black mode:
    "   clr     r0                                  \n" // bitmap = 0
    "   mul     r0, %[yshift]                       \n"
    "   movw    %[bitmap], r0                       \n" // bitmap *= yshift
    "   bst     %[mode], %[masked]                  \n" // if bitmap has no mask:
    "   brtc    3f ;render_mask                     \n" // skip next part
    "                                               \n"
    "   lpm                                         \n" // above code took 11 cycles, wait 7 cycles more for SPI data ready
    "   lpm                                         \n"
    "   clr     r1                                  \n" // restore zero reg
    "                                               \n"
    "   in      r0, %[spdr]                         \n" // read mask data
    "   out     %[spdr],r1                          \n" // start next read
    "   sbrc    %[mode], %[whiteblack]              \n" //
    "3: ;render_mask:                               \n"
    "   mov     r0, r24                             \n" // get mask in r0
    "   mul     r0, %[yshift]                       \n" // mask *= yshift
    ";render_page0:                                 \n"
    "   cpi     %[displayrow], 0                    \n" // skip if displayrow < 0
    "   brlt    4f ;render_page1                    \n"
    "                                               \n"
    "   ld      r24, %a[buffer]                     \n" // do top row or to row half
    "   sbrs    %[mode],%[invert]                   \n" // skip 1st eor for invert mode
    "   eor     %A[bitmap], r24                     \n"
    "   and     %A[bitmap], r0                      \n" // and with mask LSB
    "   eor     %A[bitmap], r24                     \n"
    "   st      %a[buffer], %A[bitmap]              \n"
    "4: ;render_page1:                              \n"
    "   subi    %A[buffer], lo8(-%[displaywidth])   \n"
    "   sbci    %B[buffer], hi8(-%[displaywidth])   \n"
    "   sbrs    %[mode], %[extrarow]                \n" // test if ExtraRow mode:
    "   rjmp    5f ;render_next                     \n" // else skip
    "                                               \n"
    "   ld      r24, %a[buffer]                     \n" // do shifted 2nd half
    "   sbrs    %[mode], %[invert]                  \n" // skip 1st eor for invert mode
    "   eor     %B[bitmap], r24                     \n"
    "   and     %B[bitmap], r1                      \n"// and with mask MSB
    "   eor     %B[bitmap], r24                     \n"
    "   st      %a[buffer], %B[bitmap]              \n"
    "5: ;render_next:                               \n"
    "   clr     r1                                  \n" // restore zero reg
    "   subi    %A[buffer], lo8(%[displaywidth]-1)  \n" 
    "   sbci    %B[buffer], hi8(%[displaywidth]-1)  \n"
    "   dec     r25                                 \n"
    "   brne    2b ;render_column                   \n" // for (c < renderheigt) loop
    "                                               \n"
    "   subi    %A[buffer], lo8(-%[displaywidth])   \n" // buffer += WIDTH - renderwidth
    "   sbci    %B[buffer], hi8(-%[displaywidth])   \n"
    "   sub     %A[buffer], %[renderwidth]          \n"
    "   sbc     %B[buffer], r1                      \n"
    "   subi    %[renderheight], 8                  \n" // reinderheight -= 8
    "   inc     %[displayrow]                       \n" // displayrow++
    "   in      r0, %[spsr]                         \n" // clear SPI status
    "   sbi     %[cartport], %[cartbit]             \n" // disable cart
    "   cp      r1, %[renderheight]                 \n" // while (renderheight > 0)
    "   brge    .+2                                 \n"
    "   rjmp    1b ;render_row                      \n" 
   :
    [address]      "+r" (address),
    [mode]         "+r" (mode),
    [rowmask]      "=&d" (rowmask),
    [bitmap]       "=&r" (bitmap),
    [renderheight] "+d" (renderheight),
    [displayrow]   "+d" (displayrow)
   :
    [width]        "r" (width),
    [height]       "r" (height),
    [yshift]       "r" (yshift),
    [renderwidth]  "r" (renderwidth),
    [buffer]       "e" (Arduboy2Base::sBuffer + displayoffset),
    
    [cartport]     "I" (_SFR_IO_ADDR(CART_PORT)),
    [cartbit]      "I" (CART_BIT),
    [cmd]          "I" (SFC_READ),
    [spdr]         "I" (_SFR_IO_ADDR(SPDR)),
    [datapage]     ""  (&programDataPage),
    [spsr]         "I" (_SFR_IO_ADDR(SPSR)),
    [spif]         "I" (SPIF),
    [lastrow]      "I" (HEIGHT / 8 - 1),
    [displaywidth] ""  (WIDTH),
    [reverseblack] "I" (dbfReverseBlack),
    [whiteblack]   "I" (dbfWhiteBlack),
    [black]        "I" (dbfBlack),
    [masked]       "I" (dbfMasked),
    [invert]       "I" (dbfInvert),
    [extrarow]     "I" (dbfExtraRow)
   :
    "r24", "r25"
   );
#else
  uint8_t lastmask = bitShiftRightMaskUInt8(height); // mask for bottom most pixels
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
        if ((mode & _BV(dbfInvert)) == 0) pixels ^= display;
        pixels &= mask;
        pixels ^= display;
        Arduboy2Base::sBuffer[displayoffset] = pixels;
      }
      if (mode & _BV(dbfExtraRow))
      {
        uint8_t display = Arduboy2Base::sBuffer[displayoffset + WIDTH];
        uint8_t pixels = bitmap >> 8;
        if ((mode & dbfInvert) == 0) pixels ^= display;
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
#endif
}


void Cart::readDataArray(uint24_t address, uint8_t index, uint8_t offset, uint8_t elementSize, uint8_t* buffer, size_t length)
{
  seekDataArray(address, index, offset, elementSize);
  readBytesEnd(buffer, length);
}


uint16_t Cart::readIndexedUInt8(uint24_t address, uint8_t index)
{
  seekDataArray(address, index, 0, sizeof(uint8_t));
  return readEnd();
}


uint16_t Cart::readIndexedUInt16(uint24_t address, uint8_t index)
{
  seekDataArray(address, index, 0, sizeof(uint16_t));
  return readPendingLastUInt16();
}


uint24_t Cart::readIndexedUInt24(uint24_t address, uint8_t index)
{
  seekDataArray(address, index, 0, sizeof(uint24_t));
  return readPendingLastUInt24();
}


uint32_t Cart::readIndexedUInt32(uint24_t address, uint8_t index)
{
  seekDataArray(address, index, 0, sizeof(uint24_t));
  return readPendingLastUInt32();
}