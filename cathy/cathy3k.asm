;===============================================================================
;
;                              ** Cathy 3K **
;
;  An optimized reversed Caterina bootloader with added features under 3K
;           For Arduboy and Arduino Leonardo, Micro and Esplora
;
;       Assembly optimalisation and additional (Arduboy) features
;                         by Mr.Blinky Oct 2017
;
;             m s t r <d0t> b l i n k y <at> g m a i l <d0t> c o m
;
;  Main features:
;
;    bootloader size is under 3K alllowing 1K more space for Application section.
;  - dual magic key address support (0x0800 and RAMEND-1) for more reliable
;    bootloader triggering from arduino IDE
;  - Software boot area protection. Sketches can't overwrite the bootloader area
;    regardless of fuse settings.
;  - Identifies itself as serial programmer 'CATHY3K' with software version 1.1
;  - Supports everything Caterina bootloader supports.
;
;  Note:  Boot size fuses must be set to BOOTSZ1 = 0 and BOOTSZ0 to 1 (1K-word)
;
;  Arduboy exclusive features (only included when building for Arduboy):
;
;  - Breathing RGB LED in bootloader mode
;  - Power on + Button Down launces bootloader instead of application
;  - Button Down in bootloader mode Extends bootloader timeout period
;  - USB icon is displayed on display to indicate bootloader mode.
;  - Data can be written to display using Write Memory Block command (streaming)
;  - Button states can be read using hardware version command
;  - Set LED command can be used to turn display on/of, control RGB LED breathing,
;  - RxLED TxLED status fuctions and control the LEDs individually.
;  - Identifies itself as serial programmer 'ARDUBOY' with software version 1.1
;
;  Same licence as below applies
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

#define TIMEOUT_PERIOD          7500    //; uint16 bootloader timeout duration
                                          ;in millisecs

#define TX_RX_LED_PULSE_PERIOD  100     //; uint8 rx/tx pulse period in millisecs

;-------------------------------------------------------------------------------
;Externally supplied defines (commmand line/makefile)

; #define ARDUBOY           //;enables Arduboy exclusive features (All versions)

; #define ARDUBOY_DEVKIT    //;configures hardware for official  Arduboy DevKit

; #define ARDUBOY_PROMICRO  //;For Arduboy clones using a Pro Micro 5V using
;                             ;alternate pins for OLED CS, RGB Green and 2nd
;                             ;speaker pin (speaker is not initialized though)

; #define OLED_SH1106       //;for Arduboy clones using SH1106 OLED display only

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
#define BOOTLOADER_VERSION_MINOR    1

#define BOOT_START_ADDR         0x7400
#define BOOT_END_ADDR           0x7C00

;boot logo positioning (ARDUBOY)
#define BOOTLOGO_WIDTH          16
#define BOOTLOGO_HEIGHT         (40 / 8)
#define BOOT_LOGO_X             56
#define BOOT_LOGO_Y             (16 / 8)
#define BOOT_LOGO_OFFSET        BOOT_LOGO_X + BOOT_LOGO_Y * 128

;OLED display commands  (ARDUBOY)
#define OLED_SET_PAGE_ADDR          0xB0
#if defined OLED_SH1106
  #define OLED_SET_COLUMN_ADDR_LO   0x02
#else
  #define OLED_SET_COLUMN_ADDR_LO   0x00
#endif
#define OLED_SET_COLUMN_ADDR_HI     0x10
#define OLED_SET_DISPLAY_ON         0xAF
#define OLED_SET_DISPLAY_OFF        0xAE

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
#define SPMCSR_ 0x0057

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

;CLKPR
#define CLKPCE  7

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
#ifdef ARDUBOY
#ifdef ARDUBOY_PROMICRO
#define OLED_RST        1
#define OLED_CS         3
#define OLED_DC         4
#define RGB_R           6
#define RGB_G           0
#define RGB_B           5
#define RGB_RED_ON      cbi     PORTB, RGB_R
#define RGB_GREEN_ON    cbi     PORTD, RGB_G
#define RGB_BLUE_ON     cbi     PORTB, RGB_B
#define RGB_RED_OFF     sbi     PORTB, RGB_R
#define RGB_GREEN_OFF   sbi     PORTD, RGB_G
#define RGB_BLUE_OFF    sbi     PORTB, RGB_B
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
#define RGB_RED_ON      cbi     PORTB, RGB_R
#define RGB_GREEN_ON    cbi     PORTB, RGB_G
#define RGB_BLUE_ON     cbi     PORTB, RGB_B
#define RGB_RED_OFF     sbi     PORTB, RGB_R
#define RGB_GREEN_OFF   sbi     PORTB, RGB_G
#define RGB_BLUE_OFF    sbi     PORTB, RGB_B
#endif
#endif

#ifdef ARDUBOY_DEVKIT
#define BUTTON_A            7
#define BUTTON_B            6
#define BUTTON_UP           4
#define BUTTON_RIGHT        6
#define BUTTON_LEFT         5
#define BUTTON_DOWN         6
#else
#define BUTTON_A            6
#define BUTTON_B            4
#define BUTTON_UP           7
#define BUTTON_RIGHT        6
#define BUTTON_LEFT         5
#define BUTTON_DOWN         4
#endif

;LED Control bits
#define LED_CTRL_OLED       7
#define LED_CTRL_RGB        6
#define LED_CTRL_RXTX       5
#define LED_CTRL_RX_ON      4
#define LED_CTRL_TX_ON      3
#define LED_CTRL_RGB_R_ON   1
#define LED_CTRL_RGB_G_ON   2
#define LED_CTRL_RGB_B_ON   0
#endif

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
#define sizeof_DeviceDescriptor     sizeof_USB_Descriptor_Header_t + (8 << 1)
#define sizeof_LanguageString       sizeof_USB_Descriptor_Header_t + (1 << 1)
#define sizeof_ProductString        sizeof_USB_Descriptor_Header_t + (16 << 1)
#define sizeof_ManufNameString      sizeof_USB_Descriptor_Header_t + (11 << 1)
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
#elif DEVICE VID == 0x1B4F
#define MANUFACTURER_STRING     'S','p','a','r','k','F','u','n',' ',' ',' '
#else
#define MANUFACTURER_STRING     'U','n','k','n','o','w','n',' ',' ',' ',' '
#endif
;-------------------------------------------------------------------------------
                            .section .data  ;Initalized data copied to ram
;-------------------------------------------------------------------------------
SECTION_DATA_START:

;- Software ID string - (7 characters)

SOFTWARE_IDENTIFIER:
                            #ifdef ARDUBOY
                            .ascii  "ARDUBOY"
                            #else
                            .ascii  "CATHY3K"
                            #endif

;;- LineEncoding structure - (moved to .bss)
;
;LineEncoding:
;                            .long   0   ;BaudRateBPS
;                            .byte   0   ;CharFormat
;                            .byte   0   ;ParityType
;                            .byte   8   ;DataBits

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
                            .byte   0x02        ;DTYPE_Configuration
                            ;-config.data -
                            .byte   0x3e, 0x00  ;TotalConfigurationSize = sizeof(USB_Descriptor_Configuration_t)
                            .byte   0x02        ;TotalInterfaces = 2
                            .byte   0x01        ;ConfigurationNumber    = 1
                            .byte   0x00        ;ConfigurationStrIndex  = NO_DESCRIPTOR
                            .byte   0x80        ;ConfigAttributes       = USB_CONFIG_ATTR_BUSPOWERED
                            .byte   0x32        ;MaxPowerConsumption    = USB_CONFIG_POWER_MA(100)
                            ;-CDC_CCI_Interface.header-
                            .byte   0x09        ;sizeof(USB_Descriptor_Interface_t)
                            .byte   0x04        ;DTYPE_Interface
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
                            .byte   0x24        ;DTYPE_CSInterface
                            ;CDC_Functional_Header.data
                            .byte   0x00        ;Subtype = 0x00
                            .word   0x0110      ;CDCSpecification = VERSION_BCD(01.10)
                            ;.header
                            .byte   0x04
                            .byte   0x24        ;DTYPE_CSInterface
                            ;.data
                            .byte   0x02
                            .byte   0x04
                            ;.header
                            .byte   0x05
                            .byte   0x24        ;DTYPE_CSInterface
                            ;.data
                            .byte   0x06
                            .byte   0x00
                            .byte   0x01
                            ;.header
                            .byte   0x07
                            .byte   0x05        ;DTYPE_Endpoint
                            ;.data
                            .byte   0x82        ;EndpointAddress   = ENDPOINT_DIR_IN | CDC_NOTIFICATION_EPNUM
                            .byte   0x03        ;Attributes        = EP_TYPE_INTERRUPT | ENDPOINT_ATTR_NO_SYNC
                            .word   0x0008      ;EndpointSize      = CDC_NOTIFICATION_EPSIZE
                            .byte   0xff        ;PollingIntervalMS = 0xFF
                            ;.header
                            .byte   0x09
                            .byte   0x04
                            ;.data
                            .byte   0x01
                            .byte   0x00, 0x02
                            .byte   0x0a, 0x00
                            .byte   0x00, 0x00
                            ;.header
                            .byte   0x07
                            .byte   0x05
                            ;.data
                            .byte   0x04
                            .byte   0x02
                            .word   0x0010
                            .byte   0x01
                            ;.header
                            .byte   0x07
                            .byte   0x05
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
ManufNameString:            ;-header-
                            .byte   sizeof_ManufNameString
                            .byte   DTYPE_String
                            ;-data-
                            .word   MANUFACTURER_STRING

                        ;OLED display initialization data

                        #ifdef ARDUBOY
