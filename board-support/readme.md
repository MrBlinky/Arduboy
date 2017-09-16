# Arbudoy and D.I.Y variants board surport

By adding this package to the Arduino IDE (1.8+) you can easly build games for different Arduboy variants by selecting the Arduboy board and
variant from the tools menu. This package also contains the most popular Arduboy libraries so there's no need to install them manually.

* Arduboy production & DevKit
* Arduino Leonardo boards with SH1106, SSD1306 OLED displays
* Arduino Micro boards with SH1106, SSD1306 OLED displays
* Pro Micro boards with SH1106, SSD1306 OLED displays (read on below)

## Installation Instructions

To install the Arduboy variants package, start Arduino and open the Preferences window (File > Preferences) then
copy and paste the following URL into the 'Additional Boards Manager URLs' input field:

https://raw.githubusercontent.com/MrBlinky/Arduboy/master/board-support/package_arduboy_variants_index.json

Note if you already have board URLs in the field, add a ',' (comma) at the end and then paste the above URL.

### Pro Micro

The Pro Micro is the smallest board usable for making your own Arduboy. But not all pins used by Arduboy are broken out.
These Pins are:

* Pin 12 (PORTD6) used for OLED Chip Select.
* Pin 11 (PORTB7) used for controlling the Green LED.
* Pin 13 (PORTC7) used as second speaker pin.

The Arduboy and Arduboy2 libraries in this package uses the following alternatives when a ProMicro variant in selected in the tools menu:

* Pin 1 (PORTD3) used for OLED Chip Select.
* Pin 3 (PORTD0) used for controlling the Green LED.
* Pin 2 (PORTD1) used as second speaker pin.
