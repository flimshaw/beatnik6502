gameLoop
	jsr tick_time	; tick the timer 1 frame

+	jmp (modeTarget)	; run the intro mode

; x reg = next mode
setMode
	cpx #BLANK_MODE
	bne +
		lda #<blank_mode
		sta modeTarget
		lda #>blank_mode
		sta modeTarget+1
+	cpx #POEM_MODE
	bne +
		lda #<poem_mode
		sta modeTarget
		lda #>poem_mode
		sta modeTarget+1
+	cpx #INTRO_MODE
	bne +
		lda #<intro_mode
		sta modeTarget
		lda #>intro_mode
		sta modeTarget+1
+	lda stat
	ora #NEWMODE_FLAG
	sta stat
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

	lda #0
	sta secs

+	; timeout and inc mode
	clc
	lda secs
	cmp #INTRO_DELAY
	bne +
	ldx #BLANK_MODE
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

	lda #0
	sta secs
	; draw the intro text
	; to the screen
	jsr clear_screen
+	lda secs
	cmp #INTRO_DELAY
	bne +
	ldx #POEM_MODE
	jsr setMode

+	jmp loopEnd

loopEnd
	rts

; this section loops over a string and displays it
drawIntro
    ldx #$0
    ldy #$0
introLoop
		lda message,y    				; put the msg + x offset in accumulator
    sta $0400,x             ; put the string byte into the screen + offset
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx                     ; increment x
    iny
    tya
    and #$0f
    tay
    cpx #0                ; see if has rolled over
    bne introLoop
    rts
