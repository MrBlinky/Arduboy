;reversedassembly source of Catarina bootloader (Leonardo) by Mr.Blinky Oct 2017 

;Made for the purpose of optimizing the code at assembly level.
;This is the original unoptimized version.

;Arduino Leonardo device VID/PID

								;Arduino
#define DEVICE_VID				0x2341 
								;Leonardo Bootloader 
#define DEVICE_PID          	0x0036 

;time durations (in millisecs)

#define TIMEOUT_PERIOD	        8000
#define	TX_RX_LED_PULSE_PERIOD	100

;atmega32u4 signature

#define AVR_SIGNATURE_1			0x1E
#define AVR_SIGNATURE_2			0x95
#define AVR_SIGNATURE_3			0x87

#define APPLICATION_START_ADDR	0x0000
#define SPM_PAGESIZE			0x0080
                                
#define BOOTKEY					0x7777
#define BOOTKEY_PTR				0x0800

;register ports (accessed through ld/st instructions)

#define	UEBCHX	0x00F3
#define	UEBCLX	0x00F2
#define	UEDATX	0x00F1

#define	UESTA0X	0x00EE
#define	UECFG1X	0x00ED
#define	UECFG0X	0x00EC
#define	UECONX	0x00EB
#define	UERST	0x00EA
#define	UENUM	0x00E9
#define	UEINTX	0x00E8

#define	UDADDR	0x00E3
#define	UDIEN	0x00E2
#define	UDINT	0x00E1
#define	UDCON	0x00E0

#define	USBINT	0x00DA
#define	USBSTA	0x00D9
#define	USBCON	0x00D8
#define	UHWCON	0x00D7

#define	TCNT1H	0x0085
#define	TCNT1L	0x0084

#define	TCCR1B	0x0081

#define	TIMSK1	0x006F


;io ports (accessed through in/out instructions)

#define	SREG	0x3f
#define	SPH		0x3e
#define	SPL		0x3d

#define	SPMCSR	0x37
#define	MCUCR	0x35

#define PORTD	0x0b

#define PORTC	0x08

#define PORTB	0x05

;-------------------------------------------------------------------------------

;size of structure defines

#define sizeof_USB_Descriptor_Header_t		2
#define	sizeof_USB_ControlRequest_t			8

;USB_DescriptorTypes:

#define DTYPE_Device					0x01	;Indicates that the descriptor is a device descriptor.
#define DTYPE_Configuration				0x02	;Indicates that the descriptor is a configuration descriptor.
#define DTYPE_String					0x03	;Indicates that the descriptor is a string descriptor.
#define DTYPE_Interface					0x04	;Indicates that the descriptor is an interface descriptor.
#define DTYPE_Endpoint					0x05	;Indicates that the descriptor is an endpoint descriptor.
#define DTYPE_DeviceQualifier			0x06	;Indicates that the descriptor is a device qualifier descriptor.
#define DTYPE_Other						0x07	;Indicates that the descriptor is of other type.
#define DTYPE_InterfacePower			0x08	;Indicates that the descriptor is an interface power descriptor.
#define DTYPE_InterfaceAssociation		0x0B	;Indicates that the descriptor is an interface association descriptor.
#define DTYPE_CSInterface				0x24	;Indicates that the descriptor is a class specific interface descriptor. *
#define DTYPE_CSEndpoint				0x25	;Indicates that the descriptor is a class specific endpoint descriptor.

;CDC_Descriptor_ClassSubclassProtocol

#define CDC_CSCP_CDCClass				0x02	;Descriptor Class value indicating that the device or interface belongs to the CDC class.
#define CDC_CSCP_NoSpecificSubclass		0x00	;Descriptor Subclass value indicating that the device or interfacebelongs to no specific subclass of the CDC class.
#define CDC_CSCP_ACMSubclass			0x02	;Descriptor Subclass value indicating that the device or interface belongs to the Abstract Control Model CDC subclass.
#define CDC_CSCP_ATCommandProtocol		0x01	;Descriptor Protocol value indicating that the device or interface belongs to the AT Command protocol of the CDC class.
#define CDC_CSCP_NoSpecificProtocol		0x00	;Descriptor Protocol value indicating that the device or interface belongs to no specific protocol of the CDC class.
#define CDC_CSCP_VendorSpecificProtocol 0xFF	;Descriptor Protocol value indicating that the device or interface belongs to a vendor-specific protocol of the CDC class.
#define CDC_CSCP_CDCDataClass			0x0A	;Descriptor Class value indicating that the device or interface belongs to the CDC Data class.
#define CDC_CSCP_NoDataSubclass			0x00	;Descriptor Subclass value indicating that the device or interface belongs to no specific subclass of the CDC data class.
#define CDC_CSCP_NoDataProtocol			0x00	;Descriptor Protocol value indicating that the device or interface belongs to no specific protocol of the CDC data class.

;CDC_ClassRequests

#define CDC_REQ_SendEncapsulatedCommand 0x00	;CDC class-specific request to send an encapsulated command to the device.
#define CDC_REQ_GetEncapsulatedResponse 0x01	;CDC class-specific request to retrieve an encapsulated command response from the device.
#define CDC_REQ_SetLineEncoding			0x20	;CDC class-specific request to set the current virtual serial port configuration settings.
#define CDC_REQ_GetLineEncoding			0x21	;CDC class-specific request to get the current virtual serial port configuration settings.
#define CDC_REQ_SetControlLineState		0x22	;CDC class-specific request to set the current virtual serial port handshake line states.
#define CDC_REQ_SendBreak				0x23	;CDC class-specific request to send a break to the receiver via the carrier channel.

#define LANGUAGE_ID_ENG 				0x0409

;-------------------------------------------------------------------------------
							.section .data	;Initalized data copied to ram
;-------------------------------------------------------------------------------
SECTION_DATA_START:

;- Software ID string - (should be 7 characters only)

SOFTWARE_IDENTIFIER:		;(should be only 7 chars)
x800100:					.ascii	"CATERINA"	;'CATERINA'
							.byte	0			;unwanted terminating zero

;- bootKey value -

bootKey:
x800109:					.word	BOOTKEY

;- bootKeyPtr pointer -

bootKeyPtr:
x80010b:					.word	BOOTKEY_PTR

;- LineEncoding structure -

LineEncoding:
#define sizeof_LineEncoding			7
x80010d:					.long	0	;BaudRateBPS
x800111:					.byte	0	;CharFormat
							.byte	0	;ParityType
x800113:					.byte	8	;DataBits
;- RunBootloader bool -

RunBootloader:
x800114:					.byte	1

;- DeviceDiscriptor structure -

DeviceDescriptor:			;-header-
#define sizeof_DeviceDescriptor		sizeof_USB_Descriptor_Header_t + (8 << 1)
x800115:					.byte 	sizeof_DeviceDescriptor
							.byte	DTYPE_Device
							;-data-
x800117:					.word	0x0110		;USB specification version = 01.10
x800119:					.byte	0x02, 0x00	;
x80011b:					.byte	0x00, 0x08	;
x80011d:					.word	DEVICE_VID	
x80011f:					.word	DEVICE_PID	
x800121:					.word	0x0001		;version                = 00.01
x800123:					.byte	0x02		;ManufacturerStrIndex   = 2
							.byte	0x01		;ProductStrIndex        = 1
x800125:					.byte	0x00		;SerialNumStrIndex	    = NO_DESCRIPTOR
							.byte	0x01		;NumberOfConfigurations = FIXED_NUM_CONFIGURATIONS

;- ConfigurationDescriptor structure -

#define sizeof_ConfigurationDescriptor	62
ConfigurationDescriptor:	;-config.header -
x800127:					.byte	0x09		;sizeof(USB_Descriptor_Configuration_Header_t)
							.byte	0x02		;DTYPE_Configuration
							;-config.data -
x800129:					.byte	0x3e, 0x00	;TotalConfigurationSize = sizeof(USB_Descriptor_Configuration_t)
x80012b:					.byte	0x02	 	;TotalInterfaces = 2
							.byte	0x01		;ConfigurationNumber    = 1
x80012d:					.byte	0x00 		;ConfigurationStrIndex  = NO_DESCRIPTOR
                            .byte	0x80		;ConfigAttributes       = USB_CONFIG_ATTR_BUSPOWERED
x80012f:					.byte	0x32		;MaxPowerConsumption    = USB_CONFIG_POWER_MA(100)
							;-CDC_CCI_Interface.header-
                            .byte	0x09		;sizeof(USB_Descriptor_Interface_t)
x800131:					.byte	0x04		;DTYPE_Interface
							;-CDC_CCI_Interface.data-
                            .byte	0x00		;InterfaceNumber   = 0
x800133:					.byte	0x00        ;AlternateSetting  = 0
                            .byte	0x01		;TotalEndpoints    = 1
x800135:					.byte	0x02		;Class             = CDC_CSCP_CDCClass
                            .byte	0x02		;SubClass          = CDC_CSCP_ACMSubclass
x800137:					.byte	0x01		;Protocol          = CDC_CSCP_ATCommandProtocol
                            .byte	0x00		;InterfaceStrIndex = NO_DESCRIPTOR
							;CDC_Functional_Header.header
