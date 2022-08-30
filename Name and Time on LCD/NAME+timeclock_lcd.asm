;update freq = 1kHz
;Saving Numbers
MOV 30H, #'0'
MOV 31H, #'1'
MOV 32H, #'2'
MOV 33H, #'3'
MOV 34H, #'4'
MOV 35H, #'5'
MOV 36H, #'6'
MOV 37H, #'7'
MOV 38H, #'8'
MOV 39H, #'9'

;Saving Name
MOV 50H, #'M'
MOV 51H, #'E'
MOV 52H, #'G'
MOV 53H, #'H'
MOV 54H, #'A'
MOV 55H, #'N'
MOV 56H, #'A'
MOV 57H, #0

MOV TMOD, #01H
      MOV R7, #00H ;stores a control instruction for clearing LCD
      
; Select Instruction Register (IR)			     
			Clr P1.3	   	; RS=0 - Instruction register is selected. 
							; Stores instruction codes, e.g., clear display...
; Function set 
			Call FuncSet
; Display on/off control	
			Call DispCon
; Entry mode set (4-bit mode)			
			Call EntryMode		
;Data sets of registers for clock
start:
       MOV R2, #30H
min1:  MOV R3, #30H ;when bit 1 of minute updates
min0:  MOV R4, #30H ;when bit 0 of minute updates
sec1:  MOV R5, #30H ;when bit 1 of second updates		
; Send data
display:
       Call CursorPos ;set pos of LCD to 00H
       SetB P1.3			; RS=1 - Data register is selected. 
							; Send data to data register to be displayed.
       JB P2.0, display_name
       CJNE R7, #0FFH, no_clear
       Call ClearLCD
no_clear:
       Clr A
       MOV 3BH, R2
       MOV R1, 3BH
       Mov A,@R1
       Call SendChar
       MOV 3BH, R3
       MOV R1, 3BH
       Mov A,@R1
       Call SendChar
       MOV 3BH, R4
       MOV R1, 3BH
       Mov A,@R1
       Call SendChar
       MOV 3BH, R5
       MOV R1, 3BH
       Mov A,@R1
       Call SendChar
       MOV R7, #0FFH
       Call CursorPos
       SetB P1.3	
       JNB P2.0, finish
display_name:
       Mov R1, #50H
       MOV R7, #00H
Back:		
       Clr A
		  Mov A,@R1
		  Jz finish
		  Call SendChar
		  Inc R1
       Jmp Back
finish:
       Call delay_clock
       INC R5
       CJNE R5, #3AH, display ;second 0 bit moves from 0 to 9
       INC R4
       CJNE R4, #36H, sec1 ;second 1 bit moves from 0 to 5
       INC R3
       CJNE R3, #3AH, min0 ;minute 0 bit moves from 0 to 9
       INC R2
       CJNE R2, #36H, min1 ;minute 1 bit moves from 0 to 5
       Jmp start
; ------------------------------- End of Main ---------------------------------

;-------------------------------- Subroutines ---------------------------------

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

CursorPos:	Clr P1.3
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

ClearLCD:
       Clr A
       MOV A,' '
       MOV R1,#50H
clear: Call SendChar
       INC R1
       CJNE R1,#57H,clear
       Clr A
       Call CursorPos
       SetB P1.3
		  Ret

Pulse:	SetB P1.2		; |*P1.2 is connected to 'E' pin of LCD module*
			Clr  P1.2		; | negative edge on E	
			Ret

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

Delay:		Mov R0, #20
			Djnz R0, $
			Ret

delay_clock:
MOV TH0, #0E7H 
MOV TL0, #096H
SETB TR0 ;starting the timer
while: JNB TF0, while ;looping till overflow of timer
;reseting the timer register and overflow flag
CLR TR0
CLR TF0
RET