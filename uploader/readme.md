# Python Hex file uploader for Arduboy

### Features

* supports uploading to Arduboy, DevKit, Arduino Leonardo,Arduino/Genuino Micro and Pro Micro boards
* supports .hex files, .hex files in .zip and .arduboy files
* no need to setup serial port manually

### Usage:

* Can be used from command line
* Drag and drop .hex or .arduboy files on the **uploader.py** file
* Create shortcut in send to folder and use right click **send to** in explorer
* Create shortcut in quick lauch bar and drag and drop files onto *Quick launch* bar

### Dependencies

* Windows OS
* Requires Python 2.7.x with PySerial installed
* Uses Avrdude for uploading (included with this archive)

### Creating Send To folder and Quick lauch shortcuts

1) Browse to the uploader folder and right click **uploader.py** and select create shortcut. Rename the shortcut to Hex uploader.
2) select the newly created shortcut and press CTRL + X to move the shortcut.
3) Press Windows Key + R to open the Run dialog box and type **shell:sendto** and press enter.
4) Click inside the newly open window and press CTRL + V to paste the shortcut.
5) select the newly pasted shortcut and press CTRL + C to copy it.
6) Press Windows Key + R again for rhe Run dialog box and type **shell:quick launch** (including the space) and press enter.
7) Click inside the newly open window and press CTRL + V to paste the shortcut.
