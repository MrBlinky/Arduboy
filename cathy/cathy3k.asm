;===============================================================================
;
;                              ** Cathy 3K **
;
;  An optimized reversed Caterina bootloader with added features in 3K
;           For Arduboy
;
;                   Assembly optimalisation and Arduboy features
;                         by Mr.Blinky Oct 2017 - August 2018
;
;             m s t r <d0t> b l i n k y <at> g m a i l <d0t> c o m
;
; This bootloader will require the boot size fuses to be set  to BOOTSZ1 = 0 and
; BOOTSZ0 = 1 (2K-byte/1K-word)
;
;  Main features:
;
;  - Bootloader size is under 3K alllowing 1K more space for Applications
;
;  - Built in menu to program sketches from external serial (SPI) Flash memory
;
;  - 100% Arduino compatible
;
;  - Dual magic key address support (0x0800 and RAMEND-1) with LUFA boot
;     signaturefor more reliable bootloader triggering from arduino IDE
;
;  - longer default bootloader timeout for slower systems
;
;  - Power on + Button Down launces bootloader instead of programmed sketch
;
;  - RGB LED flashes alternately red, green , blue in normal bootloader mode
;
;  - Display shows USB icon when no serial flash is available or initialized
;
;  - Button Down in bootloader mode extends the bootloader timeout period
;
;  - Identifies itself as serial programmer 'ARDUBOY' with software version 1.4
;
;  - Added command to write to OLED display 
;
;  - Added command to read button states
;
;  - Added command to control LEDs and button input
;
;  - Added command to read and write to serial flash memory
;
;  - Sketch self flashing support through vector at 0x7FFC
;
;  - Software bootloader area protection to protect from accidental overwrites
;
;  the following obselete commands where removed:
;
;  - Flash Low byte, flash high byte and Page write commands are removed. These
;    commands are not used because flash writing is done using the write block
;    command.
;
;  - Read flash word command. Again it is not used because all flash reading is
;    done using the read block command. A single word can be read as a 2 byte
;    block if required.
;
;  - Write single EEPROM byte. Command not used. write EEPROM block command is
;    used instead. A single EEPROM byte can be written as a one byte block.
;
;  - Read single EEPROM byte. Command not used. read EEPROM block command is
;    used instead. A single EEPROM byte can be read as a ne byte block.
;
;  Licenced as below (MIT)
;
;-------------------------------------------------------------------------------
;
;             LUFA Library
;     Copyright (C) Dean Camera, 2011.
;
;  dean [at] fourwalledcubicle [dot] com
;           www.lufa-lib.org
;
;  Permission to use, copy, modify, distribute, and sell this
;  software and its documentation for any purpose is hereby granted
;  without fee, provided that the above copyright notice appear in
;  all copies and that both that the copyright notice and this
;  permission notice and warranty disclaimer appear in supporting
;  documentation, and that the name of the author not be used in
;  advertising or publicity pertaining to distribution of the
;  software without specific, written prior permission.
;
;  The author disclaim all warranties with regard to this
;  software, including all implied warranties of merchantability
;  and fitness.  In no event shall the author be liable for any
;  special, indirect or consequential damages or any damages
;  whatsoever resulting from loss of use, data or profits, whether
;  in an action of contract, negligence or other tortious action,
;  arising out of or in connection with the use or performance of
;  this software.
;
;===============================================================================
;Adjustable timings
#define TIMEOUT_PERIOD         14000    //;uint16 bootloader timeout duration
                                          ;in millisecs for 5x RGB flash cycles
#define TX_RX_LED_PULSE_PERIOD  100     //; uint8 rx/tx pulse period in millisecs

;-------------------------------------------------------------------------------
;Externally supplied defines (commmand line/makefile)

; #define ARDUBOY_DEVKIT    //;configures hardware for official  Arduboy DevKit

; #define ARDUBOY_PROMICRO  //;For Arduboy clones using a Pro Micro 5V using
;                             ;alternate pins for OLED CS, RGB Green and 2nd
;                             ;speaker pin (speaker is not initialized though)

; #define OLED_SH1106       //;for Arduboy clones using SH1106 OLED display only

; #define LCD_ST7565        //;for Arduboy clones using ST7565 LCD displays with
;                           //;RGB backlight and Power LED

;the DEVICE_VID and DEVICE_PID will determine for which board the build will be
;made. (Arduino Leonardo, Arduino Micro, Arduino Esplora, SparkFun ProMicro)

;USB device and vendor IDs
; #define DEVICE_VID                0x2341  //; Arduino LLC
; #define DEVICE_PID                0x0036  //; Leonardo Bootloader

;===============================================================================
;boot magic

#define BOOTKEY                 0x7777
#define BOOTKEY_PTR             0x0800  //;original boot key address
#define BOOT_SIGNATURE          0xDCFB  //;LUFA signature for Arduino IDE to use
                                          ;RAMEND-1 to store magic boot key
#define BOOTLOADER_VERSION_MAJOR    1
#define BOOTLOADER_VERSION_MINOR    4

#define BOOT_START_ADDR         0x7400
#define BOOT_END_ADDR           0x7FFF

;boot logo positioning (ARDUBOY)
#define BOOTLOGO_WIDTH          16
#define BOOTLOGO_HEIGHT         (24 / 8)
#define BOOT_LOGO_X             56
#define BOOT_LOGO_Y             (16 / 8)
#define BOOT_LOGO_OFFSET        BOOT_LOGO_X + BOOT_LOGO_Y * 128

#define WIDTH   128
#define HEIGHT  64

;OLED display commands
#define OLED_SET_PAGE_ADDR          0xB0
#if defined OLED_SH1106
  #define OLED_SET_COLUMN_ADDR_LO   0x02
#else
  #define OLED_SET_COLUMN_ADDR_LO   0x00
#endif
#define OLED_SET_COLUMN_ADDR_HI     0x10
#define OLED_SET_DISPLAY_ON         0xAF
#define OLED_SET_DISPLAY_OFF        0xAE

;SPI serial flash
#define CART_CS                     2
#define SFC_PAGE_PROGRAM            0x02
#define SFC_READ_DATA               0x03
#define SFC_READ_STATUS1            0x05
#define SFC_WRITE_ENABLE            0x06
#define SFC_SECTOR_ERASE            0x20
#define SFC_JEDEC_ID                0x9F
#define SFC_RELEASE_POWERDOWN       0xAB
#define SFC_POWERDOWN               0xB9

;-------------------------------------------------------------------------------
;MCU related
;-------------------------------------------------------------------------------

;atmega32u4 signature

#define AVR_SIGNATURE_1         0x1E
#define AVR_SIGNATURE_2         0x95
#define AVR_SIGNATURE_3         0x87

#define APPLICATION_START_ADDR  0x0000
#define SPM_PAGESIZE            0x0080

#define RAMEND                  0x0AFF

;register ports (accessed through ld/st instructions)

#define UEBCHX  0x00F3
#define UEBCLX  0x00F2
#define UEDATX  0x00F1

#define UESTA0X 0x00EE
#define UECFG1X 0x00ED
#define UECFG0X 0x00EC
#define UECONX  0x00EB
#define UERST   0x00EA
#define UENUM   0x00E9
#define UEINTX  0x00E8

#define UDADDR  0x00E3
#define UDIEN   0x00E2
#define UDINT   0x00E1
#define UDCON   0x00E0

#define USBINT  0x00DA
#define USBSTA  0x00D9
#define USBCON  0x00D8
#define UHWCON  0x00D7

#define OCR1AH  0x0089
#define OCR1AL  0x0088

#define TCNT1H  0x0085
#define TCNT1L  0x0084

#define TCCR1B  0x0081

#define TIMSK1  0x006F

#define CLKPR   0x0061

#define WDTCSR  0x0060

;io ports (accessed through in/out instructions)

#define SREG    0x3f
#define SPH     0x3e
#define SPL     0x3d

#define SPMCSR  0x37
#define MCUCR   0x35
#define MCUSR   0x34

#define PLLFRQ  0x32

#define SPDR    0x2E
#define SPSR    0x2D
#define SPCR    0x2C
#define GPIOR2  0x2B
#define GPIOR1  0x2A
#define PLLCSR  0x29

#define EEARH   0x22
#define EEARL   0x21
#define EEDR    0x20
#define EECR    0x1F
#define GPIOR0  0x1E

#define PORTF   0x11
#define DDRF    0x10
#define PINF    0x0f
#define PORTE   0x0e
#define DDRE    0x0d
#define PINE    0x0c
#define PORTD   0x0b
#define DDRD    0x0a
#define PIND    0x09
#define PORTC   0x08
#define DDRC    0x07
#define PINC    0x06
#define PORTB   0x05
#define DDRB    0x04
#define PINB    0x03

;-------------------------------------------------------------------------------
;bit values
;-------------------------------------------------------------------------------

;UEINTX
#define TXINI    0
#define STALLEDI 1
#define RXOUTI   2
#define RXSTPI   3
#define NAKOUTI  4
#define RWAL     5
#define NAKINI   6
#define FIFOCON  7

;UDIEN
#define SUSPE   0
#define SOFE    2
#define EORSTE  3
#define WAKEUPE 4
#define EORSME  5
#define UPRSME  6

;UDINT
#define SUSPI   0
#define SOFI    2
#define EORSTI  3
#define WAKEUPI 4
#define EORSMI  5
#define UPRSMI  6

;UDCON
#define DETACH  0
#define RMWKUP  1
#define LSM     2
#define RSTCPU  3

;USBINT
#define VBUSTI  0

;USBSTA
#define VBUS    0
#define SPEED   3

;USBCON
#define VBUSTE  0
#define OTGPADE 4
#define FRZCLK  5
#define USBE    7

;UHWCON
#define UVREGE  0

;CLKPR
#define CLKPCE  7

;SPMCSR
#define SPMEN   0
#define PGERS   1
#define PGWRT   2
#define BLBSET  3
#define RWWSRE  4
#define SIGRD   5
#define RWWSB   6
#define SPMIE   7





;MCUCR
#define JTD     7
#define PUD     4
#define IVSEL   1
#define IVCE    0

;SPSR
#define SPIF    7
#define WCOL    6
#define SPI2X   0

;SPCR
#define SPIE    7
#define SPE     6
#define DORD    5
#define MSTR    4
#define CPOL    3
#define CPHA    2
#define SPR1    1
#define SPR0    0

;EECR
#define EEPM1   5
#define EEPM0   4
#define EERIE   3
#define EEMPE   2
#define EEPE    1
#define EERE    0


;LED defines
#ifdef ARDUBOY_PROMICRO
 #define OLED_RST        1
 #define OLED_CS         3
 #define OLED_DC         4
 #define RGB_R           6
 #define RGB_G           0
 #define RGB_B           5
 #ifdef LCD_ST7565
  #define RGB_RED_ON      sbi     PORTB, RGB_R
  #define RGB_GREEN_ON    sbi     PORTD, RGB_G
  #define RGB_BLUE_ON     sbi     PORTB, RGB_B
  #define RGB_RED_OFF     cbi     PORTB, RGB_R
  #define RGB_GREEN_OFF   cbi     PORTD, RGB_G
  #define RGB_BLUE_OFF    cbi     PORTB, RGB_B
 #else
  #define RGB_RED_ON      cbi     PORTB, RGB_R
  #define RGB_GREEN_ON    cbi     PORTD, RGB_G
  #define RGB_BLUE_ON     cbi     PORTB, RGB_B
  #define RGB_RED_OFF     sbi     PORTB, RGB_R
  #define RGB_GREEN_OFF   sbi     PORTD, RGB_G
  #define RGB_BLUE_OFF    sbi     PORTB, RGB_B
 #endif
#else
 #ifdef ARDUBOY_DEVKIT
  #define OLED_RST        6
  #define OLED_CS         7
  #define OLED_DC         4
  #define RGB_R           6
  #define RGB_G           7
  #define RGB_B           0
  #define RGB_RED_ON      cbi     PORTB, RGB_B
  #define RGB_GREEN_ON    cbi     PORTB, RGB_B
  #define RGB_BLUE_ON     cbi     PORTB, RGB_B
  #define RGB_RED_OFF     sbi     PORTB, RGB_B
  #define RGB_GREEN_OFF   sbi     PORTB, RGB_B
  #define RGB_BLUE_OFF    sbi     PORTB, RGB_B
 #else
  #define OLED_RST        7
  #define OLED_CS         6
  #define OLED_DC         4
  #define RGB_R           6
  #define RGB_G           7
  #define RGB_B           5
  #ifdef LCD_ST7565
   #define POWER_LED       0   
   #define RGB_RED_ON      sbi     PORTB, RGB_R
   #define RGB_GREEN_ON    sbi     PORTB, RGB_G
   #define RGB_BLUE_ON     sbi     PORTB, RGB_B
   #define RGB_RED_OFF     cbi     PORTB, RGB_R
   #define RGB_GREEN_OFF   cbi     PORTB, RGB_G
   #define RGB_BLUE_OFF    cbi     PORTB, RGB_B
  #else  
   #define RGB_RED_ON      cbi     PORTB, RGB_R
   #define RGB_GREEN_ON    cbi     PORTB, RGB_G
   #define RGB_BLUE_ON     cbi     PORTB, RGB_B
   #define RGB_RED_OFF     sbi     PORTB, RGB_R
   #define RGB_GREEN_OFF   sbi     PORTB, RGB_G
   #define RGB_BLUE_OFF    sbi     PORTB, RGB_B
  #endif
 #endif
#endif

;button defines
#ifdef ARDUBOY_DEVKIT
 #define BTN_UP_BIT        4
 #define BTN_UP_PIN        PINB
 #define BTN_UP_DDR        DDRB
 #define BTN_UP_PORT       PORTB

 #define BTN_RIGHT_BIT     6
 #define BTN_RIGHT_PIN     PINC
 #define BTN_RIGHT_DDR     DDRC
 #define BTN_RIGHT_PORT    PORTC

 #define BTN_LEFT_BIT      5
 #define BTN_LEFT_PIN      PINB
 #define BTN_LEFT_DDR      DDRB
 #define BTN_LEFT_PORT     PORTB

 #define BTN_DOWN_BIT      6
 #define BTN_DOWN_PIN      PINB
 #define BTN_DOWN_DDR      DDRB
 #define BTN_DOWN_PORT     PORTB

 #define BTN_A_BIT         7
 #define BTN_A_PIN         PINF
 #define BTN_A_DDR         DDRF
 #define BTN_A_PORT        PORTF

 #define BTN_B_BIT         6
 #define BTN_B_PIN         PINF
 #define BTN_B_DDR         DDRF
 #define BTN_B_PORT        PORTF

 #define LEFT_BUTTON       5
 #define RIGHT_BUTTON      2
 #define UP_BUTTON         4
 #define DOWN_BUTTON       6
 #define A_BUTTON          1
 #define B_BUTTON          0
