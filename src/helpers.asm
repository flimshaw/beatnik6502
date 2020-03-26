; this section loops over a string and displays it
drawIntro
    ldx #$0
    ldy #$0
introLoop  lda message,y    ; put the msg + x offset in accumulator
    and #$3f                ; strip the top two bytes away
    sta $0400,x             ; put the string byte into the screen + offset
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx                     ; increment x
    iny
    tya
    and #$0f
    tay
    cpx #255                ; see if x != the length of the string
    bne introLoop
    rts

tick_time  inc time
    lda #$3c
    cmp time
    bne +
    lda #0
    sta time
    inc secs
    lda #$3c
    bne +
    lda #0
    sta secs
+    rts


; clear the whole screen first
clear_screen
    pha  ; save registers
    tya
    pha
    txa
    pha

    ldx #$0
    lda #$20
-    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    cpx #0
    bne -

    pla  ; restore registers
    tax
    pla
    tay
    pla

    rts
