;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                    ;;
;;  "The shoe-maker on earth that     ;;
;;	had the soul of a poet in him     ;;
;;	won't have to make shoes here."   ;;
;;                                    ;;
;;                     -Mark Twain    ;;
;;                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
* = $0801 ; BASIC start address (#2049)
.byte $0C,$08,$0A,$00,$9E,$20,$34,$39,$31,$35,$32,$00,$00,$00 ; starts at $c000

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

pbuf = $f5
tmp = $f7
a = $f9
b = $fb
result = $fd
dictCursor = $b6
dict = $3008

length = $300b

p_dict = $b4
p_lengths = $a5
p_indices = $a7
p_count = $aa

*=$2000
print_buffer .byte (0 * range($400))+$20

*=$c000
jmp setup ; jump straight to setup

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

ss      := $400 + range(0, 1000, 40)
scrlo   .byte <ss
scrhi   .byte >ss

irq

	dec $d019

	pha

	; throw the vblank flag and get out of the interrupt asap
	lda stat
	ora #VBLANK_FLAG
	sta stat

	pla

	jmp $ea31

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
.text "Beatnik         "
poem_title
.text "Poem #"
poem_number
.text "00000"
.enc none
