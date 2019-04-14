/* *****************************************************************************
 * Flash cart test v1.2 by Mr.Blinky 2018-2019 licenced under MIT
 * *****************************************************************************
 * 
 * Press A button to view JEDEC ID
 * 
 * Press B button to view animation
 * 
 * Note:
 * 
 * This sketch uses data stored on flash cart. To successfully locate the data
 * on the cart during development, set the page value from the flash writer tool
 * at the ANIMATION_DATA_PAGE define below
 */

// for badapple-frames animation
//#define ANIMATION_DATA_PAGE 0xEE60 /* value given by flash writer tool */
//#define ANIMATION_FRAMES 6572      /* number of 1K images in bin file  */
//#define ANIMATION_FPS 30
 
// for factory-frames animation
//#define ANIMATION_DATA_PAGE 0xDCF0 /* value given by flash writer tool */
//#define ANIMATION_FRAMES 2244      /* number of 1K images in bin file  */
//#define ANIMATION_FPS 30

//thedoor-frames
#define ANIMATION_DATA_PAGE 0xE948 /* value given by flash writer tool */
#define ANIMATION_FRAMES 1454      /* number of 1K images in bin file  */
#define ANIMATION_FPS 15


#include <Arduboy2.h>
#include "src/cart.h"

Arduboy2 arduboy;
uint8_t  state;
JedecID  jedecID;
uint16_t frames;

void printHexByte(uint8_t b)
{
 if (b <16) arduboy.print(0);
 arduboy.print(b,HEX);
}

void showJedecID()
{
  cartEnable();
  cartTransfer(SFC_JEDEC_ID);
  jedecID.manufacturer = cartTransfer(0);
  jedecID.device = cartTransfer(0);
  jedecID.size = cartTransfer(0);
  cartDisable();
  
  arduboy.clear();
  arduboy.setCursor(18,32-8);
  arduboy.print(F("JEDEC ID:"));
  printHexByte(jedecID.manufacturer);
  printHexByte(jedecID.device );
  printHexByte(jedecID.size);

  arduboy.setCursor(30,32+8);
  arduboy.print(F("STATUS:"));
  cartEnable();
  cartTransfer(SFC_READSTATUS2);
  printHexByte(cartTransfer(0));
  cartDisable();
  
  cartEnable();
  cartTransfer(SFC_READSTATUS1);
  printHexByte(cartTransfer(0));
  cartDisable();
}

void showFrames()
{
  cartReadDataBlock(arduboy.sBuffer, 1024, 4 * frames, 0); // 4 = 1K / 256 byte page
  if (++frames == ANIMATION_FRAMES) frames = 0; //number of frames in animation
}

void setup() {
  arduboy.begin();
  arduboy.setFrameRate(ANIMATION_FPS);
  
  //show one time info
  arduboy.clear();
  arduboy.setCursor(36,0);
  arduboy.print(F("Cart demo"));
  arduboy.setCursor(0,28-9);
  arduboy.print(F("A)  Show cart info"));
  arduboy.setCursor(0,28+9);
  arduboy.print(F("B)  Show animation"));
  arduboy.setCursor(30,56);
  arduboy.print(F("Mr. Blinky"));
    
  disableOLED(); //OLED must be disabled before using cart
  cartInit(ANIMATION_DATA_PAGE);  //cart may be in power down mode so wake it up (from cathy bootloader)
}


void loop() {
  if (!arduboy.nextFrame()) return;

  arduboy.pollButtons();
  if (arduboy.justPressed(A_BUTTON))
  {
    state = 1;
  }
  if (arduboy.justPressed(B_BUTTON))
  { 
    state  = 2; 
    frames = 0;
  }
  switch (state)
  {
	  case 1 : showJedecID(); break;
	  case 2 : showFrames(); break;
  }
  enableOLED();// only enable OLED prior using display
  arduboy.display();
  disableOLED();// disable so flash cart can be used
}

