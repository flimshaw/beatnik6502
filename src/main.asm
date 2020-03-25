; not sure what this does! some kind of basic launcher
*=$0801
.byte $0c, $08, $0a, $00, $9e, $20
.byte $34, $30, $39, $36, $00, $00
.byte $00

RAND .word $D41B

; maybe some ram?
*=$0901
; some constants
green .byte 	5
; some variables
t1	.byte	0
t2	.byte	0
counter .byte 0
tick .byte 0
time .word 0

; start this code at $1000
*=$1000
jmp setup

irq
	;Being all kernal irq handlers switched off we have to do more work by ourselves.
	;When an interrupt happens the CPU will stop what its doing, store the status and return address
	;into the stack, and then jump to the interrupt routine. It will not store other registers, and if
	;we destroy the value of A/X/Y in the interrupt routine, then when returning from the interrupt to
	;what the CPU was doing will lead to unpredictable results (most probably a crash). So we better
	;store those registers, and restore their original value before reentering the code the CPU was
	;interrupted running.

	;If you won't change the value of a register you are safe to not to store / restore its value.
	;However, it's easy to screw up code like that with later modifying it to use another register too
	;and forgetting about storing its state.

	;The method shown here to store the registers is the most orthodox and most failsafe.

	pha        ;store register A in stack
	txa
	pha        ;store register X in stack
	tya
	pha        ;store register Y in stack

	lda #$ff   ;this is the orthodox and safe way of clearing the interrupt condition of the VICII.
	sta $d019  ;if you don't do this the interrupt condition will be present all the time and you end
	           ;up having the CPU running the interrupt code all the time, as when it exists the
	           ;interrupt, the interrupt request from the VICII will be there again regardless of the
	           ;rasterline counter.

	           ;it's pretty safe to use inc $d019 (or any other rmw instruction) for brevity, they
	           ;will only fail on hardware like c65 or supercpu. c64dtv is ok with this though.
	inc counter
	ldx counter
	ldy #$0

	lda $D41B ; get a random number from the SID

	and #$3
	adc #$1
	clc
	sta $d800,x
	sta $d900,x
	sta $da00,x
	sta $dae8,x

	pla
	tay        ;restore register Y from stack (remember stack is FIFO: First In First Out)
	pla
	tax        ;restore register X from stack
	pla        ;restore register A from stack

	rti        ;Return From Interrupt, this will load into the Program Counter register the address
	           ;where the CPU was when the interrupt condition arised which will make the CPU continue
	           ;the code it was interrupted at also restores the status register of the CPU


; setup routine
setup	; black background
		ldx #$0
		stx $d021
		stx $d020

		; green text to start
		lda green

		jsr clear_screen
textcolor	; set green on black text
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $dae8,x
		inx
		cpx #$0
		bne textcolor

		; setup fonts
		lda #$2
		ora 53272
		sta 53272
randseed	; use SID for randomness
		lda #$FF  ; maximum frequency value
		sta $D40E ; voice 3 frequency low byte
		sta $D40F ; voice 3 frequency high byte
		lda #$80  ; noise waveform, gate bit off
		sta $D412 ; voice 3 control register
		jsr drawIntro
		jsr setup_vblank

megaloop 	inx
		jmp megaloop

message
	    .text "BeAtNik v 1.0 * "

.include "helpers.asm"
;.include "dict.asm"
