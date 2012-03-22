; --- Midi read, without interrupts; 8MHz internal clocking
; At 8MHz/4 instructions per second, that gives 64 instructions between each MIDI bit
; MIDI has 10 bits per transmitted byte, which includes 8 data bits, a stop bit, and a start bit

; Main entry point

	list	P=PIC16F819

#include p16f819.inc

; ------------------------------------------------------------------------------
; CONFIG
;	- Use internal oscillator, leaing all PORTB ports as I/O
;	- Disable watchdog timer
;
	__config	_INTRC_IO & _WDT_OFF


; ------------------------------------------------------------------------------
; Variables and Constants
;
MIDI	equ	h'00'		; RB0 is MIDI IN - note this is inverted logic (1 is a 0)

	cblock	0x20		; start addresses in user register space
	W_TMP
	ST_TMP
	CNT_START_BIT		; Counts the number of start bits detected
	CNT_BITS		; Counts working bits for each transmitted byte
	TMP_BYTE		; Working byte
	LAST_BYTE		; Last completed byte
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

; Clear variables
	clrf	CNT_START_BIT
	clrf	CNT_BITS
	clrf	TMP_BYTE
	clrf	LAST_BYTE
	return

; ------------------------------------------------------------------------------
; Main code loop
;
_MAIN:
	banksel	PORTA
	;movf	CNT_START_BIT,W	; Display number of start bits encountered
	movf	LAST_BYTE,W
	movwf	PORTA

	btfsc	PORTB,MIDI	; Wait for start bit of 0
	goto	_MAIN
	
_START_BIT:
	incf	CNT_START_BIT,F
	clrf	TMP_BYTE

	; Burn 10 bits @ 64 ops each
	movlw	0x0A
	movwf	CNT_BITS

_CHECK_BIT_COUNT:
	decf	CNT_BITS,F
	btfsc	STATUS,Z
	goto	_STOP_BIT
_READ_BIT:			; The fisrt time this reads in the start bit
	bcf	STATUS,C	; Make sure we read in a 0
	rrf	TMP_BYTE
	btfss	PORTB,MIDI
	goto	_WAIT_FOR_NEXT_BIT
	bsf	TMP_BYTE,7
_WAIT_FOR_NEXT_BIT:		; We need to pad out the loop to get back to 32 uS 64 ops = 10 + 54 nop's
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
	nop
	nop
	goto	_CHECK_BIT_COUNT

_STOP_BIT:
	movf	TMP_BYTE,W
	movwf	LAST_BYTE
;	goto	_MAIN

_HOLD:
	movf	LAST_BYTE,W	; grab and display only the first byte sent
	movwf	PORTA
	goto _HOLD

	end