DisplaySetupData:           .byte   0xD5, 0xF0              ;Display Clock Divisor
                            .byte   0x8D, 0x14              ;Charge Pump Setting enabled
                            .byte   0xA1                    ;Segment remap
                            .byte   0xC8                    ;COM output scan direction
                            .byte   0x81, 0xCF              ;Set contrast
                            .byte   0xD9, 0xF1              ;set precharge
                            .byte   OLED_SET_DISPLAY_ON     ;display on
                            ;.byte  0x20, 0x00              ;set display mode to horizontal addressing
                            .byte   OLED_SET_COLUMN_ADDR_LO
                        ;   .byte   0x21, 0x00, 0x7F        ;set column address range
DisplaySetupData_End:
                        ;USB boot icon graphics

bootgfx:                    .byte   0x00, 0x00, 0xff, 0xff, 0xcf, 0xcf, 0xff, 0xff, 0xff, 0xff, 0xcf, 0xcf, 0xff, 0xff, 0x00, 0x00
                            .byte   0xfe, 0x06, 0x7e, 0x7e, 0x06, 0xfe, 0x46, 0x56, 0x56, 0x16, 0xfe, 0x06, 0x56, 0x46, 0x1e, 0xfe
                            .byte   0x3f, 0x61, 0xe9, 0xe3, 0xff, 0xe3, 0xeb, 0xe3, 0xff, 0xe3, 0xeb, 0xe3, 0xff, 0xe1, 0x6b, 0x3f

                        #endif
SECTION_DATA_END:
;-------------------------------------------------------------------------------
;Bootloader Vectors
;-------------------------------------------------------------------------------
                            .section .boot, "ax" ;

;Note each vector slot takes 4 bytes. Only two bytes are used because of the
;relative jumps. Another RJMP can be placed in these 'free' bytes for a future
;API. For that reason the NOP instructions are replaced by RET instructions.

bad_interrupt:
VECTOR_00_7800:             cli
                            rjmp    reset_vector

                            .space  9*4
                            
VECTOR_10:                  push    r0
                            rjmp    USB_general_int

                            .space 6*4
                            
VECTOR_17:                  rjmp    TIMER1_COMPA_interrupt      ;Timer/Counter1 Compare Match A

;-------------------------------------------------------------------------------
;RESET vector
;-------------------------------------------------------------------------------

reset_vector:               eor     r1, r1              ;global zero reg
                            out     SREG, r1            ;clear SREG
                            ldi     r28, lo8(RAMEND-2)  ;preserve posible MAGIC KEY at RAMEND-1
                            ldi     r29, hi8(RAMEND-2)
                            out     SPH, r29            ;SP = RAMEND-2
                            out     SPL, r28

                            in      r16, MCUSR          ;save MCUSR state
                            out     MCUSR, r1           ;MCUSR

                            ldi     r24, 0x18           ;we want watch dog disabled asap
                            sts     WDTCSR, r24
                            sts     WDTCSR, r1

                            ;initialize .data section

                            ldi     r26, lo8(SECTION_DATA_START)    ;X
                            ldi     r27, hi8(SECTION_DATA_START)
                            ldi     r30, lo8(SECTION_DATA_DATA)     ;Z
                            ldi     r31, hi8(SECTION_DATA_DATA)
                            ;ldi        r17, hi8(SECTION_DATA_END)
reset_vector_b1:
                            lpm     r0, Z+                          ;copy data from end of text
                            st      X+, r0                          ;to data section in sram
                            cpi     r26, lo8(SECTION_DATA_END)
                            ;cpc        r27, r17                    ;length < 256
                            brne    reset_vector_b1

                            ;clear .bss section

                            ;ldi    r26, lo8(SECTION_BSS_START)     ;.bss starts at .data end
                            ;ldi    r27, hi8(SECTION_BSS_START)
                            ldi     r17, hi8(SECTION_BSS_END)
reset_vector_b2:
                            st      X+, r1                          ;set to zero
                            cpi     r26, lo8(SECTION_BSS_END)
                            cpc     r27, r17
                            brne    reset_vector_b2

                        #ifdef  ARDUBOY
                            rcall   SetupHardware           ;For Arduboy we want hardware initialized now for button test and application
                        #endif
;-------------------------------------------------------------------------------
main:
                            ldi     r30,lo8(BOOTKEY_PTR)    ;get magic key at old pointer
                            ldi     r31,hi8(BOOTKEY_PTR)
                            ld      r20,Z+                  ;r20:21 magic key old location
                            ld      r21,z
                            st      z,r1                    ;clear value
                            st      -z,r1
                            pop     r22                     ;r22:23 magic key at RAMEND-1
                            pop     r23
                            sbrc    r16, 1                  ;MCUSR state EXTRF skip no external reset
                            rjmp    run_bootloader          ;enter bootloader mode

                            sbrs r16, 0                     ;MCUSR state PORF test power on reset
                            rjmp main_test_wdt              ;not POR

                            ;power on reset

                        #ifdef ARDUBOY
                            #ifdef ARDUBOY_DEVKIT
                            sbis    PINB,BUTTON_DOWN        ;DevKit DOWN button
                            #else
                            sbis    PINF,BUTTON_DOWN        ;test DOWN button
                            #endif
                            rjmp    run_bootloader          ;button pressed, enter bootloader
                        #endif
                            rcall   TestApplicationFlash
                            brne    StartSketch             ;run sketch when loaded

                            ;no application or no POR

main_test_wdt:              sbrs    r16, 3                  ;MCUSR state WDRF
                            rjmp    run_bootloader          ;WDT not triggered, enter bootloader mode

                            ;WDT was triggered, test magic key on old and new location

                            subi    r22, lo8(BOOTKEY)       ;test RAMEND-1 key
                            sbci    r23, hi8(BOOTKEY)
                            breq    run_bootloader          ;magic key, enter bootloader mode

                            subi    r20, lo8(BOOTKEY)       ;test old key
                            sbci    r21, hi8(BOOTKEY)
                            breq    run_bootloader          ;magic key, enter bootloader mode

                            ;no magic key

                            rcall   TestApplicationFlash
                            brne    StartSketch             ;run application when loaded

                            ;enter bootloader mode

run_bootloader:
                        #ifndef ARDUBOY
                            rcall   SetupHardware
                        #endif
                            rcall   USB_Init
                            sei
                            rcall   ResetTimeout
bootloader_loop:
                            rcall   CDC_Task
                            rcall   USB_USBTask
                            rcall   LEDPulse
                            rcall   GetTimeout
                            subi    r24, lo8(TIMEOUT_PERIOD)
                            sbci    r25, hi8(TIMEOUT_PERIOD)
                            brcs    bootloader_loop             ;loop < TIMEOUT_PERIOD
                            ;rjmp   StartSketch

                            ;timeout, start sketch

;-------------------------------------------------------------------------------
StartSketch:
                            cli
                            ;lds     r24, UDCON      ;USB detach
                            ;ori     r24, 0x01
                            ldi     r24, 0x01       ;DETACH
                            sts     UDCON, r24
                            
                            sts     TIMSK1, r1      ;Undo TIMER1 setup and clear the count before running the sketch
                            sts     TCCR1B, r1
                            sts     TCNT1H, r1
                            sts     TCNT1L, r1
                            ldi     r24, 1 << IVCE  ;enable interrupt vector change
                            out     MCUCR, r24
                            out     MCUCR, r1       ;relocate vector table to application section
                            rcall   LEDPulse_off
                            TX_LED_OFF
                            RX_LED_OFF
                            jmp     0               ; start application
;-------------------------------------------------------------------------------
LEDPulse:

                            ldi  r30,lo8(LLEDPulse)
                            ldi  r31,hi8(LLEDPulse)
                            ld   r24,z+
                            ld   r25,z
                            adiw r24, 1                 ;LLEDPulse++, bit 15 sets N flag
                            st   z,r25
                            st   -z,r24
                            mov  r0,r25
                            brpl LEDPulse_b1            ;branch bit 15 clear

                            ;LedPulse >= 0x8000 bright to dim

                            com     r0                  ;== 255-p rather than 254-p (which causes bright flash)

                            ;LedPulse < 0x8000 dim to bright
LEDPulse_b1:
                        #ifdef  ARDUBOY
                            lds     r16, LED_Control    ;if RGB LED breathing is disabled
                            bst     r16, LED_CTRL_RGB   ;RGB LED state shouldn't be changed
                            brts    LED_Pulse_ret       ;ret, disabled

                            adiw    r24, 0              ;test overflow for color change
                            ld      r25,-z              ;get RGBLEDstate
                            brne    LEDPulse_testperiod

                            inc     r25                 ;change RGBLED state
                            st      z,r25
                        #endif
LEDPulse_testperiod:
                            add     r0, r0
                            cp      r0, r24
                            brcc    LEDPulse_on

;-------------------------------------------------------------------------------
LEDPulse_off:
                        #ifdef ARDUBOY
                            RGB_RED_OFF
                            RGB_GREEN_OFF
                            RGB_BLUE_OFF
                        #else
                            LLED_OFF
                        #endif
