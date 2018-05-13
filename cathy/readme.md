## Cathy2K

An optimized reversed Caterina bootloader in assembly  with added features
in 2K for Arduboy and Arduino Leonardo, Micro and Esplora.

### Main features

  * bootloader size is under 2K alllowing 2K more space for Applications.

  * 100% Arduino compatible.

  * dual magic key address support (0x0800 and RAMEND-1) with LUFA boot
      at 0x7FFE for reliable bootloader triggering from arduino IDE

  * self reprogramming from application area via FlashPage vector at 0x7FFC

  * Identifies itself as serial programmer 'CATHY2K' with software version 1.2

  Note:  Boot size fuses must be set to BOOTSZ1 = 0 and BOOTSZ0 to 1 (1K-word)

  Additional Arduboy exclusive features (included only when building for Arduboy):

  * Power on + Button Down launces bootloader instead of application

  * OLED display is reset on power on / entering bootloader mode

  * Button Down in bootloader mode freezes the bootloader timeout period

  * Identifies itself as serial programmer 'ARDUBOY' with software version 1.2

  The following concessions where made to fit bootloader in 2K:

  * LLED breathing feature removed.

  * Flash Low byte, flash high byte and Page write commands are removed. These
    commands are not used because flash writing is done using the write block
    command.

  * Read flash word command. Again it is not used because all flash reading is
    done using the read block command. A single word can be read as a 2 byte
    block if required.

  * Write single EEPROM byte. Command not used. write EEPROM block command is
    used instead. A single EEPROM byte can be written as a one byte block.

  * Read single EEPROM byte. Command not used. read EEPROM block command is
    used instead. A single EEPROM byte can be read as a ne byte block.

  Arduboy Only:

  - (non mandatory) Device discriptor Manufacturer string removed

### EXAMPLE Self flashing function:

```C++
void flashPage(const uint8_t *dataInRam, uint16_t targetAddress)
{
  uint8_t oldSREG = SREG;
  asm volatile(
    "    cli                   \n" //disable interrupts
    "    call    0x7FFC        \n" //flashPage vector
    : "+x" (dataInRam)
    : "z" (targetAddress)
    : "r24", "r25"
  );
  SREG = oldSREG;
}
```
  
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
