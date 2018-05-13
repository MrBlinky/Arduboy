;===============================================================================
;
;                              ** Cathy 2K **
;
;  An optimized reversed Caterina bootloader with added features in 2K
;           For Arduboy and Arduino Leonardo, Micro and Esplora
;
;             Assembly optimalisation and additional features
;                         by Mr.Blinky Oct 2017 - May 2018
;
;             m s t r <d0t> b l i n k y <at> g m a i l <d0t> c o m
;
;  Main features:
;
;  - bootloader size is under 2K alllowing 2K more space for Applications.

;  - 100% Arduino compatible.

;  - dual magic key address support (0x0800 and RAMEND-1) with LUFA boot
;      at 0x7FFE for reliable bootloader triggering from arduino IDE

;  - self reprogramming from application area via FlashPage vector at 0x7FFC

;  - Identifies itself as serial programmer 'CATHY2K' with software version 1.2
;
;  Note:  Boot size fuses must be set to BOOTSZ1 = 0 and BOOTSZ0 to 1 (1K-word)
;
;  Additional Arduboy exclusive features (included only when building for Arduboy):
;
;  - Power on + Button Down launces bootloader instead of application

;  - OLED display is reset on power on / entering bootloader mode

;  - Button Down in bootloader mode freezes the bootloader timeout period

;  - Identifies itself as serial programmer 'ARDUBOY' with software version 1.2
;
;  the following concessions where made to fit bootloader in 2K:
;
;  - LLED breathing feature removed.
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

;  Arduboy Only:

;  - (non mandatory) Device discriptor Manufacturer string removed

;  licence as below

;-------------------------------------------------------------------------------
;EXAMPLE Self flashing function for application:
;-------------------------------------------------------------------------------

; void flashPage(const uint8_t *dataInRam, uint16_t targetAddress)
; {
;   uint8_t oldSREG = SREG;
;   asm volatile(
;     "    cli                   \n" //disable interrupts
;     "    call    0x7FFC        \n" //flashPage vector
;     : "+x" (dataInRam)
;     : "z" (targetAddress)
;     : "r24", "r25"
;   );
;   SREG = oldSREG;
; }

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
#define TIMEOUT_PERIOD          8000
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
#define BOOTLOADER_VERSION_MINOR    2

#define BOOT_START_ADDR         0x7800
#define BOOT_END_ADDR           0x7FFF

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

 ;button defines
 #ifdef ARDUBOY_DEVKIT
  #define BTN_DOWN_BIT    6
  #define BTN_DOWN_PIN   PINB
  #define BTN_DOWN_DDR   DDRB
  #define BTN_DOWN_PORT  PORTB
 #else
  #define BTN_DOWN_BIT   4
  #define BTN_DOWN_PIN   PINF
  #define BTN_DOWN_DDR   DDRF
  #define BTN_DOWN_PORT  PORTF
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
#elif DEVICE VID == 0x1B4F
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
                            #ifdef ARDUBOY
                            .ascii  "ARDUBOY"
                            #else
                            .ascii  "CATHY2K"
                            #endif

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
                        #ifdef ARDUBOY
                            .byte   0x00        ;ManufacturerStrIndex   = NO_DESCRIPTOR
                        #else
                            .byte   0x02        ;ManufacturerStrIndex   = 2
                        #endif    
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
                        #ifndef ARDUBOY
ManufacturerString:         ;-header-
                            .byte   sizeof_ManufacturerString
                            .byte   DTYPE_String
                            ;-data-
                            .word   MANUFACTURER_STRING
                        #endif
SECTION_DATA_END:

;-------------------------------------------------------------------------------
;Bootloader area
;-------------------------------------------------------------------------------

                            .section .text, "ax" ;

;Register usage:
;   r0      temp reg
;   r1      zero reg
;   r2, r3  bootloader timeout reg
;   r4, r5  Current Adrress
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
                            ldi     r30, lo8(TxLEDPulse)
                            ldi     r31, hi8(TxLEDPulse)
                            ld      r25, z
                            cp      r24, r25                    ;sets carry if r25 > 0
                            sbc     r25, r24                    ;r25 -0 - carry
                            st      z+, r25                     ;Point to RXLEDPulse
                            brne    TIMER1_COMPA_interrupt_b1

                            TX_LED_OFF
