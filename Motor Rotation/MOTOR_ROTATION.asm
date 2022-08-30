Org 0000h
		
RS 	Equ  	P1.3
E		Equ		P1.2

MOV 30H, #'A'
MOV 31H, #'n'
MOV 32H, #'t'
MOV 33H, #'i'
MOV 34H, #'-'
MOV 35H, #'C'
MOV 36H, #'l'
MOV 37H, #'o'
MOV 38H, #'c'
MOV 39H, #'k'
MOV 3AH, #'w'
MOV 3BH, #'i'
MOV 3CH, #'s'
MOV 3DH, #'e'
MOV 3EH, #0

CLR RS

Call FuncSet		; Function set
Call DispCon		; Display on/off control	
Call EntryMode	; Entry mode set (4-bit mode)	

	; LED setup and initial showing
	SETB RS
	MOV R0, #35H
	loop:
		MOV A, @R0
		JZ finish
		INC R0
		Call SendChar
		JMP loop
finish:
	CLR RS
	CLR A
	MOV R1, #0H
	MOV R2, #0H

	MOV TMOD, #50H			; put timer 1 in event counting mode
	SETB TR1					; start timer 1

	MOV DPL, #LOW(LEDcodes)		; | put the low byte of the start address of the
														; | 7-segment code table into DPL

	MOV DPH, #HIGH(LEDcodes)	; put the high byte into DPH

	CLR P3.4			; |
	CLR P3.3			; | enable Display 0