x800139:					.byte	0x05		;sizeof(USB_CDC_Descriptor_FunctionalHeader_t) 
                            .byte	0x24		;DTYPE_CSInterface
							;CDC_Functional_Header.data
x80013b:					.byte	0x00 		;Subtype = 0x00
                            .word	0x0110		;CDCSpecification = VERSION_BCD(01.10)
							;
x80013d:					.byte	0x04
x80013f:					.byte	0x24		;DTYPE_CSInterface
							;
                            .byte	0x02
                            .byte	0x04
							;
                            .byte	0x05
x800143:					.byte	0x24		;DTYPE_CSInterface 
							;
                            .byte	0x06
x800145:					.byte	0x00 
                            .byte	0x01
							;
x800147:					.byte	0x07
                            .byte	0x05		;DTYPE_Endpoint
							;
x800149:					.byte	0x82		;EndpointAddress   = ENDPOINT_DIR_IN | CDC_NOTIFICATION_EPNUM
                            .byte	0x03        ;Attributes        = EP_TYPE_INTERRUPT | ENDPOINT_ATTR_NO_SYNC 
x80014b:					.word	0x0008		;EndpointSize      = CDC_NOTIFICATION_EPSIZE
x80014d:					.byte	0xff		;PollingIntervalMS = 0xFF
							;
                            .byte	0x09
x80014f:					.byte	0x04
							;
                            .byte	0x01
x800151:					.byte	0x00, 0x02
x800153:					.byte	0x0a, 0x00
x800155:					.byte	0x00, 0x00
							;
x800157:					.byte	0x07
                            .byte	0x05
							;
x800159:					.byte	0x04
                            .byte	0x02
x80015b:					.word	0x0010
x80015d:					.byte	0x01
							;
                            .byte	0x07
x80015f:					.byte	0x05
							;
                            .byte	0x83
x800161:					.byte	0x02
                            .word	0x0010
							.byte	0x01

#define sizeof_LanguageString		sizeof_USB_Descriptor_Header_t + (1 << 1)
LanguageString:				;-header-
x800165:					.byte	sizeof_LanguageString	;USB_Descriptor_Header.Size
							.byte	DTYPE_String			;USB_Descriptor_Header.Type
							;-data-
x800167:					.word	LANGUAGE_ID_ENG

#define	sizeof_ProductString		sizeof_USB_Descriptor_Header_t + (16 << 1)
ProductString:				;-header-
x800169:					.byte	sizeof_ProductString	;USB_Descriptor_Header.Size = 2 + (16 unicode chars) << 1
							.byte	DTYPE_String			;USB_Descriptor_Header.Type = DTYPE_String
							;-data-
							.word	'A'
							.word	'r'
							.word	'd'
							.word	'u'
							.word	'i'
							.word	'n'
							.word	'o'
							.word	' '
							.word	'L'
							.word	'e'
							.word	'o'
							.word	'n'
							.word	'a'
							.word	'r'
							.word	'd'
							.word	'o'

							.word	0	;unwanted termination zero

#define	sizeof_ManufNameString		sizeof_USB_Descriptor_Header_t + (11 << 1)
ManufNameString:			;-header-
x80018d:					.byte	sizeof_ManufNameString
							.byte	DTYPE_String
							;-data-
x80018f:					.word	'A'
x800191:					.word	'r'
x800193:					.word	'd'
x800195:					.word	'u'
x800197:					.word	'i'
x800199:					.word	'n'
x80019b:					.word	'o'
x80019d:					.word	' '
x80019f:					.word	'L'
x8001a1:					.word	'L'
x8001a3:					.word	'C'

x8001a5:					.word	0	;unwanted termination zero
							.byte	0	;alignment byte
							
SECTION_DATA_END:
;-------------------------------------------------------------------------------
;Bootloader Vectors
;-------------------------------------------------------------------------------

							.section .text

;note all vectors have a 4 byte slot but only two are used. these unused two
;bytes per slot add up 86 spare bytes and could be used by interpolated strings
;or data for data initialization.

BOOT_START_ADDR:
x7000:						rjmp	x70ac_reset_vector
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
x7028:						rjmp	x7a0e_USB_general_int	;
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
x7044:						rjmp	x7136__vector_17		;Timer/Counter1 Compare Match A
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop
							rjmp	x70e2__bad_interrupt
							nop

;-------------------------------------------------------------------------------
;RESET vector
;-------------------------------------------------------------------------------

x70ac_reset_vector:			eor		r1, r1		;r1 = 0
							out		SREG, r1	;clear SREG
							ldi		r28, 0xFF	;0x0AFF = RAMEND
							ldi		r29, 0x0A	
							out		SPH, r29	;SP = RAMEND
							out		SPL, r28

							ldi		r17, hi8(SECTION_DATA_END)
							ldi		r26, lo8(SECTION_DATA_START)
							ldi		r27, hi8(SECTION_DATA_START)
							ldi		r30, lo8(SECTION_DATA_DATA)
							ldi		r31, hi8(SECTION_DATA_DATA)
							rjmp	x70c8
x70c4:
							lpm		r0, Z+		;copy data from end of text 
							st		X+, r0		;section to 0100

x70c8:						cpi		r26, lo8(SECTION_DATA_END)
							cpc		r27, r17
							brne	x70c4

							;clear .bss

							ldi		r17, hi8(SECTION_BSS_END)
							ldi		r26, lo8(SECTION_BSS_START)
							ldi		r27, hi8(SECTION_BSS_START)
							rjmp	x70d8
x70d6:
							st		X+, r1		;clear with 00

x70d8:						cpi		r26, lo8(SECTION_BSS_END)
							cpc		r27, r17
							brne	x70d6		;
							rcall	x77fe_main
							rjmp	x7f2e_exit	;remove never returns here
x70e2__bad_interrupt:
x70e2:						rjmp	BOOT_START_ADDR	;*** remove change vectors to jumps to 0x7000 immediately

;-------------------------------------------------------------------------------
x70e4_StartSketch:
x70e4:						cli
							sts TIMSK1, r1		
							sts TCCR1B, r1		
							sts TCNT1H, r1
							sts TCNT1L, r1		
							ldi r24, 0x01		
							out MCUCR, r24		
							out MCUCR, r1		
							cbi PORTC, 7
							sbi PORTD, 5		
							sbi PORTB, 0
							jmp 0				; start application

							ret					;*** remove

;-------------------------------------------------------------------------------
x7108_LEDPulse:
x7108:						lds	 r18, LLEDPulse+0
							lds	 r19, LLEDPulse+1
							subi r18, 0xFF		; +1
							sbci r19, 0xFF		
							sts	 LLEDPulse+1, r19
							sts	 LLEDPulse+0, r18
							mov	 r25, r19
							sbrs r19, 7
							rjmp x7128
							
							;LedPulse >= 0x8000

							ldi	 r24, 0xFE		
							sub	 r24, r19		;80..FF > 7E down to 0 and FF
							mov	 r25, r24
							
							;LedPulse < 0x8000
							
x7128:						add	 r25, r25		
							cp	 r25, r18		;2*H - L
							brcc x7132

							cbi	 PORTC, 7		;
							ret

x7132:						sbi	 PORTC, 7	
							ret

;-------------------------------------------------------------------------------
;TIMER1_COMPA_vect	interrupt service

x7136__vector_17:
x7136:						push	r1
							push	r0
							in	r0, SREG		;save SREG
							push	r0
							eor r1, r1
							push	r18			;*** remove r18 not used
							push	r24
							push	r25
							push	r30
							push	r31
							sts TCNT1H, r1		; reset counter
							sts TCNT1L, r1		
							lds r24, TxLEDPulse+0
							lds r25, TxLEDPulse+1
							sbiw	r24, 0x00	; test 0
							breq	x716e		;

							;!0: -1

							sbiw	r24, 0x01	; -1
							sts TxLEDPulse+1, r25
							sts TxLEDPulse+0, r24
							or	r24, r25
							brne	x716e		;

							;TXLED_OFF

							sbi PORTD, 5			;

x716e:						lds r24, RxLEDPulse+0
							lds r25, RxLEDPulse+1
							sbiw	r24, 0x00	; test 0
							breq	x718a

							;!0: -1

							sbiw	r24, 0x01	; 1
							sts RxLEDPulse+1, r25	
							sts RxLEDPulse+0, r24		
							or	r24, r25
							brne	x718a

							;RXLED_OFF

							sbi PORTB, 0 ; 5

x718a:						ldi 	r30, 0x00	;Application start
							ldi 	r31, 0x00
							lpm 	r24, Z+
							lpm 	r25, Z
							subi	r24, 0xFF	;unprogrammed application flash
							sbci	r25, 0xFF	
							breq	x71aa

							;only increase timeout when a sketch is loaded

							lds r24, Timeout+0
							lds r25, Timeout+1
							adiw	r24, 0x01	; +1
							sts Timeout+1, r25
							sts Timeout+0, r24

x71aa:						pop	 r31
							pop	 r30
							pop	 r25
							pop	 r24
							pop	 r18			;*** remove r18 not used
							pop	 r0
							out	 SREG, r0	
							pop	 r0
							pop	 r1
							reti

;-------------------------------------------------------------------------------

