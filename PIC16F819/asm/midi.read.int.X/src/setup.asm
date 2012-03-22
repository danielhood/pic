; Interrupt service handlers

	LIST   P=PIC16F819

#include p16f819.inc
#include inc/vars.inc

; ------------------------------------------------------------------------------
; Export global code refs
;
	global	_SETUP


; ------------------------------------------------------------------------------
; Initialize hardware
;
.SETUP	code			; Relocatable code for setup
_SETUP:	

; Init I/O ports
	banksel ADCON1
	movlw	0x06		; All digital
	movwf	ADCON1

	movlw	0x00		; PORTA - All output
	movwf	TRISA

	movlw	0x01		; PORTB - Input only on RB0
	movwf	TRISB		; Note RB2 is CV out.  PWM period set by TMR2,
				; which can't be changed since this also drives
				; the syncing for the MIDI input. Should be enough for about
				; 8 bits of resoultion, which should be more than enough for a 0 to 127 control range.
				
	banksel	CCP1CON		; Bank0
	movlw	b'00001111'	; Init the two LSB bits of RB2 to 0
	movwf	CCP1CON		; and enable PWM mode
	clrf	CCPR1L		; 
	;movlw	CLK		; Max value of 160 (clock cycle) - with the two LSB's set
	;movwf	CCPR1L		; represents the max voltage (5v). Min voltage is all at 0
				; TODO: consturcut a lookup table for the 128 CCPR1L and CCP1CON values

; Configure interrupts
	banksel	OPTION_REG	; Bank1
	bsf	INTCON,INTE	; Enable interrupt on RB0
	bcf	OPTION_REG,INTEDG	; Tigger on falling edge

	bsf	PIE1,TMR2IE	; Enable Timer2 interrupts
	movlw	CLK		; Set period to 160 instructions (no post/pre scaler)
	movwf	PR2		; Based on 20MHz clock
	banksel	T2CON		; Bank0
	;bcf	T2CON,TMR2ON	; Start with Timer2 disabled, enabled by INT
	bsf	T2CON,TMR2ON	; Keep Timer2 enabled: since this will drive the PWM period for the CV out

; Init and Clear PORTA
	banksel	PORTA
	clrf	PORTA

	clrf	CUR_BYTE
	clrf	BIT_READ_FLAGS

	clrf	BYTE_COUNT

; Clear then Enable Interrupts
	banksel	PIR1
	bcf	PIR1,TMR2IF	; Clear TMR2 interrupt
	bcf	INTCON,INTF	; clear the INT interrupt

	bsf	INTCON,GIE	; Enable interrupts globally
	bsf	INTCON,PEIE	; Enable interrupts globally

	return

	end