#else
 #define BTN_UP_BIT        7
 #define BTN_UP_PIN        PINF
 #define BTN_UP_DDR        DDRF
 #define BTN_UP_PORT       PORTF

 #define BTN_RIGHT_BIT     6
 #define BTN_RIGHT_PIN     PINF
 #define BTN_RIGHT_DDR     DDRF
 #define BTN_RIGHT_PORT    PORTF

 #define BTN_LEFT_BIT      5
 #define BTN_LEFT_PIN      PINF
 #define BTN_LEFT_DDR      DDRF
 #define BTN_LEFT_PORT     PORTF

 #define BTN_DOWN_BIT      4
 #define BTN_DOWN_PIN      PINF
 #define BTN_DOWN_DDR      DDRF
 #define BTN_DOWN_PORT     PORTF

 #define BTN_A_BIT         6
 #define BTN_A_PIN         PINE
 #define BTN_A_DDR         DDRE
 #define BTN_A_PORT        PORTE

 #define BTN_B_BIT         4
 #define BTN_B_PIN         PINB
 #define BTN_B_DDR         DDRB
 #define BTN_B_PORT        PORTB

 #define LEFT_BUTTON       5
 #define RIGHT_BUTTON      6
 #define UP_BUTTON         7
 #define DOWN_BUTTON       4
 #define A_BUTTON          3
 #define B_BUTTON          2
#endif

;LED Control bits
#define LED_CTRL_NOBUTTONS  7
#define LED_CTRL_RGB        6
#define LED_CTRL_RXTX       5
#define LED_CTRL_RX_ON      4
#define LED_CTRL_TX_ON      3
#define LED_CTRL_RGB_R_ON   1
#define LED_CTRL_RGB_G_ON   2
#define LED_CTRL_RGB_B_ON   0

;other LEDs
#define LLED            7
#define LLED_ON         sbi     PORTC, LLED
#define LLED_OFF        cbi     PORTC, LLED

#define RX_LED          0
#define TX_LED          5

#if DEVICE_PID == 0x0037        //; Polarity of the RX and TX LEDs is reversed on the Micro
    #define TX_LED_OFF          cbi  PORTD, TX_LED
    #define TX_LED_ON           sbi  PORTD, TX_LED

    #define RX_LED_OFF          cbi PORTB, RX_LED
    #define RX_LED_ON           sbi PORTB, RX_LED
#else
    #define TX_LED_OFF          sbi  PORTD, TX_LED
    #define TX_LED_ON           cbi  PORTD, TX_LED

    #define RX_LED_OFF          sbi PORTB, RX_LED
    #define RX_LED_ON           cbi PORTB, RX_LED
#endif

;-------------------------------------------------------------------------------
;USB
;-------------------------------------------------------------------------------

;size of structures

#define sizeof_USB_Descriptor_Header_t  2
#define sizeof_DeviceDescriptor         sizeof_USB_Descriptor_Header_t + (8 << 1)
#define sizeof_LanguageString           sizeof_USB_Descriptor_Header_t + (1 << 1)
#define sizeof_ProductString            sizeof_USB_Descriptor_Header_t + (16 << 1)
#define sizeof_ManufacturerString       sizeof_USB_Descriptor_Header_t + (11 << 1)
#define sizeof_ConfigurationDescriptor  62
#define sizeof_USB_ControlRequest_t     8
#define sizeof_LineEncoding             7

;USB_DescriptorTypes:

#define DTYPE_Device                    0x01    ;Indicates that the descriptor is a device descriptor.
#define DTYPE_Configuration             0x02    ;Indicates that the descriptor is a configuration descriptor.
#define DTYPE_String                    0x03    ;Indicates that the descriptor is a string descriptor.
#define DTYPE_Interface                 0x04    ;Indicates that the descriptor is an interface descriptor.
#define DTYPE_Endpoint                  0x05    ;Indicates that the descriptor is an endpoint descriptor.
#define DTYPE_DeviceQualifier           0x06    ;Indicates that the descriptor is a device qualifier descriptor.
#define DTYPE_Other                     0x07    ;Indicates that the descriptor is of other type.
#define DTYPE_InterfacePower            0x08    ;Indicates that the descriptor is an interface power descriptor.
#define DTYPE_InterfaceAssociation      0x0B    ;Indicates that the descriptor is an interface association descriptor.
#define DTYPE_CSInterface               0x24    ;Indicates that the descriptor is a class specific interface descriptor. *
#define DTYPE_CSEndpoint                0x25    ;Indicates that the descriptor is a class specific endpoint descriptor.

;CDC_Descriptor_ClassSubclassProtocol

#define CDC_CSCP_CDCClass               0x02    ;Descriptor Class value indicating that the device or interface belongs to the CDC class.
#define CDC_CSCP_NoSpecificSubclass     0x00    ;Descriptor Subclass value indicating that the device or interfacebelongs to no specific subclass of the CDC class.
#define CDC_CSCP_ACMSubclass            0x02    ;Descriptor Subclass value indicating that the device or interface belongs to the Abstract Control Model CDC subclass.
#define CDC_CSCP_ATCommandProtocol      0x01    ;Descriptor Protocol value indicating that the device or interface belongs to the AT Command protocol of the CDC class.
#define CDC_CSCP_NoSpecificProtocol     0x00    ;Descriptor Protocol value indicating that the device or interface belongs to no specific protocol of the CDC class.
#define CDC_CSCP_VendorSpecificProtocol 0xFF    ;Descriptor Protocol value indicating that the device or interface belongs to a vendor-specific protocol of the CDC class.
#define CDC_CSCP_CDCDataClass           0x0A    ;Descriptor Class value indicating that the device or interface belongs to the CDC Data class.
#define CDC_CSCP_NoDataSubclass         0x00    ;Descriptor Subclass value indicating that the device or interface belongs to no specific subclass of the CDC data class.
#define CDC_CSCP_NoDataProtocol         0x00    ;Descriptor Protocol value indicating that the device or interface belongs to no specific protocol of the CDC data class.

;CDC_ClassRequests

#define CDC_REQ_SendEncapsulatedCommand 0x00    ;CDC class-specific request to send an encapsulated command to the device.
#define CDC_REQ_GetEncapsulatedResponse 0x01    ;CDC class-specific request to retrieve an encapsulated command response from the device.
#define CDC_REQ_SetLineEncoding         0x20    ;CDC class-specific request to set the current virtual serial port configuration settings.
#define CDC_REQ_GetLineEncoding         0x21    ;CDC class-specific request to get the current virtual serial port configuration settings.
#define CDC_REQ_SetControlLineState     0x22    ;CDC class-specific request to set the current virtual serial port handshake line states.
#define CDC_REQ_SendBreak               0x23    ;CDC class-specific request to send a break to the receiver via the carrier channel.

#define LANGUAGE_ID_ENG                 0x0409

;-------------------------------------------------------------------------------
;USB strings

#if DEVICE_PID == 0x0036
#define PRODUCT_STRING          'A','r','d','u','i','n','o',' ','L','e','o','n','a','r','d','o'
#elif DEVICE_PID == 0x0037
#define PRODUCT_STRING          'A','r','d','u','i','n','o',' ','M','i','c','r','o',' ',' ',' '
#elif DEVICE_PID == 0x003C
#define PRODUCT_STRING          'A','r','d','u','i','n','o',' ','E','s','p','l','o','r','a',' '
#elif DEVICE_PID == 0x9205
#define PRODUCT_STRING          'P','r','o',' ','M','i','c','r','o',' ','5','V',' ',' ',' ',' '
#else
#define PRODUCT_STRING          'U','S','B',' ','I','O',' ','b','o','a','r','d',' ',' ',' ',' '
#endif

#if DEVICE_VID == 0x2341
#define MANUFACTURER_STRING     'A','r','d','u','i','n','o',' ','L','L','C'
#elif DEVICE_VID == 0x1B4F
#define MANUFACTURER_STRING     'S','p','a','r','k','F','u','n',' ',' ',' '
#else
#define MANUFACTURER_STRING     'U','n','k','n','o','w','n',' ',' ',' ',' '
#endif
;-------------------------------------------------------------------------------
                            .section .data  ;Initalized data copied to ram
;-------------------------------------------------------------------------------

;Note: this data section must be <= 256 bytes

SECTION_DATA_START:


;- Software ID string - (7 characters)

SOFTWARE_IDENTIFIER:
                            .ascii  "ARDUBOY"

                        ;OLED display initialization data
DisplaySetupData:
                        #if defined(OLED_SSD132X_96X96) || (OLED_SSD132X_128X96) || (OLED_SSD132X_128X128)
                          #if defined(OLED_SSD132X_96X96)
                            .byte   0x15, 0x10, 0x3f        ;Set column start and end address  skipping left most 32 pixels
                          #else        
                            .byte   0x15, 0x00, 0x3f        ;Set column start and end address full width
                          #endif
                          #if defined (OLED_SSD132X_96X96) 
                            .byte   0x75, 0x30, 0x6f        ;Set row start and end address
                          #elif defined (OLED_SSD132X_128X96)
                            .byte   0x75, 0x10, 0x4f
                          #else
                            .byte   0x75, 0x20, 0x5f
                          #endif
                            .byte   0xA0, 0x55              ;set re-map: split odd-even COM signals|COM remap|vertical address increment|column address remap
                            .byte   0xA1, 0x00              ;set display start line
                            .byte   0xA2, 0x00              ;set display offset
                            .byte   0xA8, 0x7F              ;Set MUX ratio
                            .byte   0x81, 0xCF              ;Set contrast
                            .byte   0xB1, 0x21              ;reset and 1st precharge phase length
                            .byte   OLED_SET_DISPLAY_ON     ;display on
                        #elif defined (LCD_ST7565)
                            .byte   0xC8                    ;SET_COM_REVERSE
                            .byte   0x28 | 0x7              ;SET_POWER_CONTROL  | 0x7
                            .byte   0x20 | 0x5              ;SET_RESISTOR_RATIO | 0x5
                            .byte   0x81                    ;SET_VOLUME_FIRST
                            .byte   0x13                    ;SET_VOLUME_SECOND
                            .byte   0xAF                    ;DISPLAY_ON
                        #else
                            .byte   0xD5, 0xF0              ;Display Clock Divisor
                            .byte   0x8D, 0x14              ;Charge Pump Setting enabled
                            .byte   0xA1                    ;Segment remap
                            .byte   0xC8                    ;COM output scan direction
                            .byte   0x81, 0xCF              ;Set contrast
                            .byte   0xD9, 0xF1              ;set precharge
                            .byte   OLED_SET_DISPLAY_ON     ;display on
                            .byte   OLED_SET_COLUMN_ADDR_LO
                        #endif
DisplaySetupData_End:
                            ;USB boot icon graphics

bootgfx:                    .byte   0x00, 0x00, 0xff, 0xff, 0xcf, 0xcf, 0xff, 0xff, 0xff, 0xff, 0xcf, 0xcf, 0xff, 0xff, 0x00, 0x00
                            .byte   0xfe, 0x06, 0x7e, 0x7e, 0x06, 0xfe, 0x46, 0x56, 0x56, 0x16, 0xfe, 0x06, 0x56, 0x46, 0x1e, 0xfe
                            .byte   0x3f, 0x61, 0xe9, 0xe3, 0xff, 0xe3, 0xeb, 0xe3, 0xff, 0xe3, 0xeb, 0xe3, 0xff, 0xe1, 0x6b, 0x3f

;- DeviceDiscriptor structure -

DeviceDescriptor:           ;-header-
                            .byte   sizeof_DeviceDescriptor
                            .byte   DTYPE_Device
                            ;-data-
                            .word   0x0110      ;USB specification version = 01.10
                            .byte   0x02, 0x00  ;
                            .byte   0x00, 0x08  ;
                            .word   DEVICE_VID  ;
                            .word   DEVICE_PID  ;
                            .word   0x0001      ;version                = 00.01
                            .byte   0x02        ;ManufacturerStrIndex   = 2
                            .byte   0x01        ;ProductStrIndex        = 1
                            .byte   0x00        ;SerialNumStrIndex      = NO_DESCRIPTOR
                            .byte   0x01        ;NumberOfConfigurations = FIXED_NUM_CONFIGURATIONS

;- ConfigurationDescriptor structure -

ConfigurationDescriptor:    ;-config.header -
                            .byte   0x09        ;sizeof(USB_Descriptor_Configuration_Header_t)
                            .byte   DTYPE_Configuration
                            ;-config.data -
                            .byte   0x3e, 0x00  ;TotalConfigurationSize = sizeof(USB_Descriptor_Configuration_t)
                            .byte   0x02        ;TotalInterfaces = 2
                            .byte   0x01        ;ConfigurationNumber    = 1
                            .byte   0x00        ;ConfigurationStrIndex  = NO_DESCRIPTOR
                            .byte   0x80        ;ConfigAttributes       = USB_CONFIG_ATTR_BUSPOWERED
                            .byte   0x32        ;MaxPowerConsumption    = USB_CONFIG_POWER_MA(100)
                            ;-CDC_CCI_Interface.header-
                            .byte   0x09        ;sizeof(USB_Descriptor_Interface_t)
                            .byte   DTYPE_Interface
                            ;-CDC_CCI_Interface.data-
                            .byte   0x00        ;InterfaceNumber   = 0
                            .byte   0x00        ;AlternateSetting  = 0
                            .byte   0x01        ;TotalEndpoints    = 1
                            .byte   0x02        ;Class             = CDC_CSCP_CDCClass
                            .byte   0x02        ;SubClass          = CDC_CSCP_ACMSubclass
                            .byte   0x01        ;Protocol          = CDC_CSCP_ATCommandProtocol
                            .byte   0x00        ;InterfaceStrIndex = NO_DESCRIPTOR
                            ;CDC_Functional_Header.header
                            .byte   0x05        ;sizeof(USB_CDC_Descriptor_FunctionalHeader_t)
                            .byte   DTYPE_CSInterface
                            ;CDC_Functional_Header.data
                            .byte   0x00        ;Subtype = 0x00
                            .word   0x0110      ;CDCSpecification = VERSION_BCD(01.10)
                            ;.header
                            .byte   0x04
                            .byte   DTYPE_CSInterface
                            ;.data
                            .byte   0x02
                            .byte   0x04
                            ;.header
                            .byte   0x05
                            .byte   DTYPE_CSInterface
                            ;.data
                            .byte   0x06
                            .byte   0x00
                            .byte   0x01
                            ;.header
                            .byte   0x07
                            .byte   DTYPE_Endpoint
                            ;.data
                            .byte   0x82        ;EndpointAddress   = ENDPOINT_DIR_IN | CDC_NOTIFICATION_EPNUM
                            .byte   0x03        ;Attributes        = EP_TYPE_INTERRUPT | ENDPOINT_ATTR_NO_SYNC
                            .word   0x0008      ;EndpointSize      = CDC_NOTIFICATION_EPSIZE
                            .byte   0xff        ;PollingIntervalMS = 0xFF
                            ;.header
                            .byte   0x09
                            .byte   DTYPE_Interface
                            ;.data
                            .byte   0x01
                            .byte   0x00, 0x02
                            .byte   0x0a, 0x00
                            .byte   0x00, 0x00
                            ;.header
                            .byte   0x07
                            .byte   DTYPE_Endpoint
                            ;.data
                            .byte   0x04
                            .byte   0x02
                            .word   0x0010
                            .byte   0x01
                            ;.header
                            .byte   0x07
                            .byte   DTYPE_Endpoint
                            ;.data
                            .byte   0x83
                            .byte   0x02
                            .word   0x0010
                            .byte   0x01