x71be_FetchNextCommandByte:
x71be:						ldi	 r24, 0x04		; 4
							sts	 UENUM, r24
							rjmp x71e0

x71c6:						lds	 r24, UEINTX
							andi r24, 0x7B		;
							sts	 UEINTX, r24
							rjmp x71d8

x71d2:						in	 r24, 0x1e	; 30
							and	 r24, r24
							breq x71ec

x71d8:						lds	 r24, UEINTX
							sbrs r24, 2
							rjmp x71d2

x71e0:						lds	 r24, UEINTX
							sbrs r24, 5
							rjmp x71c6

							lds	 r24, UEDATX
x71ec:						ret

;-------------------------------------------------------------------------------

x71ee_WriteNextResponseByte:
x71ee:						mov r25, r24
							ldi r24, 0x03	; 3
							sts UENUM, r24 
							lds r24, UEINTX
							sbrc	r24, 5
							rjmp	x7218

							lds r24, UEINTX
							andi	r24, 0x7E	; 126
							sts UEINTX, r24
							rjmp	x7210

x720a:						in	r24, 0x1e	; 30
							and r24, r24
							breq	x722a

x7210:						lds r24, UEINTX
							sbrs	r24, 0
							rjmp	x720a

x7218:						sts UEDATX, r25 
							cbi PORTD, 5 
							ldi r24, lo8(TX_RX_LED_PULSE_PERIOD)
							ldi r25, hi8(TX_RX_LED_PULSE_PERIOD)
							sts TxLEDPulse+1, r25
							sts TxLEDPulse+0, r24

x722a:						ret

;-------------------------------------------------------------------------------
;CDC Task  (1278 bytes)

x722c_CDC_Task:
x722c:						push	r4
							push	r5
							push	r6
							push	r7
							push	r8
							push	r9
							push	r10
							push	r11
							push	r12
							push	r13
							push	r14
							push	r15
							push	r16
							push	r17
							push	r28
							push	r29
							ldi		r24, 0x04		; 4
							sts		UENUM, r24 
							lds		r24, UEINTX
							sbrs	r24, 2
							rjmp	x7708

							cbi		PORTB, 0 	; 5
							ldi		r24, lo8(TX_RX_LED_PULSE_PERIOD)
							ldi		r25, hi8(TX_RX_LED_PULSE_PERIOD)
							sts		RxLEDPulse+1, r25
							sts		RxLEDPulse+0, r24 
							rcall x71be_FetchNextCommandByte
							mov		r17, r24
							cpi		r24, 'E'
							brne	x7290

							;'E'

							ldi		r24, lo8(TIMEOUT_PERIOD - 500)
							ldi		r25, hi8(TIMEOUT_PERIOD - 500)
							sts		Timeout+1, r25
							sts		Timeout+0, r24
x727c:						in		r0, 0x37	;SPMCSR
							sbrc	r0, 0
							rjmp	x727c

x7282:						sbic	0x1f, 1 ;EECR
							rjmp	x7282

							ldi		r24, 0x11	;RWWSRE | SPMEN
							sts		0x0057, r24 ;SPMCSR
							spm
							rjmp	x7296

x7290:						cpi		r24, 'T'
							brne	x729a

							;'T' drop 2nd byte

							rcall	x71be_FetchNextCommandByte

x7296:						ldi		r24, 0x0D
							rjmp	x76b4

x729a:						cpi		r24, 'L'
							breq	x7296

							cpi		r24, 'P'
							breq	x7296

							cpi		r24, 't'
							brne	x72ae

							ldi		r24, 'D'
							rcall	x71ee_WriteNextResponseByte
							ldi		r24, 0x00	; 0
							rjmp	x76b4

x72ae:						cpi		r24, 'a'
							brne	x72b6

							ldi		r24, 'Y'
							rjmp	x76b4

x72b6:						cpi		r24, 'A'
							brne	x72e6

							rcall	x71be_FetchNextCommandByte
							mov		r17, r24
							rcall	x71be_FetchNextCommandByte
							ldi		r25, 0x00	; 0
							add		r24, r24
							adc		r25, r25
							eor		r26, r26
							sbrc	r25, 7
							com		r26
							mov		r27, r26
							mov		r19, r17
							add		r19, r19
							ldi		r18, 0x00	; 0
							eor		r20, r20
							sbrc	r19, 7
							com		r20
							mov		r21, r20
							or		r24, r18
							or		r25, r19
							or		r26, r20
							or		r27, r21
							rjmp	x7656

x72e6:						cpi		r24, 'p'
							brne	x72ee

							;'p' send programmer response

							ldi		r24, 'S' ;Serial programmer
							rjmp	x76b4

x72ee:						cpi		r24, 'S'
							brne	x7304

							;'S' send software identifier response

							ldi		r28, lo8(SOFTWARE_IDENTIFIER)
							ldi		r29, hi8(SOFTWARE_IDENTIFIER)
x72f6:						ld		r24, Y+
							rcall	x71ee_WriteNextResponseByte
							ldi		r18, hi8(SOFTWARE_IDENTIFIER + 7) ;*** remove length < 256
							cpi		r28, lo8(SOFTWARE_IDENTIFIER + 7)
							cpc		r29, r18
							brne	x72f6
							rjmp	x76b6

x7304:						cpi		r24, 'V'
							brne	x7310

							;'V' version

							ldi		r24, '1'
							rcall	x71ee_WriteNextResponseByte
							ldi		r24, '0'
							rjmp	x76b4

x7310:						cpi		r24, 's'
							brne	x7320

							;'s' avr signature

							ldi		r24, AVR_SIGNATURE_3
							rcall	x71ee_WriteNextResponseByte
							ldi		r24, AVR_SIGNATURE_2
							rcall	x71ee_WriteNextResponseByte
							ldi		r24, AVR_SIGNATURE_1
							rjmp	x76b4

x7320:						cpi		r24, 'e'
							brne	x7352

							;'e': erase application section

							ldi		r30, 0x00	;Z=00000 application start
							ldi		r31, 0x00
							ldi		r25, 0x03	;PGERS | SPMEN Page erase
							ldi		r24, 0x05	;PGWRT | SPMEN pagewrite

							;loop 0000..6FFF

x732c:						sts		0x0057, r25 ;SPMCSR do page erase
							spm
x7332:						in		r0, 0x37	;SPMCSR
							sbrc	r0, 0
							rjmp	x7332	;wait

							sts		0x0057, r24 ;SPMCSR do page write
							spm
x733e:						in		r0, 0x37	;SPMCSR
							sbrc	r0, 0
							rjmp	x733e	;wait

							subi	r30, 0x80	;Z+= 128
							sbci	r31, 0xFF
							ldi		r26, hi8(BOOT_START_ADDR)
							cpi		r30, lo8(BOOT_START_ADDR)
							cpc		r31, r26
							brne	x732c		;loop until end of application area
							rjmp	x7296

x7352:						cpi		r24, 'r'
							brne	x7364

							;get lock bits
							
							ldi		r30, 0x01	; 1
							ldi		r31, 0x00	; 0
							ldi		r24, 0x09	; 9
							sts		0x0057, r24 ;SPMCSR
							lpm		r24, Z
							rjmp	x76b4

x7364:						cpi		r24, 'F'
							brne	x7376

							;get low fuse bits
							
							ldi		r30, 0x00	; 0
							ldi		r31, 0x00	; 0
							ldi		r24, 0x09	; 9
							sts		0x0057, r24 ;SPMCSR
							lpm		r24, Z
							rjmp	x76b4

x7376:						cpi		r24, 'N'
							brne	x7388

							;get high fuse bits
							
							ldi		r30, 0x03	; 3
							ldi		r31, 0x00	; 0
							ldi		r24, 0x09	; 9
							sts		0x0057, r24 ;SPMCSR
							lpm		r24, Z
							rjmp	x76b4

x7388:						cpi		r24, 'Q'
							brne	x739a
							
							;get extended fuse bits
							
							ldi		r30, 0x02	; 2
							ldi		r31, 0x00	; 0
							ldi		r24, 0x09	; 9
							sts		0x0057, r24 ;SPMCSR
							lpm		r24, Z
							rjmp	x76b4

x739a:						cpi		r24, 'b'
							brne	x73aa

							;send block support supported
							
							ldi		r24, 'Y'
							rcall	x71ee_WriteNextResponseByte
							ldi		r24, hi8(SPM_PAGESIZE)
							rcall	x71ee_WriteNextResponseByte
							ldi		r24, lo8(SPM_PAGESIZE)
							rjmp	x76b4

x73aa:						cpi		r24, 'B'
							breq	x73b4

							cpi		r24, 'g'
							breq	x73b4
							rjmp	x757e

							;'B' or 'g' read memory block
							
x73b4:						sts		Timeout+1, r1
							sts		Timeout+0, r1
							
							;ReadWriteMemoryBlock (r17 = command)
							
							rcall	x71be_FetchNextCommandByte
							mov		r16, r24
							rcall	x71be_FetchNextCommandByte
							mov		r15, r24
							rcall	x71be_FetchNextCommandByte
							mov		r6, r24
							subi	r24, 0x45	;
							cpi		r24, 0x02	;
							brcs	x73d0

							rjmp	x76b2

