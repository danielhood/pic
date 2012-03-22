; MIDI Processing Routines (Main code loop)

	list	P=PIC16F819

#include p16f819.inc
#include inc/vars.inc

; ------------------------------------------------------------------------------
; Export global code refs
;
	global	_MIDI		; Global code references


; ------------------------------------------------------------------------------
; Main code loop to process MIDI bytes read by the service handlers
;
.MIDI	code	0x0400		; Relocatable code for main application
_MIDI:
	banksel	PORTA
	movf	CUR_BYTE,W	; Display last read byte on PORTA
	;movf	BYTE_CNT,W	; Display number of bytes read on PORTA
	;movf	BIT_CNT,W	; Display number of bits read
	;movf	INT_CNT,W	; Number of times the INT interrupt is handled
	;movf	GIE_CNT,W	; Number of times the interrupt service routine is called
	movwf	PORTA

        ;bsf	PORTA,0		; turn on RA0
	;movlw	0x5C
	;movwf	PORTA

	;clrf	PORTA
	;comf	PORTA,F

	goto	_MIDI

	end

