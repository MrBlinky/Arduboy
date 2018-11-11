/* **********************************************************
 * Flash cart test v1.0 by Mr.blinky 2018 licenced under MIT
 * **********************************************************
 * 
 * Press A button to view JEDEC ID
 * 
 * Press B button to view animation
 * 
 * Note:
 * 
 * This sketch uses data stored on cart. To successfully locate the 
 * data on the cart, both sketch and data must be stored on the cart 
 * using the flasher tool and the sketch must be loaded (burned) by 
 * Cathy3K bootloader.
 *  
 * When uploading directly from Arduino IDE or a hex uploader. the 
 * animation option will show junk from the development cart space 
 * and beginning of cart space.
 * 
 */
 
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
  enableCart();
  cartTransfer(SFC_JEDEC_ID);
  jedecID.manufacturer = cartTransfer(0);
  jedecID.device = cartTransfer(0);
  jedecID.size = cartTransfer(0);
  disableCart();
  
  arduboy.clear();
  arduboy.setCursor(18,32-8);
  arduboy.print(F("JEDEC ID:"));
  printHexByte(jedecID.manufacturer);
  printHexByte(jedecID.device );
  printHexByte(jedecID.size);

  arduboy.setCursor(30,32+8);
  arduboy.print(F("STATUS:"));
  enableCart();
  cartTransfer(SFC_READSTATUS2);
  printHexByte(cartTransfer(0));
  disableCart();
  
  enableCart();
  cartTransfer(SFC_READSTATUS1);
  printHexByte(cartTransfer(0));
  disableCart();
}

void showFrames()
{
  cartReadBlock(arduboy.sBuffer, 1024, cartGetDataPage() + 4 * frames); // 4 = 1K / 256 byte page
//  arduboy.setCursor(0,0);
//  arduboy.print("Frame:");
//  arduboy.print(frames);
  if (++frames == 6572) frames = 0; //number of frames in animation
}


void setup() {
  arduboy.begin();
  arduboy.setFrameRate(30);
  
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
  cartWakeUp();  //cart may be in power down mode so wake it up (from cathy bootloader)
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
  disableOLED();// no need to keep display enabled
}