x73d0:						mov		r25, r16
							ldi		r24, 0x00	; 0
							mov		r28, r15
							ldi		r29, 0x00	; 0
							or		r28, r24
							or		r29, r25
							sts		TIMSK1, r1	
							cpi		r17, 0x67	; 'g'
							breq	x73e6

							rjmp	x747c

x73e6:						ldi		r24, 0x11	; 17
							sts		0x0057, r24 ;SPMCSR
							spm
							eor		r13, r13
							eor		r12, r12
							inc		r12
							rjmp	x7474

x73f6:						lds		r14, CurrAddress+0
							lds		r15, CurrAddress+1
							lds		r16, CurrAddress+2
							lds		r17, CurrAddress+3
							ldi		r27, 0x46	; 70
							cp		r6, r27
							brne	x7442

							mov		r30, r13
							ldi		r31, 0x00	; 0
							or		r30, r14
							or		r31, r15
							lpm		r30, Z
							mov		r24, r30
							rcall	x71ee_WriteNextResponseByte
							and		r13, r13
							breq	x743e

							ldi		r24, 0x02	; 2
							ldi		r25, 0x00	; 0
							ldi		r26, 0x00	; 0
							ldi		r27, 0x00	; 0
							add		r14, r24
							adc		r15, r25
							adc		r16, r26
							adc		r17, r27
							sts		CurrAddress+0, r14
							sts		CurrAddress+1, r15
							sts		CurrAddress+2, r16
							sts		CurrAddress+3, r17

x743e:						eor		r13, r12
							rjmp	x7472

x7442:						movw	r26, r16
							movw	r24, r14
							lsr		r27
							ror		r26
							ror		r25
							ror		r24
							rcall	x7f02__eerd_byte_m32u4
							rcall	x71ee_WriteNextResponseByte
							ldi		r24, 0x02	; 2
							ldi		r25, 0x00	; 0
							ldi		r26, 0x00	; 0
							ldi		r27, 0x00	; 0
							add		r14, r24
							adc		r15, r25
							adc		r16, r26
							adc		r17, r27
							sts		CurrAddress+0, r14
							sts		CurrAddress+1, r15
							sts		CurrAddress+2, r16
							sts		CurrAddress+3, r17

x7472:						sbiw	r28, 0x01	; 1

x7474:						sbiw	r28, 0x00	; 0
							breq	x747a

							rjmp	x73f6

x747a:						rjmp	x7576

x747c:						lds		r8,  CurrAddress+0
							lds		r9,  CurrAddress+1
							lds		r10, CurrAddress+2
							lds		r11, CurrAddress+3
							ldi		r25, 0x46	; 70
							cp		r6, r25
							breq	x7494
							rjmp	x754e

x7494:						ldi		r24, 0x03	; 3
							movw	r30, r8
							sts		0x0057, r24 ;SPMCSR
							spm

x749e:						in		r0, 0x37	; 55
							sbrc	r0, 0
							rjmp	x749e

							rjmp	x754e

x74a6:						ldi		r31, 0x46	; 70
							cp		r6, r31
							brne	x7504

							and		r7, r7
							breq	x74fc

							lds		r14, CurrAddress+0
							lds		r15, CurrAddress+1
							lds		r16, CurrAddress+2
							lds		r17, CurrAddress+3
							rcall	x71be_FetchNextCommandByte
							mov		r13, r24
							eor		r12, r12
							mov		r24, r5
							ldi		r25, 0x00	; 0
							or		r24, r12
							or		r25, r13
							movw	r30, r14
							movw	r0, r24
							sts		0x0057, r4	;SPMCSR
							spm
							eor		r1, r1
							ldi		r24, 0x02	; 2
							ldi		r25, 0x00	; 0
							ldi		r26, 0x00	; 0
							ldi		r27, 0x00	; 0
							add		r14, r24
							adc		r15, r25
							adc		r16, r26
							adc		r17, r27
							sts		CurrAddress+0, r14 
							sts		CurrAddress+1, r15 
							sts		CurrAddress+2, r16 
							sts		CurrAddress+3, r17 
							rjmp	x7500

x74fc:						rcall	x71be_FetchNextCommandByte
							mov r5, r24

x7500:						eor r7, r4
							rjmp	x754a

x7504:						lds		r14, CurrAddress+0
							lds		r15, CurrAddress+1
							lds		r16, CurrAddress+2
							lds		r17, CurrAddress+3
							lsr		r17
							ror		r16
							ror		r15
							ror		r14
							rcall	x71be_FetchNextCommandByte
							mov		r22, r24
							movw	r24, r14
							rcall	x7f12__eewr_byte_m32u4
							lds		r24, CurrAddress+0
							lds		r25, CurrAddress+1
							lds		r26, CurrAddress+2
							lds		r27, CurrAddress+3
							adiw	r24, 0x02
							adc		r26, r1
							adc		r27, r1
							sts		CurrAddress+0, r24
							sts		CurrAddress+1, r25
							sts		CurrAddress+2, r26
							sts		CurrAddress+3, r27

x754a:						sbiw	r28, 0x01	; 1
							rjmp	x7556

x754e:						eor r5, r5
							eor r7, r7
							eor r4, r4
							inc r4

x7556:						sbiw	r28, 0x00	; 0
							breq	x755c
							
							rjmp	x74a6
							
x755c:						ldi		r25, 0x46	
							cp		r6, r25
							brne	x7572

							ldi		r24, 0x05	; 5
							movw	r30, r8
							sts		0x0057, r24 ;SPMCSR
							spm

x756c:						in		r0, 0x37	; 55
							sbrc	r0, 0
							rjmp	x756c

x7572:						ldi		r24, 0x0D
							rcall	x71ee_WriteNextResponseByte

x7576:						ldi		r24, 0x02	; 2
							sts		TIMSK1, r24 
							rjmp	x76b6

x757e:						cpi		r24, 0x43	; 67
							brne	x759e

							lds		r16, CurrAddress+0
							lds		r17, CurrAddress+1
							rcall	x71be_FetchNextCommandByte
							ldi		r25, 0x00	; 0
							ldi		r18, 0x01	; 1
							movw	r30, r16
							movw	r0, r24
							sts		0x0057, r18 ;SPMCSR
							spm
							eor		r1, r1
							rjmp	x7296

x759e:						cpi		r24, 0x63	; 99
							brne	x75e8

							lds		r14, CurrAddress+0
							lds		r15, CurrAddress+1
							lds		r16, CurrAddress+2
							lds		r17, CurrAddress+3
							rcall	x71be_FetchNextCommandByte
							movw	r30, r14
							ori		r30, 0x01	; 1
							ldi		r25, 0x00	; 0
							ldi		r18, 0x01	; 1
							movw	r0, r24
							sts		0x0057, r18 ;SPMCSR
							spm
							eor		r1, r1
							ldi		r24, 0x02	; 2
							ldi		r25, 0x00	; 0
							ldi		r26, 0x00	; 0
							ldi		r27, 0x00	; 0
							add		r14, r24
							adc		r15, r25
							adc		r16, r26
							adc		r17, r27
							sts		CurrAddress+0, r14
							sts		CurrAddress+1, r15
							sts		CurrAddress+2, r16
							sts		CurrAddress+3, r17
							rjmp	x7296

x75e8:						cpi		r24, 0x6D	; 109
							brne	x7604

							lds		r30, CurrAddress+0
							lds		r31, CurrAddress+1
							ldi		r24, 0x05	; 5
							sts		0x0057, r24 ;SPMCSR
							spm

x75fc:						in		r0, 0x37	; 55
							sbrc	r0, 0
							rjmp	x75fc
							rjmp	x7296

x7604:						cpi		r24, 0x52	; 82
							brne	x761c

							lds		r30, CurrAddress+0
							lds		r31, CurrAddress+1
							lpm		r16, Z+
							lpm		r17, Z
							mov		r24, r17
							rcall	x71ee_WriteNextResponseByte
							mov		r24, r16
							rjmp	x76b4

x761c:						cpi		r24, 0x44	; 68
							brne	x7668

							lds		r14, CurrAddress+0
							lds		r15, CurrAddress+1
							lds		r16, CurrAddress+2
							lds		r17, CurrAddress+3
							lsr		r17
							ror		r16
							ror		r15
							ror		r14
							rcall	x71be_FetchNextCommandByte
							mov		r22, r24
							movw	r24, r14
							rcall	x7f12__eewr_byte_m32u4
							lds		r24, CurrAddress+0
							lds		r25, CurrAddress+1
							lds		r26, CurrAddress+2
							lds		r27, CurrAddress+3
							adiw	r24, 0x02	; 2
							adc		r26, r1
							adc		r27, r1

x7656:						sts		CurrAddress+0, r24
							sts		CurrAddress+1, r25
							sts		CurrAddress+2, r26
							sts		CurrAddress+3, r27
							rjmp	x7296

