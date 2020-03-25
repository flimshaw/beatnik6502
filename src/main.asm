; not sure what this does! some kind of basic launcher
*=$0801
.byte $0c, $08, $0a, $00, $9e, $20
.byte $34, $30, $39, $36, $00, $00
.byte $00

; maybe some ram?
*=$0901
; some constants
green .byte 	7
; some variables
t1	.byte	0
t2	.byte	0

; start this code at $1000
*=$1000

; setup routine
setup	; black background
		ldx #$0
		stx $d021
		stx $d020

		lda green
textcolor
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

; clear the whole screen first
ldx #$0
lda #$20
clear_screen 	sta $0400,x
			sta $0500,x
			sta $0600,x
			sta $0700,x
			inx
			cpx #0
			bne clear_screen

; this section loops over a string and displays it
ldx #$0
ldy #$0
loop 	lda message,y        ; put the msg + x offset in accumulator
		and #$3f                  ; strip the top two bytes away
		sta $0400,x               ; put the string byte into the screen + offset
		sta $0500,x
		sta $0600,x
		sta $0700,x
		inx                       ; increment x
		iny
		tya
		and #$0f
		tay
		cpx #255                  ; see if x != the length of the string
		bne loop

ldx #$0
ldy #$0
megaloop 	inx
		cpx #0
		nop
		nop
		nop
		bne megaloop
		iny
		cpy #0
		bne megaloop
		rts


; frameloop / raster interrupts etc
.include "loop.asm"

message
	    .text "BeAtNik v 1.0 * "

;.include "dict.asm"
