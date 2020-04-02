; POS_VERB_TRANSITIVE = 1 ; = verb.trans
; POS_VERB_INTRANSITIVE = 2 ; = verb.intrans
; POS_ADJECTIVE = 3 ; = adjective
; POS_ADVERB = 4 ; = adverb
; POS_NOUN_THING = 5 ; = noun.thing
; POS_NOUN_PERSON = 6 ; = noun.person
; POS_NOUN_PLACE = 7 ; = noun.place
; POS_PREPOSITION = 8 ; = preposition
; POS_CONJUNCTION = 9 ; = conjunction
; POS_POSSESSIVE_PRONOUN = 10 ; = possessive pronoun
; POS_SUBJECTIVE_PRONOUN = 11 ; = subjective pronoun
; POS_OBJECTIVE_PRONOUN = 12 ; = objective pronoun
; POS_ARTICLE = 13 ; = article

SCREEN_LINE_END = $60
LINE_END = 13
POEM_LINES = 24
LINE_WORDS = 3

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

	; increment the poem count
	jsr incPoemNumber

	; draw the poem title
	#setPtr poem_title, dictCursor
	lda #6
	sta length
	jsr draw_word

	#setPtr poem_number, dictCursor
	lda #5
	sta length
	jsr draw_word

  ; draw an endline character
  lda #SCREEN_LINE_END
	inc col
	sta char
	jsr draw_char

  ; skip a couple lines
  lda #0
	sta col
  inc row
  jsr draw_char
  inc row
  jsr draw_char
  inc row
  jsr draw_char

	jmp poem_loop

; grammar lookup table, based on previous word
verb_trans_pos          .byte 5, POS_ADVERB, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_OBJECTIVE_PRONOUN
verb_intrans_pos        .byte 3, POS_ADVERB, POS_PREPOSITION, POS_CONJUNCTION
adjective_pos           .byte 4, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_OBJECTIVE_PRONOUN
adverb_pos              .byte 5, POS_VERB_TRANSITIVE, POS_VERB_INTRANSITIVE, POS_ADJECTIVE, POS_ADVERB, POS_POSSESSIVE_PRONOUN
noun_pos                .byte 2, POS_CONJUNCTION, POS_ADVERB
preposition_pos         .byte 5, POS_ADJECTIVE, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_POSSESSIVE_PRONOUN
conjunction_pos         .byte 10, POS_ARTICLE, POS_VERB_TRANSITIVE, POS_VERB_INTRANSITIVE, POS_ADJECTIVE, POS_ADVERB, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_PREPOSITION, POS_POSSESSIVE_PRONOUN, POS_SUBJECTIVE_PRONOUN
pos_pronoun_pos         .byte 3, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_THING
sub_pronoun_pos         .byte 2, POS_VERB_TRANSITIVE, POS_VERB_INTRANSITIVE
obj_pronoun_pos         .byte 2, POS_CONJUNCTION, POS_ADVERB
article_pos             .byte 5, POS_ADJECTIVE, POS_ADVERB, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE

verb_trans_pos_end      .byte 3, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE
verb_intrans_pos_end    .byte 3, POS_ADVERB
adjective_pos_end       .byte 4, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_OBJECTIVE_PRONOUN
adverb_pos_end          .byte 1, POS_VERB_TRANSITIVE
noun_pos_end            .byte 2, POS_CONJUNCTION, POS_ADVERB
preposition_pos_end     .byte 5, POS_ADJECTIVE, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_POSSESSIVE_PRONOUN
conjunction_pos_end     .byte 10, POS_ARTICLE, POS_VERB_TRANSITIVE, POS_VERB_INTRANSITIVE, POS_ADJECTIVE, POS_ADVERB, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_PREPOSITION, POS_POSSESSIVE_PRONOUN, POS_SUBJECTIVE_PRONOUN
pos_pronoun_pos_end     .byte 3, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_THING
sub_pronoun_pos_end     .byte 2, POS_VERB_TRANSITIVE, POS_VERB_INTRANSITIVE
obj_pronoun_pos_end     .byte 2, POS_CONJUNCTION, POS_ADVERB
article_pos_end         .byte 3, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE

pos_lookup          .word 13, verb_trans_pos, verb_intrans_pos, adjective_pos, adverb_pos, noun_pos, noun_pos, noun_pos, preposition_pos, conjunction_pos, pos_pronoun_pos, sub_pronoun_pos, obj_pronoun_pos, article_pos
pos_lookup_end      .word verb_trans_pos_end, verb_intrans_pos_end, adjective_pos_end, adverb_pos_end, noun_pos_end, noun_pos_end, noun_pos_end, preposition_pos_end, conjunction_pos_end, pos_pronoun_pos_end, sub_pronoun_pos_end, obj_pronoun_pos_end, article_pos

; replace the accumulator with a random
; number, max = acc
rand_range
  sta rand_max
  lda RAND
  sta a
  fMod a,rand_max
  rts

; completely random word selections
; all available parts of speech
random_grammar
  lda RAND
  sta a
  lda pos_lookup
  sta b
  fMod a,b
  sta pos
  rts