LED_Pulse_ret:
                            ret
;-------------------------------------------------------------------------------
LEDPulse_on:
                        #ifdef ARDUBOY
                            andi    r25, 0x03               ;RGB LED has 4 states:
                            brne    LEDPulse_on_b1
                            RGB_RED_ON
LEDPulse_on_b1:
                            cpi     r25,1
                            brne    LEDPulse_on_b2
                            RGB_GREEN_ON
LEDPulse_on_b2:
                            cpi     r25,2
                            brne    LEDPulse_on_b3          ;3: none lit
                            RGB_BLUE_ON
LEDPulse_on_b3:
                        #else
                            LLED_ON
                        #endif
                            ret
;-------------------------------------------------------------------------------
TIMER1_COMPA_interrupt:
                            push    r0
                            in      r0, SREG                    ;save SREG
                            push    r24
                            push    r25
                            push    r30
                            push    r31
                            eor     r24,r24                     ;use as temp zero reg
                            sts     TCNT1H, r24                 ;reset counter
                            sts     TCNT1L, r24
                        #ifdef ARDUBOY
                            lds     r25,LED_Control
                            bst     r25,LED_CTRL_RXTX
                            brts    TIMER1_COMPA_interrupt_b2   ;don't update RxTx LEDs
                        #endif
                            ldi     r30,lo8(TxLEDPulse)
                            ldi     r31,hi8(TxLEDPulse)
                            ld      r25,z
                            cp      r24,r25                 ;sets carry if r25 > 0
                            sbc     r25,r24                 ;r25 -0 - carry
                            st      z+,r25                      ;Point to RXLEDPulse
                            brne    TIMER1_COMPA_interrupt_b1

                            TX_LED_OFF
TIMER1_COMPA_interrupt_b1:
                            ld   r25,z
                            cp   r24,r25                    ;again sets carry if r25 > 0
                            sbc  r25,r24                    ;r25 - carry
                            st   z,r25
                            brne TIMER1_COMPA_interrupt_b2

                            RX_LED_OFF
TIMER1_COMPA_interrupt_b2:
                            sbis    PINF,4
                            rjmp    TIMER1_COMPA_int_end    ;DOWN button pressed set timeout to half a second

                            rcall   TestApplicationFlash
                            breq    TIMER1_COMPA_int_end    ;no sketch loaded

                            rcall   GetTimeout              ;no button, sketch loaded, increase timeout
                            adiw r24, 0x01                  ;Timeout++
                            rcall   SetTimeout
TIMER1_COMPA_int_end:
                            pop  r31
                            pop  r30
                            rjmp shared_reti
;-------------------------------------------------------------------------------
USB_general_int:
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

                            lds     r24, USBCON
                            sbrs    r24, 0
                            rjmp    USB_general_int_b3

                            lds     r24, USBINT
                            andi    r24, 0xFE
                            sts     USBINT, r24
                            lds     r24, USBSTA
                            sbrs    r24, 0
                            rjmp    USB_general_int_b2

                            ldi     r24, 0x10       ;PINDIV
                            out     PLLCSR, r24
                            ldi     r24, 0x12       ;PINDIV | PLLE
                            out     PLLCSR, r24
USB_general_int_b1:
                            in      r0, PLLCSR
                            sbrs    r0, 0
                            rjmp    USB_general_int_b1

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
                            sts     USBCON, r24
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

                            ldi     r24, 0x10
                            out     PLLCSR, r24
                            ldi     r24, 0x12
                            out     PLLCSR, r24
USB_general_int_b5:
                            in      r0, PLLCSR
                            sbrs    r0, 0
                            rjmp    USB_general_int_b5

                            lds     r24, USBCON
                            andi    r24, 0xDF
                            sts     USBCON, r24
                            lds     r24, UDINT
                            andi    r24, 0xEF
                            sts     UDINT, r24

                            rcall   UDIEN_get
                            andi    r24, 0xEF
                            rcall   UDIEN_set
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

                            lds     r24, UDINT
                            andi    r24, 0xF7
                            sts     UDINT, r24
                            ldi     r24, 0x02
                            out     GPIOR0, r24
                            sts     USB_Device_ConfigurationNumber, r1
                            lds     r24, UDINT
                            andi    r24, 0xFE
                            sts     UDINT, r24
                            rcall   UDIEN_Clr0_Set4
                            ldi     r24, 0x00
                            ldi     r22, 0x00
                            ldi     r20, 0x02
                            rcall   Endpoint_ConfigureEndpoint_Prv  ;uses: r20,r22,r24,r25
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
GetTimeout:
                            lds  r24, Timeout+0             ;get LSB timeout value
                            lds  r25, Timeout+1             ;get MSB timeout value
                            ret
;-------------------------------------------------------------------------------
ResetTimeout:
                            ldi     r24,0x00
                            ldi     r25,0x00
                            ;rjmp   SetTimeout
;-------------------------------------------------------------------------------
SetTimeout:
                            sts     Timeout+0, r24
                            sts     Timeout+1, r25
                            ret
;-------------------------------------------------------------------------------
FetchNextCommandByte:

;uses r24,r25
                            ldi     r24, 0x04               ;CDC_RX_EPNUM
                            rcall   UENUM_set
                            rjmp    FetchNextCommandByte_b4
FetchNextCommandByte_b1:
                            rcall   UEINTX_clearbits_7B
                            rjmp    FetchNextCommandByte_b3
FetchNextCommandByte_b2:
                            in      r24, GPIOR0
                            and     r24, r24
                            breq    FetchNextCommandByte_ret
FetchNextCommandByte_b3:
                            rcall   UEINTX_get
                            sbrs    r24, 2                      ;RXOUTI / KILLBK
                            rjmp    FetchNextCommandByte_b2
FetchNextCommandByte_b4:
                            rcall   UEINTX_get
                            sbrs    r24, 5                      ;RWAL
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
                            rcall   UENUM_set
                            rcall   UEINTX_get
                            sbrc    r24, 5
                            rjmp    WriteNextResponseByte_b3

                            rcall   UEINTX_clearbits_7E
                            rjmp    WriteNextResponseByte_b2
WriteNextResponseByte_b1:
                            in      r24, GPIOR0
                            and     r24, r24
                            breq    WriteNextResponseByte_ret
WriteNextResponseByte_b2:
                            rcall   UEINTX_get
                            sbrs    r24, 0
                            rjmp    WriteNextResponseByte_b1
WriteNextResponseByte_b3:
                            sts     UEDATX, r0
                        #ifdef ARDUBOY
                            lds     r24,LED_Control
                            bst     r24,LED_CTRL_RXTX
                            brts    WriteNextResponseByte_ret           ;RxTx LEDs disabled
                        #endif
                            TX_LED_ON
                            ldi     r24, lo8(TX_RX_LED_PULSE_PERIOD)
                            sts     TxLEDPulse, r24
WriteNextResponseByte_ret:
                            ret
;-------------------------------------------------------------------------------
CDC_Task:
                            ldi     r24, 0x04
                            rcall   UENUM_set
                            rcall   UEINTX_get
                            sbrs    r24, 2
                            rjmp    CDC_Task_ret

                            ;endpoint has command from host
                        #ifdef ARDUBOY
                            lds     r24,LED_Control
                            bst     r24,LED_CTRL_RXTX
                            brts    CDC_Task_b1             ;RxTx LEDs disabled
                        #endif
                            RX_LED_ON
                            ldi     r24, lo8(TX_RX_LED_PULSE_PERIOD)
                            sts     RxLEDPulse, r24
CDC_Task_b1:
                            rcall FetchNextCommandByte
                            mov     r17, r24                ;save command
                            cpi     r24, 'E'
                            brne    CDC_Task_Command_T

                            ;'E': end command, sets timeout to 500 millisecs

                            ldi     r24, lo8(TIMEOUT_PERIOD - 500)
                            ldi     r25, hi8(TIMEOUT_PERIOD - 500)
                            rcall   SetTimeout
                            rcall   SPM_wait
CDC_Task_w1:
                            sbic    EECR, 1
                            rjmp    CDC_Task_w1     ;wait for any EEPROM writes to finish

                            ldi     r24, 0x11       ;RWWSRE | SPMEN
                            out     SPMCSR,r24
                            spm
                            rjmp    CDC_Task_Acknowledge
CDC_Task_Command_T:
                            cpi     r24, 'T'
                            brne    CDC_Task_Command_L

                            ;'T': select device

                            rcall   FetchNextCommandByte    ;ignore device byte
CDC_Task_Acknowledge:
                            ldi     r24, 0x0D               ;send acknowledge
                            rjmp    CDC_Task_Response
CDC_Task_Command_L:
                            cpi     r24, 'L'
                            breq    CDC_Task_Acknowledge

                            cpi     r24, 'P'
                            breq    CDC_Task_Acknowledge

                            cpi     r24, 't'
                            brne    CDC_Task_Command_a

                            ;'t': Return ATMEGA128 part code - this is only to allow AVRProg to use the bootloader

                            ldi     r24, 0x44                   ;supported device
                            rcall   WriteNextResponseByte
                            ldi     r24, 0x00                   ;end of supported devices list
                            rjmp    CDC_Task_Response
