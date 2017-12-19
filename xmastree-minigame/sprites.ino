void drawBackground(void)
{
  sprites.drawSelfMasked(GFX_BACKGROUND_X, GFX_BACKGROUND_Y, background, 0);
  //fireplace
  sprites.drawSelfMasked(GFX_FIRE_X, GFX_FIRE_Y, fire, fireframe);
  if (arduboy.everyXFrames(5)) 
  {
    fireframe++;
    fireframe &= 0x03;
  }
}

void drawCaption(void)
{
  if (caption) 
  {
    byte c = caption - 1;
    byte w = pgm_read_byte(captions[c]);
    byte x = GFX_CAPTION_X - w / 2;
    int m = moves;
    if (caption == CT_MOVES)
    {
      if (m >  9) x -= 4;
      if (m > 99) x -= 4;
      x -= 5;
    }
    sprites.drawSelfMasked(x, GFX_CAPTION_Y, captions[c], 0);
    if (caption == CT_MOVES)
    {
      x += w + 5;
      if (m > 99) 
      { 
        sprites.drawSelfMasked(x, GFX_CAPTION_Y, numbers, m / 100); 
        x += 7; 
      }
      if (m >  9) 
      {
        m %= 100; 
        sprites.drawSelfMasked(x, GFX_CAPTION_Y, numbers, m / 10) ; x += 7;
        m %=  10; 
      }
      sprites.drawSelfMasked(x, GFX_CAPTION_Y, numbers, m);
    }
  }
}

void drawPoles(void)
{  
  for (byte i = 0; i < 3; i++) 
  {
    if (poles[i]) sprites.drawPlusMask(GFX_POLE_X + i * GFX_POLE_SPACING, GFX_POLE_Y, pole_plus_mask, poles[i] - 1);
  }
  if (arduboy.everyXFrames(2)) for (byte i = 0; i < 3; i++)
  {
    if (poleState == PS_UP)
      if (poles[i] < SLICE_COUNT) {
        poles[i]++;
        break;
      }
    if (poleState == PS_DOWN)
      if (poles[i] > 0) 
      {
        poles[i]--;
        break;
      }
  }
}

void drawCursor(void)
{
  if (cursor) 
  {
    sprites.drawPlusMask(GFX_CURSOR_X + (cursor -1) * GFX_POLE_SPACING, GFX_CURSOR_Y, cursor_plus_mask, 0);
  }
}

void drawSlices(void)
{
  for(byte i = 0; i < SLICE_COUNT; i++)
  {
    if (selectedSlice == i + 1)
    {
      sprites.drawPlusMask(selectedSlice_x, selectedSlice_y, slices_plus_mask, i);
      if (selectedSlice_x != selectedSlice_end_x) 
      {
        selectedSlice_x += selectedSlice_speed_x;
      }  
      else if (selectedSlice_y != selectedSlice_end_y) 
      {
        selectedSlice_y += selectedSlice_speed_y;
      }
      else 
      {
        if (sliceState == SS_UP)
        {
          sliceState = SS_HOVER;
        }
        if (sliceState == SS_DOWN)
        {
          selectedSlice = 0;
          sliceState = SS_IDLE;
        }
      }
    } 
    else if (slices[i].pole && slices[i].pos) 
    {
      sprites.drawPlusMask(GFX_SLICE_X + (slices[i].pole -1) * GFX_POLE_SPACING, GFX_SLICE_Y - SLICE_SPACING * (slices[i].pos - 1), slices_plus_mask, i);
    }
  }
}

void drawXmasTree(void)
{
  if (starframe) 
  {
    sprites.drawPlusMask(GFX_STAR_X + (cursor -1) * GFX_POLE_SPACING, GFX_STAR_Y, star_plus_mask, starframe);
    if (arduboy.everyXFrames(5)) 
    {
      if (starframe < 2) starframe++;
      else starframe = 1;
    }
  }
  if (cursor) 
  {
    sprites.drawPlusMask(GFX_XMASTREE_X + (cursor -1) * GFX_POLE_SPACING, GFX_XMASTREE_Y, xmastree_plus_mask, 0);
  }
}

