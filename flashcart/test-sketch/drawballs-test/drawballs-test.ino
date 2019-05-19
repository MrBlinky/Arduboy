/* *****************************************************************************
 * Flash cart draw balls test v1.1 by Mr.Blinky May 2019 licenced under MIT
 * *****************************************************************************
 * 
 * This test depend on file drawballs-test.bin being uploaded with the 
 * flash-writer Python script in the develop area using the following command:
 * 
 * python flash-writer.py -d drawballs-test.bin
 * 
 * This demo draws a moving background tilemap with a bunch of balls bouncing around
 * 
 * reduce the value of MAX_BALLS to see more of the moving background
 * 
 */

#include <Arduboy2.h>
#include "src/cart.h"

#define PROGRAM_DATA_PAGE 0xFFFE
#define FRAME_RATE 60

#define MAX_BALLS 55
#define CIRCLE_POINTS 84
#define VISABLE_TILES_PER_COLUMN 5
#define VISABLE_TILES_PER_ROW 9

//datafile offsets
constexpr uint24_t gfx1 = 0x000000;    // Background tiles
constexpr uint24_t gfx2 = 0x000044;    // masked ball sprite
constexpr uint24_t tilemap = 0x000088; // 16 x 16 tilemap
constexpr uint8_t tilemapWidth = 16;   // width of a tilemap row
constexpr uint8_t tileWidth  = 16;
constexpr uint8_t tileHeight = 16;

Arduboy2 arduboy;

Point circlePoints[CIRCLE_POINTS] = 
{
  Point(-15,0),
  Point(-15,1),
  Point(-15,2),
  Point(-15,3),
  Point(-15,4),
  Point(-14,5),
  Point(-14,6),
  Point(-13,7),
  Point(-13,8),
  Point(-12,9),
  Point(-11,10),
  Point(-10,11),
  Point(-9,12),
  Point(-8,13),
  Point(-7,13),
  Point(-6,14),
  Point(-5,14),
  Point(-4,14),
  Point(-3,15),
  Point(-2,15),
  Point(-1,15),
  Point(0,15),
  Point(1,15),
  Point(2,15),
  Point(3,15),
  Point(4,14),
  Point(5,14),
  Point(6,14),
  Point(7,13),
  Point(8,13),
  Point(9,12),
  Point(10,11),
  Point(11,10),
  Point(12,9),
  Point(12,8),
  Point(13,7),
  Point(13,6),
  Point(14,5),
  Point(14,4),
  Point(14,3),
  Point(14,2),
  Point(14,1),
  Point(15,0),
  Point(15,-1),
  Point(15,-2),
  Point(15,-3),
  Point(15,-4),
  Point(14,-5),
  Point(14,-6),
  Point(13,-7),
  Point(13,-8),
  Point(12,-9),
  Point(11,-10),
  Point(10,-11),
  Point(9,-12),
  Point(8,-13),
  Point(7,-13),
  Point(6,-14),
  Point(5,-14),
  Point(4,-14),
  Point(3,-15),
  Point(2,-15),
  Point(1,-15),
  Point(0,-15),
  Point(-1,-15),
  Point(-2,-15),
  Point(-3,-15),
  Point(-4,-14),
  Point(-5,-14),
  Point(-6,-14),
  Point(-7,-13),
  Point(-8,-13),
  Point(-9,-12),
  Point(-10,-11),
  Point(-11,-10),
  Point(-12,-9),
  Point(-12,-8),
  Point(-13,-7),
  Point(-13,-6),
  Point(-14,-5),
  Point(-14,-4),
  Point(-14,-3),
  Point(-14,-2),
  Point(-14,-1)
};

Point camera;

struct Ball 
{
  Point point;
  int8_t xspeed;
  int8_t yspeed;  
};

Ball ball[MAX_BALLS];

uint8_t pos;

void setup() {
  arduboy.begin();
  arduboy.setFrameRate(FRAME_RATE);
  Cart::disableOLED(); // OLED must be disabled before cart can be used. OLED display should only be enabled prior updating the display.
  Cart::begin(PROGRAM_DATA_PAGE); // wakeup flash chip, initialize datapage, detect presence of flash chip
  
  for (uint8_t i=0; i < MAX_BALLS; i++) // initialize ball sprites
  {
   ball[i].point.x = random(113);
   ball[i].point.y = random(49);
   ball[i].xspeed = random(1,3);
   if (random(100) > 49) ball[i].xspeed = -ball[i].xspeed;
   ball[i].yspeed = random(1,3);
   if (random(100) > 49) ball[i].yspeed = -ball[i].yspeed;
  }                                     
}

uint8_t tilemapBuffer[VISABLE_TILES_PER_ROW];

void loop() {
  if (!arduboy.nextFrameDEV()) return;

  camera.x =16 + circlePoints[pos].x; // circle around a fixed point with radius 15
  camera.y =16 + circlePoints[pos].y;
  
  //draw tilemap
  for (int8_t y = 0; y < VISABLE_TILES_PER_COLUMN; y++)
  {
    Cart::seekDataArray(tilemap, y + camera.y / 16, camera.x / 16, tilemapWidth); // locate tilemap data in external flash
    Cart::readBytes(tilemapBuffer, VISABLE_TILES_PER_ROW); //reading a row of tiles is faster then reading individual tiles
    Cart::readEnd();
    for (int16_t x = 0; x < VISABLE_TILES_PER_ROW; x++)
    {
      Cart::drawBitmap(x*16 - camera.x % 16 , y*16 - camera.y % 16 , gfx1, tilemapBuffer[x], dbmNormal); //draw a row of tiles
    }
  }
  pos = ++pos % CIRCLE_POINTS;
  
  //draw balls
  for (uint8_t i=0; i < MAX_BALLS; i++)
    Cart::drawBitmap(ball[i].point.x, ball[i].point.y, gfx2, 0, dbmMasked);

  //update balls    
  for (uint8_t i=0; i < MAX_BALLS; i++)
  {
    if (ball[i].xspeed > 0)
    {
      ball[i].point.x += ball[i].xspeed;
      if (ball[i].point.x > 112)
      {
        ball[i].point.x = 112;
        ball[i].xspeed = - ball[i].xspeed;
      }
    }
    else
    {
      ball[i].point.x += ball[i].xspeed;
      if (ball[i].point.x < 0)
      {
        ball[i].point.x = 0;
        ball[i].xspeed = - ball[i].xspeed;
      }
    }
    if (ball[i].yspeed > 0)
    {
      ball[i].point.y += ball[i].yspeed;
      if (ball[i].point.y > 56)
      {
        ball[i].point.y = 56;
        ball[i].yspeed = - ball[i].yspeed;
      }
    }
    else
    {
      ball[i].point.y += ball[i].yspeed;
      if (ball[i].point.y < 0)
      {
        ball[i].point.y = 0;
        ball[i].yspeed = - ball[i].yspeed;
      }
    }
  }
      
  Cart::enableOLED();// only enable OLED prior using display
  arduboy.display(CLEAR_BUFFER);
  Cart::disableOLED();// disable so flash cart can be used
}

