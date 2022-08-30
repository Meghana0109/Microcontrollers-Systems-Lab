Org 0000h
		
RS 	Equ  	P1.3
E		Equ		P1.2

MOV 20H, #'A'
MOV 21H, #'n'
MOV 22H, #'t'
MOV 23H, #'i'
MOV 24H, #'-'
MOV 25H, #'C'
MOV 26H, #'l'
MOV 27H, #'o'
MOV 28H, #'c'
MOV 29H, #'k'
MOV 2AH, #'w'
MOV 2BH, #'i'
MOV 2CH, #'s'
MOV 2DH, #'e'
MOV 2EH, #0

	CLR P1.3		; clear RS - indicates that instructions are being sent to the module

; function set	
	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	CLR P1.4		; | high nibble set

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E

	CALL delay		; wait for BF to clear	

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E
				; same function set high nibble sent a second time

	SETB P1.7		; low nibble set (only P1.7 needed to be changed)

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E
				; function set low nibble sent
	CALL delay		; wait for BF to clear

; entry mode set
; set to increment with no shift
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E

	SETB P1.6		; |
	SETB P1.5		; |low nibble set

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E

	CALL delay		; wait for BF to clear

; display on/off control
; the display is turned on, the cursor is turned on and blinking is turned on
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E

	SETB P1.7		; |
	SETB P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E

	CALL delay		; wait for BF to clear

	SETB RS
	MOV R0, #25H
	JB P2.0, loop ;if button 0 is not pressed, motor is in clockwise rotation
	MOV R0, #20H
	SETB F0						; to set initial flag for rotation in clock wise direction when SW0 is pressed
									; so that in changedir, it is changed to anti-clockwise

loop:
	MOV A, @R0
	JZ finish1
	INC R0
	CALL SendChar
	JMP loop
finish1:
	CLR RS
	CLR A

;Setting the timer and direction of the motor rotation
	MOV TMOD, #50H			; put timer 1 in event counting mode
	SETB TR1					; start timer 1

	MOV DPL, #LOW(LEDcodes)		; | put the low byte of the start address of the
														; | 7-segment code table into DPL

	MOV DPH, #HIGH(LEDcodes)	; put the high byte into DPH

	CLR P3.4					; |
	CLR P3.3					; | enable Display 0
	
	CALL setDirection		; set the motor's direction
again:
	MOV A, TL1				; move timer 1 low byte to A
	CJNE A, #10, skip		; if the number of revolutions is not 10 skip next instruction
	CALL clearTimer		; if the number of revolutions is 10, reset timer 1
	CLR P3.0					; |
	CLR P3.1					; | stop motor
	JMP terminated
skip:
	MOVC A, @A+DPTR			; | get 7-segment code from code table - the index into the table is
										; | decided by the value in A 
										; | (example: the data pointer points to the start of the 
										; | table - if there are two revolutions, then A will contain two, 
										; | therefore the second code in the table will be copied to A)

	MOV C, F0				; move motor direction value to the carry
	MOV ACC.7, C			; and from there to ACC.7 (this will ensure Display 0's decimal point 
								; will indicate the motor's direction)

	MOV P1, A			; | move (7-seg code for) number of revolutions and motor direction 
							; | indicator to Display 0

	JMP again			; do it all again

terminated:
	MOV P1, #10000110B	; To show E when rotation has ended
	JMP $						; stay here forever when 10 counts are done in the 7-segment display

; Set Direction
setDirection:
	PUSH ACC			; save value of A on stack
	PUSH 20H			; save value of location 20H (first bit-addressable 
							;	location in RAM) on stack
	CLR A				; clear A
	MOV 20H, #0		; clear location 20H
	MOV C, P2.0		; put SW0 value in carry
	MOV ACC.0, C		; then move to ACC.0
	MOV C, F0			; move current motor direction in carry
	MOV 0, C			; and move to LSB of location 20H (which has bit address 0)

	CJNE A, 20H, changeDir		; | compare SW0 (LSB of A) with F0 (LSB of 20H)
										; | - if they are not the same, the motor's direction needs to be reversed

	JMP finish					; if they are the same, motor's direction does not need to be changed
changeDir:
	CLR P3.0			; |
	CLR P3.1			; | stop motor

	CALL clearTimer	; reset timer 1 (revolution count restarts when motor direction changes)
	MOV C, P2.0			; move SW0 value to carry
	MOV F0, C				; and then to F0 - this is the new motor direction
	MOV P3.0, C			; move SW0 value (in carry) to motor control bit 1
	CPL C					; invert the carry

	MOV P3.1, C			; | and move it to motor control bit 0 (it will therefore have the opposite
								; | value to control bit 1 and the motor will start 
								; | again in the new direction)
finish:
	POP 20H				; get original value for location 20H from the stack
	POP ACC				; get original value for A from the stack
	RET					; return from subroutine

;Clear timer 1 
clearTimer:
	CLR A				; reset revolution count in A to zero
	CLR TR1				; stop timer 1
	MOV TL1, #0		; reset timer 1 low byte to zero
	SETB TR1			; start timer 1
	RET					; return from subroutine

SendChar:
	Mov C, ACC.7		; |
	Mov P1.7, C			; |
	Mov C, ACC.6		; |
	Mov P1.6, C			; |
	Mov C, ACC.5		; |
	Mov P1.5, C			; |
	Mov C, ACC.4		; |
	Mov P1.4, C			; | high nibble set

	SETB E
	CLR E

	Mov C, ACC.3		; |
	Mov P1.7, C			; |
	Mov C, ACC.2		; |
	Mov P1.6, C			; |
	Mov C, ACC.1		; |
	Mov P1.5, C			; |
	Mov C, ACC.0		; |
	Mov P1.4, C			; | low nibble set

	SETB E
	CLR E
	Call Delay			; wait for BF to clear
	Ret

Delay:	
	Mov R3, #50
	Djnz R3, $
	Ret

LEDcodes:	; | this label points to the start address of the 7-segment code table which is 
				; | stored in program memory using the DB command below
DB 11000000B, 11111001B, 10100100B, 10110000B, 10011001B, 10010010B, 10000010B, 11111000B, 10000000B, 10010000B