#include p18f2431.inc
#include inc/vars.inc

; ------------------------------------------------------------------------------
; Export global code refs
;
	global	_SETUP


; ------------------------------------------------------------------------------
; Setup routine
;
.SETUP	code			; Relocatable code for setup
_SETUP:
; Init I/O ports
	movlw	0x00		; All Digital I/O on PORTA
	movwf	ANSEL0

	movlw	0x00		; PORTA - All output
	movwf	TRISA

	movlw	0x00		; PORTB - All output
	movwf	TRISB

	movlw	0x00		; PORTC - All output
	movwf	TRISC

	return

	end

