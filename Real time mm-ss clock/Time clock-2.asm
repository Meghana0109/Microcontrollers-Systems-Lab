MOV 30H, #0C0H ;0
MOV 31H, #0F9H ;1
MOV 32H, #0A4H ;2
MOV 33H, #0B0H ;3
MOV 34H, #099H ;4
MOV 35H, #092H ;5
MOV 36H, #082H ;6
MOV 37H, #0F8H ;7
MOV 38H, #080H ;8
MOV 39H, #098H ;9

MOV TMOD, #01H ;Time interrupt of mode 1  using only timer 1 


MOV R1, #30H 
MOV R3, #30H ; Ones - Seconds
MOV R4, #30H ; Tens - Seconds
MOV R5, #30H ; Ones - Minutes
MOV R6, #30H ; Tens - Minutes

loop:
	CJNE R3, #3AH, incNdisp1  ; displaying ones of seconds
	MOV R3,	#30H
	CJNE R4, #35H, incNdisp2  ; maximum display in the tens of seconds is '5'
	MOV R4,	#30H
	CJNE R5, #3AH, incNdisp3  
	MOV R5,	#30H
	CJNE R6, #35H, incNdisp3  
	MOV R6,	#30H
	CALL disp
	JMP loop	

incNdisp1:		;increments ones place of seconds and displays time
	CALL disp
	INC R3
	JMP loop

incNdisp2:		;increments tens place of seconds and displays time
	INC R4
	CALL disp
	INC R3
	JMP loop

incNdisp3:		;increments ones place of minutes and displays time
	INC R5
	CALL disp
	INC R3
	JMP loop

incNdisp4:		;increments tens place of minutes and displays time
	INC R6
	CALL disp
	INC R3
	JMP loop

disp:				;displays time
	CLR P3.3
	CLR P3.4
	MOV A, R3
	MOV R1, A
	MOV P1, @R1
	CALL delay1

	SETB P3.3
	CLR P3.4
	MOV A, R4
	MOV R1, A
	MOV P1, @R1
	CALL delay1

	CLR P3.3
	SETB P3.4
	MOV A, R5
	MOV R1, A
	MOV P1, @R1
	CALL delay1

	SETB P3.3
	SETB P3.4
	MOV A, R6
	MOV R1, A
	MOV P1, @R1
	CALL delay1
	RET

delay1:					;a delay of 60ms
	MOV R0, #1
	DLOOP:
		MOV TL0, #020H
		MOV TH0, #0D1H
		SETB TR0
		AGAIN1: JNB TF0, AGAIN1
		CLR TR0
		CLR TF0
		DJNZ R0, DLOOP
	RET