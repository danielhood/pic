; ------------------------------------------------------------------------------
; Variables

	cblock	0x0020		; start addresses in user register space

;------ Shared variables
	CUR_BYTE		; Completed byte read by service code

;------ service.asm variables
	W_TMP			; Storage for W register during interrupt
	ST_TMP			; Storage for STATUS register during interrupt
	BITS_READ		; Holds number of bits left to read
	TMP_BYTE		; Working byte being read
	BIT_READ_FLAGS		; Flags for status of bit read operationss
				;	READING - Bits are being read
				;	NEW_BYTE - A new byte has been written to CUR_BYTE

;------ midi.asm variables
	CV_MSB			; Scaled CV out value (MSB for CCP1RL)
	CV_LSB			; Scaled CV out value (LSB mask for CCP1CON<5:4>)
	BYTE_COUNT		; Counts number of bytes received
;------ midi.read.int.asm variables (entry point)

	endc


; ------------------------------------------------------------------------------
; Constants
;
CV_DATA:	equ	0x00	; EEPROM base Address of CV Controller data lookup
CV_NOTE:	equ	0x80	; EEPROM base Address CV Note data lookup

CLK:		equ	0xA0	; Peroid for TMR2 and max value for PWM duty cycle

; BIT_READ_FLAGS
READING:	equ	0x00
NEW_BYTE:	equ	0x01
