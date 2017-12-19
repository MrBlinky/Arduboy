void idle(void)
{
  if (arduboy.everyXFrames(30))
  {
    if (caption < 3) caption++;
    else caption = 0;
  }
  if (arduboy.buttonsState()) 
  {
    gameState = GS_INTRO;
    caption = 0;
    poleState = PS_UP;
  }
}

void intro(void)
{
  if (poles[2] != SLICE_COUNT) return;

  if (sliceState == SS_IDLE)
  {
    for (byte i = 0; i < SLICE_COUNT; i++)
    {
      if (slices[i].pole == 0)
      {
        slices[i].pole = 1;
        slices[i].pos  = i + 1;
        selectedSlice  = i + 1;
        break;
      }
    }
    if (selectedSlice)
    {
      sliceState = SS_DOWN;
      selectedSlice_x       = GFX_SLICE_X;
      selectedSlice_end_x   = selectedSlice_x;
      selectedSlice_y       = GFX_SLICE_HOVER_Y;
      selectedSlice_end_y   = GFX_SLICE_Y - SLICE_SPACING * (selectedSlice - 1);
      selectedSlice_speed_y = 2;
    }
    else
    {
      gameState = GS_PLAY;
      cursor = 1;
      moves = 0;
      caption = CT_MOVES;
    } 
  }
}

void moveCursor(byte buttons)
{
  if ((buttons & LEFT_BUTTON) && (cursor > 1)) {
    cursor--;
    button_delay = CURSOR_REPEAT_DELAY;
  }
  if ((buttons & RIGHT_BUTTON) && (cursor < 3)) 
  {
    cursor++;
    button_delay = CURSOR_REPEAT_DELAY;
  }
}

void moveSlice(byte buttons)
{
  if ((sliceState == SS_HOVER) && (buttons & (DOWN_BUTTON | A_BUTTON | B_BUTTON)))
  { 
    byte pos = 1;
    for (int8_t  i = selectedSlice; i < SLICE_COUNT; i++) 
    {
      if (slices[i].pole == cursor) 
      {
        if (!sound.playing()) sound.tone(80, 200, NOTE_REST,200);
        pos = 0;
        break;
      }
    }
    if (pos)
    {
      for (int8_t i = 0; i < selectedSlice; i++) 
      {
        if (i != selectedSlice - 1) 
          if (slices[i].pole == cursor) 
            pos++;
      }
        selectedSlice_x     = GFX_SLICE_X + GFX_POLE_SPACING * (slices[selectedSlice - 1].pole - 1);
        selectedSlice_end_x = GFX_SLICE_X + GFX_POLE_SPACING * (cursor - 1);
        if (selectedSlice_x < selectedSlice_end_x) 
          selectedSlice_speed_x = 4;
        else 
          selectedSlice_speed_x = -4;
        selectedSlice_y       = GFX_SLICE_HOVER_Y;
        selectedSlice_end_y   = GFX_SLICE_Y - SLICE_SPACING * (pos - 1);
        selectedSlice_speed_y = 2;
        if (slices[selectedSlice - 1].pole != cursor) moves++;
        slices[selectedSlice - 1].pole = cursor;
        slices[selectedSlice - 1].pos = pos;
        sliceState = SS_DOWN;
        button_delay = CURSOR_REPEAT_DELAY;
    }
  }
  if ((sliceState == SS_IDLE) && (buttons & (UP_BUTTON | A_BUTTON | B_BUTTON)))
  {
    for (int8_t i = SLICE_COUNT - 1; i >= 0; i--)
    {
      if (slices[i].pole == cursor)
      {
        selectedSlice_x     = GFX_SLICE_X + GFX_POLE_SPACING * (slices[i].pole - 1);
        selectedSlice_end_x = selectedSlice_x;
        selectedSlice_y     = GFX_SLICE_Y - SLICE_SPACING * (slices[i].pos - 1);
        selectedSlice_end_y = GFX_SLICE_HOVER_Y;
        selectedSlice_speed_y = -2;
        selectedSlice = i + 1;
        sliceState = SS_UP;
        button_delay = CURSOR_REPEAT_DELAY;
        break;
      }
    }
  }
}

void play(void)
{
  //cursor control
  if (button_delay)
  {
    button_delay--;
  } 
  else 
  {
    byte b = arduboy.buttonsState();
    moveCursor(b);
    moveSlice(b);
    if ((sliceState == SS_IDLE) && (slices[4].pole == 3) && (slices[4].pos == SLICE_COUNT)) 
    {
      gameState = GS_END; 
      poleState = PS_DOWN;
      if (moves <= BEST_MOVES) starframe = 1;
      else starframe = 0;
    }
  }
}

void gameover(void)
{
  if (poles[2] != 0)return;
  
  if (arduboy.everyXFrames(45))
  {
    switch (caption)
     {
      case CT_MOVES : if (moves <= BEST_MOVES)
                        caption = CT_PERFECT;
                      else  
                        caption = CT_WELLDONE;
                      break;
      case CT_XMAS  : caption = CT_MOVES;
                      break;
      default       : caption = CT_XMAS; break;
    }
  }
  drawXmasTree(); 
  if (!sound.playing()) sound.tones(xmastree_bgm);
  if (!arduboy.buttonsState()) return; 

  while (arduboy.buttonsState());
  sound.noTone();
  gameState = GS_IDLE;
  caption = 0;
  cursor = 0;
  for (byte i = 0; i < SLICE_COUNT; i++) slices [i] = {0, 0};
}
