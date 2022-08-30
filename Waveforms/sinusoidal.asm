; update freq = 10Hz
; no of points = 28
; reseting the scope graph, so that it starts from 0.
CLR P1.6
CLR P1.5
CLR P1.4
CLR P1.3
CLR P1.2
CLR P1.1
CLR P1.0
CLR P0.7
MOV 20H, #080H
MOV 21H, #09CH
MOV 22H, #0B7H
MOV 23H, #0CFH
MOV 24H, #0E3H
MOV 25H, #0F2H
MOV 26H, #0FCH
MOV 27H, #0FFH
MOV 28H, #064H
MOV 29H, #049H
MOV 2AH, #031H
MOV 2BH, #01DH
MOV 2CH, #00DH
MOV 2DH, #004H
MOV 2EH, #001H
main:
	MOV R0, #20H
	loop1:
		MOV P1, @R0
		INC R0
		CJNE R0, #27H, loop1
		JMP loop2
	loop2:
		DEC R0
		MOV P1, @R0
		CJNE R0, #20H, loop2
		MOV R0, #28H
		JMP loop3
	loop3:
		MOV P1, @R0
		INC R0
		CJNE R0, #2EH, loop3
		JMP loop4
	loop4:
		DEC R0
		MOV P1, @R0
		CJNE R0, #28H, loop4
		JMP main
		 
	


















