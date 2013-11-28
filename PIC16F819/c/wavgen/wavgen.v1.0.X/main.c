/*
 * File:   main.c
 * Author: dhood
 *
 * Created on November 27, 2013, 8:57 PM
 */

#include <htc.h>

//config bits that are part-specific for the PIC16F819
__CONFIG(FOSC_INTOSCIO & WDTE_OFF & PWRTE_ON & MCLRE_OFF & BOREN_ON & LVP_OFF & CPD_OFF & CP_OFF & WRT_OFF & DEBUG_OFF & CCPMX_RB3);

static unsigned int duty;

static void update_duty(void)
{
    CCP1Y = duty;
    duty >>= 1;
    CCP1X = duty;
    duty >>= 1;
    CCPR1L = duty;
}

void main(void) {
    duty = 110;
    // Set internal osc freq to 8MHz
    IRCF0 = 1;
    IRCF1 = 1;
    IRCF2 = 1;

    // PortA Config (all digital outs)
    ADCON1 = 0x06;  // All pins digital I/O
    TRISA = 0;      // All pins as output
    PORTA = 0b01010001; // Initial value

    // PWM Mode on RB3
    PR2 = 0xFF;     // Maximum PWM period
    update_duty();
    //CCPR1L = 0x00;  // Initial duty of 0
    //CCP1Y = 0;
    //CCP1X = 0;
    TRISB = 0;      // Port B outputs
    T2CKPS1 = 0;    // Prescalre of 1
    T2CKPS0 = 0;
    CCP1M3 = 1;     // Enable PWM Mode
    CCP1M2 = 1;

    // Setup timer0
    T0CS = 0;   // Timer mode
    PSA = 0;    // Prescaler for Timer0
    PS2 = 1;    // 1:256 (so we can see something)
    PS1 = 1;
    PS0 = 1;
    TMR0IE = 1; // Enable interrupt
    GIE = 1;    // Enable global interrupts

    for(;;);
}

static void interrupt isr(void) {
    if (TMR0IF)
    {
        TMR0IF = 0; // Clear interrupt
        //PORTA++;
        duty++;
        if (duty >= 1024) duty = 0;
        update_duty();
    }
}