TIMER1_COMPA_interrupt_b1:
                            ld   r25, z
                            cp   r24, r25                   ;again sets carry if r25 > 0
                            sbc  r25, r24                   ;r25 - carry
                            st   z, r25
                            brne TIMER1_COMPA_interrupt_b2

                            RX_LED_OFF
TIMER1_COMPA_interrupt_b2:
                          #ifdef ARDUBOY
                            sbis    BTN_DOWN_PIN, BTN_DOWN_BIT
                            rjmp    TIMER1_COMPA_int_end    ;DOWN button pressed, delay timeout
                          #endif
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
                          #ifdef ARDUBOY
                            out     BTN_DOWN_DDR, r1            ;temporary all as inputs
                            ldi     r24, 1 << BTN_DOWN_BIT      ;enable pullup on down button
                            out     BTN_DOWN_PORT, r24
                            
                            sbi     DDRD, OLED_RST              ;reset OLED display
                            cbi     PORTD, OLED_RST
                          #endif

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

                        #ifdef  ARDUBOY
                            sbi     PORTD, OLED_RST
                        #endif
;-------------------------------------------------------------------------------
main:
                            sbrc    r16, 1                  ;MCUSR state EXTRF skip if no external reset
                            rjmp    run_bootloader          ;enter bootloader mode

                            sbrs    r16, 0                  ;MCUSR state PORF test power on reset
                            rjmp    main_test_wdt           ;not POR

                            ;power on reset

                          #ifdef ARDUBOY
                            sbis    BTN_DOWN_PIN, BTN_DOWN_BIT  ;test DOWN button
                            rjmp    run_bootloader              ;button pressed, enter bootloader
                          #endif
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
                            rcall   SetupHardware
                            sei
                            clr     r2                      ;reset timeout
                            clr     r3
bootloader_loop:
                            rcall   CDC_Task
                            rcall   USB_USBTask
                            ;rcall   LEDPulse
                            ;rcall   GetTimeout
                            movw    r24, r2                     ;get timeout
                            subi    r24, lo8(TIMEOUT_PERIOD)
                            sbci    r25, hi8(TIMEOUT_PERIOD)
                            brcs    bootloader_loop             ;loop < TIMEOUT_PERIOD
                            ;rjmp   StartSketch

                            ;timeout, start sketch

;-------------------------------------------------------------------------------
StartSketch:
                            cli
                            ldi     r24, 1 << DETACH    ;USB DETACH
                            sts     UDCON, r24
                            sts     TIMSK1, r1          ;Undo TIMER1 setup and clear the count before running the sketch
                            sts     TCCR1B, r1
                            sts     TCNT1H, r1
                            sts     TCNT1L, r1
                            ldi     r24, 1 << IVCE      ;enable interrupt vector change
                            out     MCUCR, r24
                            out     MCUCR, r1           ;relocate vector table to application section
                            ;rcall   LEDPulse_off
                            TX_LED_OFF
                            RX_LED_OFF
                            jmp     0                   ; start application
;-------------------------------------------------------------------------------
;LEDPulse:
;
;                            ldi  r30,lo8(LLEDPulse)
;                            ldi  r31,hi8(LLEDPulse)
;                            ld   r24,z+
;                            ld   r25,z
;                            adiw r24, 1                 ;LLEDPulse++, bit 15 sets N flag
;                            st   z,r25
;                            st   -z,r24
;                            mov  r0,r25
;                            brpl LEDPulse_b1            ;branch bit 15 clear
;
;                            ;LedPulse >= 0x8000 bright to dim
;
;                            com     r0                  ;== 255-p rather than 254-p (which causes bright flash)
;
;                            ;LedPulse < 0x8000 dim to bright
;LEDPulse_b1:
;LEDPulse_testperiod:
;                            add     r0, r0
;                            cp      r0, r24
;                            brcc    LEDPulse_on
;
;;-------------------------------------------------------------------------------
;LEDPulse_off:
;                            LLED_OFF
;                            ret
;;-------------------------------------------------------------------------------
;LEDPulse_on:
;                            LLED_ON
;                            ret
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

                            RX_LED_ON
                            ldi     r24, lo8(TX_RX_LED_PULSE_PERIOD)
                            sts     RxLEDPulse, r24