CDC_Task_Command_a:
                            cpi     r24, 'a'
                            brne    CDC_Task_Command_A

                            ;'a': Indicate auto-address increment is supported

                            ldi     r24, 'Y'                ;Yes
                            rjmp    CDC_Task_Response
CDC_Task_Command_A:
                            cpi     r24, 'A'
                            brne    CDC_Task_Command_p

                            ;set current address

                            rcall   FetchNextCommandByte
                            mov     r31,r24
                            rcall   FetchNextCommandByte
                            mov     r30,r24
                            rcall   word_to_byte_addr
                            rjmp    CDC_Task_SetAddr
CDC_Task_Command_p:
                            cpi     r24, 'p'
                            brne    CDC_Task_Command_S

                            ;'p' send programmer response

                            ldi     r24, 'S'                ;'S'erial programmer
                            rjmp    CDC_Task_Response
CDC_Task_Command_S:
                            cpi     r24, 'S'
                            brne    CDC_Task_Command_V

                            ;'S' send software identifier response

                            ldi     r28, lo8(SOFTWARE_IDENTIFIER);Y
                            ldi     r29, hi8(SOFTWARE_IDENTIFIER)
CDC_Task_SendID:
                            ld      r24, Y+
                            rcall   WriteNextResponseByte
                            cpi     r28, lo8(SOFTWARE_IDENTIFIER + 7)
                            brne    CDC_Task_SendID
                            rjmp    CDC_Task_Complete
CDC_Task_Command_V:
                            cpi     r24, 'V'
                            brne    CDC_Task_Command_v

                            ;'V': Software version

                            ldi     r24, '0' + BOOTLOADER_VERSION_MAJOR
                            rcall   WriteNextResponseByte
                            ldi     r24, '0' + BOOTLOADER_VERSION_MINOR
                            rjmp    CDC_Task_Response
CDC_Task_Command_v:
                        #ifdef ARDUBOY
                            cpi     r24, 'v'
                            brne    CDC_Task_Command_x

                            ;'v': Hardware version (returns Arduboy button states)

                            ldi     r24, '1'                ;'1' + (A-button << 1) + (B-button)
                            #ifdef ARDUBOY_DEVKIT
                            sbis    PINF, BUTTON_A
                            subi    r24, -2
                            sbis    PINF, BUTTON_B
                            subi    r24, -1
                            rcall   WriteNextResponseByte
                            ldi     r24, 'A'
                            sbis    PINB, BUTTON_UP
                            subi    r24, -8
                            sbis    PINC, BUTTON_RIGHT
                            subi    r24, -4
                            sbis    PINB, BUTTON_LEFT
                            subi    r24, -2
                            sbis    PINB, BUTTON_DOWN
                            subi    r24, -1
                            #else
                            sbis    PINE, BUTTON_A
                            subi    r24, -2
                            sbis    PINB, BUTTON_B
                            subi    r24, -1
                            rcall   WriteNextResponseByte
                            in      r24,PINF            ;read D-Pad buttons
                            com     r24                 ;get active high button states in low nibble
                            swap    r24
                            andi    r24,0x0F
                            subi    r24,-'A'            ;'A' + (UP << 3) + (RIGHT << 2) + (LEFT << 1) + DOWN
                            #endif
                            rjmp    CDC_Task_Response

CDC_Task_Command_x:         ;'x': set LEDs

                            cpi     r24, 'x'
                            brne    CDC_Task_Command_s

                            rcall   FetchNextCommandByte
                            rcall   Set_LED_Control
                            rjmp    CDC_Task_Acknowledge
                        #endif
CDC_Task_Command_s:
                            cpi     r24, 's'
                            brne    CDC_Task_Command_e

                            ;'s' avr signature

                            ldi     r24, AVR_SIGNATURE_3
                            rcall   WriteNextResponseByte
                            ldi     r24, AVR_SIGNATURE_2
                            rcall   WriteNextResponseByte
                            ldi     r24, AVR_SIGNATURE_1
                            rjmp    CDC_Task_Response
CDC_Task_Command_e:
                            cpi     r24, 'e'
                            brne    CDC_Task_TestBitCmds

                            ;'e': erase application section

                            ldi     r30, lo8(APPLICATION_START_ADDR)    ;Z
                            ldi     r31, hi8(APPLICATION_START_ADDR)
                            ldi     r25, 0x03                           ;PGERS | SPMEN Page erase
                            ldi     r24, 0x05                           ;PGWRT | SPMEN pagewrite

                            ;0000..BOOT_START_ADDR
CDC_Task_Erase:
                            out     SPMCSR, r25             ;SPMCSR do page erase
                            spm
                            rcall   SPM_wait
                            out     SPMCSR, r24             ;do page write
                            spm
                            rcall   SPM_wait
                            subi    r30, 0x80               ;Z += 128
                            sbci    r31, 0xFF
                            cpi     r31, hi8(BOOT_START_ADDR)       ;BOOT_START_ADDR is always 256 byte aligned
                            brne    CDC_Task_Erase                  ;loop until end of application area
                            rjmp    CDC_Task_Acknowledge
CDC_Task_TestBitCmds:
                            cpi     r24, 'r'
                            ldi     r30, 0x01               ;get lock bits
                            breq    CDC_Task_getfusebits
                            cpi     r24, 'F'
                            ldi     r30, 0x00               ;get low fuse bits
                            breq    CDC_Task_getfusebits
                            cpi     r24, 'N'
                            ldi     r30, 0x03               ;get high fuse bits
                            breq    CDC_Task_getfusebits
                            cpi     r24, 'Q'
                            brne    CDC_Task_Command_b

                            ;'Q': get extended fuse bits

                            ldi     r30, 0x02   ;get extended fuse bits

                            ;r30 = type of bits to read
CDC_Task_getfusebits:
                            ldi     r31, 0x00   ; 0
                            ldi     r24, 0x09   ; 9
                            out     SPMCSR,r24
                            lpm     r24, Z
                            rjmp    CDC_Task_Response
CDC_Task_Command_b:
                            cpi     r24, 'b'
                            brne    CDC_Task_Command_B

                            ;send block support supported

                            ldi     r24, 'Y'                ;Yes
                            rcall   WriteNextResponseByte
                            ldi     r24, hi8(SPM_PAGESIZE)
                            rcall   WriteNextResponseByte   ;MSB
                            ldi     r24, lo8(SPM_PAGESIZE)
                            rjmp    CDC_Task_Response       ;MSB
CDC_Task_Command_B:
                            cpi     r24, 'B'
                            breq    CDC_Task_RdWrMemBlk

                            cpi     r24, 'g'
                            breq    CDC_Task_RdWrMemBlk
                            rjmp    CDC_Task_Command_C

                            ;'B' or 'g': read/write memory block
CDC_Task_RdWrMemBlk:
                            rcall   ResetTimeout

                            ;ReadWriteMemoryBlock (inline, r17 = command)

                            rcall   FetchNextCommandByte
                            mov     r29, r24                ;BlockSize MSB
                            rcall   FetchNextCommandByte
                            mov     r28, r24                ;BlockSize LSB
                            rcall   FetchNextCommandByte
                            mov     r16, r24                ;MemoryType
                        #ifdef  ARDUBOY
                            subi    r24, 'D'                ;Arduboy Supports 'D'isplay too
                            cpi     r24, 0x03               ;'F' - 'D' + 1
                        #else
                            subi    r24, 'E'
                            cpi     r24, 0x02               ;'F' - 'E' + 1
                        #endif
                            brcs    CDC_Task_RdWrMemBlk_ok

                            rjmp    CDC_Task_ErrResponse    ;not 'E'EPROM or 'F'LASH
CDC_Task_RdWrMemBlk_ok:
                            sts     TIMSK1, r1              ;disable timer 1 interrupt
                            rcall   GetCurrAddress
                            cpi     r17, 'g'
                            breq    CDC_Task_ReadMem
                            rjmp    CDC_Task_WriteMem

                            ;Read Memory Block
CDC_Task_ReadMem:
                            ldi     r24, 0x11               ;boot_rww_enable
                            out     SPMCSR, r24
                            spm
                            rjmp    CDC_Task_ReadMem_next
CDC_Task_ReadMem_loop:
                            cpi     r16, 'F'
                            brne    CDC_Task_ReadMem_EEPROM

                            lpm     r24, Z+
                            rjmp    CDC_Task_ReadMem_send
CDC_Task_ReadMem_EEPROM:
                            rcall   eeprom_read
CDC_Task_ReadMem_send:
                            rcall   WriteNextResponseByte
CDC_Task_ReadMem_next:
                            sbiw    r28, 0x01
                            brpl    CDC_Task_ReadMem_loop

                            rcall   SetCurrAddress
                            rjmp    CDC_Task_RdWrMemBlk_end

                            ;write memory block
CDC_Task_WriteMem:
                            movw    r8, r30             ;save addr for page write
                            cpi     r16, 'F'
                            brne    CDC_Task_WriteMem_next

                            cpi     r31, hi8(BOOT_START_ADDR)
                            brcc    CDC_Task_WriteMem_next

                            ;Flash memory Page erase

                            ldi     r24, 0x03   ;PGERS | SPMEN (Page Erase)
                            out     SPMCSR, r24
                            spm
                            rcall   SPM_wait
                            rjmp    CDC_Task_WriteMem_next

                            ;Write Memory loop