x7668:						cpi		r24, 0x64	; 100
							brne	x76ae

							lds		r14, CurrAddress+0
							lds		r15, CurrAddress+1
							lds		r16, CurrAddress+2
							lds		r17, CurrAddress+3
							movw	r26, r16
							movw	r24, r14
							lsr		r27
							ror		r26
							ror		r25
							ror		r24
							rcall	x7f02__eerd_byte_m32u4
							rcall	x71ee_WriteNextResponseByte
							ldi		r24, 0x02	; 2
							ldi		r25, 0x00	; 0
							ldi		r26, 0x00	; 0
							ldi		r27, 0x00	; 0
							add		r14, r24
							adc		r15, r25
							adc		r16, r26
							adc		r17, r27
							sts		CurrAddress+0, r14
							sts		CurrAddress+1, r15
							sts		CurrAddress+2, r16
							sts		CurrAddress+3, r17
							rjmp	x76b6

x76ae:						cpi		r24, 0x1B	; 27
							breq	x76b6

x76b2:						ldi		r24, 0x3F	; 63

							;send  respond byte in r24

x76b4:						rcall	x71ee_WriteNextResponseByte

x76b6:						ldi		r24, 0x03	; 3
							sts		UENUM, r24 
							lds		r25, UEINTX
							lds		r24, UEINTX
							andi	r24, 0x7E	; 126
							sts		UEINTX, r24
							sbrs	r25, 5
							rjmp	x76d6

							rjmp	x76f0

x76d0:						in		r24, 0x1e	; 30
							and		r24, r24
							breq	x7708

x76d6:						lds		r24, UEINTX
							sbrs	r24, 0
							rjmp	x76d0

							lds		r24, UEINTX
							andi	r24, 0x7E	; 126
							sts		UEINTX,r24
							rjmp	x76f0

x76ea:						in		r24, 0x1e	; 30
							and		r24, r24
							breq	x7708

x76f0:						lds		r24, UEINTX
							sbrs	r24, 0
							rjmp	x76ea

							ldi		r24, 0x04		; 4
							sts		UENUM, r24 
							lds		r24, UEINTX
							andi	r24, 0x7B		; 123
							sts		UEINTX, r24 

x7708:						pop		r29
							pop		r28
							pop		r17
							pop		r16
							pop		r15
							pop		r14
							pop		r13
							pop		r12
							pop		r11
							pop		r10
							pop		r9
							pop		r8
							pop		r7
							pop		r6
							pop		r5
							pop		r4
							ret

;-------------------------------------------------------------------------------

x772a_EVENT_USB_Device_ControlRequest:

x772a:						lds 	r25, USB_ControlRequest
							mov 	r24, r25
							andi	r24, 0x7F	; 127
							cpi 	r24, 0x21	; 33
							brne	x7788

							lds 	r24, USB_ControlRequest_brequest
							cpi 	r24, 0x20	; 32
							breq	x7766

							cpi 	r24, 0x21	; 33
							brne	x7788

							cpi 	r25, 0xA1	; 161
							brne	x7788

							lds 	r24, UEINTX
							andi	r24, 0xF7	; 247
							sts 	UEINTX, r24 
							ldi 	r24, lo8(LineEncoding)
							ldi 	r25, hi8(LineEncoding)
							ldi 	r22, lo8(sizeof_LineEncoding)
							ldi 	r23, hi8(sizeof_LineEncoding)
							
							rcall	x7b70_Endpoint_Write_Control_Stream_LE
							lds 	r24, UEINTX
							andi	r24, 0x7B	; 123
							sts 	UEINTX, r24 
							ret

x7766:						cpi 	r25, 0x21	; 33
							brne	x7788

							lds 	r24, UEINTX                             ;\ repeat of above
							andi	r24, 0xF7	; 247                      	;
							sts 	UEINTX, r24                             ;
							ldi 	r24, lo8(LineEncoding)                  ;
							ldi 	r25, hi8(LineEncoding)                  ;
							ldi 	r22, lo8(sizeof_LineEncoding)           ;
							ldi 	r23, hi8(sizeof_LineEncoding)           ;/
							
							rcall	x7c38_Endpoint_Read_Control_Stream_LE  	
							lds 	r24, UEINTX								
							andi	r24, 0x7E	; 126
							
							sts 	UEINTX, r24 							
x7788:						ret

;-------------------------------------------------------------------------------

x778a_EVENT_USB_Device_ConfigurationChanged:
x778a:						ldi r24, 0x02	; 2
							ldi r22, 0xC1	; 193
							ldi r20, 0x02	; 2
							rcall	x78fc_Endpoint_ConfigureEndpoint_Prv
							ldi r24, 0x03	; 3
							ldi r22, 0x81	; 129
							ldi r20, 0x12	; 18
							rcall	x78fc_Endpoint_ConfigureEndpoint_Prv
							ldi r24, 0x04	; 4
							ldi r22, 0x80	; 128
							ldi r20, 0x12	; 18
							rjmp	x78fc_Endpoint_ConfigureEndpoint_Prv

;-------------------------------------------------------------------------------

x77a2_SetupHardware:
x77a2:						in		r24, 0x34	; 52
							andi	r24, 0xF7	; 247
							out		0x34, r24	; 52
							ldi		r24, 0x18	; 24
							in		r0, SREG	; save SREG
							cli
							sts		0x0060, r24 ; WDTCSR
							sts		0x0060, r1	; WDTCSR
							out		SREG, r0	; restore SREG
							ldi		r18, 0x80	; 128
							ldi		r24, 0x00	; 0
							ldi		r25, 0x00	; 0
							in		r0, SREG	; save SREG
							cli
							sts		0x0061, r18 ; CLKPR
							sts		0x0061, r24 ; CLKPR
							out		SREG, r0	; restore SREG
							ldi		r24, 0x01	; 1
							out		MCUCR, r24
							ldi		r25, 0x02	; IVSEL and OCIE1A for TIMSK1
							out		MCUCR, r25	
							sbi		0x07, 7		; 7
							sbi		0x04, 0		; 4
							sbi		0x0a, 5		; 10
							ldi		r30, 0x61	; CLKPR
							ldi		r31, 0x00	;
							st		Z, r18
							st		Z, r1
							cbi		PORTC, 7		
							sbi		PORTD, 5		
							sbi		PORTB, 0		
							sts		0x0089, r1	; OCR1AH
							ldi		r24, 0xFA	; 250
							sts		0x0088, r24 ; OCR1AL
							sts		TIMSK1, r25 ; enable timer 1 output compare A match interrupt
							ldi		r24, 0x03	; CS11 | CS10 1/64 prescaler on timer 1 input
							sts		TCCR1B, r24 
							rjmp	x79de_USB_Init

;-------------------------------------------------------------------------------

x77fe_main:
							lds		r20, BOOTKEY_PTR+0
							lds		r21, BOOTKEY_PTR+1
							sts		BOOTKEY_PTR+1, r1	;0000
							sts		BOOTKEY_PTR+0, r1
							in		r25, 0x34			;save MCUSR state
							out		0x34, r1			;MCUSR
							ldi		r24, 0x18			;WDCE | WDE
							in		r0, SREG			;save SREG *** remove
							cli
							sts		0x0060, r24 ;WDTCSR = WDCE | WDE
							sts		0x0060, r1	;WDTCSR
							out		SREG, r0	;restore SREG *** remove
							mov		r18, r25	;saved MCUSR state byte to word
							ldi		r19, 0x00	;0
							movw	r30, r18
							andi	r30, 0x02	;EXTRF test external reset
							andi	r31, 0x00
							sbrc	r25, 1		;EXTRF skip no external reset
							rjmp	x7860		;enter bootloader mode

							sbrs	r25, 0		;PORF test poweer on reset
							rjmp	x783e		;not POF

							;power on reset

							lpm r24, Z+			;Z = 0000 from and operation
							lpm r25, Z
							subi	r24, 0xFF	;FFFF = no application
							sbci	r25, 0xFF
							brne	x785e		;run sketch

							;no application or no POR

x783e:						sbrs	r18, 3		;WDRF
							rjmp	x7860		;WDT not triggered, enter bootloader mode

							;WDT was triggered

							lds 	r24, bootKey
							lds 	r25, bootKey+1
							cp		r20, r24
							cpc 	r21, r25
							breq	x7860		;magic key, enter bootloader mode

							;no magic key

							ldi 	r30, 0x00	;Application start
							ldi 	r31, 0x00	
							lpm 	r24, Z+
							lpm 	r25, Z
							subi	r24, 0xFF	;unprogrammed application flash
							sbci	r25, 0xFF	
							breq	x7860		;no application, enter bootloader mode

							;run sketch

x785e:						rcall	x70e4_StartSketch

							;enter bootloader mode

x7860:						rcall	x77a2_SetupHardware
							sei
							sts 	Timeout+1, r1	;Timeout = 0000
							sts 	Timeout+0, r1
							rjmp	x7886

x786e:						rcall	x722c_CDC_Task
							rcall	x7ede_USB_USBTask
							lds 	r24, Timeout+0
							lds 	r25, Timeout+1
							subi	r24, lo8(TIMEOUT_PERIOD+1)
							sbci	r25, hi8(TIMEOUT_PERIOD+1)
							brcs	x7884		; < (TIMEOUT_PERIOD+1)

							sts RunBootloader, r1

x7884:						rcall	x7108_LEDPulse