CDC_Task_b1:
                            rcall   FetchNextCommandByte
                            mov     r17, r24                ;save command
                            movw    r30, r4                 ;get current Address in Z

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
                            mov     r31,r24
                            rcall   FetchNextCommandByte
                            mov     r30,r24
                            rcall   word_to_byte_addr       ;program word to byte address and update current address
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
                            brne    CDC_Task_Command_s

                            ldi     r24, '0' + BOOTLOADER_VERSION_MAJOR
                            rcall   WriteNextResponseByte
                            ldi     r24, '0' + BOOTLOADER_VERSION_MINOR
                            rjmp    CDC_Task_Response
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
                            rjmp    CDC_Task_Command_C
CDC_Task_RdWrBlk:           ;-----------------------------------'B' or 'g': write/read memory block
                            clr     r2                      ;clear timeout
                            clr     r3
                            rcall   FetchNextCommandByte
                            mov     r29, r24                ;BlockSize MSB
                            rcall   FetchNextCommandByte
                            mov     r28, r24                ;BlockSize LSB
                            rcall   FetchNextCommandByte
                            mov     r16, r24                ;MemoryType
                            subi    r24, 'E'
                            cpi     r24, 0x02               ;'F' - 'E' + 1
                            brcs    CDC_Task_RdWrBlk_cont
                            rjmp    CDC_Task_Error          ;not 'D'ISPLAY, 'E'EPROM or 'F'LASH
CDC_Task_RdWrBlk_cont:
                            sts     TIMSK1, r1              ;disable timer 1 interrupt
                            cpi     r17, 'g'
                            brne    CDC_Task_WriteMem

                            ;Read Block

CDC_Task_ReadBlk:
CDC_Task_ReadBlk_flash:
                            rjmp    CDC_Task_ReadBlk_next
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
CDC_Task_WriteMem_flash:
                            movw    r8, r30                     ;save addr for page write
                            cpi     r16, 'F'
                            brne    CDC_Task_WriteMem_next

                            ;write flash memory block

                            rcall   SPM_page_erase
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

                            mov     r1, r24                 ;word in r0:r1
                            rcall   SPM_write_data
CDC_Task_WriteMem_inc:
CDC_Task_WriteMem_lsb:
                            mov     r0, r24                 ;save lsb
                            rjmp    CDC_Task_WriteMem_next

CDC_Task_WriteMem_display:
                            ;EEPROM
CDC_Task_WriteMem_eeprom:
                            rcall   eeprom_write
CDC_Task_WriteMem_next:
                            sbiw    r28, 0x01
                            brpl    CDC_Task_WriteMem_loop

                            ;block write complete

                            movw    r4, r30                 ;save current Address
CDC_Task_WriteMem_flash_end:
                            cpi     r16, 'F'
                            brne    CDC_Task_WriteMem_end

                            ;Flash memory Page write

                            movw    r30, r8                             ;page addr
                            rcall   SPM_write_page
CDC_Task_WriteMem_end:
                            ldi     r24, 0x0D
                            rcall   WriteNextResponseByte
CDC_Task_RdWrBlk_end:
                            ldi     r24, 0x02                   ;OCIE1A
                            sts     TIMSK1, r24                 ;enable timer1 int
                            rjmp    CDC_Task_Complete
CDC_Task_Command_C:         ;-----------------------------------Write High byte to flash
;                            cpi     r24, 'C'
;                            brne    CDC_Task_Command_c
;
;                            ;write high byte to flash
;
;                            movw    r30, r4                 ;get current Address in Z
;                            rcall   FetchNextCommandByte
;                            mov     r0, r24
;                            ldi     r24, 0x01
;                            out     SPMCSR, r24
;                            spm
;                            rjmp    CDC_Task_Acknowledge
;CDC_Task_Command_c:         ;-----------------------------------
;                            cpi     r24, 'c'
;                            brne    CDC_Task_Command_m
;
;                            ;Write the low byte to the current flash page
;
;                            movw    r30, r4                 ;get current Address in Z
;                            rcall   FetchNextCommandByte
;                            ori     r30, 0x01               ;odd addr byte
;                            mov     r0, r24
;                            ldi     r24, 0x01
;                            out     SPMCSR, r24
;                            spm
;                            adiw    r30, 1
;                            movw    r4, r30                 ;save current Address
;                            rjmp    CDC_Task_Acknowledge
;CDC_Task_Command_m:         ;-----------------------------------
;                            cpi     r24, 'm'
;                            brne    CDC_Task_Command_R
;
;                            ;Commit flash page to memory
;
;                            movw    r30, r4                 ;get current Address in Z
;                            cpi     r31, hi8(BOOT_START_ADDR)
;                            brcc    CDC_Task_Command_m_end
;
;                            rcall   SPM_write_page
;CDC_Task_Command_m_end:
;                            rjmp    CDC_Task_Acknowledge
;CDC_Task_Command_R:         ;-----------------------------------read flash word
;                            cpi     r24, 'R'
;                            brne    CDC_Task_TestBitCmds
;
;                            movw    r30, r4                 ;get current Address in Z
;                            lpm     r24, Z+
;                            rcall   WriteNextResponseByte
;                            lpm     r24, Z
;                            rjmp    CDC_Task_Response
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
                            out     SPMCSR,r24
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
FlashPage:                  
                            rcall   SPM_page_erase
                            ldi     r25, SPM_PAGESIZE >> 1