CDC_Task_WriteMem_loop:
                            rcall   FetchNextCommandByte
                            cpi     r16, 'F'
                            brne    CDC_Task_WriteMem_display

                            ;Flash

                            bst     r28,0                   ;block length
                            brts    CDC_Task_WriteMem_lsb

                            ;msb,  write word

                            cpi     r31, hi8(BOOT_START_ADDR)
                            brcc    CDC_Task_WriteMem_inc

                            mov     r1, r24                 ;word in r0:r1
                            ldi     r24,0x01                ;SPMEN
                            out     SPMCSR, r24
                            spm
                            eor     r1, r1                  ;restore zero reg
CDC_Task_WriteMem_inc:
                            adiw    r30, 2
                            rjmp    CDC_Task_WriteMem_next
CDC_Task_WriteMem_lsb:
                            mov     r0, r24                 ;save lsb
                            rjmp    CDC_Task_WriteMem_next

CDC_Task_WriteMem_display:
                        #ifdef ARDUBOY
                            cpi     r16, 'D'
                            brne    CDC_Task_WriteMem_eeprom

                            ;OLED display

                            ldi     r26,lo8(DisplayBuffer)
                            ldi     r27,hi8(DisplayBuffer)
                            mov     r25,r31                 ;CurrAddress
                            andi    r25,0x3                 ;keep 1K address range
                            add     r26,r30
                            adc     r27,r25
                            st      X+, r24
                            adiw    r30, 1
                            rjmp    CDC_Task_WriteMem_next
                        #endif
                            ;EEPROM
CDC_Task_WriteMem_eeprom:
                            rcall   eeprom_write
CDC_Task_WriteMem_next:
                            sbiw    r28, 0x01
                            brpl    CDC_Task_WriteMem_loop

                            rcall   SetCurrAddress
                        #ifdef ARDUBOY
                            cpi     r16, 'D'
                            brne    CDC_Task_WriteMem_flash_end

                            andi    r31, 0x03
                            or      r31, r30
                            brne    CDC_Task_WriteMem_end
                            rcall   Display
                            rjmp    CDC_Task_WriteMem_end
                        #endif
CDC_Task_WriteMem_flash_end:
                            cpi     r16, 'F'
                            brne    CDC_Task_WriteMem_end

                            ;Flash memory Page write

                            cpi     r31, hi8(BOOT_START_ADDR)
                            brcc    CDC_Task_WriteMem_end

                            ldi     r24, 0x05   ;PGWRT | SPMEN (write page)
                            movw    r30, r8     ;page addr
                            out     SPMCSR, r24
                            spm
                            rcall   SPM_wait
CDC_Task_WriteMem_end:
                            ldi     r24, 0x0D
                            rcall   WriteNextResponseByte
CDC_Task_RdWrMemBlk_end:
                            ldi     r24, 0x02                   ;OCIE1A
                            sts     TIMSK1, r24                 ;enable timer1 int
                            rjmp    CDC_Task_Complete
CDC_Task_Command_C:
                            cpi     r24, 'C'
                            brne    CDC_Task_Command_c

                            ;write high byte to flash

                            rcall   GetCurrAddress
                            rcall   FetchNextCommandByte
                            mov     r0, r24
                            ldi     r24, 0x01
                            out     SPMCSR, r24
                            spm
                            rjmp    CDC_Task_Acknowledge
CDC_Task_Command_c:
                            cpi     r24, 'c'
                            brne    CDC_Task_Command_m

                            ;Write the low byte to the current flash page

                            rcall   GetCurrAddress
                            rcall   FetchNextCommandByte
                            ori     r30, 0x01               ;odd addr byte
                            movw    r0, r24
                            ldi     r24, 0x01
                            out     SPMCSR, r24
                            spm
                            adiw    r30,1
                            rcall   SetCurrAddress
                            rjmp    CDC_Task_Acknowledge
CDC_Task_Command_m:
                            cpi     r24, 'm'
                            brne    CDC_Task_Command_R

                            ;Commit flash page to memory

                            rcall   GetCurrAddress
                            cpi     r31, hi8(BOOT_START_ADDR)
                            brcc    CDC_Task_Command_m_end

                            ldi     r24, 0x05
                            out     SPMCSR,r24
                            spm
                            rcall   SPM_wait
CDC_Task_Command_m_end:
                            rjmp    CDC_Task_Acknowledge
CDC_Task_Command_R:
                            cpi     r24, 'R'
                            brne    CDC_Task_Command_D

                            ;read flash word

                            rcall   GetCurrAddress
                            lpm     r24, Z+
                            rcall   WriteNextResponseByte
                            lpm     r24, Z
                            rjmp    CDC_Task_Response
CDC_Task_Command_D:
                            cpi     r24, 'D'
                            brne    CDC_Task_Command_d

                            ;write next byte to EEPROM at (CurrAddress)

                            rcall   FetchNextCommandByte
                            rcall   GetCurrAddress
                            rcall   eeprom_write
CDC_Task_SetAddr:
                            rcall   SetCurrAddress
                            rjmp    CDC_Task_Acknowledge
CDC_Task_Command_d:
                            cpi     r24, 'd'
                            brne    CDC_Task_Command_1B

                            ;Read the EEPROM byte

                            rcall   GetCurrAddress
                            rcall   eeprom_read
                            rcall   WriteNextResponseByte
                            rcall   SetCurrAddress
                            rjmp    CDC_Task_Complete
CDC_Task_Command_1B:
                            cpi     r24, 0x1B               ;ESCAPE
                            breq    CDC_Task_Complete
CDC_Task_ErrResponse:
                            ldi     r24, '?'                ;Unsupported command

                            ;(send byte in r24)
CDC_Task_Response:
                            rcall   WriteNextResponseByte
CDC_Task_Complete:
                            ldi     r24, 0x03
                            rcall   UENUM_set
                            rcall   UEINTX_clearbits_7E
                            sbrs    r25, 5
                            rjmp    x76d6

                            rjmp    x76f0

x76d0:                      in      r24, GPIOR0
                            and     r24, r24
                            breq    CDC_Task_ret

x76d6:                      rcall   UEINTX_get
                            sbrs    r24, 0
                            rjmp    x76d0

                            rcall   UEINTX_clearbits_7E
                            rjmp    x76f0

x76ea:                      in      r24, GPIOR0
                            and     r24, r24
                            breq    CDC_Task_ret

x76f0:                      rcall   UEINTX_get
                            sbrs    r24, 0
                            rjmp    x76ea

                            ldi     r24, 0x04       ; 4
                            rcall   UENUM_set
                            rcall   UEINTX_clearbits_7B
CDC_Task_ret:
                            ret
;-------------------------------------------------------------------------------
GetCurrAddress:
                            lds     r30, CurrAddress+0
                            lds     r31, CurrAddress+1
                            ret
;-------------------------------------------------------------------------------
SetCurrAddress:
                            sts     CurrAddress+0, r30
                            sts     CurrAddress+1, r31
                            ret
;-------------------------------------------------------------------------------
SPM_wait:
                            in      r0, SPMCSR
                            sbrc    r0, 0
                            rjmp    SPM_wait
                            ret
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
                            rcall   Endpoint_Write_Control_Stream_LE
                            rjmp    UEINTX_clearbits_7B
EVENT_USB_Device_ControlRequest_b1:
                            cpi     r24, 0x20                           ;CDC_REQ_SetLineEncoding
                            brne    EVENT_USB_Device_ControlRequest_ret
                            rcall   LineEncoding_sub
                            rcall   Endpoint_Read_Control_Stream_LE
                            ;rjmp   UEINTX_clearbits_7E

;-------------------------------------------------------------------------------
UEINTX_clearbits_7E:
                            ldi     r24, 0x7E           ;FIFOCON, TXI
                            rjmp    UEINTX_clearbits

;-------------------------------------------------------------------------------
UEINTX_clearbits_F7:
                            ldi     r24, 0xF7           ;RXSTPI
                            rjmp    UEINTX_clearbits

;-------------------------------------------------------------------------------
UEINTX_clearbits_7B:
                            ldi     r24, 0x7B           ;FIFOCON, RXOUTI
                            ;rjmp   UEINTX_clearbits
;-------------------------------------------------------------------------------
;USB Endpoint clear interrupt flag bits

;entry:
;   r24 = bitmask
;exit:
;   r24 = masked UEINTX
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
UEINTX_get:
                            lds     r24, UEINTX
                            ret
;-------------------------------------------------------------------------------
UDIEN_get:
                            lds     r24, UDIEN
                            ret
UDIEN_Clr0_Set4:
                            rcall   UDIEN_get
                            andi    r24, 0xFE
                            rcall   UDIEN_set
                            ori     r24, 0x10
                            ;rjmp   UDIEN_set
;-------------------------------------------------------------------------------
UDIEN_set:
                            sts     UDIEN, r24
                            ret
;-------------------------------------------------------------------------------
LineEncoding_sub:
                            rcall   UEINTX_clearbits_F7
                            ldi     r24, lo8(LineEncoding)
                            ldi     r25, hi8(LineEncoding)
                            ldi     r22, lo8(sizeof_LineEncoding)
                            ret
