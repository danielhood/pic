; MIDI Processing Routines (Main code loop)

	list	P=PIC16F819

#include p16f819.inc
#include inc/vars.inc

; ------------------------------------------------------------------------------
; Export global code refs
;
	global	_MAIN


; ------------------------------------------------------------------------------
; Generates and applys CV LSB based on MSB value currently in W
;
_GENERATE_LSB	macro
; Generate LSB from MSB in W
	banksel	CV_LSB
	movwf	CV_LSB
	rrf	CV_LSB,F	; shift on position for CV_LSB
	movlw	b'00110000'	; mask for CV_LSB
	andwf	CV_LSB,F	; generate masked value for bits <5:4> into variable
	movlw	b'00001111'	; mask for CCP1CON
	andwf	CCP1CON,W	; generated masked value into W
	iorwf	CV_LSB,W	; combine nibbles into W
	movwf	CCP1CON		; apply LSB to CCP1CON
	endm

; ------------------------------------------------------------------------------
; Converts a 7 bit value in CUR_BYTE and outputs the result on the CV port (RB2)
; Register W is expected to contain the base address of the CV value lookup table.
_CV_OUT	macro
	banksel	CUR_BYTE
	addwf	CUR_BYTE,W	; Add 7-bit offset from CUR_BYTE to W
	banksel	EEADR
	MOVWF	EEADR		; Address to read
	banksel	EECON1
	BSF	EECON1,RD	; EE Read
	banksel	EEDATA
	MOVF	EEDATA,W	; W = EEDATA
	banksel	CCPR1L
	movwf	CCPR1L		; apply MSB to CCP1RL
	
	_GENERATE_LSB

	endm


; ------------------------------------------------------------------------------
; Outputs 7-bit CV Data value on CUR_BYTE to CV Port
;
_CV_DATA_OUT	macro
; Lookup MSB
	banksel	CV_DATA
	movlw	CV_DATA		; Base address of CV lookup in Data EEPROM memory space
	_CV_OUT

	endm


; ------------------------------------------------------------------------------
; Outputs 7-bit CV Note value on CUR_BYTE to CV Port
;
_CV_NOTE_OUT	macro
; Lookup MSB
	banksel	CV_NOTE
	movlw	CV_NOTE		; Base address of CV lookup in Data EEPROM memory space
	_CV_OUT

	endm


; ------------------------------------------------------------------------------
; Main code loop to process MIDI bytes read by the service handlers
;
.MAIN	code			; Relocatable code for main application
_MAIN:
	banksel	PORTA
	btfss	BIT_READ_FLAGS,NEW_BYTE	; Check to see if there is a new byte available
	goto	_MAIN

; Process new byte
	bcf	BIT_READ_FLAGS,NEW_BYTE	; Signal that we've read the new data
	incf	BYTE_COUNT,F	; DEBUG: Track the number of bytes read

; Display the scaled value of CUR_BYTE on CV port
	;_CV_DATA_OUT
	_CV_NOTE_OUT


; Display last read byte on PORTA
;	movf	CUR_BYTE,W
;	movwf	PORTA

; Display number of bytes read so far
;	movf	BYTE_COUNT,W
;	movwf	PORTA

        ;bsf	PORTA,0		; turn on RA0
	;movlw	0x5C
	;movwf	PORTA

	;clrf	PORTA
	;comf	PORTA,F


	goto	_MAIN


	end

