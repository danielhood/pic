; Interrupt service handlers

	LIST   P=PIC16F819

#include p16f819.inc
#include inc/vars.inc

; ------------------------------------------------------------------------------
; Export global code refs
;
	global	_SERVICE


; ------------------------------------------------------------------------------
; Local Constants

MIDI:		equ	h'00'	; MIDI input on RB0


; ------------------------------------------------------------------------------
; Context SAVE/RESTORE macros
;
_SAVE_CTX	macro
	movwf	W_TMP		;Copy W to TEMP register
	swapf	STATUS, W	;Swap status to be saved into W
	clrf	STATUS		;bank 0, regardless of current bank, Clears IRP,RP1,RP0
	movwf	ST_TMP		;Save status to bank zero STATUS_TEMP register
	endm

_RESTORE_CTX	macro
	SWAPF ST_TMP, W		;Swap STATUS_TEMP register into W
				;(sets bank to original state)
	MOVWF STATUS		;Move W into STATUS register
	SWAPF W_TMP, F		;Swap W_TEMP
	SWAPF W_TMP, W		;Swap W_TEMP into W
	endm


; ------------------------------------------------------------------------------
; Dispatcher for interrupt handlers
;
.SERVICE	code	; Relocatable code for interrupt handler
_SERVICE:
	banksel	PORTA
	_SAVE_CTX

; Assumes only one interrupt will be enabled at a time
_CHECK_TMR:
	btfsc	PIR1,TMR2IF	; Check for Timer2 interrupt
	goto	_HANDLE_TMR
_CHECK_INT:
	btfsc	INTCON,INTF	; Check for INT/RB0 interrupt
	goto	_HANDLE_INT

_EXIT_SERVICE:
	_RESTORE_CTX
	retfie			; Service return



; ------------------------------------------------------------------------------
; Handler for INT/RB0 interrupt
;
_HANDLE_INT:
	banksel	PORTA
	btfsc	BIT_READ_FLAGS,READING	; Check bit 0 to see if flag is set
	goto	_INT_CLEANUP

; Ensure we have a valid start bit (0)
; We seem to need this since having the timer enabled casues false INT interrupts
	btfsc	PORTB,MIDI	; Read the current MIDI bit
	goto	_INT_CLEANUP	; If bit is not 0, exit handler

; Switch to bit reading mode
	movlw	0x09		; Setup handler to read 9 bits (8 data and one stop bit)
	movwf	BITS_READ	; Start bit is skipped
	clrf	TMP_BYTE	; Reset temp byte
	bsf	BIT_READ_FLAGS,READING	; Inidicate that we are now reading bits

	clrf	TMR2		; Reset Timer2 <<- This is critical to ensure timing is accurate!
	;bsf	T2CON, TMR2ON	; Enable Timer2

_INT_CLEANUP:
	bcf	INTCON,INTF	; clear the INT interrupt
	goto	_EXIT_SERVICE


; ------------------------------------------------------------------------------
; Handler for bit Timer interrupt
;
_HANDLE_TMR:
	banksel	PORTA
	btfss	BIT_READ_FLAGS,READING	; Check bit 0 to see if flag is set
	goto	_TMR_CLEANUP

; Check to see if we've reached the stop bit
	decf	BITS_READ,F
	btfsc	STATUS,Z	
	goto	_KILL_TIMER

	; Read the current bit into TMP_BYTE
	bcf	STATUS,C	; Ensure carry is cleared
	rrf	TMP_BYTE,F	; rotate and add the new bit into TMP_BYTE
	btfsc	PORTB,MIDI	; Read the current MIDI bit
	bsf	TMP_BYTE,7
	goto	_TMR_CLEANUP

_KILL_TIMER:
	;bcf	T2CON, TMR2ON	; Disable Timer2
	bcf	BIT_READ_FLAGS,READING	; Inidicate that we are no longer reading bits

	movf	TMP_BYTE,W	; Publish the built up byte to CUR_BYTE which can be consumed externally
	movwf	CUR_BYTE

	bsf	BIT_READ_FLAGS,NEW_BYTE	; Signal that a new byte is avaialble. We may need to implement a FIFO queue if we can't process the stream of bytes fast enough.

_TMR_CLEANUP:
	banksel	PIR1
	bcf	PIR1,TMR2IF	; Clear TMR2 interrupt
	goto	_EXIT_SERVICE


	end
