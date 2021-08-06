LIST P=PIC16F877A
include <P16f877A.inc>

__CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC  & _LVP_OFF & _DEBUG_OFF & _CPD_OFF
;initial settings for program operation
START1
distance equ 0x37
R1 equ 0x34
R2 equ 0x35
quotient equ h'30'
remainder equ h'31'
save equ h'33'
counter EQU 0x45
ones EQU 0x38
RS EQU RB0      ;defined as RB0 RS
RW EQU RB1      ;defined as RB1 RW
EN EQU RB2      ;defined as RB2 EN

;port settings
bsf STATUS,RP0
movlw b'00000010';ECHO(input) equ  RC1 and TRIGGER(output) equ RC0
movwf TRISC
clrf TRISB;PORTB is output
clrf TRISD;PORTD is output for LCD
movlw b'00000111';prescalar value is set for distance limit and TMRO is internal clock source
movwf OPTION_REG
bcf STATUS,RP0
;clear required registers and ports before starting operations
bcf PORTC,0
clrf PORTB
clrf PORTD
clrf quotient
clrf remainder
clrf save
clrf ones
clrf counter

MOVLW 0x38      ;LCD 2 * 16 line and 5X7 resolution setting command.
CALL COMMAND;send command
CALL DELAY_100uS ;give lcd time to process the command.

MOVLW 0x0E      ;command to open LCD screen and cursor
CALL COMMAND
CALL DELAY_100uS 

MOVLW 0x01      ;cleaning the LCD screen
CALL COMMAND
CALL DELAY_100uS 

MOVLW 0X06
CALL COMMAND
CALL DELAY_100uS

;main program
START
clrf counter
clrf quotient
clrf remainder
clrf save
clrf ones

MOVLW 0x80
CALL COMMAND
CALL DELAY_100uS 

MOVLW 0X44        ;D
CALL DATA_LCD     ;Send data to lcd
CALL DELAY_100uS

MOVLW 0X49        ;I
CALL DATA_LCD
CALL DELAY_100uS

MOVLW 0X53        ;S
CALL DATA_LCD
CALL DELAY_100uS

MOVLW 0X54        ;T
CALL DATA_LCD
CALL DELAY_100uS

MOVLW 0X3D        ;=
CALL DATA_LCD
CALL DELAY_100uS

call delay_50msec;50 ms delay between sending each ultrasonic sound
bsf PORTC,0 ;TRIGGER pin set and ultrasonic sound signal start
call Delay_10us;the signal from TRIGGER remains in set 10us
bcf PORTC,0;ultrasonic sound signal end

LOOP
btfss   PORTC,1 ;signal must be entered from ECHO to start distance measurement
goto    LOOP
MOVLW   .0;TMR0 is initially reset to calculate the amount of time that it takes for a signal to hit and rotate
MOVWF   TMR0;TMR0 starts counting

LOOP1
BTFSC   PORTC,1;TMR0 continues counting until the signal output from ECHO is reset
GOTO    LOOP1

MOVLW b'11111111'
XORWF TMR0,w
btfss STATUS,2;if zero bit is 1 therefore reached the maximum distance and the program should only show the maximum number
goto display
goto max_display;only show the maximum number

max_display
movlw b'11111111'
movwf PORTB
loop
goto loop

display
goto DIV;for the time interval TMR0 counts, the division in 58 of the formula is applied.

DIV
movf TMR0,w
movwf save
LOOP2
movlw .58
subwf save,f
btfss STATUS,0
goto next;carry was 0 so the number inside the save was negative
incf quotient,f
goto LOOP2;58 can be removed again from TMRO

next
movf save,w
addlw .58;found remainder by adding 58 to negative save number
movwf remainder


DIV_LCD
MOVLW .10
SUBWF quotient,F
BTFSS STATUS,C
GOTO NEXT
INCF counter,F
GOTO DIV_LCD

NEXT
MOVF quotient,W;the remaining number from the first 10 a partition operation
ADDLW .10
MOVWF ones
MOVF ones,W;show the first digit of the number divided by 58 in lcd
CALL LCD_TABLE
CALL DATA_LCD
CALL DELAY_100uS
clrf quotient

;for 3-digit numbers cascading continues
DIV_LCD1
movlw .10
subwf counter,F;counter is equal to quotient for first division by 10 
btfss STATUS,C
goto next_1
incf quotient
goto DIV_LCD1

next_1
MOVF counter,W
ADDLW .10 ;show the second digit of the number divided by 58 in lcd
CALL LCD_TABLE
CALL DATA_LCD
CALL DELAY_100uS

MOVF quotient,W;show the last digit of the number divided by 58 in lcd
CALL LCD_TABLE
CALL DATA_LCD
CALL DELAY_100uS

goto START

;delay for the signal from TRIGGER
Delay_10us
movlw .15
movwf R1
LOP1
decfsz R1,f
goto LOP1
RETURN

;the delay required for TRIGGER and ECHO signals not to overlap
delay_50msec
movlw .10
movwf R1

test1
movlw .10
movwf R2

test2
decfsz R2,f
goto test2
decfsz R1,f
goto test1
RETURN

COMMAND
MOVWF PORTD
BCF PORTB,RS
BSF PORTB,EN
CALL DELAY_100uS
BCF PORTB,EN
RETURN

DATA_LCD
MOVWF PORTD    
BSF PORTB,RS    
BSF PORTB,EN    
CALL DELAY_100uS
BCF PORTB,EN    
RETURN

;ASCII codes for numbers to be displayed
LCD_TABLE
ADDWF PCL,F
RETLW 0X30
RETLW 0X31
RETLW 0X32
RETLW 0X33
RETLW 0X34
RETLW 0X35
RETLW 0X36
RETLW 0X37
RETLW 0X38
RETLW 0X39
RETURN

;delay for lcd processing the command.
DELAY_100uS
MOVLW .10
MOVWF 0X36

LOOP_3
DECFSZ 0X36
GOTO LOOP_3

RETURN
END