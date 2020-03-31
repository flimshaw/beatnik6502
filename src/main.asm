
* = $0801                               ; BASIC start address (#2049)
.byte $0C,$08,$0A,$00,$9E,$20,$34,$30,$39,$36,$00,$00,$00 ; starts at $1000

*= $1000
jmp setup

; CONSTANTS
; a few constants for state machine
VBLANK_FLAG = $01			; time to trigger a vblank
NEWMODE_FLAG = $02		; mode has changed
MODEREADY_FLAG = $04	; mode setup complete
MODEDONE_FLAG = $08		; modedone flag

; some constants for mode types
INTRO_MODE = $00
BLANK_MODE = $01
POEM_MODE = $02

MODE_COUNT = $03
RAND = $D41B
INTRO_DELAY = 1
POEM_DELAY = 5

a = $f9
b = $fb
result = $fd
dictCursor = $b6
dict = $3008

length = $300b
; w1 = $02

p_dict = $b4
p_lengths = $a5
p_indices = $a7
p_count = $aa

*=$c000
; jump straight to setup

; a bunch of variables
secs 	.byte 0
time 	.byte 0

cursor .byte 0
item	 .byte 0
pos .byte 0

; some constants
green 	.byte 5
stat	 	.byte (NEWMODE_FLAG) ; main state variable
mode		.byte 0
nextMode	.byte 0

; some variables
t1		.byte 0	; a bunch of temps
t2		.byte 0
t3		.byte 0
t4		.byte 0
t5		.byte 0
ta		.byte 0
tb		.byte 0
tc		.byte 0

poem_count .word 0
dict_count .byte 2
rand_max	 .byte 4
poem_cursor .byte 0

counter .byte 0
modeTarget .word intro_mode
screenBank .byte $04

col .byte 0
row .byte 0
char .byte 0
addr .word 0

; allocate an 8x8 block for pos definitions
; or possibly complete poem defs w/ dict
; indices
poem_pos_data .byte $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0


irq
	; Being all kernal irq handlers switched off we have to do more work by ourselves.
	; When an interrupt happens the CPU will stop what its doing, store the status and return address
	; into the stack, and then jump to the interrupt routine. It will not store other registers, and if
	; we destroy the value of A/X/Y in the interrupt routine, then when returning from the interrupt to
	; what the CPU was doing will lead to unpredictable results (most probably a crash). So we better
	; store those registers, and restore their original value before reentering the code the CPU was
	; interrupted running.

	; If you won't change the value of a register you are safe to not to store / restore its value.
	; However, it's easy to screw up code like that with later modifying it to use another register too
	; and forgetting about storing its state.
	dec $d019
	; The method shown here to store the registers is the most orthodox and most failsafe.

	pha
	; throw the vblank flag and get out of the interrupt asap

	clc
	lda stat
	ora #VBLANK_FLAG
	sta stat

	pla

	jmp $ea31
	; rti        ;Return From Interrupt, this will load into the Program Counter register the address
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
		clc
		inx
		cpx #$0
		bne textcolor

		; setup fonts
		lda #23
		ora 53272
		sta 53272

randseed	; use SID for randomness
		lda #$FF  ; maximum frequency value
		sta $D40E ; voice 3 frequency low byte
		sta $D40F ; voice 3 frequency high byte
		lda #$80  ; noise waveform, gate bit off
		sta $D412 ; voice 3 control register
		jsr setup_vblank

; the outermost loop, also controls frame events
megaloop
		clc
		lda stat
		and #VBLANK_FLAG
		beq megaloop	; just loop if there's no flag set
		lda stat		; otherwise, flip flag on stat
		and #~VBLANK_FLAG
		sta stat
		jsr gameLoop	; and run a single game loop
		jmp megaloop

setup_vblank
		sei
		lda #<irq
		sta 788
		lda #>irq
		sta 789
		cli
		rts

.include "helpers.asm"
.include "poem.asm"
.include "loop.asm"

; string data
.enc screen
.include "dict.asm"
message
.text "Beatnik v 1.0 * "
poem_title
.text "Poem #"
poem_number
.text "00000"
.enc none
