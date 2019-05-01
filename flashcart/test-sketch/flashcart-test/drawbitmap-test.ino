/* *****************************************************************************
 * Flash cart drawBitmap test v1.2 by Mr.Blinky Apr-May 2019 licenced under MIT
 * *****************************************************************************
 * 
 * This test depend on file drawbitmap-test-2.bin being uploaded to flash chip
 */

#include <Arduboy2.h>
#include "src/cart.h"

#define PROGRAM_DATA_PAGE 0xFF65
#define FRAME_RATE 60

constexpr uint24_t gfx1 = 0x000000;
constexpr uint24_t gfx2 = 0x0092A4;

Arduboy2 arduboy;
bool showposition = true;
uint8_t select,color;
int x [2];
int y [2];

void setup() {
  arduboy.begin();
  arduboy.setFrameRate(FRAME_RATE);
  Cart::disableOLED();//OLED must be disabled before cart can be used. OLED display should only be enabled prior updating the display.
  Cart::begin(PROGRAM_DATA_PAGE);  //cart may be in power down mode so wake it up (Cathy bootloader puts cart into powerdown mode)
                                     //and set the program data flash page for development / uploading through Arduino IDE
}

void loop() {
  if (!arduboy.nextFrameDEV()) return;

  arduboy.pollButtons();
  if (arduboy.justPressed(B_BUTTON)) showposition = !showposition;
  if (arduboy.pressed(B_BUTTON)) select = 0;
  else select = 1;
  if (arduboy.justPressed(A_BUTTON)) color ^= dbmReverse;
  if (arduboy.pressed(A_BUTTON))
  {
  if (arduboy.justPressed(UP_BUTTON)) y[select]--;
  if (arduboy.justPressed(DOWN_BUTTON)) y[select]++;
  if (arduboy.justPressed(LEFT_BUTTON)) x[select]--;
  if (arduboy.justPressed(RIGHT_BUTTON)) x[select]++;
  }
  else
  {
  if (arduboy.pressed(UP_BUTTON)) y[select]--;
  if (arduboy.pressed(DOWN_BUTTON)) y[select]++;
  if (arduboy.pressed(LEFT_BUTTON)) x[select]--;
  if (arduboy.pressed(RIGHT_BUTTON)) x[select]++;
  }
  
  asm volatile("dbg:\n");
  Cart::drawBitmap(x[0],y[0],gfx1,0,dbmNormal);
  Cart::drawBitmap(x[1],y[1],gfx2,0,dbmMasked | color);
  //Cart::drawBitmap(x[1],y[1],gfx2,0,dbmMasked | dbmBlack); //draw black pixels. white transparent
  //Cart::drawBitmap(x[1],y[1],gfx2,0,dbmMasked | dbmWhite); //white pixels are drawn black, black transparent
  //Cart::drawBitmap(x[1],y[1],gfx2,0,dbmMasked | dbmInvert); //pixels are xored together
  //Cart::drawBitmap(x[1],y[1],gfx2,0,dbmMasked | dbmReverse); //white pixels are drawn black, black as white
  if (showposition)
  {
    arduboy.setCursor(0,0);
    arduboy.print(x[select]);
    arduboy.setCursor(0,8);
    arduboy.print(y[select]);
  } 
  Cart::enableOLED();// only enable OLED prior using display
  arduboy.display(CLEAR_BUFFER);
  Cart::disableOLED();// disable so flash cart can be used
}