LanguageString:             ;-header-
                            .byte   sizeof_LanguageString   ;USB_Descriptor_Header.Size
                            .byte   DTYPE_String            ;USB_Descriptor_Header.Type
                            ;-data-
                            .word   LANGUAGE_ID_ENG

ProductString:              ;-header-
                            .byte   sizeof_ProductString    ;USB_Descriptor_Header.Size = 2 + (16 unicode chars) << 1
                            .byte   DTYPE_String            ;USB_Descriptor_Header.Type = DTYPE_String
                            ;-data-
                            .word   PRODUCT_STRING
ManufacturerString:         ;-header-
                            .byte   sizeof_ManufacturerString
                            .byte   DTYPE_String
                            ;-data-
                            .word   MANUFACTURER_STRING
SECTION_DATA_END:

;-------------------------------------------------------------------------------
;Bootloader area
;-------------------------------------------------------------------------------

                            .section .boot, "ax" ;

;Register usage:
;   r0      temp reg
;   r1      zero reg
;   r2, r3  bootloader timeout reg
;   r4, r5  Current Adrress
;   r6, r7  Current application page
;   r8      Current list
;-------------------------------------------------------------------------------
;Reset Vector

VECTOR_00_7800:
                            eor     r1, r1              ;global zero reg
                            out     SREG, r1            ;clear SREG
                            ldi     r24, lo8(RAMEND-2)  ;preserve posible MAGIC KEY at RAMEND-1
                            ldi     r25, hi8(RAMEND-2)
                            out     SPH, r25            ;SP = RAMEND-2
                            out     SPL, r24

                            in      r16, MCUSR          ;save MCUSR state
                            out     MCUSR, r1           ;MCUSR

                            ldi     r24, 0x18           ;we want watch dog disabled asap
                            sts     WDTCSR, r24
                            sts     WDTCSR, r1

                            lds     r20, BOOTKEY_PTR+0  ;r20:21 old BOOTKEY location
                            lds     r21, BOOTKEY_PTR+1
                            pop     r22                 ;r22:23 posible BOOTKEY at RAMEND-1
                            pop     r23
                            rjmp    reset_b0

;-------------------------------------------------------------------------------
;General USB vector

VECTOR_10_7828:             push    r0
                            push    r24
                            push    r25
                            push    r1
                            in      r0, SREG
                            push    r0
                            eor     r1, r1
                            push    r20
                            push    r22
                            lds     r24, USBINT
                            sbrs    r24, 0
                            rjmp    USB_general_int_b3
                            rjmp    USB_general_int_b1

;-------------------------------------------------------------------------------
;Timer 1 comparator A vector

VECTOR_17_7844:
TIMER1_COMPA_interrupt:     push    r0
                            in      r0, SREG                    ;save SREG
                            push    r24
                            push    r25
                            push    r30
                            push    r31
                            eor     r24, r24                    ;use as temp zero reg
                            sts     TCNT1H, r24                 ;reset counter
                            sts     TCNT1L, r24
                            ldi     r30, lo8(IndexedVars)
                            ldi     r31, hi8(IndexedVars)
                            ldd     r25, z+IDX_LEDCONTROL
                            andi    r25, 1 << LED_CTRL_RXTX
                            brne    TIMER1_COMPA_interrupt_b2   ;don't update RxTx LEDs
                            ldd     r25, z+IDX_TXLEDPULSE
                            cp      r24, r25                    ;sets carry if r25 > 0
                            sbc     r25, r24                    ;r25 -0 - carry
                            std     z+IDX_TXLEDPULSE, r25
                            brne    TIMER1_COMPA_interrupt_b1

                            TX_LED_OFF
TIMER1_COMPA_interrupt_b1:
                            ldd     r25, z+IDX_RXLEDPULSE
                            cp      r24, r25                    ;again sets carry if r25 > 0
                            sbc     r25, r24                    ;r25 - 0 - carry
                            std     z+IDX_RXLEDPULSE, r25
                            brne    TIMER1_COMPA_interrupt_b2

                            RX_LED_OFF
TIMER1_COMPA_interrupt_b2:
                            ldd     r25, z+IDX_DEBOUNCEDELAY
                            subi    r25, 1
                            brcs    TIMER1_COMPA_interrupt_b3   ;decrease until 0
                            std     z+IDX_DEBOUNCEDELAY, r25
TIMER1_COMPA_interrupt_b3:
                            ldd     r25, z+IDX_REPEATDELAY
                            subi    r25, 1
                            brcs    TIMER1_COMPA_interrupt_b4   ;decrease until 0
                            std     z+IDX_REPEATDELAY, r25
TIMER1_COMPA_interrupt_b4:
                            cp      r8, r24                     ;don't increase timeout if game lists are selected
                            brne    TIMER1_COMPA_int_end

                            sbis    BTN_DOWN_PIN, BTN_DOWN_BIT  ;don't increase timeout if DOWN button pressed
                            rjmp    TIMER1_COMPA_int_end
                            rcall   TestApplicationFlash
                            breq    TIMER1_COMPA_int_end    ;no sketch loaded

                            movw    r24, r2                 ;get timeout
                            adiw r24, 1                     ;Timeout++
                            movw    r2, r24                 ;set timeout
TIMER1_COMPA_int_end:
                            pop  r31
                            pop  r30
                            rjmp shared_reti

;-------------------------------------------------------------------------------
pll_enable:
                            ldi     r24, 0x10       ;PINDIV (PLL 1:2, clear PLOCK)
                            out     PLLCSR, r24
                            ldi     r24, 0x12       ;PINDIV | PLLE (PLL 1:2, PLL enable)
                            out     PLLCSR, r24
pll_wait_locked:
                            in      r0, PLLCSR
                            sbrs    r0, 0           ;PLOCK
                            rjmp    pll_wait_locked ;wait for PLL locked
                            ret
;-------------------------------------------------------------------------------
USB_general_int_b1:
                            lds     r24, USBCON
                            sbrs    r24, 0
                            rjmp    USB_general_int_b3

                            lds     r24, USBINT
                            andi    r24, 0xFE
                            sts     USBINT, r24
                            lds     r24, USBSTA
                            sbrs    r24, 0
                            rjmp    USB_general_int_b2

                            rcall   pll_enable
                            ldi     r24, 0x01
                            out     GPIOR0, r24
                            rjmp    USB_general_int_b3
USB_general_int_b2:
                            out     PLLCSR, r1
                            out     GPIOR0, r1
USB_general_int_b3:
                            lds     r24, UDINT
                            sbrs    r24, 0
                            rjmp    USB_general_int_b4

                            rcall   UDIEN_get
                            sbrs    r24, 0
                            rjmp    USB_general_int_b4

                            rcall   UDIEN_Clr0_Set4
                            lds     r24, USBCON
                            ori     r24, 0x20
                            rcall   USBCON_set
                            out     PLLCSR, r1
                            ldi     r24, 0x05
                            out     GPIOR0, r24
USB_general_int_b4:
                            lds     r24, UDINT
                            sbrs    r24, 4
                            rjmp    USB_general_int_b8

                            rcall   UDIEN_get
                            sbrs    r24, 4
                            rjmp    USB_general_int_b8
                            rcall   pll_enable
                            lds     r24, USBCON
                            andi    r24, 0xDF
                            rcall   USBCON_set
                            ldi     r24, 0xEF
                            rcall   UDINT_clr_bit
                            rcall   UDIEN_get
                            andi    r24, 0xEF
                            ;rcall   UDIEN_set
                            ori     r24, 0x01
                            rcall   UDIEN_set

                            lds     r24, USB_Device_ConfigurationNumber
                            and     r24, r24
                            brne    USB_general_int_b6

                            lds     r24, UDADDR
                            sbrc    r24, 7
                            rjmp    USB_general_int_b6

                            ldi     r24, 0x01
                            rjmp    USB_general_int_b7
USB_general_int_b6:
                            ldi     r24, 0x04
USB_general_int_b7:
                            out     GPIOR0, r24
USB_general_int_b8:
                            lds     r24, UDINT
                            sbrs    r24, 3
                            rjmp    USB_general_int_ret

                            rcall   UDIEN_get
                            sbrs    r24, 3
                            rjmp    USB_general_int_ret

                            ldi     r24, 0xF7
                            rcall   UDINT_clr_bit
                            ldi     r24, 0x02
                            out     GPIOR0, r24
                            sts     USB_Device_ConfigurationNumber, r1
                            rcall   UDINT_clr_bit0
                            rcall   UDIEN_Clr0_Set4
                            rcall   Endpoint_ConfigureEndpoint_Prv_00_00_02  ;uses: r20,r22,r24,r25
USB_general_int_ret:
                            pop     r22
                            pop     r20
                            pop     r0
                            pop     r1
shared_reti:
                            pop     r25
                            pop     r24
                            out     SREG, r0
                            pop     r0
                            reti
;-------------------------------------------------------------------------------
UDINT_clr_bit0:             ldi     r24, 0xFE
;-------------------------------------------------------------------------------
UDINT_clr_bit:              lds     r0, UDINT
                            and     r0, r24
                            sts     UDINT, r0
                            ret
;-------------------------------------------------------------------------------
reset_b0:
                            rcall   SetupHardware

                            ;initialize .data section

                            ldi     r26, lo8(SECTION_DATA_START)    ;X
                            ldi     r27, hi8(SECTION_DATA_START)
                            ldi     r30, lo8(SECTION_DATA_DATA)     ;Z
                            ldi     r31, hi8(SECTION_DATA_DATA)
reset_b1:
                            lpm     r0, Z+                                                          ;copy data from end of text
                            st      X+, r0                                                          ;to data section in sram
                            cpi     r26, lo8(SECTION_DATA_END)
                            brne    reset_b1

                            ;clear .bss section and remaining ram
reset_b4:
                            st      X+, r1                          ;set to zero
                            cpi     r27, hi8(RAMEND+1)
                            brne    reset_b4

;-------------------------------------------------------------------------------
main:
                            sbrc    r16, 1                  ;MCUSR state EXTRF skip if no external reset
                            rjmp    run_bootloader          ;enter bootloader mode

                            sbrs    r16, 0                  ;MCUSR state PORF test power on reset
                            rjmp    main_test_wdt           ;not POR

                            ;power on reset

                            sbis    BTN_DOWN_PIN, BTN_DOWN_BIT  ;test DOWN button
                            rjmp    run_bootloader              ;button pressed, enter bootloader
                            rjmp    run_sketch              ;run sketch when loaded

                            ;no application or not POR

main_test_wdt:              sbrs    r16, 3                  ;MCUSR state WDRF
                            rjmp    run_bootloader          ;WDT not triggered, enter bootloader mode

                            ;WDT was triggered, test magic key on old and new location

                            subi    r22, lo8(BOOTKEY)       ;test RAMEND-1 key
                            sbci    r23, hi8(BOOTKEY)
                            breq    run_bootloader          ;magic key, enter bootloader mode

                            subi    r20, lo8(BOOTKEY)       ;test old key
                            sbci    r21, hi8(BOOTKEY)
                            breq    run_bootloader          ;magic key, enter bootloader mode

                            ;no BOOTKEY
run_sketch:
                            rcall   TestApplicationFlash
                            brne    StartSketch             ;run application when loaded

                            ;enter bootloader mode
run_bootloader:
                            rcall   SetupHardware_bootloader
                            clr     r2                      ;reset timeout counter
                            clr     r3
                            movw    r6, r2                  ;reset applicaton pointer
                            clr     r8
                            rcall   LoadApplicationInfo
                            sei
bootloader_loop:
                            rcall   CDC_Task
                            rcall   USB_USBTask
                            rcall   ReadButtons
                            rcall   SelectList
                            cp      r8, r1                  ;test bootloader list
                            breq    bootloader_mode

                            ;menu mode

                            rcall   SelectGame
                            rjmp    bootloader_loop
bootloader_mode:
                            rcall   LEDPulse

                            movw    r24, r2                     ;get timeout
                            subi    r24, lo8(TIMEOUT_PERIOD)
                            sbci    r25, hi8(TIMEOUT_PERIOD)
                            brcs    bootloader_loop             ;loop < TIMEOUT_PERIOD
                            ;rjmp   StartSketch

                            ;timeout, start sketch

;-------------------------------------------------------------------------------
StartSketch:
                            cli
                            ldi     r24,SFC_POWERDOWN
                            rcall   SPI_flash_cmd_deselect
                            ldi     r24, 1 << DETACH    ;USB DETACH
                            sts     UDCON, r24
                            sts     TIMSK1, r1          ;Undo TIMER1 setup and clear the count before running the sketch
                            sts     TCCR1B, r1
                            sts     TCNT1H, r1
                            sts     TCNT1L, r1
                            ldi     r24, 1 << IVCE      ;enable interrupt vector change
                            out     MCUCR, r24
                            out     MCUCR, r1           ;relocate vector table to application section
                            rcall   LEDPulse_off
                            TX_LED_OFF
                            RX_LED_OFF
                            jmp     0                   ; start application
;-------------------------------------------------------------------------------
FetchNextCommandByte:
;                       entry:  none
;                       exit:   r24 = byte
;                       uses:   r24,r25

                            rcall   UENUM_set_04_UEINTX_get     ;CDC_RX_EPNUM
                            rjmp    FetchNextCommandByte_b4
FetchNextCommandByte_b1:
                            rcall   UEINTX_clear_FIFOCON_RXOUTI
                            rjmp    FetchNextCommandByte_b3
FetchNextCommandByte_b2:
                            rcall   GPIOR0_test
                            breq    FetchNextCommandByte_ret
FetchNextCommandByte_b3:
                            rcall   UEINTX_get
                            sbrs    r24, RXOUTI
                            rjmp    FetchNextCommandByte_b2
FetchNextCommandByte_b4:
                            sbrs    r24, RWAL
                            rjmp    FetchNextCommandByte_b1
                            ;rjmp   UEDATX_get
;-------------------------------------------------------------------------------
UEDATX_get:
                            lds     r24, UEDATX
FetchNextCommandByte_ret:
                            ret
;-------------------------------------------------------------------------------
WriteNextResponseByte:

;uses r0,r24,r25
                            mov     r0, r24
                            ldi     r24, 0x03
                            rcall   UENUM_set_UEINTX_get
                            sbrc    r24, RWAL
                            rjmp    WriteNextResponseByte_b3

                            rcall   UEINTX_clear_FIFOCON_TXINI
                            rjmp    WriteNextResponseByte_b2
WriteNextResponseByte_b1:
                            rcall   GPIOR0_test
                            breq    WriteNextResponseByte_ret
WriteNextResponseByte_b2:
                            rcall   UEINTX_get
                            sbrs    r24, TXINI
                            rjmp    WriteNextResponseByte_b1
