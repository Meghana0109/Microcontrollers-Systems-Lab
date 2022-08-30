;Update Frequency 1,000
;UART parity = NO PARITY
;UART 8-bit BAUD @ 4800 BAUD
Org 0000h
		
RS 	Equ  	P1.3
E		Equ		P1.2

CLR RS
;Function set
			Clr  P1.7		; |
			Clr  P1.6		; |
			SetB P1.5		; | bit 5=1
			Clr  P1.4		; | (DB4)DL=0 - puts LCD module into 4-bit mode 
	
			SETB E
			CLR E
			CALL Delay		; wait for BF to clear
			SETB E
			CLR E
							
			SetB P1.7		; P1.7=1 (N) - 2 lines 
			Clr  P1.6
			Clr  P1.5
			Clr  P1.4
			
			SETB E
			CLR E			
			Call Delay

;Display on/off control
; The display is turned on, the cursor is turned on
			Clr P1.7		; |
			Clr P1.6		; |
			Clr P1.5		; |
			Clr P1.4		; | high nibble set (0H - hex)

			SETB E
			CLR E

			SetB P1.7		; |
			SetB P1.6		; |Sets entire display ON
			SetB P1.5		; |Cursor ON
			SetB P1.4		; |Cursor blinking ON

			SETB E
			CLR E
			Call Delay		; wait for BF to clear	
			
;Entry mode set (4-bit mode)
;    Set to increment the address by one and cursor shifted to the right
			Clr P1.7		; |P1.7=0
			Clr P1.6		; |P1.6=0
			Clr P1.5		; |P1.5=0
			Clr P1.4		; |P1.4=0

			SETB E
			CLR E

			Clr  P1.7		; |P1.7 = '0'
			SetB P1.6		; |P1.6 = '1'
			SetB P1.5		; |P1.5 = '1'
			Clr  P1.4		; |P1.4 = '0'
 
			SETB E
			CLR E
			Call Delay		; wait for BF to clear
			
;tranmitting data
TX:	 	CLR SM0 				; |
 			SETB SM1 				; | put serial port in 8-bit UART mode
			MOV A, PCON
			SETB ACC.7 
 			MOV PCON, A 			; set SMOD in PCON to double baud rate
 			MOV TMOD, #20H 	; put timer 1 in 8-bit auto-reload mode
 			MOV TH1, #243 		; put -13 in timer 1 high byte
 			MOV TL1, #243 		; put same value in low byte
 
 			SETB TR1 				; start timer 1 ; put data start address in R0
			CLR F0 					; clear flag 0
 			ACALL SCAN 			; scan first number from keypad,
 			MOV A, R0 			; move from R0 to the accumulator
			CLR F0					; clear flag 0
			ACALL SCAN			; scan second number from the keypad
			ADD A, R0  			; Add the number in R0 with the first number in A
			ACALL ASCII_Conv	; change the sum in HEX to ASCII
			MOV R0, #30H
ASCII_loop:
			MOV A, @R0
 			MOV SBUF, A 			; move data to be sent to the serial port
 			INC R0 					; increment R0 to point at next byte of data to be sent
 			JNB TI, $ 			; wait for TI to be set, indicating serial port has
										; finished sending byte
 			CLR TI 					; clear TI	
			CJNE R0, #32H, ASCII_loop ; for sending all the digits to the serial port
 			JMP RX 			  		; jump to RX

; Receiving data
RX: 		CLR SM0 
 			SETB SM1 				; | put serial port in 8-bit UART mode
 			SETB REN 				; enable serial port receiver
 			MOV A, PCON 
 			SETB ACC.7 
 			MOV PCON, A 			; | set SMOD in PCON to double baud rate
 			MOV TMOD, #20H 	; put timer 1 in 8-bit auto-reload mode
 			MOV TH1, #243 		; put -13 in timer 1 high byte
 			MOV TL1, #243 		; put same value in low byte
 			SETB TR1 				; start timer 1
 
 			SETB P1.3
AGAIN1: JNB RI, $ 			; wait for byte to be received
 			CLR RI 					; clear the RI flag
 			MOV A, SBUF 			; move received byte to A
 			ACALL SendChar 	; send data to LCD
			CJNE A, #0DH, AGAIN1 ; to send data to LCD until the end of transmission
 			JMP FINISH1 			; if it is the terminating character, jump to finish1

FINISH1:
			JMP $ ; do nothing

;SCAN sub-routine
SCAN: 	MOV R0, #01H 		; move address of ASCII data
 ; scan row0
 			SETB P0.3 			; set row3
 			CLR P0.0 				; clear row0
 			ACALL colScan 		; call column-scan subroutine
 			JB F0, finish2 	; if F0 is set, jump to end of program
 ; scan row1
 			SETB P0.0 			; set row0
 			CLR P0.1 				; clear row1
 			ACALL colScan 		; call column-scan subroutine
 			JB F0, finish2 	; | if F0 is set, jump to end of program
 
 ; scan row2
 			SETB P0.1 			; set row1
 			CLR P0.2 				; clear row2
 			ACALL colScan 		; call column-scan subroutine
 			JB F0, finish2 	; | if F0 is set, jump to end of program
 
 ; scan row3
 			SETB P0.2 			; set row2
 			CLR P0.3 				; clear row3
 			ACALL colScan 		; call column-scan subroutine
 			JB F0, finish2 	; | if F0 is set, jump to end of program
 
 			JMP SCAN 				; | go back to scan row 0
finish2:
			RET 						; key is found - return

;column-scan subroutine
colScan:JB P0.4, SKIP1 	; if col0 is cleared - key found, else skip
 			SETB F0
 			JNB P0.4, $
 			RET
SKIP1: INC R0 					; otherwise move to next key
 			JB P0.5, SKIP2 	; if col1 is cleared - key found, else skip
 			SETB F0
 			JNB P0.5, $
 			RET
SKIP2: INC R0 					; otherwise move to next key
 			JB P0.6, SKIP3 	; if col2 is cleared - key found, else skip
 			SETB F0
 			JNB P0.6, $
			RET
SKIP3: INC R0 					; otherwise move to next key
 			RET

SendChar:	Mov C, ACC.7		; |
			Mov P1.7, C			; |
			Mov C, ACC.6			; |
			Mov P1.6, C			; |
			Mov C, ACC.5			; |
			Mov P1.5, C			; |
			Mov C, ACC.4			; |
			Mov P1.4, C			; | high nibble set

			SETB E
			CLR E

			Mov C, ACC.3			; |
			Mov P1.7, C			; |
			Mov C, ACC.2			; |
			Mov P1.6, C			; |
			Mov C, ACC.1			; |
			Mov P1.5, C			; |
			Mov C, ACC.0			; |
			Mov P1.4, C			; | low nibble set

			SETB E
			CLR E
			Call Delay			; wait for BF to clear
			Ret

;ASCII Convert
ASCII_Conv:
;Dividing value in A by 10 continuously and storing the remainders and quotient
			MOV B, #0AH
  			DIV AB
			ADD A, #30H ;for correct ASCII values
  			MOV 30H, A
			MOV A, B
			ADD A, #30H
			MOV 31H, A	
			Ret

Delay:		Mov R2, #50
			Djnz R2, $
			Ret