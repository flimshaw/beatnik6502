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

POS_ARTICLE = 0 ; = article
POS_VERB_TRANSITIVE = 1 ; = verb.trans
POS_VERB_INTRANSITIVE = 2 ; = verb.intrans
POS_ADJECTIVE = 3 ; = adjective
POS_ADVERB = 4 ; = adverb
POS_NOUN_THING = 5 ; = noun.thing
POS_NOUN_PERSON = 6 ; = noun.person
POS_NOUN_PLACE = 7 ; = noun.place
POS_PREPOSITION = 8 ; = preposition
POS_CONJUNCTION = 9 ; = conjunction
POS_POSSESSIVE_PRONOUN = 10 ; = possessive pronoun
POS_SUBJECTIVE_PRONOUN = 11 ; = subjective pronoun
POS_OBJECTIVE_PRONOUN = 12 ; = objective pronoun

setPtr  .macro
        lda #\1
        sta \2
        lda #\1+1
        sta \2+1
        .endm

setPos  .macro
        lda #<\1_data
        sta dict
        lda #>\1_data+1
        sta dict+1

      	; store the length of the word
      	lda \1_lengths,x
      	sta t1

      	txa
      	asl ; double the index, since it's words
      	tax

      	lda \1_indices,x
      	sta dictCursor

      	inx
      	lda \1_indices,x
      	sta dictCursor+1
        .endm
; sets up pointers and counters to
; draw a random pos to the screen
load_word
  .switch pos
  ; .case POS_ARTICLE
  ; .case POS_VERB_TRANSITIVE
  ; .case POS_VERB_INTRANSITIVE
  ; .case POS_ADJECTIVE
  ; .case POS_ADVERB
  ; .case POS_NOUN_THING
  ; .case POS_NOUN_PERSON
  ; .case POS_NOUN_PLACE
  ; .case POS_PREPOSITION
  ; .case POS_CONJUNCTION
  ; .case POS_POSSESSIVE_PRONOUN
  ; .case POS_SUBJECTIVE_PRONOUN
  ; .case POS_OBJECTIVE_PRONOUN
  .default
    #setPos data_adjective
  .endswitch
  rts

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

; extremely basic multiplication
; by just repeatedly adding
; good enough for punk rock
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
