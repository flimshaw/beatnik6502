gameLoop
	pha
	txa
	pha
	tya
	pha

	jsr tick_time	; tick the timer 1 frame

+	jmp (modeTarget)	; run the intro mode

setMode
	lda #<blank_mode
	sta modeTarget
	lda #>blank_mode
	sta modeTarget+1
	lda stat
	ora #NEWMODE_FLAG
	sta stat
	rts

colorCycling

	lda time
	and #$03
	bne +
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
+	rts

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

; MODES
; called on frame loop
intro_mode
	; skip first run stuff if not new
	lda stat
	and #NEWMODE_FLAG
	cmp #0
	beq +

	; here's the init code
	lda stat ; kill newmode
	and #~NEWMODE_FLAG
	sta stat

	; draw the intro text
	; to the screen
	jsr drawIntro

+	jsr colorCycling

	; timeout and inc mode
	lda secs
	cmp #INTRO_DELAY
	bne +
	jsr setMode
+	jmp loopEnd

blank_mode
	; skip first run stuff if not new
	lda stat
	and #NEWMODE_FLAG
	cmp #0
	beq +
	; here's the init code
	lda stat ; kill newmode
	and #~NEWMODE_FLAG
	sta stat

	; draw the intro text
	; to the screen
	jsr clear_screen
+	jmp loopEnd

; this section loops over a string and displays it
drawIntro
    ldx #$0
    ldy #$0
introLoop  lda message,y    ; put the msg + x offset in accumulator
    and #$3f                ; strip the top two bytes away
    clc
    sta $0400,x             ; put the string byte into the screen + offset
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx                     ; increment x
    iny
    tya
    and #$0f
    tay
    cpx #0                ; see if x != the length of the string
    bne introLoop
    rts
