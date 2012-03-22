#include <p16f819.inc>


; Configuration Requirements
; (note PIC16 uses __CONFIG, PIC18 ues CONFIG
;	- internal clock
;       - watch dog timer off (otherwise app won't start)
    __CONFIG    _INTRC_IO & _WDT_OFF
;   __CONFIG    _HS_OSC & _WDT_OFF

MIDI:   equ h'0';               ; MIDI In is connected to B0
BYTE:   equ h'20'		;Temporary MIDI data storage
CHANNEL:equ h'21'		;Working MIDI channel
TEMP1:  equ h'22'               ;temporary data manipulation storage file 1
TEMP2:	equ h'23'		;temporary data manipulation storage file 2
SCRATCHNOTE:	equ h'24'	;Stores the value of any note that is to be deleted from stack
LASTSTATUSBYTE: equ h'25'	;Stores the last status byte received, *if processed*- needed for Running Status support.
NOTESP:	equ h'26'	 	;Note Stack Pointer
NOTESTACK:  equ h'27'				;<<< 10 byptes (27h to 31h) reserved for note stack >>>

	cblock	0x20	; start addresses in user register space
	Delay:2	; array of two bytes - Delay+0 and Delay+1

	endc

	org	0x0000
_STARTUP:
	;pagesel	_MAIN
	goto	_MAIN

	org 0x004		; interrupt vectors
	; no iv's defined

_MAIN:
        ; Set Internal Oscillator to 4Mhz => 110
        banksel OSCCON
        ;bsf     OSCCON, IRCF0
        bsf     OSCCON, IRCF1
        bsf     OSCCON, IRCF2

	; Configure PORTA
	banksel	PORTA	; Init and Clear PORTA
	clrf	PORTA
        comf    PORTA,F   ; Flip on

	movlw	0x06	; All digital
	banksel	ADCON1
	movwf	ADCON1

	movlw	0x00	; All output
	banksel	TRISA	; This isn't needed since bank is already set by ADCON1
	movwf	TRISA
        banksel PORTA

        clrf    BYTE    ; Set BYTE to 0

simple_read:                    ; This routine just tests to see if we're getting any bit data on the MIDI port
        movlw b'00000001'       ; set RB0 as read
        banksel TRISB
        movwf   TRISB
        banksel PORTB
wait_for_start_bit:
        btfsc   PORTB,MIDI      ; Normal state is high, so start bit will be read as a 0
        goto    wait_for_start_bit
wait_for_bit_change:
        btfss   PORTB,MIDI      ; Wait for input to go high again
        goto    wait_for_bit_change
        incf    BYTE,F          ; Increment counter
        movf    BYTE,W            ; Write current value to PORTA
        movWf   PORTA
        goto    wait_for_start_bit

start:                          ;***System waiting for a new MIDI message***
	;bsf PORTA,1		;Port A bit 1 must always be returned to high, as it is changed to 0 to write data.
        call getByte		;Get the first MIDI byte for the new message
        BSF SCRATCHNOTE,7	;Will have been made use of by now and must be disabled. Makes sure that SCRATCNOTE
	BSF SCRATCHNOTE,6	;holds an invalid note value.

        ;push the byte to port A for now to simply display retrieved data
        movf BYTE,W
        movwf PORTA
        goto start

processFirstByte:               ;***Process the Status Byte***
				;!!!This subroutine manipulates the contents of BYTE!!!
	btfss BYTE,7		;If the MSB in the byte is 0, it must be Running Status information. Branch accordingly
	goto processRunningStatus 	;to processRunningStatus.
				;
	movf BYTE,W		;
	movwf TEMP2		;Keep a record of this status byte- may be needed later for running status support.
				;A record is kept of it only if this version can handle the particular message type.
				;Iff so, the status byte is recorded from TEMP2 into LASTSTATUSBYTE in the respective
				;message handling routine.
				;
	andlw b'11110000'	;Check to see if the received status byte is a system message, or the start of a
	xorlw b'11110000'	;2 or 3 byte system message. If so, handleSystemMessage is CALLED to deal with the
	btfss STATUS,Z		;system message. Once the system message has been dealt with, the program returns
;	goto getchan		;back to here...
;	call handleSystemMessage;
	goto start		;...and a jump is then made back to start.


processRunningStatus:		;***Process data bytes that have been sent without a status byte***
	movf LASTSTATUSBYTE,W	;Must move the last status byte into TEMP1 for manipulation. No manipulation is to
	movwf TEMP1		;be done with BYTE here- it carries data and that data is to be dealt with in the
				;appropriate section.
				;
	movlw b'00001111'       ;Extract channel number from *last received* Status Byte.
        andwf TEMP1,W		;
        xorwf CHANNEL,W         ;Branch back to start if wrong channel.
        btfss STATUS,Z		;
        goto start		;
        swapf TEMP1,F           ;Otherwise swap nybbles in Status Byte and
	movlw b'00001111'	;extract the Message Type.
        andwf TEMP1,F           ;
        movf TEMP1,W            ;Branch to appropriate message handling
        addwf PCL,F             ;routine according to the type of message.
        goto start		;0000 - keep this here- will be accessed if LASTSTATUSBYTE contains the null value, 0.
	nop			;
	nop			;
	nop			;***ALL NOPs ESSENTIAL FOR CORRECT LOOKUP TABLE OPERATION***
        nop			;
	nop			;
	nop			;
	nop			;
        goto handleRunningStatusNoteOff      ;1000   note off
        goto handleRunningStatusNoteOn       ;1001   note on
        goto start              	     ;1010   poly key pressure
        goto handleRunningStatusController   ;1011   control change
        goto start              	     ;1100   program change
        goto start                  	     ;1101   overall key pressure
        goto start              	     ;1110   pitch wheel
        goto start              	     ;1111   SYSTEM MESSAGES- not currently implemented.

handleRunningStatusNoteOff:
    goto start

handleRunningStatusNoteOn:
    goto start

handleRunningStatusController:
    goto start


getByte:			;*****RECEIVE SINGLE MIDI BYTE*****
waitForIdle:                    ;***This subroutine also deals with NoteStack updating and channel switch checking***
        btfss PORTB,MIDI           ;Make sure input is 1 first
        goto waitForIdle	;
waitForStartBit:                ;Wait for start bit of MIDI byte (low pulse)
        btfsc PORTB,MIDI           ;
        goto waitForStartBit	;
        bcf STATUS,C            ;initial setup
        movlw b'10000000'       ;
        movwf BYTE             	;
				;
        movlw b'10001111'	;Check least significant nybble on port B for the current MIDI channel setting,
        banksel TRISB           ;and put that value into CHANNEL. The LS nybble of Port B are made inputs to do this.
        movwf TRISB             ;They are put back to outputs in the LOOP section.
	banksel PORTB
        movf PORTB,W		;
	andlw b'00011110'	; Channel is selected on DIP switch connected to B1 to B4
	movwf CHANNEL		;

	nop			;Five extra NOP's added 16-8-99. These compensate for the fact that the bit is sampled
	nop			;five microseconds before, and not at the end, of the 32uS 'timing' loop. This should
	nop			;cure any problems with slow low-high transitions.
	nop			;
	nop			;

	nop			;
	nop			;***ALL NOPs ESSENTIAL FOR CORRECT DATA SYNC***
				;
	  			;
	movlw NOTESTACK		;initial setup for Note Stack Updating.
	movwf FSR		;Points FSR (File Special Register) at the next lowest note stack position.

LOOP: 				;
				;************************Note Stack Updating*************************
				;Must be 20 steps long no matter which branches are taken to ensure accurately timed MIDI reception
  				;
        movf INDF,W		;Write the value 10000000 into current stack position if it contains
        xorwf SCRATCHNOTE,W	;the note that is to be deleted
	movlw b'10000000'	;
        btfss STATUS,Z		;
	goto check		;
	movwf INDF		;
        decf NOTESP,F		;Must decrement the stack pointer: a note has been deleted.
				;
check:	xorwf INDF,W		;See if the current stack address contains no note (W still contains 10000000 at this moment)
        btfss STATUS,Z		;
	goto delay		;branch if the current stack address does contain a note value.
	incf FSR,F		;...Otherwise start shifting stack data down.
        movf INDF,W		;Get data from next position up in stack
	decf FSR,F		;
	movwf INDF		;stick that data into the current stack position address
				;
	incf FSR,F		;MUST also now assign the address above as No Note (%10000000)
	movlw b'10000000'	;
	movwf INDF		;
	decf FSR,F		;
	goto final		;

delay:	nop			;The additional delay required depends on the path previously taken.
	nop			;This subroutine MUST take 20 steps no matter which branches are taken.
	nop			;
	nop			;***ALL NOPs ESSENTIAL FOR CORRECT DATA SYNC***
	nop			;
	nop			;
	nop			;
	nop			;
	nop			;

final:	incf FSR,F		;Finally move up one in the stack for next time.
	nop			;***ALL NOPs ESSENTIAL FOR CORRECT DATA SYNC***
        banksel TRISB		;
        movlw b'10000000'	;All bits on either ports are outputs EXCEPT Port B, bit 7 = MIDI input. This is to
        movwf TRISB             ;restore the port data direction registers after they were changed for checking the
                		;current midi channel.
        banksel PORTB
	nop			;
        rrf BYTE,F		; Shift BYTE, C will be set if the start bit is moved into C, indicating all bits are loaded
        btfsc PORTB,MIDI		;
        bsf BYTE,7		; flip the new bit on BYTE
        btfss STATUS,C          ;
        goto LOOP               ;
        return			;

    end