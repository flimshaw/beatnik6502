gameLoop
	pha
	txa
	pha
	tya
	pha

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

	lda #0
	sta secs

+	;jsr colorCycling

	; timeout and inc mode
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

	jmp loopEnd

poem_mode

	; initialization
	lda stat
	and #NEWMODE_FLAG
	cmp #0
	beq poem_loop

	; here's the init code
	lda stat ; kill newmode + done
	and #~NEWMODE_FLAG
	and #~MODEDONE_FLAG
	sta stat

	; restart counter
	lda #0
	sta secs

	; initialize temp vars
	sta t2
	sta t3
	sta t4

	; draw the poem title
	#setPtr poem_title, dictCursor
	; lda #<poem_title
	; sta dictCursor
	; lda #>poem_title
	; sta dictCursor+1

	lda #6
	sta length
	jsr draw_word

	#setPtr poem_number, dictCursor
	lda #5
	sta length
	jsr draw_word

	lda #0
	sta col

	lda #3
	sta row

	jmp poem_loop

poem_loop

	; check for doneness
	lda stat
	and #MODEDONE_FLAG
	bne poem_end

	; if we're done, skip all this
	lda row
	cmp #16
	beq poem_reset

	lda #3
	sta counter
-
	; pick a random pos
	lda RAND
	and #$7
	sta pos
	jsr load_word
	jsr draw_word
	lda #$20
	inc col
	sta char
	jsr draw_char
	dec counter
	bne -


	inc row
	lda #0
	sta col

 	; inc word counter
	;inc row

	jmp poem_end

poem_reset
	lda #0
	sta row
	lda stat
	ora #MODEDONE_FLAG
	sta stat
	clc
	inc poem_count
	bne poem_end
	inc poem_count+1
	jmp poem_end

poem_end
	;jsr colorCycling
	lda secs
	cmp #POEM_DELAY
	bne +
	ldx #BLANK_MODE
	jsr setMode
+	jmp loopEnd


test_loop
	lda col
	adc row
	and #$f
	tax
	lda message,x
	sta char

	jsr draw_char

	clc
	inc col
	lda #40
	cmp col
	bne +
	lda #0
	sta col
	clc
	inc row
	lda #25
	cmp row
	bne +
	lda #0
	sta row
+	jmp poem_end

; this section loops over a string and displays it
drawIntro
    ldx #$0
    ldy #$0
introLoop  lda message,y    ; put the msg + x offset in accumulator
    ; and #$3f                ; strip the top two bytes away
    ; clc
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
