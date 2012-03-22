#include <p16f819.inc>

; Configuration Requirements
; (note PIC16 uses __CONFIG, PIC18 ues CONFIG
;	- internal clock to 31.25kHz (default)
;       - watch dog timer off (otherwise app won't start)
    __CONFIG    _INTRC_IO & _WDT_OFF
;__CONFIG    _HS_OSC & _WDT_OFF
;__CONFIG    0x3FF8

	cblock	0x20	; start addresses in user register space
	Delay:2	; array of two bytes - Delay+0 and Delay+1
	endc

	org	0x0000
_STARTUP:
	;pagesel	_MAIN
	goto	_MAIN

	org 0x004		; interrupt vectors
	; no iv's defined

_MAIN:
        ; Set Internal Oscillator to max frequency (8Mhz => 111)
        banksel OSCCON
        bsf     OSCCON, IRCF0
        bsf     OSCCON, IRCF1
        bsf     OSCCON, IRCF2

	; Configure PORTA
	banksel	PORTA	; Init and Clear PORTA
	clrf	PORTA
        comf	PORTA,1	; compliment PORTA

	movlw	0x06	; All digital
	banksel	ADCON1
	movwf	ADCON1

	movlw	0x00	; All output
	banksel	TRISA	; This isn't needed since bank is already set by ADCON1
	movwf	TRISA

_DELAY_START:
	; Reset 1 second Delay and decrement
	banksel	Delay
	;movlw	0x79	; 121 multiplier
        movlw	0xFF	; 255 multiplier
	movwf	Delay+1	;

_DELAY_LOOP:
	incfsz	Delay,1	; 256 instructions (+3)
	goto	_DELAY_LOOP	; 258 / 31250 = 0.008256s
	decfsz	Delay+1,1	; 121 * 0.008256s = about 1s
	goto	_DELAY_LOOP

_TOGGLE:	; Flip state of all bits on PORTA
	banksel	PORTA
	comf	PORTA,1	; compliment PORTA
	goto	_DELAY_START	; loop forever

	end


