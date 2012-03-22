; Main entry point

; ------------------------------------------------------------------------------
;	Test to flash the RB0 and RB5 outs to see if the hardware and programmer
;	is working.
;

#include p18f2431.inc

; ------------------------------------------------------------------------------
; External code refs
;
	extern	_MAIN		; Main App code
	extern	_SERVICE_HI	; Interrupt handlers
	extern	_SERVICE_LO
	extern	_SETUP		; Setup code

; ------------------------------------------------------------------------------
; Main entry and RESET vector
;
.RIVEC	org	0x0000
	call	_SETUP		; Init hardware
	goto	_MAIN		; Main app code


; ------------------------------------------------------------------------------
; High-Priority Interrupt Vector
;
.HIVEC	org	0x0008
	goto	_SERVICE_LO	; Points to interrupt service routine

; ------------------------------------------------------------------------------
; Lo-Priority Interrupt Vector
;
.LIVEC	org	0x0018
	goto	_SERVICE_HI	; Points to interrupt service routine


	end