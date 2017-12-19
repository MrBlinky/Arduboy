#include <Arduino.h>
#include <Arduboy2.h>
#include <ArduboyTones.h>
#include "bitmaps.h"
#include "music.h"

#define GS_IDLE      0
#define GS_INTRO     1
#define GS_PLAY      2
#define GS_END       3

#define GFX_BACKGROUND_X 0
#define GFX_BACKGROUND_Y 0
#define GFX_CAPTION_X (WIDTH / 2)
#define GFX_CAPTION_Y 2
#define GFX_FIRE_X 38
#define GFX_FIRE_Y 42
#define GFX_POLE_X 17
#define GFX_POLE_Y 15
#define GFX_POLE_SPACING 44
#define GFX_XMASTREE_X 3
#define GFX_XMASTREE_Y 13
#define GFX_STAR_X 13
#define GFX_STAR_Y 5
#define GFX_CURSOR_X 6
#define GFX_CURSOR_Y 53

#define SLICE_COUNT       5
#define SLICE_SPACING     8
#define GFX_SLICE_X       3
#define GFX_SLICE_Y       (13 + (SLICE_COUNT - 1) * SLICE_SPACING)
#define GFX_SLICE_HOVER_Y 5

#define BEST_MOVES 31

const unsigned char * captions[] = 
{
  press_gfx,
  anybutton_gfx,  
  toplay_gfx,
  moves_gfx,
  welldone_gfx,
  perfect_gfx,
  merryxmas_gfx
};
#define CT_PRESS    1
#define CT_BUTTON   2
#define CT_PLAY     3
#define CT_MOVES    4
#define CT_WELLDONE 5
#define CT_PERFECT  6
#define CT_XMAS     7

Arduboy2 arduboy;
Sprites sprites;
ArduboyTones sound(arduboy.audio.enabled);

byte gameState;
byte caption;
byte fireframe;
byte starframe;

byte poles[3];
byte poleState;
#define PS_IDLE 0
#define PS_UP   1
#define PS_DOWN 2

struct slice_t
{
 int pole;
 int pos;
};
slice_t slices[SLICE_COUNT];
byte sliceState;
#define SS_IDLE  0
#define SS_UP    1
#define SS_HOVER 2
#define SS_DOWN  3
byte selectedSlice;
byte selectedSlice_x;
byte selectedSlice_end_x;
byte selectedSlice_speed_x;
byte selectedSlice_y;
byte selectedSlice_end_y;
byte selectedSlice_speed_y;
int moves;
byte cursor;
byte button_delay;
#define CURSOR_REPEAT_DELAY 6
byte cardMode;

void setup() 
{
  arduboy.begin();
  gameState = GS_IDLE;
  arduboy.setFrameRate(30);
}

void loop() 
{
  if (!(arduboy.nextFrame())) return;
  
  drawBackground();
  drawCaption();
  drawPoles();
  drawSlices();
  switch (gameState)
  {
    case GS_IDLE  : idle(); break;
    case GS_INTRO : intro(); break;
    case GS_PLAY  : play(); break;
    case GS_END   : gameover(); break;
  }
  drawCursor();
  arduboy.display(true);
}
