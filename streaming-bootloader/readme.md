## Streaming bootloader (Bad Apple) demo

Python script that sends Image data continiously to Arduboy while in bootloader mode until the A or B button is pressed. Pressing Left or rightbutton will turn the status LEDs off and on respectively.

### How does it work
The **Cathy3K** Arduboy bootloader supports a new memory type 'D' for the write block command ('B') that writes to a display buffer. When the end of the 1K display buffer is reached, the display buffer is copied to the Arduboy's OLED display.

Buttons states are read by requesting the hardware version using the 'v' command. When issued it returns a two character version number with the buttons data encoded as following:

First character:
'1' + (BUTTON_A << 1) + (BUTTON_B)

Second character:
'A' + (BUTTON_UP << 3) + (BUTTON_RIGHT << 2) + (BUTTON_LEFT << 1) + (BUTTON_DOWN)

For more info see **Cathy3K**

## Requirements
* Arduboy must be flashed with the Cathy3K Arduboy bootloader
* Python 2.7 + PySerial on Windows.
