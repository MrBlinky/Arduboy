/* *****************************************************************************
 * Flash cart draw balls test v1.12 by Mr.Blinky May 2019 licenced under MIT
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

#define PROGRAM_DATA_PAGE 0xFFFE  //value given by flashcart-writer.py script using -d option
#define FRAME_RATE 60

#define MAX_BALLS 55
#define CIRCLE_POINTS 84
#define VISABLE_TILES_PER_COLUMN 5
#define VISABLE_TILES_PER_ROW 9

//datafile offsets
constexpr uint24_t gfx1 = 0x000000;    // Background tiles offset in external flash
constexpr uint24_t gfx2 = 0x000044;    // masked ball sprite offset in external flash
constexpr uint8_t ballWidth = 16;
constexpr uint8_t ballHeight = 16;

constexpr uint24_t tilemap = 0x000088; // 16 x 16 tilemap offset in external flash
constexpr uint8_t tilemapWidth = 16;   // number of tiles in a tilemap row
constexpr uint8_t tileWidth  = 16;
constexpr uint8_t tileHeight = 16;

Arduboy2 arduboy;

Point circlePoints[CIRCLE_POINTS] = // all the points of a circle with radius 15 used for the circling background effect
{
  {-15,0},  {-15,1},   {-15,2},   {-15,3},  {-15,4},  {-14,5},  {-14,6},  {-13,7},  {-13,8},  {-12,9},   {-11,10},  {-10,11}, {-9,12},  {-8,13},  {-7,13},  {-6,14},
  {-5,14},  {-4,14},   {-3,15},   {-2,15},  {-1,15},  {0,15},   {1,15},   {2,15},   {3,15},   {4,14},    {5,14},    {6,14},   {7,13},   {8,13},   {9,12},   {10,11},
  {11,10},  {12,9},    {12,8},    {13,7},   {13,6},   {14,5},   {14,4},   {14,3},   {14,2},   {14,1},    {15,0},    {15,-1},  {15,-2},  {15,-3},  {15,-4},  {14,-5},
  {14,-6},  {13,-7},   {13,-8},   {12,-9},  {11,-10}, {10,-11}, {9,-12},  {8,-13},  {7,-13},  {6,-14},   {5,-14},   {4,-14},  {3,-15},  {2,-15},  {1,-15},  {0,-15},
  {-1,-15}, {-2,-15},  {-3,-15},  {-4,-14}, {-5,-14}, {-6,-14}, {-7,-13}, {-8,-13}, {-9,-12}, {-10,-11}, {-11,-10}, {-12,-9}, {-12,-8}, {-13,-7}, {-13,-6}, {-14,-5},
  {-14,-4}, {-14,-3},  {-14,-2},  {-14,-1}
};

Point camera;
Point mapLocation = {16,16};

struct Ball 
{
  Point point;
  int8_t xspeed;
  int8_t yspeed;  
};

Ball ball[MAX_BALLS];
uint8_t ballsVisible = MAX_BALLS;

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

uint8_t tilemapBuffer[VISABLE_TILES_PER_ROW]; // a small buffer to store one horizontal row of tiles from the tilemap

void loop() {
  if (!arduboy.nextFrame()) return;

  arduboy.pollButtons();
  if ((arduboy.justPressed(A_BUTTON) && ballsVisible < MAX_BALLS)) ballsVisible++; // Pressing A button increases the number of visible balls until the maximum has been reached
  if ((arduboy.justPressed(B_BUTTON) && ballsVisible > 0)) ballsVisible--;         // Pressing B reduces the number of visible balls until none are visible
  if (arduboy.pressed(UP_BUTTON) && mapLocation.y > 16) mapLocation.y--;           // Pressing directional buttons will scroll the tilemap
  if (arduboy.pressed(DOWN_BUTTON) && mapLocation.y < 176) mapLocation.y++; 
  if (arduboy.pressed(LEFT_BUTTON) && mapLocation.x > 16) mapLocation.x--;
  if (arduboy.pressed(RIGHT_BUTTON) && mapLocation.x < 112) mapLocation.x++; 
  
  camera.x = mapLocation.x + circlePoints[pos].x; // circle around a fixed point
  camera.y = mapLocation.y + circlePoints[pos].y;
  
  //draw tilemap
  for (int8_t y = 0; y < VISABLE_TILES_PER_COLUMN; y++)
  {
    Cart::readDataArray(tilemap,                   // read the visible tiles on a row from the tilemap in external flash
                        y + camera.y / tileHeight, // the tilemap row
                        camera.x / tileWidth,      // the column within tilemap row
                        tilemapWidth,              // use the width of tilemap as array element size
                        tilemapBuffer,             // reading tiles into a small buffer is faster then reading each tile individually
                        VISABLE_TILES_PER_ROW);

    for (uint8_t x = 0; x < VISABLE_TILES_PER_ROW; x++)
    {
      Cart::drawBitmap(x * tileWidth - camera.x % tileWidth,   // we're substracting the tile width and height modulus for scrolling effect
                       y * tileHeight - camera.y % tileHeight, //
                       gfx1,                                   // the tilesheet bitmap offset in external flash
                       tilemapBuffer[x],                       // tile index
                       dbmNormal);                             // draw a row of normal tiles
    }
  }
  if (arduboy.notPressed(UP_BUTTON | DOWN_BUTTON | LEFT_BUTTON | RIGHT_BUTTON)) pos = ++pos % CIRCLE_POINTS; //only circle around when no directional buttons are pressed
  
  //draw balls
  for (uint8_t i=0; i < ballsVisible; i++)
    Cart::drawBitmap(ball[i].point.x,                // although the function is called drawBitmap it can also draw masked sprites
                     ball[i].point.y, 
                     gfx2,                           // the ball sprites masked bitmap offset in external flash memory
                     0,                              // currently there's only a single sprite frame
                     dbmMasked /* | dbmReverse */ ); // remove the '/*' and '/*' to reverse the balls into white balls
                     
  //update ball movements
  for (uint8_t i=0; i < ballsVisible; i++)
  {
    if (ball[i].xspeed > 0) // Moving right
    {
      ball[i].point.x += ball[i].xspeed;
      if (ball[i].point.x > WIDTH - ballWidth) //off the right
      {
        ball[i].point.x = WIDTH - ballWidth;
        ball[i].xspeed = - ball[i].xspeed;
      }
    }
    else // moving left
    {
      ball[i].point.x += ball[i].xspeed;
      if (ball[i].point.x < 0) // off the left
      {
        ball[i].point.x = 0;
        ball[i].xspeed = - ball[i].xspeed;
      }
    }
    if (ball[i].yspeed > 0) // moving down
    {
      ball[i].point.y += ball[i].yspeed;
      if (ball[i].point.y > HEIGHT - tileHeight) // off the bottom
      {
        ball[i].point.y = HEIGHT - tileHeight;
        ball[i].yspeed = - ball[i].yspeed;
      }
    }
    else // moving up
    {
      ball[i].point.y += ball[i].yspeed;
      if (ball[i].point.y < 0) // off the top
      {
        ball[i].point.y = 0;
        ball[i].yspeed = - ball[i].yspeed;
      }
    }
  }
      
  Cart::enableOLED();// only enable OLED for updating the display
  arduboy.display(CLEAR_BUFFER);
  Cart::disableOLED();// disable so flash cart can be used at any time
}