; classic Beatnik Box grammar, ported from
; the original Perl script. WIP
classic_grammar

  ; load the poem cursor
  lda poem_cursor
  beq classic_random ; if it's the first word, all bets are off

  ; otherwise, choose a new pos based on the previous word
  ldx poem_cursor
  dex
  lda poem_pos_data,x ; load the previous word's pos
  asl                 ; mult by 2
  tax                 ; move back to x

  ; copy the pointer to the given pos matrix
  lda pos_lookup,x
  sta result
  inx
  lda pos_lookup,x
  sta result+1

  ; finally, get a random word part of speech
  ldy #0
  lda (result),y
  jsr rand_range
  tay
  lda (result),y
  sta pos ; and finally, store it in the pos
  jmp classic_done

classic_random
  lda #5 ; truly random part of speech
  jsr rand_range
  adc #3
  sta pos
classic_done
  ldx poem_cursor
  sta poem_pos_data,x
  inx
  txa
  sta poem_cursor
  rts

poem_loop

	; check for doneness
	lda stat
	and #MODEDONE_FLAG
	bne poem_end

	; if we're done, skip all this
	lda row
	cmp #POEM_LINES
	beq poem_reset

  ; word loop - LINE_WORDS words per line
	lda #LINE_WORDS
	sta counter
- jsr random_grammar  ; apply grammar
	jsr load_word       ; load a random word
	jsr draw_word       ; draw it to the screen
	lda #$20            ; add a space after it
	inc col
	sta char
	jsr draw_char
	dec counter
	bne -               ; repeat till words are done

  ; draw a carriage return
  lda #SCREEN_LINE_END
	inc col
	sta char
	jsr draw_char

	inc row
  lda #0
	sta col  ; zero out the col

	jmp poem_end

poem_reset

	lda #0
  sta poem_cursor
	sta row
	lda stat
	ora #MODEDONE_FLAG
	sta stat

  ; print the poem out
  jsr poem_print

	jmp poem_end

col_starts  .word $0400,$0428,$0450,$0478,$04a0,$04c8,$04f0,$0518,$0540,$0568,$0590,$05b8,$05e0,$0608,$0630,$0658,$0680,$06a8,$06d0,$06f8,$0720,$0748,$0770,$0798,$07c0
lines_per_page  .byte 66

; char to be converted is in a
screen_to_petscii
  clc
  cmp #SCREEN_LINE_END    ; end conversion on CR
  beq newline
  cmp #$20                ; 0-20 add 64
  bcs +
  jmp add64
+ cmp #$40                ; 20-40 do nothing
  bcs +
  jmp stp_done
+ cmp #$60                ; 40-60 add 32
  bcs +
  jmp add32
+ jmp stp_done            ; default to no change
newline
  lda #LINE_END
  jmp stp_done
add32
  clc
  adc #$20
  jmp stp_done
add64
  clc
  adc #$40
  jmp stp_done
stp_done
  rts

format_poem
        ; loop through every line of the screen
        lda #0
        sta col
        sta row

        ; setup the buffer pointer
        sta pbuf
        lda #$20
        sta pbuf+1

        ; setup the loop
        ldx #0
        ldy #0

  -     jsr get_char
        jsr screen_to_petscii
        sta (pbuf),y
        iny
        cmp #LINE_END ; if it's a line ending, handle it
        beq z
        clc
        cpy #254      ; if we overflowed, print what we have
                      ; before continuing...
        bne +
        jmp ze
      + inc col
        jmp -
      z lda #0
        sta col
        inc row
        clc
        lda #POEM_LINES
        cmp row
        bne -
  ze    ; end the poem with a null
        lda #0
        iny
        sta (pbuf),y
        sta col
        sta row
        rts

format_line
        ; loop through every line of the screen
        lda #0
        sta col

        ; setup the loop
        ldx #0
        ldy #0

-       jsr get_char
        jsr screen_to_petscii
        sta print_buffer,y
        iny
        inc col
        cmp #LINE_END ; if it's a line ending, handle it
        bne -
        lda #0
        sta print_buffer,y
        sta col
        rts

stall
  ldx #0
  ldy #255
- nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  inx
  bne -
  dey
  bne -
  rts

poem_print
; print out the current screen ram
; to the printer, one line at a time
; until it's all done
; initialize the printer
lda #1        ; logical file number
ldx #4        ; device
ldy #7        ; secondary address
jsr k_setlfs

jsr k_open    ; open the file

ldx #1
jsr k_chkout  ; set it as default print output

jsr k_print_newline
jsr k_print_newline
jsr k_print_newline
jsr k_print_newline

- jsr format_line


  lda #<print_buffer
  ldy #>print_buffer
  jsr k_print_str0


  ; jsr stall

  inc row
  lda #POEM_LINES
  cmp row
  bne -

  jsr k_print_newline
  jsr k_print_newline
  jsr k_print_newline
  jsr k_print_newline


  ; close out the printer connection
  lda #1
  jsr k_close

  lda #0
  sta row
  sta col

  rts

poem_end
	;jsr colorCycling
	lda secs
	cmp #POEM_DELAY
	bne +
	ldx #INTRO_MODE
	jsr setMode
+	jmp loopEnd
