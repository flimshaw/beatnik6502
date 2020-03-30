; not sure what this does! some kind of basic launcher
; *=$0801
; .byte $0c, $08, $0a, $00, $9e, $20
; .byte $34, $30, $39, $36, $00, $00
; .byte $00

* = $0801                               ; BASIC start address (#2049)
.byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000
.byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152
;* = $c000     				; start address for 6502 code



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

a = $fb
b = $fc
result = $fd
dictCursor = $b6
dict = $3008

length = $300b
; w1 = $02

p_dict = $b4
p_lengths = $a5
p_indices = $a7
p_count = $aa

; maybe some ram? no idea if this is
; a good spot
*=$0900
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

; start this code at $1000
*=$c000

jmp setup

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

	; The method shown here to store the registers is the most orthodox and most failsafe.

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

	; throw the vblank flag and get out of the interrupt asap
	lda stat
	ora VBLANK_FLAG
	sta stat

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
		lda stat
		and #VBLANK_FLAG
		beq megaloop	; just loop if there's no flag set
		lda stat		; otherwise, flip flag on stat
		and #~VBLANK_FLAG
		sta stat
		jsr gameLoop	; and run a game loop
		jmp megaloop


setup_vblank
		sei      		;disable maskable IRQs
		pha			; store the acc
		lda #$7f
		sta $dc0d		;disable timer interrupts which can be generated by the two CIA chips
		sta $dd0d		;the kernal uses such an interrupt to flash the cursor and scan the keyboard, so we better
								;stop it.

		lda $dc0d		;by reading this two registers we negate any pending CIA irqs.
		lda $dd0d		;if we don't do this, a pending CIA irq might occur after we finish setting up our irq.
								;we don't want that to happen.

		lda #$01 		;this is how to tell the VICII to generate a raster interrupt
		sta $d01a

		lda #$40 		;this is how to tell at which rasterline we want the irq to be triggered
		sta $d012

		lda #$1b 		;as there are more than 256 rasterlines, the topmost bit of $d011 serves as
		sta $d011		;the 9th bit for the rasterline we want our irq to be triggered.
								;here we simply set up a character screen, leaving the topmost bit 0.

		lda #$35 		;we turn off the BASIC and KERNAL rom here
		sta $01  		;the cpu now sees RAM everywhere except at $d000-$e000, where still the registers of
								;SID/VICII/etc are visible

		lda #<irq		;this is how we set up
		sta $fffe		;the address of our interrupt code
		lda #>irq
		sta $ffff

		cli					;enable maskable interrupts again

		pla 				; restore
		rts 				; we better don't RTS, the ROMS are now switched off,
								;there's no way back to the system


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