again:
	CALL setDirection		; set the motor's direction
	MOV A, TL1				; move timer 1 low byte to A
	MOV R2, A					; move the revolutions value to R2
	
	MOVC A, @A+DPTR			; | get 7-segment code from code table - the index into the table is
										; | decided by the value in A 
										; | (example: the data pointer points to the start of the 
										; | table - if there are two revolutions, then A will contain two, 
										; | therefore the second code in the table will be copied to A)

	MOV C, F0				; move motor direction value to the carry
	MOV ACC.7, C			; and from there to ACC.7 (this will ensure Display 0's decimal point 
								; will indicate the motor's direction)

	CLR P3.4			; |
	CLR P3.3			; | enable Display 0
	MOV P1, A			; | move (7-seg code for) number of revolutions and motor direction 
							; | indicator to Display 0

	JMP again			; do it all again


;Set Direction
setDirection:
	PUSH ACC			; save value of A on stack
	PUSH 20H			; save value of location 20H (first bit-addressable 
							;	location in RAM) on stack
	CLR A				; clear A
	MOV 20H, #0		; clear location 20H
	CJNE R2, #5H, skip
	CLR P3.0			; |
	CLR P3.1			; | stop motor
	CALL change_LCD
skip:
	MOV C, P2.0		; put SW0 value in carry
	MOV ACC.0, C		; then move to ACC.0
	MOV C, F0			; move current motor direction in carry
	MOV 0, C			; and move to LSB of location 20H (which has bit address 0)

	CJNE A, 20H, changeDir		; | compare SW0 (LSB of A) with F0 (LSB of 20H)
										; | - if they are not the same, the motor's direction needs to be reversed

	JMP finish3					; if they are the same, motor's direction does not need to be changed

changeDir:
	CALL clearTimer	; reset timer 1 (revolution count restarts when motor direction changes)
	MOV C, P2.0			; move SW0 value to carry
	MOV F0, C				; and then to F0 - this is the new motor direction
	MOV P3.0, C			; move SW0 value (in carry) to motor control bit 1
	CPL C					; invert the carry

	MOV P3.1, C			; | and move it to motor control bit 0 (it will therefore have the opposite
								; | value to control bit 1 and the motor will start 
								; | again in the new direction)
finish3:
	POP 20H				; get original value for location 20H from the stack
	POP ACC				; get original value for A from the stack
	RET	
;Clear timer 1
clearTimer:
	CLR A				; reset revolution count in A to zero
	CLR TR1				; stop timer 1
	MOV TL1, #0		; reset timer 1 low byte to zero
	SETB TR1			; start timer 1
	RET					; return from subroutine

;changing direction every 5 rotations. 
change_LCD:
	CPL P2.0
	SETB P3.4			; |
	SETB P3.3			; | enable Display 0
	CLR RS
	Call FuncSet		; Function set
	Call DispCon		; Display on/off control	
	Call EntryMode	; Entry mode set (4-bit mode)
	CALL CursorPos
	SETB RS
	CJNE R1, #0H, clockwise
	MOV R0, #30H
	loop1:
		MOV A, @R0
		JZ finish1
		INC R0
		CALL SendChar
		JMP loop1
finish1:
	CLR RS
	CLR A
	MOV R1, #1H
	RET

clockwise:			; for making the LCD clockwise
	MOV R0, #35H
	loop2:
		MOV A, @R0
		JZ finish2
		INC R0
		CALL SendChar
	JMP loop2
finish2:
	CLR RS
	CLR A
	MOV R1, #0H				; resetting the registers in use
	RET


; ------------------------- Function set --------------------------------------
FuncSet:	Clr  P1.7		; |
			Clr  P1.6		; |
			SetB P1.5		; | bit 5=1
			Clr  P1.4		; | (DB4)DL=0 - puts LCD module into 4-bit mode 

			Call Pulse
			Call Delay		; wait for BF to clear
			Call Pulse
							
			SetB P1.7		; P1.7=1 (N) - 2 lines 
			Clr  P1.6
			Clr  P1.5
			Clr  P1.4
			
			Call Pulse
			Call Delay
			Ret

;------------------------------- Display on/off control -----------------------
; The display is turned on, the cursor is turned on
DispCon:	Clr P1.7		; |
			Clr P1.6		; |
			Clr P1.5		; |
			Clr P1.4		; | high nibble set (0H - hex)

			Call Pulse

			SetB P1.7		; |
			SetB P1.6		; |Sets entire display ON
			Clr P1.5		; |Cursor OFF
			Clr P1.4		; |Cursor blinking OFF

			Call Pulse
			Call Delay		; wait for BF to clear	
			Ret
			
;----------------------------- Entry mode set (4-bit mode) ----------------------
;    Set to increment the address by one and cursor shifted to the right
EntryMode:	Clr P1.7		; |P1.7=0
			Clr P1.6		; |P1.6=0
			Clr P1.5		; |P1.5=0
			Clr P1.4		; |P1.4=0

			Call Pulse

			Clr  P1.7		; |P1.7 = '0'
			SetB P1.6		; |P1.6 = '1'
			SetB P1.5		; |P1.5 = '1'
			Clr  P1.4		; |P1.4 = '0'
 
			Call Pulse
			Call Delay		; wait for BF to clear
			Ret
;-------------------------------CursorPos----------------------------------------			
CursorPos:	Clr RS
			SetB P1.7		; Sets the DDRAM address
			Clr P1.6		; Set address. Address starts here - '0'
			Clr P1.5		; 									 '0'
			Clr P1.4		; 									 '0' 
							; high nibble
			Call Pulse

			Clr P1.7		; 									 '0'
			Clr P1.6		; 									 '0'
			Clr P1.5		; 									 '0'
			Clr P1.4		; 									 '0'
							; low nibble
							; Therefore address is 000 0000 or 00H
							
			Call Pulse
			Call Delay		; wait for BF to clear	
			Ret	

;------------------------------------- SendChar -------------------------------------			
SendChar:	Mov C, ACC.7		; |
			Mov P1.7, C			; |
			Mov C, ACC.6		; |
			Mov P1.6, C			; |
			Mov C, ACC.5		; |
			Mov P1.5, C			; |
			Mov C, ACC.4		; |
			Mov P1.4, C			; | high nibble set

			Call Pulse

			Mov C, ACC.3		; |
			Mov P1.7, C			; |
			Mov C, ACC.2		; |
			Mov P1.6, C			; |
			Mov C, ACC.1		; |
			Mov P1.5, C			; |
			Mov C, ACC.0		; |
			Mov P1.4, C			; | low nibble set

			Call Pulse
			Call Delay			; wait for BF to clear
			Ret

;------------------------------------ Pulse --------------------------------------
Pulse:		SetB E		; |*P1.2 is connected to 'E' pin of LCD module*
			Clr  E			; | negative edge on E	
			Ret

;------------------------------------- Delay -----------------------------------------			
Delay:		Mov R3, #50
			Djnz R3, $
			Ret

LEDcodes:	; | this label points to the start address of the 7-segment code table which is 
				; | stored in program memory using the DB command below
	DB 11000000B, 11111001B, 10100100B, 10110000B, 10011001B, 10010010B, 10000010B, 11111000B, 10000000B, 10010000B