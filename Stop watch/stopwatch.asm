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

MOV TMOD, #01H

restart : JB P2.0, restart
start:
	MOV R2, #30H
	MOV R3, #30H
	MOV R4, #30H
	MOV R5, #30H

display:
	CLR P3.3
	CLR P3.4
	MOV A, R2
	MOV R1, A
	MOV P1, @R1
	CALL delay

	MOV P1, #0FFH

	SETB P3.3
	MOV A, R3
	MOV R1, A
	MOV P1, @R1
	CALL delay
	
	MOV P1, #0FFH
	
	CLR P3.3
	SETB P3.4
	MOV A, R4
	MOV R1,A 
	MOV P1, @R1
	CALL delay

	MOV P1, #0FFH

	SETB P3.3
	MOV A, R5
	MOV R1,A 
	MOV P1, @R1
	CALL delay
	
	MOV P1, #0FFH
	
	JNB P2.0, start
	JNB P2.1, display
	JNB P2.2, restart

	INC R2
	CJNE R2, #3AH, display
	MOV R2, #30H
	INC R3
	CJNE R3, #36H, display
	MOV R3, #30H
	INC R4
	CJNE R4, #3AH, display
	MOV R4, #30H
	INC R5
	CJNE R5, #36H, display
	MOV R5, #30H
	JMP start


delay:
	MOV TH0, #0FEH
	MOV TL0, #0FBH
	SETB TR0
	while: JNB TF0, while
	CLR TR0
	CLR TF0
RET

;(reset mode)P2.2 = 0 ; reset to blank and is changed to 1 to stop/start the stopwatch
;(stop mode)P2.1 = 0 | P2.0 = 1 ; pausing at the current display, thus displays same time repeatedly until P2.1 is changed to 1.
;(start mode)P2.1 = 1 | P2.0 = 0 ; starting the stopwatch, thus displaying 00:00 until P2.0 is changed to 1, where the stopwatch starts displaying the time.


