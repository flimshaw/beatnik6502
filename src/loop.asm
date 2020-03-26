gameLoop
	pha
	txa
	pha
	tya
	pha

	jsr tick_time

	; skip fancy for now
	ldx #$10
	cpx secs
	beq +
	jmp loopEnd
+	lda #0
	sta secs
	jmp colorCycling

colorCycling

	; color cycling
	inc counter
	ldx counter
	ldy #$0

	lda $d41b ; get a random number from the SID

	and #$3
	adc #$1
	clc
	sta $d800,x
	sta $d900,x
	sta $da00,x
	sta $dae8,x

	lda $d41b
	bne loopEnd
	jmp loopEnd

dissolveText
	lda $d41b
	tax
	lda #$20
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x


loopEnd
	pla
	tay
	pla
	tax
	pla

	rts
