; --- Test for clock speed and instruction ops


; Main entry point

	list	P=PIC16F819

#include p16f819.inc

; ------------------------------------------------------------------------------
; CONFIG
;	- Use internal oscillator, leaing all PORTB ports as I/O
;	- Disable watchdog timer
;
	;__config	_INTRC_IO & _WDT_OFF
	__config	_HS_OSC & _WDT_OFF	; External Crystal Oscillator - produces slightly more than two transistions per second
						; Was able to sucessfully run the chip with only the Xtal directly connected to the
						; OSC1/OSC0 pins, no resistor, no capacitors!

	cblock	0x20		; start addresses in user register space
	W_TMP
	ST_TMP
	CNT1
	CNT2
	CNT3
	endc


; ------------------------------------------------------------------------------
; Main entry and RESET vector
;
	org	0x0000
	call	_SETUP		; Init hardware
	goto	_MAIN		; Jump to main code defined in Example.asm


; ------------------------------------------------------------------------------
; Interrupt vector
;
	org	0x0004
	goto	_SERVICE	; Points to interrupt service routine


; ------------------------------------------------------------------------------
; Dispatcher for interrupt handlers
;
_SERVICE:
	banksel	PORTA
	call	_SAVE_CONTEXT

	; Assumes only one interrupt will be enabled at a time
_CHECK_TMR0:
	;btfsc	INTCON,TMR0IF	; Check for Timer0 interrupt
	;goto	_HANDLE_TMR0
_CHECK_INT:
	;btfsc	INTCON,INTF	; Check for INT/RB0 interrupt
	;goto	_HANDLE_INT

_UNHANDLED:

_EXIT_SERVICE:
	;bcf	INTCON,INTF	; clear the INT interrupt
	;bcf	INTCON,TMR0IF	; clear the TMR0 interrupt

	call	_RESTORE_CONTEXT
	retfie			; Service return


; ------------------------------------------------------------------------------
; Context SAVE/RESTORE routines
;
_SAVE_CONTEXT:
	movwf	W_TMP		;Copy W to TEMP register
	swapf	STATUS, W	;Swap status to be saved into W
	clrf	STATUS		;bank 0, regardless of current bank, Clears IRP,RP1,RP0
	movwf	ST_TMP		;Save status to bank zero STATUS_TEMP register
	return

_RESTORE_CONTEXT:
	SWAPF ST_TMP, W		;Swap STATUS_TEMP register into W
				;(sets bank to original state)
	MOVWF STATUS		;Move W into STATUS register
	SWAPF W_TMP, F		;Swap W_TEMP
	SWAPF W_TMP, W		;Swap W_TEMP into W
	return


; ------------------------------------------------------------------------------
; Initialize hardware
;
_SETUP:
; Init clock to 8Mhz => 111
        banksel OSCCON		; Bank 1, used for all other setup calls
        bsf	OSCCON, IRCF0
        bsf	OSCCON, IRCF1
        bsf	OSCCON, IRCF2

; Init I/O ports
	movlw	0x06		; All digital
	movwf	ADCON1

	movlw	0x00		; PORTA - All output
	movwf	TRISA

	movlw	0x01		; PORTB - Input only on RB0
	movwf	TRISB

; Configure interrupts
	bcf	INTCON,GIE	; Disable interrupts globally

; Init and Clear PORTA
	banksel	PORTA
	clrf	PORTA
	;bsf	PORTA,0		; turn on RA0
	;comf	PORTA		; turn on all bits

	clrf	CNT1
	clrf	CNT2
	clrf	CNT3
	return

; ------------------------------------------------------------------------------
; Main code loop
;
;	Total ops between ecah comf should be:
;		256 * (256 * 4 - 1) + 256 * 4 - 1 + 2 + 2
;		257 * (256 * 4 - 1) + 4
;		262,915 ops
;
_MAIN:
	; 2 ops
	banksel	PORTA
	comf	PORTA,F

_CNT1:	; Executes 256 * (4+26) - 1ops
	incf	CNT1,F

	; 26 NOP's to round out to 2M ops
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	btfss	STATUS,Z
	goto	_CNT1

	;movfw	CNT2
	;movw	PORTA

	; Executes CNT1 256 times, plus 256*4-1
	incf	CNT2,F
	btfss	STATUS,Z
	goto	_CNT1

	; 2 ops
	goto	_MAIN
	end