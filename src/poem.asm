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

LINE_END = 13

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
  lda #LINE_END
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
verb_trans_pos      .byte 5, POS_ADVERB, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_OBJECTIVE_PRONOUN
verb_intrans_pos    .byte 3, POS_ADVERB, POS_PREPOSITION, POS_CONJUNCTION
adjective_pos       .byte 4, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_OBJECTIVE_PRONOUN
adverb_pos          .byte 5, POS_VERB_TRANSITIVE, POS_VERB_INTRANSITIVE, POS_ADJECTIVE, POS_ADVERB, POS_POSSESSIVE_PRONOUN
noun_pos            .byte 2, POS_CONJUNCTION, POS_ADVERB
preposition_pos     .byte 5, POS_ADJECTIVE, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_POSSESSIVE_PRONOUN
conjunction_pos     .byte 10, POS_ARTICLE, POS_VERB_TRANSITIVE, POS_VERB_INTRANSITIVE, POS_ADJECTIVE, POS_ADVERB, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_PLACE, POS_PREPOSITION, POS_POSSESSIVE_PRONOUN, POS_SUBJECTIVE_PRONOUN
pos_pronoun_pos     .byte 3, POS_NOUN_THING, POS_NOUN_PERSON, POS_NOUN_THING
sub_pronoun_pos     .byte 2, POS_VERB_TRANSITIVE, POS_VERB_INTRANSITIVE
obj_pronoun_pos     .byte 2, POS_CONJUNCTION, POS_ADVERB

pos_lookup          .word 0, verb_trans_pos, verb_intrans_pos, adjective_pos, adverb_pos, noun_pos, noun_pos, noun_pos, preposition_pos, conjunction_pos, pos_pronoun_pos, sub_pronoun_pos, obj_pronoun_pos, noun_pos

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
  lda #12
  sta b
  fMod a,b
  sta pos
  rts

; classic Beatnik Box grammar, ported from
; the original Perl script. WIP
classic_grammar

  ; load the previous word
  lda poem_cursor
  beq classic_random ; if it's the first word, all bets are off

  ; otherwise, choose a new pos based on the previous word
  ldx poem_cursor
  dex
  lda poem_pos_data,x ; load the previous word's pos
  asl ; mult by 2
  tax ; move back to x

  ; get the pointer to the pos listing
  lda pos_lookup,x
  sta result
  inx
  lda pos_lookup,x
  sta result+1

  ; finally, get a random word
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
	cmp #16
	beq poem_reset

  ; word loop - 3 words per line
	lda #3
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
  lda #LINE_END
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

	clc
	inc poem_count
	bne poem_end
	inc poem_count+1
	jmp poem_end

col_starts  .word $0400,$0428,$0450,$0478,$04a0,$04c8,$04f0,$0518,$0540,$0568,$0590,$05b8,$05e0,$0608,$0630,$0658,$0680,$06a8,$06d0,$06f8,$0720,$0748,$0770,$0798,$07c0
lines_per_page  .byte 66

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

  ; line print loop
  ldy #0
  ldx #0
- tya
  asl                ; double the line index for the word offset
  tax

  lda col_starts,x    ; copy the current column start addr
  inx
  ldy col_starts,x
  jsr k_print_str0

  jsr k_print_newline

  clc
  iny
  cpy #10
  beq -

  ; close out the printer connection
  lda #1
  jsr k_close

  rts

poem_end
	;jsr colorCycling
	lda secs
	cmp #POEM_DELAY
	bne +
	ldx #INTRO_MODE
	jsr setMode
+	jmp loopEnd
