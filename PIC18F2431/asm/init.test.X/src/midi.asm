; MIDI Processing Routines (Main code loop)

#include p18f2431.inc
#include inc/vars.inc

; ------------------------------------------------------------------------------
; Export global code refs
;
	global	_MAIN

; ------------------------------------------------------------------------------
; Main code
;
.MAIN	code			; Relocatable code for main application
_MAIN:
	movlw	0xFF
	movwf	PORTA

	movlw	0xF0
	movwf	PORTB

	movlw	0xFF
	movwf	PORTC

	goto	_MAIN

	end