x7886:						lds r24, RunBootloader
							and r24, r24
							brne	x786e
							
							;0: USB detach and start sketch
							
							lds r24, UDCON
							ori r24, 0x01	; 1
							sts UDCON, r24
							rcall	x70e4_StartSketch

							ldi r24, 0x00	;*** remove StartSketch doesn't return
							ldi r25, 0x00	;*** remove
							ret				;*** remove

;-------------------------------------------------------------------------------

;entry:
;	r24		= DiscriptorNumber
;	r25		= DiscriptorType
;	r20:r21 = void**

;exit:
;	void** = Discriptor address
;	r24:r25 = length

x78a0_CALLBACK_USB_GetDescriptor:
x78a0:						movw	r30, r20	;*** Remove use Z directoy
							cpi r25, 0x02		;DTYPE_Configuration
							breq	x78b8

							cpi r25, 0x03		;DTYPE_String
							breq	x78c2

							cpi r25, 0x01		;DTYPE_Device
							brne	x78ec

							;DTYPE_Device

							ldi r24, lo8(DeviceDescriptor)
							ldi r25, hi8(DeviceDescriptor)
							ldi r18, lo8(sizeof_DeviceDescriptor)
							ldi r19, hi8(sizeof_DeviceDescriptor)
							rjmp	x78f4

x78b8:						ldi r24, lo8(ConfigurationDescriptor)
							ldi r25, hi8(ConfigurationDescriptor)
							ldi r18, lo8(sizeof_ConfigurationDescriptor)
							ldi r19, hi8(sizeof_ConfigurationDescriptor)
							rjmp	x78f4

							;DTYPE_String

x78c2:						and r24, r24
							brne	x78d0

							;0: LanguageString

							ldi r24, lo8(LanguageString)
							ldi r25, hi8(LanguageString)
							ldi r18, lo8(sizeof_LanguageString)
							ldi r19, hi8(sizeof_LanguageString)
							rjmp	x78f4

							;!0:

x78d0:						cpi r24, 0x01	; 1
							brne	x78de

							;1: ProductString

							ldi r24, lo8(ProductString)
							ldi r25, hi8(ProductString)
							ldi r18, lo8(sizeof_ProductString)
							ldi r19, hi8(sizeof_ProductString)
							rjmp	x78f4

							;!1:
x78de:						cpi r24, 0x02	; 2
							brne	x78ec

							;2: ManufNameString

x78e2:						ldi r24, lo8(ManufNameString)
							ldi r25, hi8(ManufNameString)
							ldi r18, lo8(sizeof_ManufNameString)
							ldi r19, hi8(sizeof_ManufNameString)
							rjmp	x78f4

							;unsupported

x78ec:						ldi		r24, 0x00	; null pointer
							ldi		r25, 0x00	; 
							ldi		r18, 0x00	; zero size
							ldi		r19, 0x00	; 

							;

x78f4:						std		Z+1, r25	;store Discriptor address
							st		Z, r24
							movw	r24, r18	;return discriptor length
							ret

;-------------------------------------------------------------------------------

x78fc_Endpoint_ConfigureEndpoint_Prv:
x78fc:						sts		UENUM, r24
							lds		r24, UECONX
							ori		r24, 0x01
							sts		UECONX, r24 
							sts		UECFG1X, r1
							sts		UECFG0X, r22 
							sts		UECFG1X, r20 
							lds		r24, UESTA0X	;				|*** result not used
							adc		r24, r24		;CFGOK to carry |	 can be removed
							eor		r24, r24		;0				|
							adc		r24, r24		;0 + carry		|
							ret

;-------------------------------------------------------------------------------

x7922_Endpoint_ClearStatusStage:
x7922:						lds r24, USB_ControlRequest
							and r24, r24
							brge	x794c

							rjmp	x7932

x792c:						in	r24, 0x1e	; 30
							and r24, r24
							breq	x795e

x7932:						lds r24, UEINTX
							sbrs	r24, 2
							rjmp	x792c

							lds r24, UEINTX
							andi	r24, 0x7B	; 123
							sts UEINTX, r24 
							ret

x7946:						in	r24, 0x1e	; 30
							and r24, r24
							breq	x795e

x794c:						lds r24, UEINTX
							sbrs	r24, 0
							rjmp	x7946

							lds r24, UEINTX
							andi	r24, 0x7E	; 126
							sts UEINTX, r24 
x795e:						ret

;-------------------------------------------------------------------------------

x7960_USB_ResetInterface:
							push	r14
							push	r15
							push	r16
							push	r17
							rcall	x79f4_USB_INT_DisableAllInterrupts
							rcall	x7a04_USB_INT_ClearAllInterrupts
							ldi 	r16, USBCON
							ldi 	r17, 0x00
							movw	r30, r16
							ld		r24, Z
							andi	r24, 0x7F	
							st		Z, r24
							ld		r24, Z
							ori 	r24, 0x80	
							st		Z, r24
							ld		r24, Z
							andi	r24, 0xDF	
							st		Z, r24
							out 	0x29, r1	
							out 	0x1e, r1	
							sts 	USB_Device_ConfigurationNumber, r1
							ldi 	r24, UDCON
							mov 	r14, r24
							mov 	r15, r1
							movw	r30, r14
							ld		r24, Z
							andi	r24, 0xFB	
							st		Z, r24
							movw	r30, r16
							ld		r24, Z
							ori 	r24, 0x01	
							st		Z, r24
							ldi 	r24, 0x00	
							ldi 	r22, 0x00	
							ldi 	r20, 0x02	
							rcall	x78fc_Endpoint_ConfigureEndpoint_Prv
							ldi 	r30, UDINT
							ldi 	r31, 0x00
							ld		r24, Z
							andi	r24, 0xFE	
							st		Z, r24
							ldi 	r30, UDIEN
							ldi 	r31, 0x00	
							ld		r24, Z
							ori 	r24, 0x01	
							st		Z, r24
							ld		r24, Z
							ori 	r24, 0x08	
							st		Z, r24
							movw	r30, r14
							ld		r24, Z
							andi	r24, 0xFE	
							st		Z, r24
							movw	r30, r16
							ld		r24, Z
							ori 	r24, 0x10	
							st		Z, r24
							pop 	r17
							pop 	r16
							pop 	r15
							pop 	r14
							ret

;-------------------------------------------------------------------------------

x79de_USB_Init:
							ldi 	r30, UHWCON
							ldi 	r31, 0x00	
							ld		r24, Z
							ori 	r24, 0x01
							st		Z, r24
							ldi 	r24, 0x4A
							out 	0x32, r24
							ldi 	r24, 0x01				;*** remove, not used
							sts 	USB_IsInitialized, r24	;*** remove, not used
							rjmp	x7960_USB_ResetInterface

x79f4_USB_INT_DisableAllInterrupts:
							ldi 	r30, USBCON
							ldi 	r31, 0x00	
							ld		r24, Z
							andi	r24, 0xFE	
							st		Z, r24
							sts 	UDIEN, r1	
							ret

x7a04_USB_INT_ClearAllInterrupts:
							sts USBINT, r1	
							sts UDINT, r1	
							ret

;-------------------------------------------------------------------------------
;General USB interrupt
;-------------------------------------------------------------------------------

x7a0e_USB_general_int:
x7a0e:						push	r1
							push	r0
							in		r0, SREG
							push	r0
							eor		r1, r1
							push	r18
							push	r19
							push	r20
							push	r21
							push	r22
							push	r23
							push	r24
							push	r25
							push	r26
							push	r27
							push	r30
							push	r31
							lds		r24, USBINT
							sbrs	r24, 0
							rjmp	x7a6e

							lds		r24, USBCON
							sbrs	r24, 0
							rjmp	x7a6e

							lds		r24, USBINT
							andi	r24, 0xFE	; 254
							sts		USBINT, r24 
							lds		r24, USBSTA
							sbrs	r24, 0
							rjmp	x7a68

							ldi		r24, 0x10	
							out		0x29, r24	
							ldi		r24, 0x12	
							out		0x29, r24	
x7a5a:						in		r0, 0x29	
							sbrs	r0, 0
							rjmp	x7a5a

							ldi		r24, 0x01	
							out		0x1e, r24	
							rcall	x7edc_USB_Event_Stub	;*** remove
							rjmp	x7a6e

x7a68:						out		0x29, r1	
							out		0x1e, r1	
							rcall	x7edc_USB_Event_Stub	;*** remove
x7a6e:						lds		r24, UDINT
							sbrs	r24, 0
							rjmp	x7aa4

							lds		r24, UDIEN
							sbrs	r24, 0
							rjmp	x7aa4

							lds		r24, UDIEN
							andi	r24, 0xFE	
							sts		UDIEN, r24 
							lds		r24, UDIEN
							ori		r24, 0x10	
							sts		UDIEN, r24 
							lds		r24, USBCON
							ori		r24, 0x20	
							sts		USBCON, r24 
							out		0x29, r1	
							ldi		r24, 0x05	
							out		0x1e, r24	
							rcall	x7edc_USB_Event_Stub	;*** remove
x7aa4:						lds		r24, UDINT
							sbrs	r24, 4
							rjmp	x7b04

							lds		r24, UDIEN
							sbrs	r24, 4
							rjmp	x7b04

							ldi		r24, 0x10	
							out		0x29, r24	
							ldi		r24, 0x12	
							out		0x29, r24	