;-------------------------------------------------------------------------------
x778a_EVENT_USB_Device_ConfigurationChanged:

                            ldi r24, 0x02
                            ldi r22, 0xC1
                            ldi r20, 0x02
                            rcall   Endpoint_ConfigureEndpoint_Prv
                            ldi r24, 0x03
                            ldi r22, 0x81
                            rcall   Endpoint_ConfigureEndpoint_Prv_12
                            ldi r24, 0x04
                            ldi r22, 0x80
Endpoint_ConfigureEndpoint_Prv_12:
                            ldi r20, 0x12
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
;   r24:25 = Descriptor address r22 = length

                            cpi     r25, 0x02                   ;DTYPE_Configuration
                            breq    CALLBACK_USB_GetDesc_conf

                            cpi     r25, 0x03                   ;DTYPE_String
                            breq    CALLBACK_USB_GetDesc_str

                            cpi     r25, 0x01                   ;DTYPE_Device
                            brne    CALLBACK_USB_GetDesc_err

                            ;DTYPE_Device
CALLBACK_USB_GetDesc_dev:
                            ldi     r24, lo8(DeviceDescriptor)
                            ldi     r22, lo8(sizeof_DeviceDescriptor)
                            rjmp    CALLBACK_USB_GetDesc_ret

                            ;DTYPE_Configuration
CALLBACK_USB_GetDesc_conf:
                            ldi     r24, lo8(ConfigurationDescriptor)
                            ldi     r22, lo8(sizeof_ConfigurationDescriptor)
                            rjmp    CALLBACK_USB_GetDesc_ret

                            ;DTYPE_String
CALLBACK_USB_GetDesc_str:
                            cpi     r24, 1
                            brcc    CALLBACK_USB_GetDesc_b1 ;>0

                            ;0: LanguageString

                            ldi     r24, lo8(LanguageString)
                            ldi     r22, lo8(sizeof_LanguageString)
                            rjmp    CALLBACK_USB_GetDesc_ret

                            ;!0:
CALLBACK_USB_GetDesc_b1:
                            brne    CALLBACK_USB_GetDesc_b2

                            ;1: ProductString

                            ldi     r24, lo8(ProductString)
                            ldi     r22, lo8(sizeof_ProductString)
                            rjmp    CALLBACK_USB_GetDesc_ret

                            ;!1:
CALLBACK_USB_GetDesc_b2:
                            cpi     r24, 0x02
                            brne    CALLBACK_USB_GetDesc_err

                            ;2: ManufNameString

                            ldi     r24, lo8(ManufNameString)
                            ldi     r22, lo8(sizeof_ManufNameString)
                            rjmp    CALLBACK_USB_GetDesc_ret

                            ;unsupported DTYPE
CALLBACK_USB_GetDesc_err:
                            ldi     r22, 0x00       ; zero length (pointer is irrelevant)
CALLBACK_USB_GetDesc_ret:
                            ldi     r25, hi8(DeviceDescriptor) ;all descriptor data in same 256 byte page
                            ret
;-------------------------------------------------------------------------------

Endpoint_ClearStatusStage:
                            lds     r24, USB_ControlRequest
                            and     r24, r24
                            brge    Endpoint_ClearStatus_b4

                            rjmp    Endpoint_ClearStatus_b2
Endpoint_ClearStatus_b1:
                            in  r24, GPIOR0
                            and r24, r24
                            breq    Endpoint_ClearStatus_ret
Endpoint_ClearStatus_b2:
                            rcall   UEINTX_get
                            sbrs    r24, 2
                            rjmp    Endpoint_ClearStatus_b1
                            rjmp    UEINTX_clearbits_7B
Endpoint_ClearStatus_b3:
                            in      r24, GPIOR0
                            and     r24, r24
                            breq    Endpoint_ClearStatus_ret
Endpoint_ClearStatus_b4:
                            lds     r24, UEINTX
                            sbrs    r24, 0
                            rjmp    Endpoint_ClearStatus_b3

                            rcall   UEINTX_clearbits_7E
Endpoint_ClearStatus_ret:
                            ret
;-------------------------------------------------------------------------------
Endpoint_Write_Control_Stream_LE:

;r24:25 = pointer to data, r22 = length

                            movw    r30, r24                            ;Z = data pointer
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
                            rcall   UEINTX_clearbits_7E
                            ldi     r20, 0x00
                            rjmp    x7b80
x7ba0:
                            in      r24, GPIOR0
                            and     r24, r24
                            brne    x7ba8

                            rjmp    x7c30
x7ba8:
                            cpi     r24, 0x05
                            brne    x7bae

                            rjmp    x7c34
x7bae:
                            rcall   UEINTX_get
                            sbrs    r24, 3
                            rjmp    x7bba

                            ldi     r24, 0x01               ;ENDPOINT_RWCSTREAM_HostAborted
                            ret
x7bba:
                            rcall   UEINTX_get
                            sbrc    r24, 2
                            rjmp    x7c24

                            rcall   UEINTX_get
                            sbrs    r24, 0
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
                            ldi     r24, 0x7E
                            rcall   UEINTX_clearbits
x7c0e:
                            cp      r20, r1
                            brne    x7ba0

                            and     r21, r21
                            brne    x7ba0                   ;LastPacketFull

                            rjmp    x7c24
x7c1a:
                            in      r24, GPIOR0
                            and     r24, r24
                            breq    x7c30

                            cpi     r24, 0x05
                            breq    x7c34
x7c24:
                            rcall   UEINTX_get
                            sbrs    r24, 2
                            rjmp    x7c1a

                            ldi     r24, 0x00   ;ENDPOINT_RWCSTREAM_NoError
                            ret
x7c30:
                            ldi     r24, 0x02   ;ENDPOINT_RWCSTREAM_DeviceDisconnected
                            ret
x7c34:
                            ldi     r24, 0x03   ;ENDPOINT_RWCSTREAM_BusSuspended
                            ret
;-------------------------------------------------------------------------------
Endpoint_Read_Control_Stream_LE:

;r24:25 points to LineEncoding, r22 length

                            movw    r30, r24
                            cp      r22, r1
                            brne    Endpoint_Read_CtrlStrm_b1   ;!0

                            rcall   UEINTX_clearbits_7B
Endpoint_Read_CtrlStrm_b1:
                            rjmp    Endpoint_Read_CtrlStrm_b7
Endpoint_Read_CtrlStrm_b2:
                            in      r24, GPIOR0
                            and     r24, r24
                            breq    Endpoint_Read_CtrlStrm_b10

                            cpi     r24, 0x05   ; 5
                            breq    Endpoint_Read_CtrlStrm_b11

                            rcall   UEINTX_get
                            sbrs    r24, 3
                            rjmp    Endpoint_Read_CtrlStrm_b3

                            ldi     r24, 0x01   ; 1
                            ret
Endpoint_Read_CtrlStrm_b3:
                            sbrs    r24, 2
                            rjmp    Endpoint_Read_CtrlStrm_b2

                            rjmp    Endpoint_Read_CtrlStrm_b5
Endpoint_Read_CtrlStrm_b4:
                            rcall   UEDATX_get
                            st      Z+, r24
                            subi    r22, 0x01
                            breq    Endpoint_Read_CtrlStrm_b6
Endpoint_Read_CtrlStrm_b5:
                            lds     r25, UEBCHX
                            lds     r24, UEBCLX
                            or      r24, r25    ;r24 = UEBCLX | UEBCHX
                            brne    Endpoint_Read_CtrlStrm_b4
Endpoint_Read_CtrlStrm_b6:
                            rcall   UEINTX_clearbits_7B
Endpoint_Read_CtrlStrm_b7:
                            cp      r22, r1
                            brne    Endpoint_Read_CtrlStrm_b2
                            rjmp    Endpoint_Read_CtrlStrm_b9
Endpoint_Read_CtrlStrm_b8:
                            in      r24, GPIOR0
                            and     r24, r24
                            breq    Endpoint_Read_CtrlStrm_b10

                            cpi     r24, 0x05
                            breq    Endpoint_Read_CtrlStrm_b11
Endpoint_Read_CtrlStrm_b9:
                            rcall   UEINTX_get
                            sbrs    r24, 0
                            rjmp    Endpoint_Read_CtrlStrm_b8

                            ldi     r24, 0x00   ;ENDPOINT_RWCSTREAM_NoError
                            ret
Endpoint_Read_CtrlStrm_b10:
                            ldi     r24, 0x02   ;ENDPOINT_RWCSTREAM_DeviceDisconnected
                            ret
Endpoint_Read_CtrlStrm_b11:
                            ldi     r24, 0x03   ;ENDPOINT_RWCSTREAM_BusSuspended
                            ret

;-------------------------------------------------------------------------------
                            .section    .text
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
                            sbrs    r24, 3                          ;RXSTPI Received setup Interrupt Flag
                            rjmp    x7eb2

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
                            brne    x7d18
                            rjmp    x7e7c       ;bmRequestType = 9: REQ_SetConfiguration
x7d18:
                            rjmp    x7eb2       ;others: end

                            ;bmRequestType= 0: REQ_GetStatus

x7d20:                      cpi     r24, 0x80
                            brne    x7d26

                            rjmp    x7eb2

x7d26:                      cpi     r24, 0x82
                            breq    x7d2c

                            rjmp    x7eb2

