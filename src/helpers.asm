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

; x,y,acc = x,y,char
; draws a char at the given location in
; the screen buffer
draw_char

  ; store registers
  pha
  tya
  pha
  txa
  pha

  ; determine which page
  lda row
  sta a  ; put it in num1
  lda #40
  sta b
  clc
  jsr mult ; multiply y * rows

  ; add x as an additional offset
  clc
  lda col
  adc result
  bcc +
  inc result+1
+ sta result

  ; add $04 to the top result to offset it
  ; for the screen buffer addr
  clc
  lda result+1
  adc #$04
  sta result+1

  ; finally, write the char to the screen
  lda char
  ldy #0
  sta (result),y

  ; restore registers
  pla
  tax
  pla
  tay
  pla

  rts

; diy multiplication
mult
  ; zero out the result
  lda #0
  sta result
  sta result+1

multloop
  ; if the first number is zero, quit
  lda a
  cmp #0
  beq multend

  dec a         ; dec the first number
  lda result    ; get the result lsb
  clc
  adc b
  sta result
  bcc multloop
  inc result+1  ; if we overflowed, inc
                ; the msb
  jmp multloop

multend
  rts


; basic multiplication routine
; mult
;       lda a
;       sta mod+1		; modify code, this way we can use an immediate adc-command
;       lda #$00
;       tay			; initialisation of result: accu is lowbyte, and y-register is highbyte
;       ldx b
;       inx
;
; loop1	clc
; loop2	dex
;       beq end
; mod		adc #$00		; becomes modified -> adc a
;       bcc loop2
;       iny
;       bne loop1
; end		sta result
;       sty result+1
;       rts

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
