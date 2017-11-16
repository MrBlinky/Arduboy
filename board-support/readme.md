# Arduboy and D.I.Y variants board surport

By adding this package to the Arduino IDE (1.8+) you can easly build games for different Arduboy variants by selecting the Arduboy board and
variant from the tools menu. This package also contains the most popular Arduboy libraries to make it easier for beginners.

* Arduboy production & DevKit
* Arduino Leonardo boards with SH1106, SSD1306 OLED displays
* Arduino Micro boards with SH1106, SSD1306 OLED displays
* Pro Micro boards with SH1106, SSD1306 OLED displays (read on below)

## Installation Instructions

To install the Arduboy variants package, start the Arduino IDE and open the preferences window (**File > Preferences**)

![preferences](https://raw.githubusercontent.com/MrBlinky/Arduboy/master/board-support/images/preferences.png)

Copy and paste the following URL into the **Additional Boards Manager URLs** input field:
```
https://raw.githubusercontent.com/MrBlinky/Arduboy/master/board-support/package_arduboy_variants_index.json
```
Note if you already have one or more board URLs in the field, add a ',' (comma) at the end and then paste the above URL.

After closing preferences, open the boards manager by going to **tools > boards > board manager** and type **Arduboy** in the search bar at the top. Select **Arduboy and D.I.Y variants** and click install. Go back to **tools > boards** and select **Arduboy**. Go to **tools** once more and select your Arduboy **Variant** and you're ready to go. When you need to compile for a different Arduboy, just change the variant in the tools menu and click upload.
### Select board menu ###
![Select board menu](https://raw.githubusercontent.com/MrBlinky/Arduboy/master/board-support/images/select-arduboy-board.png)
### Select variant menu ###
![Select variant menu](https://raw.githubusercontent.com/MrBlinky/Arduboy/master/board-support/images/select-arduboy-variant.png)

### Pro Micro

The Pro Micro is the smallest board usable for making your own Arduboy. But not all pins used by Arduboy are broken out (not available).
These Pins are:

* Pin 12 (PORTD6) used for OLED Chip Select.
* Pin 11 (PORTB7) used for controlling the Green LED.
* Pin 13 (PORTC7) used as second speaker pin.

The Arduboy and Arduboy2 libraries in this package use the following alternatives when a ProMicro variant is selected in the tools menu:

* Pin 1 (PORTD3) used for OLED Chip Select.
* Pin 3 (PORTD0) used for controlling the Green LED.
* Pin 2 (PORTD1) used as second speaker pin.

### using variants in sketches

To add board and/or display exclusive code to your sketches you can check for the following defines using #ifdef / #ifndef preprocessor commands:
* **ARDUINO_AVR_ARDUBOY** defined when Arduboy production version is selected.
* **ARDUINO_AVR_ARDUBOY_DEVKIT** defined when Arduboy DevKit is selected.
* **ARDUINO_AVR_LEONARDO** defined when Arduino Leonardo is selected.
* **ARDUINO_AVR_MICRO** defined when Arduino Micro is selected.
* **ARDUINO_AVR_PROMICRO** defined when Pro Micro 5V is selected.

In addition to the above defines you can also use these:

* **ARDUBOY_10** defined for Arduboy production version and all variants but the DevKit.
* **AB_DEVKIT** defined for Arduboy DevKit only.

Checking for alternative displays can be done using the following defines:

* **OLED_SH1106** defined when a variant with SH1106 display is selected.
* **OLED_SSD1309** defined when a variant with SSD1309 display is selected.

For boards not having the builtin LED (only Leonardo and Micro have the LED) the standard Arduino define **LED_BUILTIN** is set to use the RxLED so the Blink example sketch will make the RX LED on Arduboy.

## Arduboy +1K

The Arduboy +1K board and variants are the same as above except that the Arduboy board uses the Cathy 3K Arduboy bootloader which gives you 1K more application space. If your Arduboy doesn't have this bootloader yet then you can burn it using the Arduino IDE.

### Libraries

Note. Libraries that are in your sketchbook (installed manually or through the Library manager) overrule the libraries in this board package. So if you've installed the **Arduboy** and **Arduboy2** Libraries, you need to remove them. You can do this by going to **preferences** again, copy the Sketchbook location then press Windowskey + R for the run dialog, paste the sketchbook location and hit enter or click ok. open the **libraries** directory and delete or rename the **Arduboy** and **Arduboy2** directories


### Default package and library locations

On Windows:
* Package location: **%localappdata%\Arduino15\packages**
* Library location: **%userprofile%\Documents\Arduino**