x7d2c:                      lds     r24, USB_ControlRequest_wIndex
                            andi    r24, 0x07
                            rcall   UENUM_set
                            lds     r24, UECONX
                            sts     UENUM, r1
                            rcall   UEINTX_clearbits_F7
                            swap    r24                     ;(r24 >> 5) & 1
                            lsr     r24
                            andi    r24, 0x01
                            sts     UEDATX, r24
                            sts     UEDATX, r1
                            rjmp    x7e6e

                            ;bmRequestType = 1,3

x7d60:                      and     r24, r24
                            breq    x7d6a
                            cpi     r24, 0x02
                            breq    x7d6a

                            rjmp    x7eb2

x7d6a:                      andi    r24, 0x1F
                            cpi     r24, 0x02
                            breq    x7d72

                            rjmp    x7eb2

x7d72:                      lds     r24, USB_ControlRequest_wValue
                            and     r24, r24
                            brne    x7dc6

                            lds     r18, USB_ControlRequest_wIndex
                            andi    r18, 0x07
                            brne    x7d84
                            rjmp    x7eb2

x7d84:                      sts     UENUM, r18
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
                            rcall   UEINTX_clearbits_F7
                            rjmp    x7e74

                            ;bmRequestType = 5

x7dd2:                      and     r24, r24
                            breq    x7dd8

                            rjmp    x7eb2

x7dd8:                      lds     r17, USB_ControlRequest_wValue
                            andi    r17, 0x7F
                            in      r16, SREG
                            cli
                            rcall   UEINTX_clearbits_F7
                            rcall   Endpoint_ClearStatusStage

x7dee:                      rcall   UEINTX_get
                            sbrs    r24, 0
                            rjmp    x7dee

                            lds     r24, UDADDR
                            andi    r24, 0x80
                            or      r24, r17
                            sts     UDADDR, r24
                            ori     r24, 0x80
                            sts     UDADDR, r24
                            and     r17, r17
                            ldi     r24, 0x03
                            brne    x7e12

                            ldi     r24, 0x02
x7e12:
                            out     GPIOR0, r24
                            out     SREG, r16
                            rjmp    x7eb2

                            ;bmRequestType = 6: REQ_GetDescriptor

x7e18:                      subi    r24, 0x80   ; -128
                            cpi     r24, 0x02
                            brcs    x7e20       ;was 128 or 129
                            rjmp    x7eb2       ;end

x7e20:                      lds     r24, USB_ControlRequest_wValue
                            lds     r25, USB_ControlRequest_wValue+1
                            lds     r22, USB_ControlRequest_wIndex
                            movw    r20, r28
                            rcall   CALLBACK_USB_GetDescriptor
                            cpi     r22, 0
                            brne    x7e3c
                            rjmp    x7eb2                           ;end if zero length

                            ;length > 0

x7e3c:                      lds     r23, UEINTX
                            andi    r23, 0xF7
                            sts     UEINTX, r23
                            rcall   Endpoint_Write_Control_Stream_LE
                            rcall   UEINTX_clearbits_7B
                            rjmp    x7eb2

x7e58:                      cpi     r24, 0x80
                            brne    x7eb2

                            rcall   UEINTX_clearbits_F7
                            lds     r24, USB_Device_ConfigurationNumber
                            sts     UEDATX, r24
x7e6e:
                            rcall   UEINTX_clearbits_7E
x7e74:
                            rcall   Endpoint_ClearStatusStage
                            rjmp    x7eb2

x7e7c:                      and     r24, r24
                            brne    x7eb2

                            lds     r25, USB_ControlRequest_wValue
                            cpi     r25, 0x02
                            brcc    x7eb2

                            rcall   UEINTX_clearbits_F7
                            sts     USB_Device_ConfigurationNumber, r25
                            rcall   Endpoint_ClearStatusStage
                            lds     r24, USB_Device_ConfigurationNumber
                            and     r24, r24
                            brne    x7eac

                            lds     r24, UDADDR
                            sbrc    r24, 7
                            rjmp    x7eac

                            ldi     r24, 0x01
                            rjmp    x7eae
x7eac:
                            ldi     r24, 0x04
x7eae:
                            out     GPIOR0, r24
                            rcall   x778a_EVENT_USB_Device_ConfigurationChanged
x7eb2:
                            rcall   UEINTX_get
                            sbrs    r24, 3
                            ret

                            ldi     r24, 0x20
                            rcall   UECONX_setbits
                            rjmp    UEINTX_clearbits_F7
;-------------------------------------------------------------------------------
USB_USBTask:
                            in      r24, GPIOR0
                            and     r24, r24
                            breq    USB_USBTask_ret         ;ret, zero

                            lds     r24, UENUM
                            push    r24                     ;save USB endpoint
                            sts     UENUM, r1
                            rcall   UEINTX_get
                            sbrs    r24, 3
                            rjmp    USB_USB_USBTask_restore ;clear, no process

                            rcall   USB_Device_ProcessControlRequest
USB_USB_USBTask_restore:
                            pop     r24                     ;restore USB endpoint
                            andi    r24, 0x07
                            ;rjmp   UENUM_set
;-------------------------------------------------------------------------------
UENUM_set:
                            sts     UENUM, r24
USB_USBTask_ret:            ret
;-------------------------------------------------------------------------------
SetupHardware:
                            ldi     r18, 1 << CLKPCE    ;enable CLK prescaler change
                            sts     CLKPR, r18
                            sts     CLKPR, r1           ;PCLK/1
                            ldi     r24, 1 << IVCE      ;enable interrupt vector select
                            out     MCUCR, r24
                            ldi     r19, 0x02           ;select bootloader vectors (also used as OCIE1A for TIMSK1 below)
                            out     MCUCR, r19
                    #ifdef ARDUBOY
                        #ifdef ARDUBOY_DEVKIT
                            ldi     r24, 0x07           ;SPI_CLK, MOSI, RXLED as outputs
                            out     DDRB, r24
                            ldi     r24, 0x71           ;Pull-ups on UP,LEFT,DOWN Buttons, RXLED off
                            out     PORTB, r24
                            out     DDRC, r1            ;all inputs
                            sbi     PORTC, BUTTON_RIGHT ;pull-up on right button
                            out     DDRF, r1            ;Set all as inputs
                            ldi     r24, 0xC0           ;pullups on button A and B
                            out     PORTF, r24
                        #else
                            ldi     r24, 0xE7           ;RGBLED, SPI_CLK, MOSI, RXLED as outputs
                            out     DDRB, r24
                            #if DEVICE_PID == 0x0037    //; Micro RXLED is reversed
                            ldi     r24, 0xF0           ;RGBLED OFF | PULLUP B-Button | RXLED OFF
                            #else
                            ldi     r24, 0xF1           ;RGBLED OFF | PULLUP B-Button | RXLED OFF
                            #endif
                            out     PORTB, r24
                            out     DDRE, r1            ;all as inputs
                            sbi     PORTE, BUTTON_A     ;enable pullup for A button
                            out     DDRF, r1            ;all as inputs
                            ldi     r24, 0xF0           ;pullups on D-PAD
                            out     PORTF, r24
                        #endif

                            ;setup SPI

                            ldi     r24,  (1 << SPE) | (1 << MSTR)  ;SPI master, mode 0, MSB first
                            out     SPCR, r24
                            ldi     r24, 1 << SPI2X                 ;SPI clock CPU / 2 (8MHz)
                            out     SPSR,r24

                            ;setup display io and reset
                        #ifdef ARDUBOY_PROMICRO
                            ldi     r24, (1 << OLED_RST) | (1 << OLED_CS) | (1 << OLED_DC) | (1 << TX_LED) | (1 << RGB_G) ; as outputs
                            out     DDRD, r24
                            ldi     r24, (1 << OLED_CS) | (1 << TX_LED) | (RGB_G) ;RST active low, CS inactive high, Command mode, Tx LED off, RGB green off
                        #else
                            ldi     r24, (1 << OLED_RST) | (1 << OLED_CS) | (1 << OLED_DC) | (1 << TX_LED) ; as outputs
                            out     DDRD, r24
                            ldi     r24, (1 << OLED_CS) | (1 << TX_LED) ;RST active low, CS inactive high, Command mode, Tx LED off
                        #endif
                            out     PORTD, r24

                            ;copy USB icon to display buffer. Gives OLED display reset pulse
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
                            st      x+ ,r0
                            dec     r17
                            brne    DisplayBootGfx_l2
                            subi    r26, -(128 - BOOTLOGO_WIDTH)    ;'adiw' to one line down (negated substraction is addition)
                            sbci    r27, -1
                            dec     r16
                            brne    DisplayBootGfx_l1

                            ;pull display out of reset

                        #ifdef ARDUBOY_PROMICRO
                            ldi     r24, (1 << OLED_RST) | (1 << TX_LED) | (RGB_G) ;RST inactive, CS active low, Command mode, Tx LED off, RGB green off
                        #else
                            ldi     r24, (1 << OLED_RST) | (1 << TX_LED) ;RST inactive, CS active low, Command mode, Tx LED off
                        #endif
                            out     PORTD, r24

                            ;Setup display

                            ldi     r30,lo8(DisplaySetupData)
                            ldi     r31,hi8(DisplaySetupData)