x7abc:						in		r0, 0x29	
							sbrs	r0, 0
							rjmp	x7abc

							lds		r24, USBCON
							andi	r24, 0xDF	
							sts		USBCON, r24 
							lds		r24, UDINT
							andi	r24, 0xEF	
							sts		UDINT, r24 
							lds		r24, UDIEN
							andi	r24, 0xEF	
							sts		UDIEN, r24 
							lds		r24, UDIEN
							ori		r24, 0x01	
							sts		UDIEN, r24 
							lds		r24, USB_Device_ConfigurationNumber
							and		r24, r24
							brne	x7afe

							lds		r24, UDADDR
							sbrc	r24, 7
							rjmp	x7afe

							ldi		r24, 0x01	
							rjmp	x7b00       
                                                
x7afe:						ldi		r24, 0x04	
x7b00:						out		0x1e, r24	
							rcall	x7edc_USB_Event_Stub	;*** remove
x7b04:						lds		r24, UDINT
							sbrs	r24, 3
							rjmp	x7b4e
							lds		r24, UDIEN
							sbrs	r24, 3
							rjmp	x7b4e

							lds		r24, UDINT
							andi	r24, 0xF7	
							sts		UDINT, r24 
							ldi		r24, 0x02	
							out		0x1e, r24	
							sts		USB_Device_ConfigurationNumber, r1	
							lds		r24, UDINT
							andi	r24, 0xFE	
							sts		UDINT, r24 
							lds		r24, UDIEN
							andi	r24, 0xFE	
							sts		UDIEN, r24 
							lds		r24, UDIEN
							ori		r24, 0x10	
							sts		UDIEN, r24 
							ldi		r24, 0x00	
							ldi		r22, 0x00	
							ldi		r20, 0x02	
							rcall	x78fc_Endpoint_ConfigureEndpoint_Prv
							rcall	x7edc_USB_Event_Stub	;*** remove

x7b4e:						pop		r31
							pop		r30
							pop		r27
							pop		r26
							pop		r25
							pop		r24
							pop		r23
							pop		r22
							pop		r21
							pop		r20
							pop		r19
							pop		r18
							pop		r0
							out		SREG, r0	
							pop		r0
							pop		r1
							reti

;-------------------------------------------------------------------------------

x7b70_Endpoint_Write_Control_Stream_LE:
x7b70:						movw	r18, r24
							lds		r20, USB_ControlRequest_wLength+0
							lds		r21, USB_ControlRequest_wLength+1
							cp		r20, r22
							cpc		r21, r23
							brcc	x7b86

x7b80:						movw	r30, r18
							ldi		r25, 0x00
							rjmp	x7c0e

x7b86:						cp		r22, r1
							cpc		r23, r1
							breq	x7b90

							movw	r20, r22
							rjmp	x7b80

x7b90:						lds		r24, UEINTX
							andi	r24, 0x7E	
							sts		UEINTX, r24 
							ldi		r20, 0x00	
							ldi		r21, 0x00	
							rjmp	x7b80

x7ba0:						in		r24, 0x1e	
							and		r24, r24
							brne	x7ba8

							rjmp	x7c30

x7ba8:						cpi		r24, 0x05	
							brne	x7bae

							rjmp	x7c34

x7bae:						lds		r24, UEINTX
							sbrs	r24, 3
							rjmp	x7bba

							ldi		r24, 0x01	
							ret

x7bba:						lds		r24, UEINTX
							sbrc	r24, 2
							rjmp	x7c24

							lds		r24, UEINTX
							sbrs	r24, 0
							rjmp	x7c0e

							lds		r24, UEBCHX
							lds		r25, UEBCLX
							mov		r23, r24
							ldi		r22, 0x00	
							mov		r18, r25
							ldi		r19, 0x00	
							or		r18, r22
							or		r19, r23
							rjmp	x7bee

x7be0:						ld		r24, Z+
							sts		UEDATX, r24 
							subi	r20, 0x01	; -1
							sbci	r21, 0x00	
							subi	r18, 0xFF	; +1
							sbci	r19, 0xFF	
x7bee:						cp		r20, r1
							cpc		r21, r1
							breq	x7bfa

							cpi		r18, 0x08	
							cpc		r19, r1
							brcs	x7be0

x7bfa:						ldi		r25, 0x00	
							cpi		r18, 0x08	
							cpc		r19, r1
							brne	x7c04

							ldi		r25, 0x01	
x7c04:						lds		r24, UEINTX
							andi	r24, 0x7E	
							sts		UEINTX, r24 
x7c0e:						cp		r20, r1
							cpc		r21, r1
							brne	x7ba0

							and		r25, r25
							brne	x7ba0

							rjmp	x7c24

x7c1a:						in		r24, 0x1e	
							and		r24, r24
							breq	x7c30
							cpi		r24, 0x05	
							breq	x7c34

x7c24:						lds		r24, UEINTX
							sbrs	r24, 2
							rjmp	x7c1a

							ldi		r24, 0x00	
							ret

x7c30:						ldi		r24, 0x02	
							ret

x7c34:						ldi		r24, 0x03	
							ret

;-------------------------------------------------------------------------------

x7c38_Endpoint_Read_Control_Stream_LE:
x7c38:						movw	r18, r24
							cp		r22, r1
							cpc		r23, r1
							brne	x7c4a

							lds		r24, UEINTX
							andi	r24, 0x7B	; 123
							sts		UEINTX, r24 

x7c4a:						movw	r30, r18
							rjmp	x7c9a

x7c4e:						in		r24, 0x1e	; 30
							and		r24, r24
							breq	x7cb8

							cpi		r24, 0x05	; 5
							breq	x7cbc

							lds		r24, UEINTX
							sbrs	r24, 3
							rjmp	x7c64

							ldi		r24, 0x01	; 1
							ret

x7c64:						lds		r24, UEINTX
							sbrs	r24, 2
							rjmp	x7c4e

							rjmp	x7c7a

x7c6e:						lds		r24, UEDATX
							st		Z+, r24
							subi	r22, 0x01	; 1
							sbci	r23, 0x00	; 0
							breq	x7c90

x7c7a:						lds		r18, UEBCHX
							lds		r24, UEBCLX
							mov		r19, r18
							ldi		r18, 0x00	; 0
							ldi		r25, 0x00	; 0
							or		r24, r18
							or		r25, r19
							or		r24, r25
							brne	x7c6e

x7c90:						lds		r24, UEINTX
							andi	r24, 0x7B	; 123
							sts		UEINTX, r24 

x7c9a:						cp		r22, r1
							cpc		r23, r1
							brne	x7c4e

							rjmp	x7cac

x7ca2:						in		r24, 0x1e	; 30
							and		r24, r24
							breq	x7cb8

							cpi		r24, 0x05	; 5
							breq	x7cbc

x7cac:						lds		r24, UEINTX
							sbrs	r24, 0
							rjmp	x7ca2

							ldi		r24, 0x00	; 0
							ret

x7cb8:						ldi		r24, 0x02	; 2
							ret

x7cbc:						ldi		r24, 0x03	; 3
							ret

;-------------------------------------------------------------------------------

x7cc0_USB_Device_ProcessControlRequest:
x7cc0:						push	r16
							push	r17
							push	r29
							push	r28
							rcall	x7cca		;create 2 bytes stack space

x7cca:						in		r28, SPL
							in		r29, SPH
							ldi		r30, lo8(USB_ControlRequest)
							ldi		r31, hi8(USB_ControlRequest)

							;01B6..01BD

x7cd2:						lds		r24, UEDATX
							st		Z+, r24
							ldi		r24, hi8(USB_ControlRequest + sizeof_USB_ControlRequest_t)
							cpi		r30, lo8(USB_ControlRequest + sizeof_USB_ControlRequest_t)
							cpc		r31, r24
							brne	x7cd2		;

							rcall	x772a_EVENT_USB_Device_ControlRequest
							lds		r24, UEINTX
							sbrs	r24, 3
							rjmp	x7eb2

							lds		r24, USB_ControlRequest
							lds		r25, USB_ControlRequest_brequest
							cpi		r25, 0x05	; 5
							brne	x7cf8
							
							rjmp	x7dd2
							
x7cf8:						cpi		r25, 0x06	; 6
							brcc	x7d0c

							cpi		r25, 0x01	; 1
							breq	x7d60

							cpi		r25, 0x01	; 1
							brcs	x7d20

							cpi		r25, 0x03	; 3
							breq	x7d0a

							rjmp	x7eb2
x7d0a:						rjmp	x7d60

x7d0c:						cpi		r25, 0x08	; 8
							brne	x7d12

							rjmp	x7e58

x7d12:						cpi		r25, 0x09	; 9
							brne	x7d18

							rjmp	x7e7c

x7d18:						cpi		r25, 0x06	; 6
							breq	x7d1e

							rjmp	x7eb2

x7d1e:						rjmp	x7e18

x7d20:						cpi		r24, 0x80	; 128
							brne	x7d26

							rjmp	x7eb2

x7d26:						cpi		r24, 0x82	; 130
							breq	x7d2c

							rjmp	x7eb2

