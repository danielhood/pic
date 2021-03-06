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
	CLOCKVAL
	ADVAL
	SAMPDONE
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
_CHECK_ADI:
	btfsc	PIR1,ADIF
	goto	_HANDLE_ADI

_UNHANDLED:

_EXIT_SERVICE:
	;bcf	INTCON,TMR0IF	; clear the TMR0 interrupt
	call	_RESTORE_CONTEXT
	retfie			; Service return


_HANDLE_INT:
	banksel	CLOCKVAL
	decfsz	CLOCKVAL,F
	goto	_HANDLE_INT_END
	; Reset to 64
	movlw	0x40
	movwf	CLOCKVAL
_HANDLE_INT_END:
	bcf	INTCON,INTF	; clear the INT interrupt
	goto	_EXIT_SERVICE

_HANDLE_ADI:
	banksel ADRESH		; Copy current AD conversion to CURVAL
	movfw	ADRESH

	banksel ADVAL
	movwf	ADVAL
	bcf	PIR1,ADIF	; clear ADI
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
	banksel	PIE1
	bsf	PIE1,ADIE	; Enable AD conversion interrupt
	banksel	INTCON
	bsf	INTCON,INTE	; Enable external int on RB0
	bsf	INTCON,PEIE	; Enable periferial interrups for ADI
	bsf	INTCON,GIE	; Enable interrupts globally

	bcf	PIR1,ADIF	; clear ADI

; Configure External interrupt
	banksel	OPTION_REG
	movlw	0xC0		; Rising edge
	movwf	OPTION_REG

; Init and Clear PORTA and PORTB
	banksel	PORTA
	clrf	PORTA
	clrf	PORTB

	banksel	CNT1
	clrf	CNT1
	clrf	CNT2
	clrf	CNT3

	; Init to 64 steps
	movlw	0x40
	movwf	CLOCKVAL

	clrf	ADVAL
	clrf	SAMPDONE
	bsf	SAMPDONE,0	; Trigger sampling on start



;Setup AD Conversion on A0 for now
	banksel	ADCON0
	movlw	0x81	; AD Enabled on A0, 32Tosc clock
	movwf	ADCON0

	banksel	ADCON1
	movlw	0x00	; left justify since we're only going to read ADRESH for now
	movwf	ADCON1

	return

; -------
; Subs
;

_RB4_CLR:
	bcf	PORTB,4
	;goto	_INIT_CNT1
	goto	_RB4_CLR_RET

_RB5_CLR:
	bcf	PORTB,5
	goto	_RB5_CLR_RET

_START_SAMPLE:
	banksel	ADCON0
	bsf	ADCON0,2	; Start Sampling
			; End will be handled by interrupt
	banksel	SAMPDONE
	clrf	SAMPDONE
	goto	_INIT_CNT1


; ------------------------------------------------------------------------------
; Main code loop
;
; RB4 drives LED
; RB0 clock input
;

_MAIN:


_LOOP:

_UPDATE_RB4:
	nop
	banksel CLOCKVAL
	btfss	CLOCKVAL,0	; Clock Counter
	goto	_RB4_CLR
	bsf	PORTB,4

_RB4_CLR_RET:
	;goto _UPDATE_RB4

	banksel ADVAL
	movfw	ADVAL		; AD Sample
	;banksel PORTB
	;movwf	PORTB		; Dump the value onto Port B

	banksel	CNT1
	sublw	0xFE		; Light up RB5 if ADVAL > literal
	btfsc	STATUS,C	; Skip if borrow (inverted carry)
	goto	_RB5_CLR	; no borrow -> ADVAL <= literal
	bsf	PORTB,5		; borrow -> ADVAL > literal

_RB5_CLR_RET:
	;banksel	PORTB		; Toggle RB4
	;btfsc	PORTB,4
	;goto	_RB4_CLR
	;bsf	PORTB,4

_CHECK_SAMPLE:
	btfsc	SAMPDONE,0
	goto	_START_SAMPLE
	btfsc	ADCON0,2
	goto	_INIT_CNT1
	bsf	SAMPDONE,0	; Signal that sampling is done so that next loop we can restart sampling

	;banksel ADRESH		; Copy current AD conversion to CURVAL
	;movfw	ADRESH

	;banksel	CURVAL
	;movlw	0xff
	;movwf	CURVAL


_INIT_CNT1:
	banksel	CNT1		
	movlw	0xFF		; Load counter
	movwf	CNT1
	
_CNT1:	
	decfsz	CNT1,F
	goto	_INIT_CNT2
	goto	_END

_INIT_CNT2:
	banksel	CNT2
	movlw	0x80		; Load counter
	movwf	CNT2

_CNT2:
	decfsz	CNT2,F
	goto	_INIT_CNT3
	goto	_CNT1

_INIT_CNT3:
	banksel	CNT3
	movlw	0x01		; Load counter
	movwf	CNT3

_CNT3:
	decfsz	CNT3,F
	goto	_CNT3
	goto	_CNT2

_END:
	;bcf	PORTB,4
	goto	_LOOP

_ENDLESSLOOP:
	nop
	goto	_ENDLESSLOOP
	end