SetupHardware_display:
                            rcall   SPI_Write_Z
                            cpi     r30, lo8(DisplaySetupData_End)
                            brne    SetupHardware_display

                            ;copy display buffer to display

                            rcall   Display
                    #else
                            sbi     DDRC,  LLED         ;as output
                            LLED_OFF
                            sbi     DDRB, RX_LED        ;as output
                            RX_LED_OFF
                            sbi     DDRD, TX_LED        ;as output
                            TX_LED_OFF
                    #endif
                            ldi     r30, CLKPR
                            ldi     r31, 0x00
                            st      Z, r18              ;enable CLK prescaler change
                            st      Z, r1               ;PCLK/1
                            sts     OCR1AH, r1
                            ldi     r24, 0xFA           ;for 1 millisec (PCLK/64/1000)
                            sts     OCR1AL, r24
                            sts     TIMSK1, r19         ;enable timer 1 output compare A match interrupt
                            ldi     r24, 0x03           ;CS11 | CS10 1/64 prescaler on timer 1 input
                            sts     TCCR1B, r24
                            ret
                            
;-------------------------------------------------------------------------------
USB_Init:
                            ldi     r30, UHWCON
                            ldi     r31, 0x00               ;r31 still 0 from CLKPR above
                            ld      r24, Z
                            ori     r24, 0x01               ;UVREGE: enable USB pad regulator
                            st      Z, r24
                            ldi     r24, 0x4A
                            out     PLLFRQ, r24
                            ;rjmp   USB_ResetInterface
                            
;-------------------------------------------------------------------------------
USB_ResetInterface:
                            ;USB_INT_DisableAllInterrupts:
                            
                            ldi     r30, USBCON
                            ;ldi     r31, 0x00               ;r31 still 0 from CLKPR above
                            rcall   clearbit_z0             ;clear VBUSTE
                            sts     UDIEN, r1

                            ;USB_INT_ClearAllInterrupts:

                            sts USBINT, r1                  ;clear VBUSTI
                            sts UDINT, r1                   ;clear USB device interrupts

                            ;ldi     r30, USBCON            
                            ;ldi     r31, 0
                            ld      r24, Z
                            andi    r24, 0x7F
                            st      Z, r24
                            ori     r24, 0x80               ;USBE
                            st      Z, r24
                            andi    r24, 0xDF
                            st      Z, r24
                            out     PLLCSR, r1
                            out     GPIOR0, r1
                            sts     USB_Device_ConfigurationNumber, r1
                            ldi     r30,UDCON
                            ld      r24, Z
                            andi    r24, 0xFB               ;full speed
                            st      Z, r24
                            ldi     r30, USBCON
                            ld      r24, Z
                            ori     r24, 0x01               ;VBUSTE
                            st      Z, r24
                            ldi     r24, 0x00
                            ldi     r22, 0x00
                            ldi     r20, 0x02
                            rcall   Endpoint_ConfigureEndpoint_Prv
                            ldi     r30, UDINT
                            ;ldi    r31, 0x00           ;(call didn't change r30:31)
                            rcall   clearbit_z0
                            rcall   UDIEN_get
                            ori     r24, 0x08 | 0x01    ;EORSTE | SUSPE
                            rcall   UDIEN_set
                            ldi     r30,UDCON
                            rcall   clearbit_z0
                            ldi     r30, USBCON
                            ld      r24, Z
                            ori     r24, 0x10
                            st      Z, r24
                            ret
                            
;-------------------------------------------------------------------------------
clearbit_z0:                            
                            ld      r24, Z
                            andi    r24, 0xFE               
                            st      Z, r24
                            ret
;-------------------------------------------------------------------------------
TestApplicationFlash:

;returns r24:25 = 0000 and Z flag set if unprogrammed application flash (FFFF)

                            ldi     r30, lo8(APPLICATION_START_ADDR)
                            ldi     r31, hi8(APPLICATION_START_ADDR)
                            lpm     r24, Z+
                            lpm     r25, Z
                            adiw    r24,1
                            ret
;-------------------------------------------------------------------------------
;EEPROM code
;-------------------------------------------------------------------------------
eeprom_read:

;read r24 from EEPROM address r30:31

                            lsr     r31             ;addr >> 1
                            ror     r30
eeprom_rd_wait:
                            sbic    EECR, EEPE
                            rjmp    eeprom_rd_wait

                            out     EEARH, r31
                            out     EEARL, r30
                            sbi     EECR, EERE
                            in      r24, EEDR       ;read eeprom byte
                            rjmp    eeprom_addr_inc

;-------------------------------------------------------------------------------
eeprom_write:

;Write r24 to EEPROM address r30:31

                            lsr     r31             ;addr >> 1
                            ror     r30
eeprom_wr_wait:
                            sbic    EECR, EEPE
                            rjmp    eeprom_wr_wait

                            out     EECR, r1
                            out     EEARH, r31
                            out     EEARL, r30
                            out     EEDR, r24
                            in      r0, SREG
                            cli
                            sbi     EECR, EEMPE
                            sbi     EECR, EEPE
                            out     SREG, r0
eeprom_addr_inc:
                            adiw    r30, 1          ;++
                            ;rjmp   word_to_byte_addr
;-------------------------------------------------------------------------------
word_to_byte_addr:
                            add     r30,r30         ;addr << 1
                            adc     r31,r31
                            ret
;-------------------------------------------------------------------------------
                    #ifdef  ARDUBOY
SPI_Write_Z:
                            ld      r24, Z+
                            ;rjmp   SPI_Write
;-------------------------------------------------------------------------------
SPI_Write:
                            out     SPDR, r24
                            ;rjmp   SPI_Wait
;-------------------------------------------------------------------------------
SPI_Wait:
                            in      r24, SPSR
                            sbrs    r24, SPIF
                            rjmp    SPI_Wait
                            ret
;-------------------------------------------------------------------------------
Display:

;copies diisplay buffer to OLED display using page mode (supported on most displays)

;Uses: r24, r25, r30, r31
                            ldi     r30, lo8(DisplayBuffer)
                            ldi     r31, hi8(DisplayBuffer)
                            ;rjmp   Display_Z
;-------------------------------------------------------------------------------
Display_Z:
                            ldi     r25, OLED_SET_PAGE_ADDR
Display_l1:
                            cbi     PORTD, OLED_DC                  ;Command mode
                            mov     r24, r25
                            rcall   SPI_Write                       ;select page
                            ldi     r24, OLED_SET_COLUMN_ADDR_HI
                            rcall   SPI_Write                       ;select column hi nibble
                            sbi     PORTD, OLED_DC                  ;Data mode
Display_l2:
                            rcall   SPI_Write_Z
                            ldi     r24, lo8(DisplayBuffer)
                            eor     r24, r30
                            andi    r24, 0x7F                       ;every 128 zero
                            brne    Display_l2

                            inc     r25
                            cpi     r25, OLED_SET_PAGE_ADDR + 8
                            brne    Display_l1
                            ret
;-------------------------------------------------------------------------------
Set_LED_Control:
                            sts     LED_Control, r24
                            RX_LED_OFF
                            sbrc    r24,LED_CTRL_RX_ON
                            RX_LED_ON
                            TX_LED_OFF
                            sbrc    r24,LED_CTRL_TX_ON
                            TX_LED_ON
                            sbi     PORTB, RGB_R
                            sbrc    r24,LED_CTRL_RGB_R_ON
                            cbi     PORTB, RGB_R
                        #ifdef ARDUBOY_PROMICRO
                            sbi     PORTD, 0
                            sbrc    r24,LED_CTRL_RGB_G_ON
                            cbi     PORTD, 0
                        #else
                            sbi     PORTB, RGB_G
                            sbrc    r24,LED_CTRL_RGB_G_ON
                            cbi     PORTB, RGB_G
                        #endif
                            sbi     PORTB, RGB_B
                            sbrc    r24,LED_CTRL_RGB_B_ON
                            cbi     PORTB, RGB_B
                            bst     r24,LED_CTRL_OLED
                            ldi     r24,OLED_SET_DISPLAY_ON
                            brtc    Set_LED_Control_end
                            ldi     r24,OLED_SET_DISPLAY_OFF
Set_LED_Control_end:
                            cbi     PORTD, OLED_DC                  ;Command mode
                            rjmp    SPI_Write
                        #endif
;-------------------------------------------------------------------------------
SECTION_DATA_DATA:          ;(Initialized data stored after text area here)
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
                            .section .bss   ;zero initialized data
;-------------------------------------------------------------------------------
SECTION_BSS_START:

TxLEDPulse:                         .byte   0
RxLEDPulse:                         .byte   0   ;Note: must be right after TXLEDPulse
Timeout:                            .word   0
CurrAddress:                        .word   0   ;reduced to 16 bit
RGBLEDstate:                        .byte   0   ;Note: must be exactly before LLEDPulse
LLEDPulse:                          .word   0
USB_Device_ConfigurationNumber:     .byte   0
;USB_IsInitialized:                 .byte   0   ;not used

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
                                #ifdef  ARDUBOY
LED_Control:                        .byte   0
DisplayBuffer:                      .space  1024
                                #endif
SECTION_BSS_END:
;-------------------------------------------------------------------------------
                            .section .bootsignature, "ax" ;FLASHEND - 2
;-------------------------------------------------------------------------------

                            .word   BOOT_SIGNATURE
;===============================================================================