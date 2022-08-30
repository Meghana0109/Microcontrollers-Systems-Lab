;update frequency = 10Hz
CLR P0.7  ; clear the DAC WR line
MOV A, #00H ;for sawtooth waveform: giving the accumulator lowest value
loop:
	MOV P1, A ;moving the data in accumulator value to DAC inputs(P1)
	ADD A, #4 ;adding a fixed value from data in accumulator
	JMP loop ; jumping to loop