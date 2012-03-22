; Interrupt service handlers

#include p18f2431.inc
#include inc/vars.inc

; ------------------------------------------------------------------------------
; Export global code refs
;
	global	_SERVICE_HI
	global	_SERVICE_LO


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
_SERVICE_LO:
	retfie

_SERVICE_HI:
	retfie


	end


