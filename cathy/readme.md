## Cathy3K 

An optimized reversed Caterina bootloader in assembly  with added features
under 3K for Arduboy and Arduino Leonardo, Micro and Esplora.

### Main features

  bootloader size is under 3K alllowing 1K more space for Application section.
* dual magic key address support (0x0800 and RAMEND-1) for more reliable
  bootloader triggering from arduino IDE
* Software boot area protection. Sketches can't overwrite the bootloader area
  regardless of fuse settings.
* Identifies itself as serial programmer 'CATHY3K' with software version 1.1
* Supports everything Caterina bootloader supports.

Note:  Boot size fuses must be set to BOOTSZ1 = 0 and BOOTSZ0 to 1 (1K-word)

### Arduboy exclusive features

* Breathing RGB LED in bootloader mode
* Power on + Button Down launces bootloader instead of application
* Button Down in bootloader mode Extends bootloader timeout period
* USB icon is displayed on display to indicate bootloader mode.
* Data can be written to display using Write Memory Block command (streaming)
* Button states can be read using hardware version command
* Set LED command can be used to turn display on/of, control RGB LED breathing,
* RxLED TxLED status fuctions and control the LEDs individually.
* Identifies itself as serial programmer 'ARDUBOY' with software version 1.1
