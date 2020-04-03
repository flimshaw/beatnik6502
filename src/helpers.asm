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


stall
    pha
    txa
    pha
    tya
    pha

    ldx #0
    ldy #8
  - nop
    inx
    bne -
    dey
    bne -

    pla
    tay
    pla
    tax
    pla

    rts

; printer specific subroutines
k_print_str0 = $ab1e
k_print_newline = $aad7

k_setlfs = $ffba
k_open = $ffc0
k_chkout = $ffc9
k_close = $ffc3

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
POS_ARTICLE = 13 ; = article


; macro to copy a 16 bit pointer into a
; target block for indirect addressing
; later
setPtr  .macro
        lda #<\1
        sta \2
        lda #>\1+1
        sta \2+1
        .endm

; sets up dictionary pointers for writing
; a particular part of speech
setPos  .macro
        ; store the pointer to dict data
        lda #<\1_data
        sta p_dict
        lda #>\1_data+1
        sta p_dict+1

      	; and the dict lengths
      	lda #<\1_lengths
      	sta p_lengths
        ; and the dict lengths
        lda #>\1_lengths
        sta p_lengths+1

        ; and the dict indices
        lda #<\1_indices
        sta p_indices
        ; and the dict indices
        lda #>\1_indices
        sta p_indices+1

        ; and the dict_count
        lda \1_count
        sta dict_count
        .endm

fMod    .macro
        lda \1
        sta ta
        lda \2
        sta tb
        jsr mod
        .endm

incPoemNumber
        ldx #4
-       inc poem_number,x
        lda poem_number,x
        cmp #$3a
        bne +
        lda #$30
        sta poem_number,x
        dex
        jmp -
+       rts

; queues up a random word from the
; currently selected dictionary
randWord

        ; get a random index from this dict
        #fMod $d41b, dict_count

        ; load the word length from the table
        tay
        lda (p_lengths),y
        sta length

        ; double the index and send it to y
        tya
        clc
        asl
        bcc +
        inc p_indices+1
        ldx #1 ; set a flag to undo this later
+       tay

        ; load the target word address
        ; into the dict cursor
        lda (p_indices),y
        sta dictCursor
        iny
        lda (p_indices),y
        sta dictCursor+1

        cpx #1
        bne +
        dec p_indices+1
+
        rts

load_dict
        ; figure out which dictionary to load
        ; based on the pos
        lda pos
        asl ; mult by 8 to get the staring index
        asl ; TODO maybe a struct?
        asl
        tax

        ; dictionary
        lda dict_index,x
        sta dict
        inx
        lda dict_index,x
        sta dict+1
        inx

        ; lengths
        lda dict_index,x
        sta p_lengths
        inx
        lda dict_index,x
        sta p_lengths+1
        inx

        ; indices
        lda dict_index,x
        sta p_indices
        inx
        lda dict_index,x
        sta p_indices+1
        inx

        ; wordcount
        lda dict_index,x
        sta p_count
        inx
        lda dict_index,x
        sta p_count+1

        ; and copy wordcount
        ldy #0
        lda (p_count),y
        sta dict_count


        rts

; sets up pointers and counters to
; draw a random pos to the screen
load_word
        jsr load_dict
        jsr randWord
        rts

draw_word
  	  ; load the current char
dloop   ldy #0
  	    lda (dictCursor),y
      	sta char

        ; draw the char to the screen
      	jsr draw_char

        ; move the cursor right one
        inc col

      	; move the word cursor right also
      	clc
      	inc dictCursor
      	bne +	; handle page crossings
      	inc dictCursor+1
      	; dec the length remaining
+       clc
        dec length
      	bne dloop  ; rinse & repeat
        rts

get_char
        txa
        pha
        tya
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

        ldy #0
        lda (result),y
        sta tmp

        pla ; restore the stack
        tay
        pla
        tax

        lda tmp

        rts



; draws a char at the given location in
; the screen buffer
draw_char
        ; store registers
        pha
        tya
        pha
        txa
        pha

        jsr stall

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
        ; clc
        ; adc #$20
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

; mod function
mod
        lda ta
        sec
modl    sbc tb
        bcs modl
        adc tb
        rts

; clear the whole screen first
clear_screen
        pha  ; save registers
        tya
        pha
        txa
        pha

        ; fast clear
        ldx #$0
        lda #$20
    -   sta $0400,x
        sta $0500,x
        sta $0600,x
        sta $0700,x
        inx
        bne -

        pla  ; restore registers
        tax
        pla
        tay
        pla

        rts
