; Interrupt service handlers

	LIST   P=PIC16F819

#include p16f819.inc
#include inc/vars.inc

; ------------------------------------------------------------------------------
; Export global code refs
;
	global	_SERVICE		; Global code references


; ------------------------------------------------------------------------------
; Dispatcher for interrupt handlers
;
.SERVICE	code	; Relocatable code for interrupt handler
_SERVICE:
	banksel	PORTA
	call	_SAVE_CONTEXT
; 11 OPS
	;movf	INTCON,W
	;bcf	INTCON,TMR0IF
	;bcf	INTCON,INTF
	;movwf	TMP_INTCON

	incf	GIE_CNT,F	; Count the number of interrupts
	;movf	GIE_CNT,W	; Number of times the interrupt service routine is called
	;movwf	PORTA
	;goto	_EXIT_SERVICE	; Simply count the number of high to low transitions (i.e. 0 to 1 transitions)

	; Assumes only one interrupt will be enabled at a time
;_CHECK_TMR0:
;	btfss	TMP_INTCON,TMR0IE	; Is Timer0 enabled?
;	goto	_CHECK_INT
;	btfsc	TMP_INTCON,TMR0IF	; Check for Timer0 interrupt
;	goto	_HANDLE_TMR
_CHECK_TMR2:
	;banksel	PIR1
	btfsc	PIR1,TMR2IF	; Check for Timer2 interrupt
	goto	_HANDLE_TMR
_CHECK_INT:
	;btfss	INTCON,INTE	; Is INT enabled?
	;goto	_UNHANDLED
	btfsc	INTCON,INTF	; Check for INT/RB0 interrupt
	goto	_HANDLE_INT

_UNHANDLED:

_EXIT_SERVICE:
	;banksel	PIR1
	;bcf	INTCON,INTF	; clear the INT interrupt
	;bcf	INTCON,TMR0IF	; clear the TMR0 interrupt
	;bcf	PIR1,TMR2IF	; Clear TMR2 interrupt

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
; Handler for INT/RB0 interrupt
;
_HANDLE_INT:
	banksel	PORTA

	;incf	INT_CNT,F	; Count handled INT interrupts before checking flags

	btfsc	READING_BITS,0	; Check bit 0 to see if flag is set
	goto	_INT_CLEANUP

; Ensure we have a valid start bit (0)
; We seem to need this since having the timer enabled casues false INT interrupts
	btfsc	PORTB,MIDI	; Read the current MIDI bit
	goto	_INT_CLEANUP	; If bit is not 0, exit handler

	;movlw	0xDD		; Reset Timer0 for 64 ops - 29
	;movlw	0x7D		; Reset Timer0 for 160 ops - 29
	;movwf	TMR0

	;bcf	INTCON,TMR0IF	; clear the TMR0 interrupt

	;bcf	INTCON,INTE	; Disable interrupt on RB0 while bits are being read

	;bcf	INTCON,TMR0IF	; clear the TMR0 interrupt
	;bsf	INTCON,TMR0IE	; Enable Timer0 interrupt to read bits

	movlw	0x09		; Setup handler to read 9 bits (8 data and one stop bit)
	movwf	TMR0_CNT
	clrf	TMP_BYTE	; Reset temp byte
	bsf	READING_BITS,0	; Inidicate that we are now reading bits


	incf	INT_CNT,F	; Count handled INT interrupts

	clrf	TMR2		; Reset Timer2 <<- This is critical to ensure timing is accurate!

	;banksel	PIR1
	;bcf	PIR1,TMR2IF	; Clear TMR2 interrupt

	bsf	T2CON, TMR2ON	; Enable Timer2


	;clrf	BIT_CNT

	;bsf	PORTA,0		; ### Turn on bit read light

;	goto	_INT_CLEANUP
;
;	incf	INT_CNT,F	; Update INT light
;	btfss	INT_CNT,0
;	goto	_CLEAR_INT
;        bsf	PORTA,1		; turn on RA1
;	goto	_INT_CLEANUP
;_CLEAR_INT:
;	bcf	PORTA,1

_INT_CLEANUP:
	bcf	INTCON,INTF	; clear the INT interrupt
	goto	_EXIT_SERVICE


; ------------------------------------------------------------------------------
; Handler for bit Timer interrupt
;
_HANDLE_TMR:
	banksel	PORTA

	btfss	READING_BITS,0	; Check bit 0 to see if flag is set
	goto	_TMR_CLEANUP

	;movlw	0xDA		; Reset Timer0 for 64 ops - 26
	;movlw	0x7A		; Reset Timer0 for 160 ops - 26
	;movwf	TMR0

	;movf	PORTB,W		; Grab the current MIDI input value right away
	;movwf	MIDI_TMP

	;bcf	INTCON,INTF	; clear the INT interrupt
	;bcf	INTCON,TMR0IF	; clear the TMR0 interrupt
	decf	TMR0_CNT,F
	btfsc	STATUS,Z	; Check to see if this was the stop bit
	goto	_KILL_TIMER

	;bcf	INTCON,INTF	; clear the INT interrupt
				; This must be cleared at this point, as if we clear it
				; before KILL_TIMER is called, we may 'miss' the trigger
				; for the next byte.  We need to call it, as there are some
				; transitions while the timer is going that the interrupt is
				; still fired. A faster clock speed (above 8MHz) may help this.

	; Read the current bit into TMP_BYTE
	bcf	STATUS,C	; Ensure carry is cleared
	rrf	TMP_BYTE,F	; rotate and add the new bit into TMP_BYTE
	btfsc	PORTB,MIDI	; Read the current MIDI bit
	bsf	TMP_BYTE,7

	incf	BIT_CNT,F	; Increment bit counter

;	btfss	TMR0_CNT,0
;	goto	_CLEAR_TMR0
;	bsf	PORTA,0
;	goto	_TMR0_CLEANUP
;_CLEAR_TMR0:
;	bcf	PORTA,0

_TMR_CLEANUP:
	banksel	PIR1
	bcf	PIR1,TMR2IF	; Clear TMR2 interrupt
	goto	_EXIT_SERVICE

_KILL_TIMER:
	;bcf	INTCON,INTF	; clear the INT interrupt
	;bcf	INTCON,TMR0IE	; Disable Timer0 interrupt
	;banksel	PIR1
	;bcf	PIR1,TMR2IF	; Clear TMR2 interrupt

	bcf	T2CON, TMR2ON	; Disable Timer2
	;clrf	TMR2		; Reset Timer2
	bcf	READING_BITS,0	; Inidicate that we are no longer reading bits


	;bsf	INTCON,INTE	; Enable interrupt on RB0

	incf	BYTE_CNT,F

	movf	TMP_BYTE,W	; Publish the built up byte to CUR_BYTE which can be consumed externally
	movwf	CUR_BYTE

	;movlw	0x19		; Test value
	;movwf	CUR_BYTE

	;bcf	PORTA,0		; ### Turn off read light

	goto	_TMR_CLEANUP
	end
