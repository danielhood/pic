; Main entry point

	list	P=PIC16F819

#include p16f819.inc
#include inc/vars.inc

; ------------------------------------------------------------------------------
; External code refs
;
	extern	_MIDI		; MIDI processing entry point (main app loop)
	extern	_SERVICE	; Interrupt handler entry point


; ------------------------------------------------------------------------------
; CONFIG
;	- Use 20MHz crystal, leaing all PORTB ports as I/O
;	- Disable watchdog timer
;
	;__config	_INTRC_IO & _WDT_OFF	; Internal oscillator
	__config	_HS_OSC & _WDT_OFF & _BOREN_OFF & _PWRTE_ON	; 20MHz crystal (directly tied to OSC pins)

; ------------------------------------------------------------------------------
; Main entry and RESET vector
;
.RESET	org	0x0000
	call	_SETUP		; Init hardware
	goto	_MIDI		; Jump to main code defined in Example.asm


; ------------------------------------------------------------------------------
; Interrupt vector
;
.IVEC	org	0x0004
	goto	_SERVICE	; Points to interrupt service routine
	banksel	PORTA
	incf	GIE_CNT,F
	bcf	INTCON,INTF	; clear the INT interrupt
	retfie

; ------------------------------------------------------------------------------
; Initialize hardware
;
_SETUP:
; Init clock to 8Mhz => 111 <-- not needed when using crystal osc
        ;banksel OSCCON		; Bank 1, used for all other setup calls
        ;bsf	OSCCON, IRCF0
        ;bsf	OSCCON, IRCF1
        ;bsf	OSCCON, IRCF2

; Init I/O ports
	banksel ADCON1
	movlw	0x06		; All digital
	movwf	ADCON1

	movlw	0x00		; PORTA - All output
	movwf	TRISA

	movlw	0x01		; PORTB - Input only on RB0
	movwf	TRISB

; Configure interrupts
	bsf	INTCON,INTE	; Enable interrupt on RB0
	bcf	OPTION_REG,INTEDG	; Tigger on falling edge

	;bcf	INTCON,TMR0IE	; Enable Timer0 interrupt (enabled in INT handler)
	;bcf	OPTION_REG,T0CS	; Use internal clock for Timer0
	;bsf	OPTION_REG,PSA	; Disable prescaler on Timer0
	;bsf	OPTION_REG,PS0	; Set pr`escaler to 1:256 => 111
	;bsf	OPTION_REG,PS1
	;bsf	OPTION_REG,PS2

	bsf	PIE1,TMR2IE	; Enable Timer2 interrupts
	movlw	0xA0		; Set period to 160 instructions (no post/pre scaler)
	movwf	PR2
	banksel	TMR2		; Bank0
	clrf	TMR2		; Reset Timer
	;bsf	T2CON,TMR2ON	; Enable Timer2, with no pre or postscale
	bcf	T2CON,TMR2ON	; Start with Timer2 disabled, enabled by INT


; Init and Clear PORTA
	banksel	PORTA
	clrf	PORTA		
	;bsf	PORTA,0		; turn on RA0
	;comf	PORTA		; turn on all bits

	clrf	CUR_BYTE	; Clear CUR_BYTE
	clrf	BYTE_CNT	; Clear BYTE_CNT
	clrf	BIT_CNT
	clrf	INT_CNT
	clrf	GIE_CNT
	clrf	TMP_BYTE
	clrf	READING_BITS

; Clear then Enable Interrupts
	banksel	PIR1
	bcf	PIR1,TMR2IF	; Clear TMR2 interrupt
	bcf	INTCON,INTF	; clear the INT interrupt

	bsf	INTCON,GIE	; Enable interrupts globally
	bsf	INTCON,PEIE	; Enable interrupts globally

	return

	end