WriteNextResponseByte_b3:
                            sts     UEDATX, r0
                            lds     r24, LED_Control
                            bst     r24, LED_CTRL_RXTX
                            brts    WriteNextResponseByte_ret           ;RxTx LEDs disabled
                            TX_LED_ON
                            ldi     r24, lo8(TX_RX_LED_PULSE_PERIOD)
                            sts     TxLEDPulse, r24
WriteNextResponseByte_ret:
                            ret
;-------------------------------------------------------------------------------
CDC_Task:
                            rcall   UENUM_set_04_UEINTX_get
                            sbrs    r24, RXOUTI
                            rjmp    CDC_Task_ret

                            ;endpoint has command from host

                            lds     r24, LED_Control
                            bst     r24, LED_CTRL_RXTX
                            brts    CDC_Task_b1             ;RxTx LEDs disabled
                            RX_LED_ON
                            ldi     r24, lo8(TX_RX_LED_PULSE_PERIOD)
                            sts     RxLEDPulse, r24
CDC_Task_b1:
                            rcall   FetchNextCommandByte
                            mov     r17, r24                        ;save command
                            ;-----------------------------------End programmer command
                            cpi     r24, 'E'
                            brne    CDC_Task_Command_T

                            ldi     r24, lo8(TIMEOUT_PERIOD - 500)  ;end command, sets timeout to 500 millisecs
                            ldi     r25, hi8(TIMEOUT_PERIOD - 500)
                            movw    r2, r24                         ;SetTimeout
CDC_Task_w1:
                            rcall   eeprom_prep                     ;wait for any EEPROM writes to finish
CDC_Task_Acknowledge:
                            ldi     r24, 0x0D                       ;send acknowledge
                            rjmp    CDC_Task_Response
CDC_Task_Command_T:         ;-----------------------------------select device
                            cpi     r24, 'T'
                            brne    CDC_Task_Command_L

                            rcall   FetchNextCommandByte    ;drop device byte
                            rjmp    CDC_Task_Acknowledge
CDC_Task_Command_L:         ;-----------------------------------leave programming mode
                            cpi     r24, 'L'
                            breq    CDC_Task_Acknowledge     ;just acknowledge

                            ;-----------------------------------enter programming mode
                            cpi     r24, 'P'
                            breq    CDC_Task_Acknowledge     ;just acknowledge

                            ;-----------------------------------Requestsupported device list
                            cpi     r24, 't'
                            brne    CDC_Task_Command_a

                            ;'t': Return ATMEGA128 part code - this is only to allow AVRProg to use the bootloader

                            ldi     r24, 0x44                   ;supported device
                            rcall   WriteNextResponseByte
                            ldi     r24, 0x00                   ;end of supported devices list
                            rjmp    CDC_Task_Response
CDC_Task_Command_a:         ;-----------------------------------auto address increment inquiry
                            cpi     r24, 'a'
                            brne    CDC_Task_Command_A

                            ldi     r24, 'Y'                    ;'Y'es supported
                            rjmp    CDC_Task_Response
CDC_Task_Command_A:         ;-----------------------------------set current address / flash sector
                            cpi     r24, 'A'
                            brne    CDC_Task_Command_p

                            rcall   FetchNextCommandByte
                            mov     r5, r24
                            rcall   FetchNextCommandByte
                            mov     r4, r24
                            rjmp    CDC_Task_Acknowledge
CDC_Task_Command_p:         ;-----------------------------------programmer type
                            cpi     r24, 'p'
                            brne    CDC_Task_Command_S

                            ldi     r24, 'S'                ;'S'erial programmer
                            rjmp    CDC_Task_Response
CDC_Task_Command_S:         ;-----------------------------------send software identifier string response
                            cpi     r24, 'S'
                            brne    CDC_Task_Command_V

                            ldi     r28, lo8(SOFTWARE_IDENTIFIER)
                            ldi     r29, hi8(SOFTWARE_IDENTIFIER)
CDC_Task_SendID:
                            ld      r24, Y+
                            rcall   WriteNextResponseByte
                            cpi     r28, lo8(SOFTWARE_IDENTIFIER + 7)
                            brne    CDC_Task_SendID
                            rjmp    CDC_Task_Complete
CDC_Task_Command_V:         ;-----------------------------------Software version
                            cpi     r24, 'V'
                            brne    CDC_Task_Command_v

                            ldi     r24, '0' + BOOTLOADER_VERSION_MAJOR
                            rcall   WriteNextResponseByte
                            ldi     r24, '0' + BOOTLOADER_VERSION_MINOR
                            rjmp    CDC_Task_Response
CDC_Task_Command_v:         ;-----------------------------------Hardware version
                            cpi     r24, 'v'
                            brne    CDC_Task_Command_x

                            ;'v': Hardware version (returns Arduboy button states)

                            ldi     r24, '1'                ;'1' + (A-button << 1) + (B-button)
                            sbis    BTN_A_PIN, BTN_A_BIT
                            subi    r24, -2
                            sbis    BTN_B_PIN, BTN_B_BIT
                            subi    r24, -1
                            rcall   WriteNextResponseByte
                          #ifdef ARDUBOY_DEVKIT
                            ldi     r24, 'A'
                            sbis    BTN_UP_PIN, BTN_UP_BIT
                            subi    r24, -8
                            sbis    BTN_RIGHT_PIN, BTN_RIGHT_BIT
                            subi    r24, -4
                            sbis    BTN_LEFT_PIN, BTN_LEFT_BIT
                            subi    r24, -2
                            sbis    BTN_DOWN_PIN, BTN_DOWN_BIT
                            subi    r24, -1
                          #else
                            in      r24,PINF            ;read D-Pad buttons
                            com     r24                 ;get active high button states in low nibble
                            swap    r24
                            andi    r24, 0x0F
                            subi    r24,-'A'            ;'A' + (UP << 3) + (RIGHT << 2) + (LEFT << 1) + DOWN
                          #endif
                            rjmp    CDC_Task_Response
CDC_Task_Command_x:         ;-----------------------------------set LEDs
                            cpi     r24, 'x'
                            brne    CDC_Task_Command_j

                            rcall   FetchNextCommandByte
                            sts     LED_Control, r24
                            RX_LED_OFF
                            sbrc    r24,LED_CTRL_RX_ON
                            RX_LED_ON
                            TX_LED_OFF
                            sbrc    r24,LED_CTRL_TX_ON
                            TX_LED_ON
                            RGB_RED_OFF
                            sbrc    r24,LED_CTRL_RGB_R_ON
                            RGB_RED_ON
                            RGB_GREEN_OFF
                            sbrc    r24,LED_CTRL_RGB_G_ON
                            RGB_GREEN_ON
                            RGB_BLUE_OFF
                            sbrc    r24,LED_CTRL_RGB_B_ON
                            RGB_BLUE_ON
                            sbrc    r24, LED_CTRL_NOBUTTONS
                            clr     r8                          ;reset menu to bootloader list
                            rjmp    CDC_Task_Acknowledge
CDC_Task_Command_j:
                            cpi     r24, 'j'
                            brne    CDC_Task_Command_s

                            ;read SPI flash Jedec ID

                            ldi     r24, SFC_JEDEC_ID
                            rcall   SPI_flash_cmd
                            ldi     r28, 3
CDC_Task_get_jedec:
                            rcall   SPI_transfer
                            rcall   WriteNextResponseByte
                            dec     r28
                            brne    CDC_Task_get_jedec
                            rcall   SPI_flash_deselect
                            rjmp    CDC_Task_Complete
CDC_Task_Command_s:         ;-----------------------------------avr signature
                            cpi     r24, 's'
                            brne    CDC_Task_Command_e

                            ldi     r24, AVR_SIGNATURE_3
                            rcall   WriteNextResponseByte
                            ldi     r24, AVR_SIGNATURE_2
                            rcall   WriteNextResponseByte
                            ldi     r24, AVR_SIGNATURE_1
                            rjmp    CDC_Task_Response
CDC_Task_Command_e:         ;-----------------------------------
                            cpi     r24, 'e'                            ;erase chip
                            brne    CDC_Task_Command_b

                            ;'e': erase application section

                            ldi     r30, lo8(BOOT_START_ADDR - SPM_PAGESIZE)
                            ldi     r31, hi8(BOOT_START_ADDR - SPM_PAGESIZE)
CDC_Task_Erase:
                            ;ldi     r24, (1 << PGERS) | (1 << SPMEN)    ;Page erase
                            rcall   SPM_page_erase
                            subi    r30, lo8(SPM_PAGESIZE)
                            sbci    r31, hi8(SPM_PAGESIZE)
                            brcc    CDC_Task_Erase                      ;loop until 1st application page done
                            rjmp    CDC_Task_Acknowledge
CDC_Task_Command_b:         ;-----------------------------------block support command
                            cpi     r24, 'b'
                            brne    CDC_Task_Command_B

                            ldi     r24, 'Y'                ;Yes
                            rcall   WriteNextResponseByte
                            ldi     r24, hi8(SPM_PAGESIZE)
                            rcall   WriteNextResponseByte   ;MSB flash Page size
                            ldi     r24, lo8(SPM_PAGESIZE)
                            rjmp    CDC_Task_Response       ;LSB flash Page size

CDC_Task_Command_B:         ;-----------------------------------Write memory block
                            cpi     r24, 'B'
                            breq    CDC_Task_RdWrBlk
                            ;-----------------------------------Read memory block
                            cpi     r24, 'g'
                            breq    CDC_Task_RdWrBlk
                            rjmp    CDC_Task_TestBitCmds
CDC_Task_RdWrBlk:           ;-----------------------------------'B' or 'g': write/read memory block
                            clr     r2                      ;clear timeout
                            clr     r3
                            rcall   FetchNextCommandByte
                            mov     r29, r24                ;BlockSize MSB
                            rcall   FetchNextCommandByte
                            mov     r28, r24                ;BlockSize LSB
                            rcall   FetchNextCommandByte
                            mov     r16, r24                ;MemoryType
                            subi    r24, 'C'                ;Arduboy Supports 'C'artridge and 'D'isplay memory blocks
                            cpi     r24, 0x04               ;'F' - 'D' + 1
                            brcs    CDC_Task_RdWrBlk_check_f
                            rjmp    CDC_Task_Error          ;not 'D'ISPLAY, 'E'EPROM or 'F'LASH
CDC_Task_RdWrBlk_check_f:
                            cpi     r16, 'F'
                            brne    CDC_Task_RdWrBlk_begin
                            lsl     r4                     ;word to byte addr for Flash
                            rol     r5
CDC_Task_RdWrBlk_begin:
                            movw    r30, r4                 ;get current Address in Z
                            sts     TIMSK1, r1              ;disable timer 1 interrupt
                            cpi     r17, 'g'
                            brne    CDC_Task_WriteMem

                            ;Read Block
CDC_Task_ReadBlk:
                            cpi     r16, 'C'                    ;test SPI flash cart
                            brne    CDC_Task_ReadBlk_next

                            ;read SPI flash cart

                            ldi     r24, SFC_READ_DATA
                            rcall   SPI_flash_cmd_addr          ;send read command, set address
CDC_Task_ReadBlk_cart:
                            rcall   SPI_transfer
                            rcall   WriteNextResponseByte
                            sbiw    r28, 1                      ;length of 0 == 64K length
                            brne    CDC_Task_ReadBlk_cart
CDC_Task_ReadBlk_cart_end:
                            rcall   SPI_flash_deselect
                            rjmp    CDC_Task_ReadBlk_end
CDC_Task_ReadBlk_loop:
                            cpi     r16, 'F'
                            brne    CDC_Task_ReadBlk_EEPROM

                            lpm     r24, Z+
                            rjmp    CDC_Task_ReadBlk_send
CDC_Task_ReadBlk_EEPROM:
                            rcall   eeprom_read
CDC_Task_ReadBlk_send:
                            rcall   WriteNextResponseByte
CDC_Task_ReadBlk_next:
                            sbiw    r28, 0x01
                            brpl    CDC_Task_ReadBlk_loop
CDC_Task_ReadBlk_end:
                            movw    r4, r30                     ;update current Address
                            rjmp    CDC_Task_RdWrBlk_end

                            ;write block
CDC_Task_WriteMem:
                            cpi     r16, 'C'
                            brne    CDC_Task_WriteMem_flash

                            ;write flash cart
CDC_Task_Write_cart_sector:
                            mov     r24, r30                    ;test start of 4K block
                            andi    r24, 0x0f
                            brne    CDC_Task_Write_cart_page

                            rcall   SPI_write_enable
                            ldi     r24, SFC_SECTOR_ERASE
                            rcall   SPI_flash_cmd_addr
                            rcall   SPI_flash_wait
CDC_Task_Write_cart_page:
                            rcall   SPI_write_enable
                            ldi     r24, SFC_PAGE_PROGRAM
                            rcall   SPI_flash_cmd_addr
CDC_Task_Write_cart_data:
                            rcall   FetchNextCommandByte        ;write page data
                            rcall   SPI_transfer
                            dec     r28                         ;test last page byte written
                            brne    CDC_Task_Write_cart_data

                            rcall   SPI_flash_wait              ;program page amd wait to complete
                            adiw    r30, 1                      ;next page
                            dec     r29
                            brne    CDC_Task_Write_cart_sector
                            movw    r4, r30                     ;update current Address
                            rjmp    CDC_Task_WriteMem_end
CDC_Task_WriteMem_flash:
                            cpi     r16, 'F'
                            brne    CDC_Task_WriteMem_next

                            ;write flash memory block

                            movw    r18, r30                    ;save addr for page write
                            cpi     r31, hi8(BOOT_START_ADDR)   ;test extended bootloader area
                            brcc    CDC_Task_WriteMem_next

                            ;Flash memory page erase

                            rcall   SPM_page_erase
                            rjmp    CDC_Task_WriteMem_next

                            ;Write Memory loop
CDC_Task_WriteMem_loop:
                            rcall   FetchNextCommandByte
                            cpi     r16, 'F'
                            brne    CDC_Task_WriteMem_display

                            ;Flash

                            bst     r28, 0                   ;block length
                            brts    CDC_Task_WriteMem_lsb

                            ;msb,  write word

                            cpi     r31, hi8(BOOT_START_ADDR)
                            brcc    CDC_Task_WriteMem_inc

                            mov     r1, r24                 ;word in r0:r1
                            ldi     r24,(1 << SPMEN)
                            out     SPMCSR, r24             ;write word to page buffer
                            spm
                            eor     r1, r1                  ;restore zero reg
CDC_Task_WriteMem_inc:
                            adiw    r30, 2
CDC_Task_WriteMem_lsb:
                            mov     r0, r24                 ;save lsb
                            rjmp    CDC_Task_WriteMem_next

CDC_Task_WriteMem_display:
                            cpi     r16, 'D'
                            brne    CDC_Task_WriteMem_eeprom

                            ;OLED display

                            movw    r26, r30                    ;current addr
                            andi    r27, 0x3                    ;keep 1K address range
                            subi    r26, lo8(-(DisplayBuffer))
                            sbci    r27, hi8(-(DisplayBuffer))
                            st      X+, r24
                            adiw    r30, 1
                            rjmp    CDC_Task_WriteMem_next
                            
                            ;EEPROM