x7d2c:						lds		r24, USB_ControlRequest_wIndex
							andi	r24, 0x07	; 7
							sts		UENUM, r24 
							lds		r24, UECONX
							sts		UENUM, r1	
							lds		r18, UEINTX
							andi	r18, 0xF7	; 247
							sts		UEINTX, r18 
							ldi		r25, 0x00	; 0
							ldi		r18, 0x05	; 5

x7d4c:						lsr		r25
							ror		r24
							dec		r18
							brne	x7d4c

							andi	r24, 0x01	; 1
							sts		UEDATX, r24 
							sts		UEDATX, r1	
							rjmp	x7e6e

x7d60:						and		r24, r24
							breq	x7d6a
							cpi		r24, 0x02	; 2
							breq	x7d6a

							rjmp	x7eb2

x7d6a:						andi	r24, 0x1F	; 31
							cpi		r24, 0x02	; 2
							breq	x7d72

							rjmp	x7eb2

x7d72:						lds		r24, USB_ControlRequest_wValue
							and		r24, r24
							brne	x7dc6	;.+76
							lds		r18, USB_ControlRequest_wIndex
							andi	r18, 0x07	; 7
							brne	x7d84
							rjmp	x7eb2

x7d84:						sts		UENUM, r18 
							lds		r24, UECONX
							sbrs	r24, 0
							rjmp	x7dc6

							cpi		r25, 0x03	; 3
							brne	x7d9c
							
							lds		r24, UECONX
							ori		r24, 0x20	; 32
							rjmp	x7dc2

x7d9c:						lds		r24, UECONX
							ori		r24, 0x10	; 16
							sts		UECONX, r24 
							ldi		r24, 0x01	; 1
							ldi		r25, 0x00	; 0
							rjmp	x7db0

x7dac:						add		r24, r24
							adc		r25, r25
x7db0:						dec		r18
							brpl	x7dac

							sts		UERST, r24 
							sts		UERST, r1	
							lds		r24, UECONX
							ori		r24, 0x08	; 8
x7dc2:						sts		UECONX, r24 
x7dc6:						sts		UENUM, r1	
							lds		r24, UEINTX
							andi	r24, 0xF7	; 247
							rjmp	x7e74

x7dd2:						and		r24, r24
							breq	x7dd8

							rjmp	x7eb2

x7dd8:						lds		r17, USB_ControlRequest_wValue
							andi	r17, 0x7F	; 127
							in		r16, SREG
							cli
							lds		r24, UEINTX
							andi	r24, 0xF7	; 247
							sts		UEINTX, r24 
							rcall	x7922_Endpoint_ClearStatusStage
							
x7dee:						lds		r24, UEINTX
							sbrs	r24, 0
							rjmp	x7dee
							
							lds		r24, UDADDR
							andi	r24, 0x80	; 128
							or		r24, r17
							sts		UDADDR, r24 
							ori		r24, 0x80	; 128
							sts		UDADDR, r24 
							and		r17, r17
							brne	x7e10

							ldi		r24, 0x02	; 2
							rjmp	x7e12

x7e10:						ldi		r24, 0x03	; 3

x7e12:						out		0x1e, r24	; 30
							out		SREG, r16	
							rjmp	x7eb2

							;

x7e18:						subi	r24, 0x80	; 128
							cpi		r24, 0x02	; 2
							brcs	x7e20

							rjmp	x7eb2

x7e20:						lds		r24, USB_ControlRequest_wValue
							lds		r25, USB_ControlRequest_wValue+1
							lds		r22, USB_ControlRequest_wIndex
							movw	r20, r28	;r20:r21 = sp+1
							subi	r20, 0xFF	
							sbci	r21, 0xFF	 
							rcall	x78a0_CALLBACK_USB_GetDescriptor
							movw	r22, r24
							sbiw	r24, 0x00	;test zero length
							brne	x7e3c

							;zero length
							
							rjmp	x7eb2

x7e3c:						lds		r24, UEINTX
							andi	r24, 0xF7	; 247
							sts		UEINTX, r24 
							ldd		r24, Y+1	; 0x01
							ldd		r25, Y+2	; 0x02
							rcall	x7b70_Endpoint_Write_Control_Stream_LE
							lds		r24, UEINTX
							andi	r24, 0x7B	; 123
							sts		UEINTX, r24 
							rjmp	x7eb2

x7e58:						cpi		r24, 0x80	; 128
							brne	x7eb2

							lds		r24, UEINTX
							andi	r24, 0xF7	; 247
							sts		UEINTX, r24 
							lds		r24, USB_Device_ConfigurationNumber
							sts		UEDATX, r24 

x7e6e:						lds		r24, UEINTX
							andi	r24, 0x7E	; 126

x7e74:						sts		UEINTX, r24 
							rcall	x7922_Endpoint_ClearStatusStage
							rjmp	x7eb2

x7e7c:						and		r24, r24
							brne	x7eb2

							lds		r25, USB_ControlRequest_wValue
							cpi		r25, 0x02	; 2
							brcc	x7eb2

							lds		r24, UEINTX
							andi	r24, 0xF7	; 247
							sts		UEINTX, r24 
							sts		USB_Device_ConfigurationNumber, r25
							rcall	x7922_Endpoint_ClearStatusStage
							lds		r24, USB_Device_ConfigurationNumber
							and		r24, r24
							brne	x7eac
							lds		r24, UDADDR
							sbrc	r24, 7
							rjmp	x7eac

							ldi		r24, 0x01	; 1
							rjmp	x7eae

x7eac:						ldi		r24, 0x04	; 4

x7eae:						out		0x1e, r24	; 30
							rcall	x778a_EVENT_USB_Device_ConfigurationChanged

							;

x7eb2:						lds		r24, UEINTX
							sbrs	r24, 3
							rjmp	x7ece	
							
							lds		r24, UECONX
							ori		r24, 0x20	
							sts		UECONX, r24 
							lds		r24, UEINTX
							andi	r24, 0xF7	
							sts		UEINTX, r24 

x7ece:						pop		r0			;*** remove from call
							pop		r0			;*** remove from call
							pop		r28
							pop		r29
							pop		r17
							pop		r16
							ret

;-------------------------------------------------------------------------------

x7edc_USB_Event_Stub:
							ret					;*** remove + remove source calls

;-------------------------------------------------------------------------------

x7ede_USB_USBTask:
							push	r17			;*** remove r17 saved by call
							in		r24, 0x1e	;GPIOR0
							and		r24, r24	;
							breq	x7efe		;

							lds		r17, UENUM
							sts		UENUM, r1
							lds		r24, UEINTX
							sbrs	r24, 3		;
							rjmp	x7ef8		;

							rcall	x7cc0_USB_Device_ProcessControlRequest

x7ef8:						andi	r17, 0x07	;restore USB endpoint
							sts		UENUM, r17 ;
x7efe:						pop		r17			;*** remove r17 saved by call
							ret

;-------------------------------------------------------------------------------
;eeprom read byte from R25:r24 into r24

x7f02__eerd_byte_m32u4:
							sbic	0x1f, 1		;EECR.EEPE
							rjmp	x7f02__eerd_byte_m32u4

							out		0x22, r25	;EEARH
							out		0x21, r24	;EEARL
							sbi		0x1f, 0		;EECR.EERE
							eor		r25, r25	;*** remove
							in		r24, 0x20	;EEDR read eeprom byte
							ret

;-------------------------------------------------------------------------------
;eeprom write byte r22 to r25:r24

x7f12__eewr_byte_m32u4:
							mov r18, r22
x7f14__eewr_r18_m32u4:
							sbic	0x1f, 1		;EECR EEPE
							rjmp	x7f14__eewr_r18_m32u4	;wait

							out		0x1f, r1	;EECR
							out		0x22, r25	;EEARH
							out		0x21, r24	;EEARL
							out		0x20, r18	;EEDR
							in		r0, SREG
							cli
							sbi		0x1f, 2		;EECR
							sbi		0x1f, 1		;EECR
							out		SREG, r0	
							adiw	r24, 0x01	; 1
							ret

;-------------------------------------------------------------------------------
x7f2e_exit:
							cli
x7f30:						rjmp	x7f30		;*** remove never gets here

;-------------------------------------------------------------------------------
SECTION_DATA_DATA:			;(Initialized data stored after text section)
;-------------------------------------------------------------------------------

							.section .bss
SECTION_BSS_START:

							
TxLEDPulse:							.word	0 ;01a8
RxLEDPulse:							.word	0 ;01aa
Timeout:							.word	0 ;01ac
CurrAddress:						.long	0 ;01ae
LLEDPulse:							.word	0 ;01b2
USB_Device_ConfigurationNumber:		.byte	0 ;01b4
USB_IsInitialized:					.byte	0 ;01b5 

USB_ControlRequest:					;structure:
USB_ControlRequest_bmRequestType:	.byte	0 ;01b6
USB_ControlRequest_brequest:		.byte	0 ;01b7
USB_ControlRequest_wValue:			.word	0 ;01b8
USB_ControlRequest_wIndex:			.word	0 ;01bA
USB_ControlRequest_wLength:			.word	0 ;01bC

SECTION_BSS_END:
;-------------------------------------------------------------------------------
