tick_time
    ; frame step
    inc time
    lda time
    cmp #$3c
    bne +
    lda #0
    sta time
    ; secs step
    inc secs
    lda secs
    cmp #$3c
    bne +
    lda #0
    sta secs
+   rts


; clear the whole screen first
clear_screen
    pha  ; save registers
    tya
    pha
    txa
    pha

    ldx #$0
    lda #$20
-   sta $0400,x
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