CDC_Task_WriteMem_eeprom:
                            rcall   eeprom_write
CDC_Task_WriteMem_next:
                            sbiw    r28, 0x01
                            brpl    CDC_Task_WriteMem_loop

                            ;block write complete

                            cpi     r16, 'D'
                            brne    CDC_Task_WriteMem_flash_end

                            ;copy display buffer to display if full

                            movw    r4, r30                             ;update current address
                            andi    r31, 0x03
                            or      r31, r30
                            brne    CDC_Task_WriteMem_end               ;update display on 1K overflow
                            rcall   Display
                            rjmp    CDC_Task_WriteMem_end
CDC_Task_WriteMem_flash_end:
                            cpi     r16, 'F'
                            brne    CDC_Task_WriteMem_end

                            ;Flash memory Page write

                            movw    r4, r30
                            movw    r30, r18                           ;page addr

                            cpi     r31, hi8(BOOT_START_ADDR)
                            brcc    CDC_Task_WriteMem_end              ;don't flash pages in protected bootloader area

                            rcall   SPM_page_write
CDC_Task_WriteMem_end:
                            ldi     r24, 0x0D
                            rcall   WriteNextResponseByte
CDC_Task_RdWrBlk_end:
                            cpi     r16, 'F'                    ;convert byte to word addr for flash
                            brne    CDC_Task_RdWrBlk_end_2
                            lsr     r5
                            ror     r4
CDC_Task_RdWrBlk_end_2:
                            ldi     r24, 0x02                   ;OCIE1A
                            sts     TIMSK1, r24                 ;enable timer1 int
                            rjmp    CDC_Task_Complete
CDC_Task_TestBitCmds:       ;-----------------------------------get lock bits
                            cpi     r24, 'r'
                            ldi     r30, 0x01
                            breq    CDC_Task_getfusebits
                            ;-----------------------------------get low fuse bits
                            cpi     r24, 'F'
                            ldi     r30, 0x00
                            breq    CDC_Task_getfusebits
                            ;-----------------------------------get high fuse bits
                            cpi     r24, 'N'
                            ldi     r30, 0x03
                            breq    CDC_Task_getfusebits
                            ;-----------------------------------get extended fuse bits
                            cpi     r24, 'Q'
                            brne    CDC_Task_Command_D

                            ldi     r30, 0x02               ;get extended fuse bits

                            ;r30 = type of bits to read
CDC_Task_getfusebits:
                            ldi     r31, 0x00
                            ldi     r24, 0x09
                            out     SPMCSR, r24
                            lpm     r24, Z
                            rjmp    CDC_Task_Response
CDC_Task_Command_D:         ;-----------------------------------Write EEPROM byte
;                            cpi     r24, 'D'
;                            brne    CDC_Task_Command_d
;
;                            rcall   FetchNextCommandByte
;                            rcall   eeprom_write
;                            rjmp    CDC_Task_Acknowledge
;
;CDC_Task_Command_d:         ;-----------------------------------Read EEPROM byte
;                            cpi     r24, 'd'
;                            brne    CDC_Task_Command_1B
;
;                            rcall   eeprom_read
;                            rjmp    CDC_Task_Response
CDC_Task_Command_1B:        ;-----------------------------------ESCAPE
                            cpi     r24, 0x1B
                            breq    CDC_Task_Complete
CDC_Task_Error:             ;-----------------------------------Unsupported command
                            ldi     r24, '?'
                            ;-----------------------------------(send byte in r24)
CDC_Task_Response:
                            rcall   WriteNextResponseByte
CDC_Task_Complete:          ;-----------------------------------
                            ldi     r24, 0x03
                            rcall   UENUM_set
                            rcall   UEINTX_clear_FIFOCON_TXINI
                            sbrs    r25, RWAL
                            rjmp    x76d6
                            rjmp    x76f0

x76d0:                      rcall   GPIOR0_test
                            breq    CDC_Task_ret

x76d6:                      rcall   UEINTX_get
                            sbrs    r24, TXINI
                            rjmp    x76d0

                            rcall   UEINTX_clear_FIFOCON_TXINI
                            rjmp    x76f0

x76ea:                      rcall   GPIOR0_test
                            breq    CDC_Task_ret

x76f0:                      rcall   UEINTX_get
                            sbrs    r24, TXINI
                            rjmp    x76ea

                            ldi     r24, 4
                            rcall   UENUM_set
                            ;rjmp   UEINTX_clear_FIFOCON_RXOUTI
;-------------------------------------------------------------------------------
UEINTX_clear_FIFOCON_RXOUTI:
                            ldi     r24, ~(1 << FIFOCON | 1 << RXOUTI)
                            rjmp   UEINTX_clearbits
;-------------------------------------------------------------------------------
;PROGMEM
;-------------------------------------------------------------------------------
FlashPage:

;entry:
;    x = *data to burn in ram
;    z = page address
;uses:
;    r0, r24, r25, x
                            cpi     r31, hi8(BOOT_START_ADDR)
                            brcc    SPM_ret                     ;protect bootloader area

                            rcall   SPM_page_erase
                            ldi     r25, SPM_PAGESIZE >> 1
FlahsPage_loop:
                            ld      r0, x+
                            ld      r1, x+
                            ldi     r24, (1 << SPMEN)
                            out     SPMCSR, r24
                            spm
                            adiw    r30, 2
                            dec     r25
                            brne    FlahsPage_loop
                            clr     r1                          ;restore zero reg
                            subi    r30, lo8(SPM_PAGESIZE)
                            sbci    r31, hi8(SPM_PAGESIZE)
                            ;rjmp   SPM_page_write
;-------------------------------------------------------------------------------
SPM_page_write:
                            ldi     r24, (1 << PGWRT) | (1 << SPMEN)    ;write page
                            rjmp    SPM_write
;-------------------------------------------------------------------------------
SPM_page_erase:
                            ldi     r24, (1 << PGERS) | (1 << SPMEN) ;Page Erase
                            ;rjmp   SPM_write
;-------------------------------------------------------------------------------
SPM_write:                  rcall   SPM_write_sub
                            ldi     r24, (1 << RWWSRE) | (1 << SPMEN)   ;RWW section read enable
                            ;rjmp   SPM_write_sub
;-------------------------------------------------------------------------------
SPM_write_sub:
                            out     SPMCSR, r24
                            spm
SPM_wait:
                            in      r0, SPMCSR
                            sbrc    r0, 0
                            rjmp    SPM_wait
;-------------------------------------------------------------------------------
CDC_Task_ret:
SPM_ret:                    ret
;-------------------------------------------------------------------------------
EVENT_USB_Device_ControlRequest:
                            lds     r25, USB_ControlRequest
                            lds     r24, USB_ControlRequest_brequest
                            cpi     r25, 0x21                           ;REQDIR_HOSTTODEVICE | REQTYPE_CLASS | REQREC_INTERFACE
                            breq    EVENT_USB_Device_ControlRequest_b1

                            cpi     r25, 0xA1                           ;REQDIR_DEVICETOHOST | REQTYPE_CLASS | REQREC_INTERFACE
                            brne    EVENT_USB_Device_ControlRequest_ret

                            cpi     r24, 0x21                           ;CDC_REQ_GetLineEncoding
                            brne    EVENT_USB_Device_ControlRequest_ret
                            rcall   LineEncoding_sub
                            rjmp    Endpoint_Write_Control_Stream_LE
EVENT_USB_Device_ControlRequest_b1:
                            cpi     r24, 0x20                           ;CDC_REQ_SetLineEncoding
                            brne    EVENT_USB_Device_ControlRequest_ret

                            rcall   LineEncoding_sub
                            ;rcall   Endpoint_Read_Control_Stream_LE
                            ;rjmp   UEINTX_clear_FIFOCON_TXINI

;-------------------------------------------------------------------------------
Endpoint_Read_Control_Stream_LE:

;entry:
;   r30:31 points to LineEncoding, r22 lineEncoding length

Endpoint_Read_CtrlStrm_b2:
                            rcall   GPIOR0_test
                            breq    Endpoint_Read_CtrlStrm_ret

                            cpi     r24, 5
                            breq    Endpoint_Read_CtrlStrm_ret

                            rcall   UEINTX_get
                            sbrc    r24, RXSTPI
                            rjmp    Endpoint_Read_CtrlStrm_ret
Endpoint_Read_CtrlStrm_b3:
                            sbrs    r24, RXOUTI
                            rjmp    Endpoint_Read_CtrlStrm_b2
                            rjmp    Endpoint_Read_CtrlStrm_b5
Endpoint_Read_CtrlStrm_b4:
                            rcall   UEDATX_get
                            st      Z+, r24
                            subi    r22, 1
                            breq    Endpoint_Read_CtrlStrm_b6
Endpoint_Read_CtrlStrm_b5:
                            lds     r25, UEBCHX
                            lds     r24, UEBCLX
                            or      r24, r25                    ;r24 = UEBCLX | UEBCHX
                            brne    Endpoint_Read_CtrlStrm_b4
Endpoint_Read_CtrlStrm_b6:
                            rcall   UEINTX_clear_FIFOCON_RXOUTI
Endpoint_Read_CtrlStrm_b7:
                            cp      r22, r1
                            brne    Endpoint_Read_CtrlStrm_b2   ;length != 0
                            rjmp    Endpoint_Read_CtrlStrm_b9
Endpoint_Read_CtrlStrm_b8:
                            rcall   GPIOR0_test
                            breq    Endpoint_Read_CtrlStrm_ret

                            cpi     r24, 5
                            breq    Endpoint_Read_CtrlStrm_ret
Endpoint_Read_CtrlStrm_b9:
                            rcall   UEINTX_get
                            sbrs    r24, TXINI
                            rjmp    Endpoint_Read_CtrlStrm_b8
Endpoint_Read_CtrlStrm_ret:
                            ;ret

;-------------------------------------------------------------------------------
UEINTX_clear_FIFOCON_TXINI:
                            ldi     r24, ~(1 << FIFOCON | 1 << TXINI)
                            ;rjmp    UEINTX_clearbits

;-------------------------------------------------------------------------------
;USB Endpoint clear interrupt flag bits

;entry:
;   r24 = bitmask
;exit:
;   r25 = UEINTX state

UEINTX_clearbits:
                            lds     r25, UEINTX
                            and     r24, r25
                            ;rjmp   UEINTX_set
;-------------------------------------------------------------------------------
UEINTX_set:
                            sts     UEINTX, r24
EVENT_USB_Device_ControlRequest_ret:
                            ret
;-------------------------------------------------------------------------------
UENUM_set_04_UEINTX_get:    ldi     r24, 0x04
                            ;rjmp   UENUM_set_UEINTX_get
;-------------------------------------------------------------------------------
UENUM_set_UEINTX_get:       rcall   UENUM_set
                            ;rjmp   UEINTX_get
;-------------------------------------------------------------------------------
UEINTX_get:
                            lds     r24, UEINTX
                            ret
;-------------------------------------------------------------------------------
UDIEN_get:
                            lds     r24, UDIEN
                            ret
;-------------------------------------------------------------------------------
UDIEN_Clr0_Set4:
                            rcall   UDIEN_get
                            andi    r24, 0xFE
                            ori     r24, 0x10
                            ;rjmp   UDIEN_set
;-------------------------------------------------------------------------------
UDIEN_set:
                            sts     UDIEN, r24
                            ret
;-------------------------------------------------------------------------------
LineEncoding_sub:
                            rcall   UEINTX_clear_RXSTPI
                            ldi     r30, lo8(LineEncoding)
                            ldi     r31, hi8(LineEncoding)
                            ldi     r22, lo8(sizeof_LineEncoding)
                            ret
;-------------------------------------------------------------------------------
EVENT_USB_Device_ConfigurationChanged:
                            ldi     r24, 0x02
                            ldi     r22, 0xC1
                            rcall   Endpoint_ConfigureEndpoint_Prv_02
                            ldi     r24, 0x03
                            ldi     r22, 0x81
                            rcall   Endpoint_ConfigureEndpoint_Prv_12
                            ldi     r24, 0x04
                            ldi     r22, 0x80
                            ;rjmpEndpoint_ConfigureEndpoint_Prv_12
;-------------------------------------------------------------------------------
Endpoint_ConfigureEndpoint_Prv_12:
                            ldi     r20, 0x12
                            rjmp    Endpoint_ConfigureEndpoint_Prv
;-------------------------------------------------------------------------------
Endpoint_ConfigureEndpoint_Prv_00_00_02:
                            ldi     r24, 0x00
                            ldi     r22, 0x00
                            ;rjmp   Endpoint_ConfigureEndpoint_Prv_02
;-------------------------------------------------------------------------------
Endpoint_ConfigureEndpoint_Prv_02:
                            ldi     r20, 0x02
                            ;rjmp   Endpoint_ConfigureEndpoint_Prv
;-------------------------------------------------------------------------------
Endpoint_ConfigureEndpoint_Prv:

;uses: r20,r22,r24,r25
                            rcall   UENUM_set
                            ldi     r24, 0x01
                            rcall   UECONX_setbits
                            sts     UECFG1X, r1
                            sts     UECFG0X, r22
                            sts     UECFG1X, r20
                            ret
;-------------------------------------------------------------------------------
UECONX_setbits:

;uses: r24,r25
                            lds     r25, UECONX
                            or      r24, r25
                            sts     UECONX, r24
                            ret
;-------------------------------------------------------------------------------
CALLBACK_USB_GetDescriptor:

;entry:
;   r24 = DiscriptorNumber, r25 = DiscriptorType
;exit:
;   r30:31 = Descriptor address, r22 = length
;note:
;   when length == 0, pointer is ignored

                            ldi     r22, 0x00                  ;zero length for unsupported types
                            cpi     r25, 0x02                   ;DTYPE_Configuration
                            breq    CALLBACK_USB_GetDesc_conf

                            cpi     r25, 0x03                   ;DTYPE_String
                            breq    CALLBACK_USB_GetDesc_str

                            cpi     r25, 0x01                   ;DTYPE_Device
                            brne    CALLBACK_USB_GetDesc_ret

                            ;01: DTYPE_Device
CALLBACK_USB_GetDesc_dev:
                            ldi     r30, lo8(DeviceDescriptor)
                            ldi     r22, lo8(sizeof_DeviceDescriptor)
                            rjmp    CALLBACK_USB_GetDesc_ret

                            ;02: DTYPE_Configuration
CALLBACK_USB_GetDesc_conf:
                            ldi     r30, lo8(ConfigurationDescriptor)
                            ldi     r22, lo8(sizeof_ConfigurationDescriptor)
                            rjmp    CALLBACK_USB_GetDesc_ret

                            ;03: DTYPE_String
CALLBACK_USB_GetDesc_str:
                            cpi     r24, 1
                            brcc    CALLBACK_USB_GetDesc_b1 ;>0

                            ;0: LanguageString

                            ldi     r30, lo8(LanguageString)
                            ldi     r22, lo8(sizeof_LanguageString)
                            rjmp    CALLBACK_USB_GetDesc_ret

                            ;!0:
CALLBACK_USB_GetDesc_b1:
                            brne    CALLBACK_USB_GetDesc_b2

                            ;1: ProductString

                            ldi     r30, lo8(ProductString)
                            ldi     r22, lo8(sizeof_ProductString)
                            rjmp    CALLBACK_USB_GetDesc_ret

                            ;>1:
CALLBACK_USB_GetDesc_b2:
                            cpi     r24, 0x02
                            brne    CALLBACK_USB_GetDesc_ret

                            ;2: ManufacturerString

                            ldi     r30, lo8(ManufacturerString)
                            ldi     r22, lo8(sizeof_ManufacturerString)
CALLBACK_USB_GetDesc_ret:
                            ldi     r31, hi8(DeviceDescriptor) ;all descriptor data in same 256 byte page
                            ret
;-------------------------------------------------------------------------------
Endpoint_ClearStatusStage:
                            lds     r24, USB_ControlRequest
                            and     r24, r24
                            brge    Endpoint_ClearStatus_b4

                            rjmp    Endpoint_ClearStatus_b2
Endpoint_ClearStatus_b1:
                            rcall   GPIOR0_test
                            breq    Endpoint_ClearStatus_ret
Endpoint_ClearStatus_b2:
                            rcall   UEINTX_get
                            sbrs    r24, RXOUTI
                            rjmp    Endpoint_ClearStatus_b1
                            rjmp    UEINTX_clear_FIFOCON_RXOUTI
Endpoint_ClearStatus_b3:
                            rcall   GPIOR0_test
                            breq    Endpoint_ClearStatus_ret
Endpoint_ClearStatus_b4:
                            rcall   UEINTX_get
                            sbrs    r24, TXINI
                            rjmp    Endpoint_ClearStatus_b3

                            rcall   UEINTX_clear_FIFOCON_TXINI
Endpoint_ClearStatus_ret:
                            ret
;-------------------------------------------------------------------------------
Endpoint_Write_Control_Stream_LE:

;entry:
;   r30:31 = pointer to data, r22 = length

                            lds     r20, USB_ControlRequest_wLength+0
                            lds     r21, USB_ControlRequest_wLength+1
                            cp      r20, r22
                            cpc     r21, r1
                            brcc    x7b86                               ;ControlRequest_wLength >= length

                            ;ControlRequest_wLength < length
x7b80:
                            ldi     r25, 0x00                           ;LastPacketFull = false
                            rjmp    x7c0e

                            ;ControlRequest_wLength >= length
x7b86:
                            cp      r22, r1
                            breq    x7b90                               ;length = 0

                            mov     r20, r22
                            rjmp    x7b80
x7b90:
                            rcall   UEINTX_clear_FIFOCON_TXINI
                            ldi     r20, 0x00
                            rjmp    x7b80
x7ba0:
                            rcall   GPIOR0_test
                            breq    x7c30

                            cpi     r24, 0x05
                            breq    x7c34

                            rcall   UEINTX_get
                            sbrc    r24, RXSTPI
                            rjmp    UEINTX_clear_FIFOCON_RXOUTI

                            rcall   UEINTX_get
                            sbrc    r24, RXOUTI
                            rjmp    x7c24

                            sbrs    r24, TXINI
                            rjmp    x7c0e

                            lds     r19, UEBCHX             ;FIFO endpoint byte count MSB
                            lds     r18, UEBCLX             ;FIFO endpoint byte count LSB
                            rjmp    x7bee

                            ;0..7
x7be0:
                            ld      r24, Z+                 ;data
                            sts     UEDATX, r24             ;to USB
                            subi    r20, 0x01               ;length--
                            subi    r18, 0xFF               ;BytesInEndPoint++
x7bee:
                            cp      r20, r1
                            breq    x7bfa                   ;length = 0

                            cpi     r18, 0x08               ;USB_Device_ControlEndpointSize
                            cpc     r19, r1
                            brcs    x7be0                   ;loop < 8
x7bfa:
                            ldi     r21, 0x00               ;LastPacketFull = false
                            cpi     r18, 0x08               ;USB_Device_ControlEndpointSize
                            cpc     r19, r1
                            brne    x7c04

                            ldi     r21, 0x01               ;LastPacketFull = true
x7c04:
                            rcall   UEINTX_clear_FIFOCON_TXINI
x7c0e:
                            cp      r20, r1
                            brne    x7ba0

                            and     r21, r21
                            brne    x7ba0                   ;LastPacketFull
                            rjmp    x7c24
x7c1a:
                            rcall   GPIOR0_test
                            breq    x7c30

                            cpi     r24, 0x05
                            breq    x7c34
x7c24:
                            rcall   UEINTX_get
                            sbrs    r24, RXOUTI
                            rjmp    x7c1a
x7c30:
x7c34:
                            rjmp    UEINTX_clear_FIFOCON_RXOUTI
;-------------------------------------------------------------------------------
USB_Device_ProcessControlRequest:

                            ldi  r30, lo8(USB_ControlRequest)
                            ldi  r31, hi8(USB_ControlRequest)

                            ;read USB_ControlRequest
x7cd2:
                            rcall   UEDATX_get
                            st      Z+, r24
                            ;ldi    r24, hi8(USB_ControlRequest + sizeof_USB_ControlRequest_t)
                            cpi     r30, lo8(USB_ControlRequest + sizeof_USB_ControlRequest_t)
                            ;cpc    r31, r24                                                    ;not required size < 256
                            brne    x7cd2

                            rcall   EVENT_USB_Device_ControlRequest
                            rcall   UEINTX_get                      ;get USB Endpoint Interrupt
                            sbrs    r24, RXSTPI                     ;Received setup Interrupt Flag
jmp_x7eb2:                  rjmp    x7eb2

                            ;RXSTPI Setup received

                            lds     r24, USB_ControlRequest
                            lds     r25, USB_ControlRequest_brequest

                            cpi     r25, 0x01
                            breq    x7d60       ;bmRequestType = 1: REQ_ClearFeature
                            brcs    x7d20       ;< 1: bmRequestType= 0: REQ_GetStatus

                            cpi     r25, 0x03   ;bmRequestType = 3: REQ_SetFeature
                            breq    x7d60

                            cpi     r25, 0x05
                            brne    x7cf8
                            rjmp    x7dd2       ;bmRequestType = 5: REQ_SetAddress
x7cf8:
                            cpi     r25, 0x06
                            brne    x7d0c
                            rjmp    x7e18       ;bmRequestType = 6: REQ_GetDescriptor
x7d0c:
                            cpi     r25, 0x08
                            brne    x7d12
                            rjmp    x7e58       ;bmRequestType = 8: REQ_GetConfiguration
x7d12:
                            cpi     r25, 0x09
                            brne    jmp_x7eb2   ;others: end
                            rjmp    x7e7c       ;bmRequestType = 9: REQ_SetConfiguration

                            ;bmRequestType= 0: REQ_GetStatus

x7d20:
                            cpi     r24, 0x82
                            brne    jmp_x7eb2

                            ;r24 = 0x82

                            lds     r24, USB_ControlRequest_wIndex
                            rcall   UENUM_set_and_07
                            lds     r18, UECONX
                            sts     UENUM, r1
                            rcall   UEINTX_clear_RXSTPI
                            swap    r18                     ;(r18 >> 5) & 1
                            lsr     r18
                            andi    r18, 0x01
                            sts     UEDATX, r18
                            sts     UEDATX, r1
                            rjmp    x7e6e

                            ;bmRequestType = 1,3

x7d60:                      and     r24, r24
                            breq    x7d6a
                            cpi     r24, 0x02
                            brne    jmp_x7eb2

x7d6a:                      andi    r24, 0x1F
                            cpi     r24, 0x02
                            brne    jmp_x7eb2

                            lds     r24, USB_ControlRequest_wValue
                            and     r24, r24
                            brne    x7dc6

                            lds     r18, USB_ControlRequest_wIndex
                            andi    r18, 0x07
                            breq    jmp_x7eb2

                            sts     UENUM, r18
                            lds     r24, UECONX
                            sbrs    r24, 0
                            rjmp    x7dc6

                            cpi     r25, 0x03
                            brne    x7d9c

                            ldi     r24, 0x20
                            rjmp    x7dc2
x7d9c:
                            ldi     r24, 0x10
                            rcall   UECONX_setbits
                            ldi     r24, 0x01   ; 1 << r18 (r18 > 0)
x7dac:
                            add     r24, r24
                            dec     r18
                            brne    x7dac

                            sts     UERST, r24
                            sts     UERST, r1
                            ldi     r24, 0x08
x7dc2:
                            rcall   UECONX_setbits
x7dc6:
                            sts     UENUM, r1
                            rcall   UEINTX_clear_RXSTPI
                            rjmp    x7e74

                            ;bmRequestType = 5

x7dd2:                      and     r24, r24
                            brne    jmp_x7eb2_2

                            lds     r17, USB_ControlRequest_wValue
                            ori     r17, 0x80
                            in      r16, SREG
                            cli
                            rcall   UEINTX_clear_RXSTPI
                            rcall   Endpoint_ClearStatusStage

x7dee:                      rcall   UEINTX_get
                            sbrs    r24, TXINI
                            rjmp    x7dee

                            sts     UDADDR, r17
                            cpi     r17, 0x80
                            ldi     r24, 0x03
                            brne    x7e12

                            ldi     r24, 0x02
x7e12:
                            out     GPIOR0, r24
                            out     SREG, r16
jmp_x7eb2_2:
                            rjmp    x7eb2

                            ;bmRequestType = 6: REQ_GetDescriptor

x7e18:                      subi    r24, 0x80
                            cpi     r24, 0x02
                            brcc    x7eb2       ;wasn't 128 or 129

x7e20:                      lds     r24, USB_ControlRequest_wValue
                            lds     r25, USB_ControlRequest_wValue+1
                            rcall   CALLBACK_USB_GetDescriptor
                            cpi     r22, 0
                            breq    x7eb2

                            ;length > 0

                            rcall   UEINTX_clear_RXSTPI
                            rcall   Endpoint_Write_Control_Stream_LE
                            rjmp    x7eb2

x7e58:                      cpi     r24, 0x80
                            brne    x7eb2

                            rcall   UEINTX_clear_RXSTPI
                            lds     r24, USB_Device_ConfigurationNumber
                            sts     UEDATX, r24
x7e6e:
                            rcall   UEINTX_clear_FIFOCON_TXINI
x7e74:
                            rcall   Endpoint_ClearStatusStage
                            rjmp    x7eb2

x7e7c:                      and     r24, r24
                            brne    x7eb2

                            lds     r25, USB_ControlRequest_wValue
                            cpi     r25, 0x02
                            brcc    x7eb2

                            sts     USB_Device_ConfigurationNumber, r25
                            rcall   UEINTX_clear_RXSTPI
                            rcall   Endpoint_ClearStatusStage
                            lds     r24, USB_Device_ConfigurationNumber
                            and     r24, r24
                            brne    x7eac

                            lds     r24, UDADDR
                            ldi     r25, 0x01       ;DEVICE_STATE_Powered
                            sbrc    r24, 7
x7eac:                      ldi     r25, 0x04       ;DEVICE_STATE_Configured
                            out     GPIOR0, r25
                            rcall   EVENT_USB_Device_ConfigurationChanged
x7eb2:
                            rcall   UEINTX_get
                            sbrs    r24, RXSTPI
                            ret

                            ldi     r24, 0x20
                            rcall   UECONX_setbits
                            ;rjmp    UEINTX_clear_RXSTPI
;-------------------------------------------------------------------------------
UEINTX_clear_RXSTPI:
                            ldi     r24, ~(1 << RXSTPI)
                            rjmp    UEINTX_clearbits

;-------------------------------------------------------------------------------
GPIOR0_test:
                            in      r24, GPIOR0
test_r24:
                            and     r24, r24
                            ret
;-------------------------------------------------------------------------------
USB_USBTask:
                            rcall   GPIOR0_test
                            breq    USB_USBTask_ret         ;ret, zero

                            lds     r24, UENUM
                            push    r24                     ;save USB endpoint
                            sts     UENUM, r1
                            rcall   UEINTX_get
                            sbrs    r24, RXSTPI
                            rjmp    USB_USB_USBTask_restore ;clear, no process

                            rcall   USB_Device_ProcessControlRequest
USB_USB_USBTask_restore:
                            pop     r24                     ;restore USB endpoint
                            ;rjmp   UENUM_set_and_07
;-------------------------------------------------------------------------------
UENUM_set_and_07:
                            andi    r24, 0x07
                            ;rjmp   UENUM_set
;-------------------------------------------------------------------------------
UENUM_set:
                            sts     UENUM, r24
USB_USBTask_ret:            ret
;-------------------------------------------------------------------------------
                            .section    .text
;-------------------------------------------------------------------------------
TestApplicationFlash:

;returns r24:25 = 0000 and Z flag set if unprogrammed application flash (FFFF)

                            ldi     r30, lo8(APPLICATION_START_ADDR)
                            ldi     r31, hi8(APPLICATION_START_ADDR)
                            lpm     r24, Z+
                            lpm     r25, Z
                            adiw    r24, 1
                            ret