FlashPage_b1:                            
                            ld      r0, x+            
                            ld      r1, x+            
                            rcall   SPM_write_data
                            dec     r25
                            brne    FlashPage_b1
                            subi    r30, lo8(SPM_PAGESIZE)
                            sbci    r31, hi8(SPM_PAGESIZE)
                            ;rjmp   SPM_write_page
;-------------------------------------------------------------------------------
SPM_write_page:                            
                            ldi     r24, (1 << PGWRT) | (1 << SPMEN)    ;write page
                            rjmp   SPM_write
;-------------------------------------------------------------------------------
SPM_write_data:
                            ldi     r24,(1 << SPMEN)
                            out     SPMCSR, r24         ;write word to page buffer
                            spm
                            clr     r1                  ;restore zero reg
                            adiw    r30, 2
                            ret
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
                        #ifndef ARDUBOY
                            cpi     r24, 0x02
                            brne    CALLBACK_USB_GetDesc_ret

                            ;2: ManufacturerString

                            ldi     r30, lo8(ManufacturerString)
                            ldi     r22, lo8(sizeof_ManufacturerString)
                        #endif
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
SetupHardware:
                            ldi     r18, 1 << CLKPCE    ;enable CLK prescaler change
                            sts     CLKPR, r18
                            sts     CLKPR, r1           ;PCLK/1
                            ldi     r24, 1 << IVCE      ;enable interrupt vector select
                            out     MCUCR, r24
                            ldi     r19, 0x02           ;select bootloader vectors (also used as OCIE1A for TIMSK1 below)
                            out     MCUCR, r19
                            ;sbi     DDRC,  LLED         ;as output
                            ;LLED_OFF
                            sbi     DDRB, RX_LED        ;as output
                            RX_LED_OFF
                            sbi     DDRD, TX_LED        ;as output
                            TX_LED_OFF
                            sts     OCR1AH, r1
                            ldi     r24, 0xFA           ;for 1 millisec (PCLK/64/1000)
                            sts     OCR1AL, r24
                            sts     TIMSK1, r19         ;enable timer 1 output compare A match interrupt
                            ldi     r24, 0x03           ;CS11 | CS10 1/64 prescaler on timer 1 input
                            sts     TCCR1B, r24
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
eeprom_prep:
                            movw    r30, r4             ;get current address in Z
                            lsr     r31                 ;addr >> 1
                            ror     r30
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
                            ;rjmp   word_to_byte_addr
;-------------------------------------------------------------------------------
word_to_byte_addr:
                            lsl     r30                 ;addr << 1
                            rol     r31
                            movw    r4, r30             ;update current address
                            ret
;-------------------------------------------------------------------------------
SECTION_DATA_DATA:          ;(Initialized data stored after text area here)
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
                            .section .bss   ;zero initialized data
;-------------------------------------------------------------------------------
SECTION_BSS_START:

TxLEDPulse:                         .byte   0
RxLEDPulse:                         .byte   0   ;Note: must be right after TXLEDPulse
CurrAddress:                        .word   0   ;reduced to 16 bit
RGBLEDstate:                        .byte   0   ;Note: must be exactly before LLEDPulse
LLEDPulse:                          .word   0
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
SECTION_BSS_END:
;-------------------------------------------------------------------------------
                            .section .bootsignature, "ax"
;-------------------------------------------------------------------------------

                            rjmp    FlashPage
                            .word   BOOT_SIGNATURE
;===============================================================================