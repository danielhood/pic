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
	CURVAL
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
	btfsc	INTCON,INTF	; Check for INT/RB0 interrupt
	goto	_HANDLE_INT

_UNHANDLED:

_EXIT_SERVICE:
	bcf	INTCON,INTF	; clear the INT interrupt
	;bcf	INTCON,TMR0IF	; clear the TMR0 interrupt

	call	_RESTORE_CONTEXT
	retfie			; Service return


_HANDLE_INT:
	banksel	CURVAL
	decfsz	CURVAL,F
	goto	_EXIT_SERVICE
	; Reset to 64
	movlw	0x40
	movwf	CURVAL
	goto	_EXIT_SERVICE


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
        ;banksel OSCCON		; Bank 1, used for all other setup calls
        ;bsf	OSCCON, IRCF0
        ;bsf	OSCCON, IRCF1
        ;bsf	OSCCON, IRCF2

; Init I/O ports
	banksel	ADCON1
	movlw	0x00		; 0:4 Analog
	movwf	ADCON1

	banksel	TRISA
	movlw	0xFF		; PORTA - All input
	movwf	TRISA

	banksel	TRISB
	movlw	0x01		; PORTB - Input only on RB0
	movwf	TRISB

; Configure interrupts
	banksel	INTCON
	bsf	INTCON,GIE	; Enable interrupts globally

; Init and Clear PORTA
	banksel	PORTA
	clrf	PORTA

	banksel	CNT1
	clrf	CNT1
	clrf	CNT2
	clrf	CNT3

	; Init to 64 steps
	movlw	0x40
	movwf	CURVAL
	return

; ------------------------------------------------------------------------------
; Main code loop
;
; RB4 drives LED
; RB0 clock input
;

_MAIN:
	banksel	PORTA
	;comf	PORTA,F
	clrf	CURVAL

_LOOP:
	; Update RB4
	banksel	PORTB
	btfsc	PORTB,4
	goto	_RB4_CLR
	goto	_RB4_SET
_RB4_CLR:
	bcf	PORTB,4
	goto	_INIT_CNT
_RB4_SET:
	bsf	PORTB,4

_INIT_CNT:
	; Load counters
	banksel	CNT1
	movlw	0xFF
	movwf	CNT1
	movwf	CNT2
	movwf	CNT3
	
_CNT1:	
	decfsz	CNT1,F
	goto	_CNT1
	
_CNT2:
	decfsz	CNT2,F
	goto	_CNT2

_CNT3:
	decfsz	CNT3,F
	goto _CNT3

	goto	_LOOP
	end