;-------------------------------------------------------------------------------
SetupHardware:
                            ldi     r18, 1 << CLKPCE        ;enable CLK prescaler change
                            sts     CLKPR, r18  
                            sts     CLKPR, r1               ;PCLK/1
                            ldi     r24, 1 << IVCE          ;enable interrupt vector select
                            out     MCUCR, r24  
                            ldi     r24, 1 << IVSEL         ;select bootloader vectors
                            out     MCUCR, r24
                        #ifdef ARDUBOY_DEVKIT
                            ldi     r24, 0x07               ;SPI_CLK, MOSI, RXLED as outputs
                            out     DDRB, r24
                            ldi     r24, 0x71               ;Pull-ups on UP,LEFT,DOWN Buttons, RXLED off
                            out     PORTB, r24
                            out     DDRC, r1                ;all inputs
                            sbi     PORTC, BTN_RIGHT_BIT    ;pull-up on right button
                            out     DDRF, r1                ;Set all as inputs
                            ldi     r24, 0xC0               ;pullups on button A and B
                            out     PORTF, r24
                        #else
                          #if DEVICE_PID == 0x0037        //; Micro RXLED is reversed
                            ldi     r24, 0xF0               ;RGBLED OFF | PULLUP B-Button | RXLED OFF
                          #else 
                            ldi     r24, 0xF1               ;RGBLED OFF | PULLUP B-Button | RXLED OFF
                          #endif    
                            out     PORTB, r24  
                            ldi     r24, 0xE7               ;RGBLED, SPI_CLK, MOSI, RXLED as outputs
                            out     DDRB, r24   
                        #if defined (ARDUBIGBOY)
                            ldi     r24, (1 << CART_CS)     ; Flash cart as output
                            out     DDRE, r24
                            ldi     r24, (1 << BTN_A_BIT) | (1 << CART_CS) ; Enable pullup for A button, Flash cart inactive high
                            out     PORTE, r24
                        #else
                            out     DDRE, r1                ;all as inputs
                            sbi     PORTE, BTN_A_BIT        ;enable pullup for A button
                        #endif
                            out     DDRF, r1                ;all as inputs
                            ldi     r24, 0xF0               ;pullups on D-PAD
                            out     PORTF, r24
                        #endif
                            
                            ;setup display io and reset

                        #if defined (ARDUBOY_PROMICRO)
                            ldi     r24, (1 << OLED_CS) | (1 << TX_LED) | (RGB_G) | (1 << CART_CS) ;RST active low, CS inactive high, Command mode, Tx LED off, RGB green off, Flash cart inactive high
                            out     PORTD, r24
                            ldi     r24, (1 << OLED_RST) | (1 << OLED_CS) | (1 << OLED_DC) | (1 << TX_LED) | (1 << RGB_G) | (1 << CART_CS) ; as outputs
                            out     DDRD, r24
                        #elif defined (LCD_ST7565)
                            ldi     r24, (1 << OLED_CS) | (1 << TX_LED) | (1 << CART_CS) ;RST active low, CS inactive high, Command mode, Tx LED off, Flash cart inactive high. Power LED active low
                            out     PORTD, r24
                            ldi     r24, (1 << OLED_RST) | (1 << OLED_CS) | (1 << OLED_DC) | (1 << TX_LED) | (1 << CART_CS) | (1 << POWER_LED); as outputs
                            out     DDRD, r24
                        #elif defined (ARDUBIGBOY)
                            ldi     r24, (1 << OLED_CS) | (1 << TX_LED); RST active low, CS inactive high, Command mode, Tx LED off
                            out     PORTD, r24
                            ldi     r24, (1 << OLED_RST) | (1 << OLED_CS) | (1 << OLED_DC) | (1 << TX_LED); as outputs
                            out     DDRD, r24
                        #else
                            ldi     r24, (1 << OLED_CS) | (1 << TX_LED) | (1 << CART_CS) ;RST active low, CS inactive high, Command mode, Tx LED off, Flash cart inactive high
                            out     PORTD, r24
                            ldi     r24, (1 << OLED_RST) | (1 << OLED_CS) | (1 << OLED_DC) | (1 << TX_LED) | (1 << CART_CS); as outputs
                            out     DDRD, r24
                        #endif
                            
                            ;setup SPI

                            ldi     r24,  (1 << SPE) | (1 << MSTR)  ;SPI master, mode 0, MSB first
                            out     SPCR, r24
                            ldi     r24, 1 << SPI2X                 ;SPI clock CPU / 2 (8MHz)
                            out     SPSR, r24
                            ret

                            
;-------------------------------------------------------------------------------                            
SetupHardware_bootloader:
                            ;pull display out of reset

                        #ifdef ARDUBOY_PROMICRO
                            ldi     r24, (1 << OLED_RST) | (1 << TX_LED) | (RGB_G)  | (1 << OLED_CS) ;RST inactive, OLED CS inactive, Command mode, Tx LED off, RGB green off, Flash cart active
                        #else
                            ldi     r24, (1 << OLED_RST) | (1 << TX_LED)  | (1 << OLED_CS) ;RST inactive, OLED CS inactive, Command mode, Tx LED off, Flash cart active
                        #endif
                            out     PORTD, r24
                            
                            ;release SPI flash from power down

                            ldi     r24, SFC_RELEASE_POWERDOWN
                            rcall   SPI_flash_cmd_deselect
                            
                            sts     OCR1AH, r1
                            ldi     r24, 0xFA           ;for 1 millisec (PCLK/64/1000)
                            sts     OCR1AL, r24
                            ldi     r24, 0x02           ;OCIE1A
                            sts     TIMSK1, r24         ;enable timer 1 output compare A match interrupt
                            ldi     r24, 0x03           ;CS11 | CS10 1/64 prescaler on timer 1 input
                            sts     TCCR1B, r24

                            ;clear full display ram for SSD132X displays
                            
                           #if defined (OLED_SSD132X_96X96) || (OLED_SSD132X_128X96) || (OLED_SSD132X_128X128)
                            sbi     PORTD, OLED_DC              ;data mode
                            ldi     r30,lo8(128 * 128 / 2)
                            ldi     r31,hi8(128 * 128 / 2)
SetupHardware_dc:                            
                            ldi     r24, 0
                            rcall   SPI_transfer
                            sbiw    30, 1
                            brne    SetupHardware_dc
                            cbi     PORTD, OLED_DC              ;command mode
                           #endif
                           
                            ;Setup display

                            ldi     r30,lo8(DisplaySetupData)
                            ldi     r31,hi8(DisplaySetupData)
SetupHardware_display:
                            rcall   SPI_transfer_Z
                            cpi     r30, lo8(DisplaySetupData_End)
                            brne    SetupHardware_display

                            ;copy USB icon to display buffer
DisplayBootGfx:
                            ldi     r26, lo8(DisplayBuffer + BOOT_LOGO_OFFSET)
                            ldi     r27, hi8(DisplayBuffer + BOOT_LOGO_OFFSET)
                            ldi     r30, lo8(bootgfx)
                            ldi     r31, hi8(bootgfx)
                            ldi     r16, BOOTLOGO_HEIGHT
DisplayBootGfx_l1:
                            ldi     r17, BOOTLOGO_WIDTH
DisplayBootGfx_l2:
                            ld      r0, z+
                            st      x+, r0
                            dec     r17
                            brne    DisplayBootGfx_l2
                            subi    r26, -(128 - BOOTLOGO_WIDTH)    ;'adiw' to one line down
                            sbci    r27, -1
                            dec     r16
                            brne    DisplayBootGfx_l1
                            
                            ;copy display buffer to display

                            rcall   Display
                            ;ret
;-------------------------------------------------------------------------------
USB_Init:
                            ldi     r24, 0x01               ;UVREGE: enable USB pad regulator
                            sts     UHWCON, r24
                            ldi     r24, 0x4A
                            out     PLLFRQ, r24

                            ;USB_INT_DisableAllInterrupts

                            sts     USBCON, r1                    ;clear VBUSTE
                            sts     UDIEN, r1

                            ;USB_INT_ClearAllInterrupts

                            sts     USBINT, r1              ;clear VBUSTI
                            sts     UDINT, r1               ;clear USB device interrupts
                            ldi     r24, 0x80               ;USBE
                            rcall   USBCON_set
                            out     PLLCSR, r1
                            out     GPIOR0, r1
                            ;sts     USB_Device_ConfigurationNumber, r1     ;(cleared by BSS init)
                            sts     UDCON, r1                               ;full speed
                            rcall   Endpoint_ConfigureEndpoint_Prv_00_00_02
                            ldi     r24, 0x08 | 0x01                        ;EORSTE | SUSPE
                            rcall   UDIEN_set
                            ldi     r24, 0x91
USBCON_set:
                            sts     USBCON, r24
                            ret
;-------------------------------------------------------------------------------
;EEPROM code
;-------------------------------------------------------------------------------
eeprom_prep:
                            movw    r30, r4             ;get current address in Z
eeprom_wait:
                            sbic    EECR, EEPE
                            rjmp    eeprom_wait

                            out     EEARH, r31          ;write address
                            out     EEARL, r30
                            ret
;-------------------------------------------------------------------------------
eeprom_read:
                            rcall   eeprom_prep         ;wait and select address
                            sbi     EECR, EERE
                            in      r24, EEDR           ;read eeprom byte
                            rjmp    eeprom_addr_inc
;-------------------------------------------------------------------------------
eeprom_write:
                            rcall   eeprom_prep         ;wait and select address
                            out     EECR, r1
                            out     EEDR, r24
                            in      r0, SREG
                            cli
                            sbi     EECR, EEMPE
                            sbi     EECR, EEPE
                            out     SREG, r0
eeprom_addr_inc:
                            adiw     r30, 1             ;current address++
                            movw    r4, r30             ;update current address
                            ret
;-------------------------------------------------------------------------------
;SPI FLASH
;-------------------------------------------------------------------------------
SPI_read_page:

;entry: x = buffer
;uses:  r24, r25, x
                            ldi     r25, SPM_PAGESIZE
SPI_read_page_loop:
                            rcall   SPI_transfer
                            st      x+, r24
                            dec     r25
                            brne    SPI_read_page_loop
                            ret
;-------------------------------------------------------------------------------
SPI_write_enable:
                            ldi     r24, SFC_WRITE_ENABLE
                            ;rjmp   SPI_flash_cmd_deselect
;-------------------------------------------------------------------------------
SPI_flash_cmd_deselect:
                            rcall   SPI_flash_cmd
                            rjmp    SPI_flash_deselect
;-------------------------------------------------------------------------------
SPI_flash_read_addr:
                            ldi     r24, SFC_READ_DATA
                            ;rjmp   SPI_flash_cmd_addr
;-------------------------------------------------------------------------------
SPI_flash_cmd_addr:

;Send SPI command and sets flash sector address
;
;entry:
;        r24 = SPI command
;        Z   = page address
;uses:
;        r24, r25
                            rcall   SPI_flash_cmd       ;select SPI flash and send command
                            mov     r24, r31
                            rcall   SPI_transfer        ;address bits 23-16
                            mov     r24, r30
                            rcall   SPI_transfer
                            ldi     r24, 0x00           ;address bits 7-0
                            ;rjmp    SPI_transfer
;-------------------------------------------------------------------------------
SPI_flash_cmd:
                            sbi     PORTD, OLED_CS      ;disable display
                        #if defined (ARDUBIGBOY)
                            cbi     PORTE, CART_CS      ;enable SPI flash cart
                        #else
                            cbi     PORTD, CART_CS      ;enable SPI flash cart
                        #endif
                            rjmp    SPI_transfer        ;send command
;-------------------------------------------------------------------------------
SPI_flash_wait:
                            rcall   SPI_flash_deselect
                            ldi     r24, SFC_READ_STATUS1
                            rcall   SPI_flash_cmd
SPI_flash_wait_2:           rcall   SPI_transfer        ;read status reg
                            sbrc    r24, 0              ;test busy bit
                            rjmp    SPI_flash_wait_2
                            ;rjmp   SPI_flash_deselect
;-------------------------------------------------------------------------------
SPI_flash_deselect:
                        #if defined(ARDUBIGBOY)
                            sbi     PORTE, CART_CS      ;deselect SPI flash cart to complete command
                        #else
                            sbi     PORTD, CART_CS      ;deselect SPI flash cart to complete command
                        #endif
                            cbi     PORTD, OLED_CS      ;select display
                            ret
;-------------------------------------------------------------------------------
SPI_transfer_Z:
                            ld      r24, Z+
                            ;rjmp   SPI_transfer
;-------------------------------------------------------------------------------
SPI_transfer:
                            out     SPDR, r24
                            ;rjmp   SPI_Wait
;-------------------------------------------------------------------------------
SPI_Wait:
                            in      r24, SPSR
                            nop
                            sbrs    r24, SPIF
                            rjmp    SPI_Wait
                            in      r24, SPDR
                            ret
;-------------------------------------------------------------------------------
Display:
;-------------------------------------------------------------------------------

;copies display buffer to OLED display using page mode (supported on most displays)

;                       Uses:
;                           r24, r25, r30, r31
                        #if defined(OLED_SSD132X_96X96)
                            ldi     r30, lo8(DisplayBuffer + 16)
                            ldi     r31, hi8(DisplayBuffer + 16)
                        #else   
                            ldi     r30, lo8(DisplayBuffer)
                            ldi     r31, hi8(DisplayBuffer)
                        #endif
                        #if defined(OLED_SSD132X_96X96) || (OLED_SSD132X_128X96) || (OLED_SSD132X_128X128)
                            sbi     PORTD, OLED_DC          ;ensure Data mode
                          #if defined(OLED_SSD132X_96X96)
                            ldi     r20, 96 / 2             ;visible width
                          #else
                            ldi     r20, WIDTH / 2
                          #endif
Display_column:
                            ldi     r21, HEIGHT / 8
Display_row:
                            ld      r22, z
                            ldd     r23, z+1
                            ldi     r25, 8
Display_shift:
                            ldi     r24, 0xff       ;expand 1 bit to MSB 4 bits
                            sbrs    r22, 0
                            andi    r24, 0x0f
                            sbrs    r23, 0          ;expand 1 bit to LSB 4 bits
                            andi    r24, 0xf0
                            rcall   SPI_transfer
                            lsr     r22
                            lsr     r23
                            dec     r25
                            brne    Display_shift

                            subi     r30, lo8(-WIDTH)   ;add WIDTH
                            sbci     r31, hi8(-WIDTH)
                            dec      r21
                            brne     Display_row

                            subi     r30, lo8(HEIGHT / 8 * WIDTH - 2)
                            sbci     r31, hi8(HEIGHT / 8 * WIDTH - 2)
                            dec      r20
                            brne     Display_column
                        #else
                            ldi     r25, OLED_SET_PAGE_ADDR
Display_l1:
                            cbi     PORTD, OLED_DC                  ;Command mode
                            mov     r24, r25
                            rcall   SPI_transfer                    ;select page
                            ldi     r24, OLED_SET_COLUMN_ADDR_HI
                            rcall   SPI_transfer                    ;select column hi nibble
                            sbi     PORTD, OLED_DC                  ;Data mode
Display_l2:
                            rcall   SPI_transfer_Z
                            ldi     r24, lo8(DisplayBuffer)
                            eor     r24, r30
                            andi    r24, 0x7F                       ;every 128 zero
                            brne    Display_l2

                            inc     r25
                            cpi     r25, OLED_SET_PAGE_ADDR + 8
                            brne    Display_l1
                        #endif
                            ret
;-------------------------------------------------------------------------------
LEDPulse:

                            ldi     r30, lo8(LLEDPulse)
                            ldi     r31, hi8(LLEDPulse)
                            ld      r24, z+
                            ld      r25, z
                            adiw    r24, 1              ;LLEDPulse++, bit 15 sets N flag
                            st      z, r25
                            st      -z, r24
                            mov     r0, r25
                            brpl    LEDPulse_b1         ;branch bit 15 clear

                            ;LedPulse >= 0x8000 bright to dim

                            com     r0                  ;== 255-p rather than 254-p (which causes bright flash)

                            ;LedPulse < 0x8000 dim to bright
LEDPulse_b1:
                            lds     r16, LED_Control    ;if RGB LED breathing is disabled
                            bst     r16, LED_CTRL_RGB   ;RGB LED state shouldn't be changed
                            brts    LED_Pulse_ret       ;ret, disabled

                            adiw    r24, 0              ;test overflow for color change
                            ld      r25, -z              ;get RGBLEDstate
                            brne    LEDPulse_testperiod

                            inc     r25                 ;change RGBLED state
                            st      z, r25
LEDPulse_testperiod:
                            add     r0, r0
                            cp      r0, r24
                            brcc    LEDPulse_on
                            ;rjmp   LEDPulse_off

;-------------------------------------------------------------------------------
LEDPulse_off:
                            RGB_RED_OFF
                            RGB_GREEN_OFF
                            RGB_BLUE_OFF
LED_Pulse_ret:
                            ret
;-------------------------------------------------------------------------------
LEDPulse_on:
                            andi    r25, 0x03               ;RGB LED has 4 states:
                            brne    LEDPulse_on_b1
                            RGB_RED_ON
