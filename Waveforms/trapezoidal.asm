;update freq = 5Hz
CLR P0.7
main: ;after each cycle
MOV A, #00H
rise: ; for rise part of trapezoidal waveform
	MOV P1,A
	ADD A, #61  ;incrementing by 61 provides 5%rise time
	JNC rise
	CLR C
	MOV A, #0FFH ;setting accumulator to the highest voltage value
	MOV R0, #25 ;for 40% duty cycle
	JMP constant_at_5V
constant_at_5V: ;for the constant value at high voltage
	MOV P1, A
	DJNZ R0, constant_at_5V ;loop until R0 = 0
	JMP fall
fall: ; for fall part of trapezoidal waveform
	MOV P1,A
	SUBB A, #61  ;decrementing by 61 provides 5% fall time
	JNC fall
	CLR C
	MOV R0, #35   ; for 50% time when the value = 0 
	JMP constant_at_0V
constant_at_0V: ; for the constant value at low voltage
	MOV A, #00H
	MOV P1, A
	DJNZ R0, constant_at_0V
	JMP main