LEDPulse_on_b1:
                            cpi     r25, 1
                            brne    LEDPulse_on_b2
                            RGB_GREEN_ON
LEDPulse_on_b2:
                            cpi     r25, 2
                            brne    LEDPulse_on_b3          ;3: none lit
                            RGB_BLUE_ON
LEDPulse_on_b3:
                            ret
;-------------------------------------------------------------------------------
ReadButtons:

;read newly pressed buttons with debounce and repeat

;exit:
;   r24 = copy of Buttons
;uses:
;   r24,r25,r30,r31
                            ldi     r30, lo8(IndexedVars)
                            ldi     r31, hi8(IndexedVars)
                            ldd     r25, z+IDX_LEDCONTROL
                            tst     r25                         ;test button input disabled
                            brmi    clearButtons

                            ;read current buttons state

                        #ifdef ARDUBOY_DEVKIT
                            in	    r24, PINB   ;down, left, up buttons
                            com     r24
                            andi    r24, 0x70
                            sbis    PINC, BTN_RIGHT_BIT
                            ori	    r24, 1 << RIGHT_BUTTON
                        #else
                            in	    r24, PINF   ;directional buttons
                            com     r24
                            andi    r24, 0xF0
                        #endif
                            sbis    BTN_A_PIN, BTN_A_BIT
                            ori	    r24, 1 << A_BUTTON
                            sbis    BTN_B_PIN, BTN_B_BIT
                            ori	    r24, 1 << B_BUTTON

                            ;handle button debouncing

                            ldd     r25, z+IDX_DEBOUNCESTATE
                            cpse    r24, r25
                            rjmp    DebounceButtons         ;not same state

                            ;same button state, test still debouncing

                            ldd     r25, z+IDX_DEBOUNCEDELAY
                            tst     r25
                            brne    clearButtons

                            ;debounce time up, buttons are stable

                            ldd     r25, z+IDX_OLDBUTTONS
                            cpse    r24, r25
                            rjmp    ButtonsChanged

                            ;Same buttons pressed as before, test for repeat

                            ldd     r25, z+IDX_REPEATDELAY
                            tst     r25
                            ldi     r25, 150
                            breq    SetButtonRepeat

                            ;no repeat yet, clear new buttons

                            ldi     r24, 0                      ;no buttons
                            rjmp    SetButtonsVar

                            ;different buttons are pressed
ButtonsChanged:
                            std     z+IDX_OLDBUTTONS, r24
                            com     r25                         ;get non pressed buttons mask
                            and     r24, r25                    ;keep only newly pressed buttons
                            rjmp    SetButtons
DebounceButtons:
                            std     z+IDX_DEBOUNCESTATE, r24    ;current button state
                            ldi     r25, 10
                            std     z+IDX_DEBOUNCEDELAY, r25    ;reset debounce delay
clearButtons:
                            ldi     r24, 0
SetButtons:
                            ldi     r25, 255
SetButtonRepeat:
                            std     z+IDX_REPEATDELAY, r25      ;reset repeat delay
SetButtonsVar:
                            std     z+IDX_BUTTONS, r24
                            ret
;-------------------------------------------------------------------------------
SelectGame:

;Note: select game may only be called after SelectList or successful LoadApplicationInfo

                            lds     r24, LED_Control        ;test breating RGB LED disabled
                            sbrs    r24, LED_CTRL_RGB
                           #ifdef   LCD_ST7565
                            RGB_RED_ON                      ;force white backlight for LCD display
                            RGB_GREEN_ON
                            RGB_BLUE_ON
                           #else
                            rcall   LEDPulse_off            ;turn them off if not disabled
                           #endif
                            clr     r2                      ;clear bootloader timeout
                            clr     r3
                        #if !defined (OLED_SSD132X_96X96) && !defined (OLED_SSD132X_128X96) && !defined (OLED_SSD132X_128X128)
                            ldi     r30, lo8(IndexedVars)
                            ldi     r31, hi8(IndexedVars)
                            std     z+IDX_RGBLEDSTATE, r1
                            std     z+IDX_LLEDPULSE_LSB, r1
                            std     z+IDX_LLEDPULSE_MSB, r1
                        #endif
                            ldi     r30, lo8(FlashBuffer)
                            ldi     r31, hi8(FlashBuffer)
                            lds     r24, Buttons
                            sbrc    r24, UP_BUTTON
                            rjmp    SelectGame_up
                            sbrc    r24, DOWN_BUTTON
                            rjmp    SelectGame_down
                            sbrs    r24, B_BUTTON           ;skip if B pressed to flash application
SelectGame_ret:
                            ret

                            ;test if there is an application to flash

                            ldd     r28, z+FBO_APPSIZE      ;application length in 128 byte pages
                            tst     r28                     ;test zero length
                            breq    SelectGame_ret          ;return no executable application

                            ;size > 0, flash application

                            cli                             ;no ints wanted
                            RX_LED_ON                       ;visible feedback we're flashing
                            ldd     r0, z+FBO_APPPAGE_LSB   ;flash cart application page address
                            ldd     r31, z+FBO_APPPAGE_MSB
                            mov     r30, r0
                            rcall   SPI_flash_read_addr
                            ldi     r30, lo8(APPLICATION_START_ADDR)
                            ldi     r31, hi8(APPLICATION_START_ADDR)

                            ;load page from flash cart
FlashApp_loop:
                            ldi     r26, lo8(FlashBuffer)
                            ldi     r27, hi8(FlashBuffer)
                            rcall   SPI_read_page

                            ;program page

                            ldi     r26, lo8(FlashBuffer)
                            ldi     r27, hi8(FlashBuffer)
                            rcall   FlashPage
                            subi    r30, lo8(-(SPM_PAGESIZE)) ;Z += PAGESIZE
                            sbci    r31, hi8(-(SPM_PAGESIZE))

                            dec     r28
                            brne    FlashApp_loop
                            rcall   SPI_flash_deselect
                            rjmp    StartSketch

SelectGame_up:              ;select previous game in list

                            movw    r16, r6                             ;save current selected game
                            mov     r18, r8
SelectGame_prev:
                            lds     r6, FlashBuffer+FBO_PREVSLOT_LSB
                            lds     r7, FlashBuffer+FBO_PREVSLOT_MSB
                            rcall   LoadApplicationInfo
                            brne    SelectGame_last                     ;no previous game found
                            tst     r24                                 ;test found game in list
                            brne    SelectGame_prev                     ;not on list, try previous
                            ret                                         ;return found

                            ;no previous game found, wrap to last
SelectGame_last:
                            movw    r6, r16                             ;last selected game page addr
                            clr     r8                                  ;use bootloader list to prevent loading of title screens
SelectGame_last_b1:
                            rcall   LoadApplicationInfo
                            brne    SelectList_eof                      ;end of storage, select last found game

                            lds     r24, FlashBuffer+FBO_LIST
                            cp      r24, r18                            ;test member of wanted game list
                            brne    SelectGame_last_b2                  ;loop if not

                            movw    r16, r6                             ;update last game page addr
SelectGame_last_b2:
                            lds     r6, FlashBuffer+FBO_NEXTSLOT_LSB
                            lds     r7, FlashBuffer+FBO_NEXTSLOT_MSB
                            rjmp    SelectGame_last_b1

SelectGame_down:            ;select next game in list

                            lds     r6, FlashBuffer+FBO_NEXTSLOT_LSB
                            lds     r7, FlashBuffer+FBO_NEXTSLOT_MSB
                            rcall   LoadApplicationInfo
                            brne    SelectGame_first                    ;end of storage, find first in list
                            tst     r24
                            brne    SelectGame_down                     ;different list, try again
                            ret
;-------------------------------------------------------------------------------
SelectList:

;entry:
;   r24 = buttons
                            ldi     r25, -1
                            sbrc    r24, LEFT_BUTTON
                            rjmp    SelectList_prev
                            sbrc    r24, RIGHT_BUTTON
                            rjmp    SelectList_next
                            sbrs    r24, A_BUTTON       ;skip if pressed
SelectList_ret:             ret                         ;return no left or right or A button

                            ;run last application

                            rcall   TestApplicationFlash
                            breq    SelectList_ret     ;return no application
                            rjmp    StartSketch

                            ;next list
SelectList_next:
                            ldi     r25, 1
SelectList_prev:
                            bst     r25, 7              ;save direction in T flag
                            add     r8, r25             ;get new list
SelectGame_first:
                            clr     r6                  ;search from beginning of cart
                            clr     r7
                            movw    r16, r6             ;reset nearest list page
                            clr     r18                 ;reset nearest list nr
SelectList_loop:
                            rcall   LoadApplicationInfo
                            brne    SelectList_eof     ;end of file storage
                            tst     r24
                            breq    SelectList_ret     ;return list found

                            ;not found, check if nearest

                            lds     r24, FlashBuffer+FBO_LIST  ;get list
                            brts    SelectList_below

                            ;get nearest list above
SelectList_above:
                            cp      r8, r24
                            brcc    SelectList_cont    ;not above
                            cp      r24, r18            ;lowest above
                            brcs    SelectList_nearest
                            cpi      r18, 1             ;lowest can't be zero
                            rjmp    SelectList_check

                            ;get nearest list below

SelectList_below:          cp      r24, r8
                            brcc    SelectList_cont    ;not below
                            cp      r18, r24            ;highest below
SelectList_check:
                            brcc    SelectList_cont    ;not new nearest

                            ;update  nearest
SelectList_nearest:
                            movw    r16, r6             ;update nearest list page
                            mov     r18, r24            ;update nearest list nr

SelectList_cont:           ;try next

                            lds     r6, FlashBuffer+FBO_NEXTSLOT_LSB    ;next application slot page
                            lds     r7, FlashBuffer+FBO_NEXTSLOT_MSB
                            rjmp    SelectList_loop                    ;loop different list

SelectList_eof:            ;list not found, set nearest

                            movw    r6, r16             ;select nearest list
                            mov     r8, r18
                            ;rjmp   LoadApplicationInfo
;-------------------------------------------------------------------------------
LoadApplicationInfo:

;entry:
;   r6,r7 = flash cart page address
;   r8    = list
;exit:
;   Z-flag clear: No application info found (end of storage)
;   Z-flag set:   Application info found. r24 = load status:
;                 r24 > 0: Application info not loaded (not a member of selected list)
;                 r24 = 0: Application info loaded

                            movw    r30, r6
                            rcall   SPI_flash_read_addr
                            ldi     r26, lo8(FlashBuffer)
                            ldi     r27, hi8(FlashBuffer)
                            rcall   SPI_read_page

                            ;check arduboy magic key

                            ldi     r28, lo8(FlashBuffer)        ;(using y to preserve x)
                            ldi     r29, hi8(FlashBuffer)
                            ldi     r30, lo8(SOFTWARE_IDENTIFIER)
                            ldi     r31, hi8(SOFTWARE_IDENTIFIER)
                            ldi     r25, 7
LoadAppInfo_CheckKey:
                            ld      r0, y+
                            ld      r24, z+
                            cp      r0, r24
                            brne    LoadAppInfo_Fail        ;Z flag cleared: End of storage
                            dec     r25
                            brne    LoadAppInfo_CheckKey

                            ;key ok, check list

                            ld      r0, y
                            cpse    r8, r0                  ;test appt list = current list
LoadAppInfo_Fail:           rjmp    SPI_flash_deselect      ;Z flag set from dec r25, r24 > 0

                            ;load remaining application info + title screen
LoadAppInfo_Load:
                            ldi     r28, 1 + 8              ;remaining header + titlescreen
LoadAppInfo_Page:
                            rcall   SPI_read_page
                            dec     r28
                            brne    LoadAppInfo_Page

                            rcall   SPI_flash_deselect
                            rcall   Display                 ;show titlescreen
                            clr     r24                     ;Z flag set , R24 = 0    signal app info loaded
                            ret
;-------------------------------------------------------------------------------
SECTION_DATA_DATA:          ;(Initialized data stored after text area here)
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
                            .section .bss   ;zero initialized data
;-------------------------------------------------------------------------------
SECTION_BSS_START:
                                    ;indices for IndexedVars
                                    .equ    IDX_TXLEDPULSE,     0
                                    .equ    IDX_RXLEDPULSE,     1
                                    .equ    IDX_BUTTONS,        2
                                    .equ    IDX_OLDBUTTONS,     3
                                    .equ    IDX_REPEATDELAY,    4
                                    .equ    IDX_DEBOUNCESTATE,  5
                                    .equ    IDX_DEBOUNCEDELAY,  6
                                    .equ    IDX_LEDCONTROL,     7
                                    .equ    IDX_RGBLEDSTATE,    8
                                    .equ    IDX_LLEDPULSE,      9
                                    .equ    IDX_LLEDPULSE_LSB,  9
                                    .equ    IDX_LLEDPULSE_MSB,  10
IndexedVars:
TxLEDPulse:                         .byte   0   ;| Note:  Do not change order of these vars
RxLEDPulse:                         .byte   0   ;|
Buttons:                            .byte   0   ;|
OldButtons:                         .byte   0   ;|
RepeatDelay:                        .byte   0   ;|
DebounceState:                      .byte   0   ;|
DebounceDelay:                      .byte   0   ;|
LED_Control:                        .byte   0   ;|
RGBLEDstate:                        .byte   0   ;|
LLEDPulse:                          .word   0   ;|

USB_Device_ConfigurationNumber:     .byte   0

LineEncoding:                       ;structure:
                                    .long   0   ;BaudRateBPS
                                    .byte   0   ;CharFormat
                                    .byte   0   ;ParityType
                                    .byte   0   ;DataBits

USB_ControlRequest:                 ;structure:
USB_ControlRequest_bmRequestType:   .byte   0
USB_ControlRequest_brequest:        .byte   0
USB_ControlRequest_wValue:          .word   0
USB_ControlRequest_wIndex:          .word   0
USB_ControlRequest_wLength:         .word   0

FlashBuffer:                        .space  256
                                    .equ    FBO_SIGNATURE,      0
                                    .equ    FBO_LIST,           7
                                    .equ    FBO_PREVSLOT,       8
                                    .equ    FBO_PREVSLOT_MSB,   8
                                    .equ    FBO_PREVSLOT_LSB,   9
                                    .equ    FBO_NEXTSLOT,       10
                                    .equ    FBO_NEXTSLOT_MSB,   10
                                    .equ    FBO_NEXTSLOT_LSB,   11
                                    .equ    FBO_SLOTSIZE,       12
                                    .equ    FBO_SLOTSIZE_MSB,   12
                                    .equ    FBO_SLOTSIZE_LSB,   13
                                    .equ    FBO_APPSIZE,        14
                                    .equ    FBO_APPPAGE,        15
                                    .equ    FBO_APPPAGE_MSB,    15
                                    .equ    FBO_APPPAGE_LSB,    16
DisplayBuffer:                      .space  1024

SECTION_BSS_END:
;-------------------------------------------------------------------------------
                            .section .bootsignature, "ax"
;-------------------------------------------------------------------------------

                            rjmp    FlashPage

                            .word   BOOT_SIGNATURE
;===============================================================================