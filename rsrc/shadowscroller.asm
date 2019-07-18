.pc = $8000 "Shadow Scroller"
jmp func_map_to_speedcode
jmp func_draw_scroller
jmp func_scroll_scroller


//NOTE: this is code expects colorquads loaded at $b000
.label COLOR_HIGH = $b000
.label COLOR_MID = $b100
.label COLOR_LOW = $b200
.label COLOR_REAL = $b300

//Setup the existing banked memory map ($0400 is just a lookup)
.label CHAR_MAP = $4000
.label COLOR_MAP = $0400
.label COLOR_RAM = $d800
.var Y_SCROLLER_OFFSET = $07
//zp
.var scrollFontLo = $39
.var scrollFontHi = $3a

currentChar:
.fill $09, $00

shadowBufferA:
.fill $0a, $00

shadowBufferB:
.fill $0a, $00

scrollBytePointer:
.byte $00

//speedcode params
.var char_map_lda_offset = 4 //hi byte of the lda color mid!
.var color_map_lda_offset = 12
.var speed_code_size = 16
.var char_original_byte_offset = 1
.var color_original_byte_offset = 9


//init: copy charmap and colormap to speedcode
func_map_to_speedcode:
	ldx #$00
!loop:
	.for(var y=0;y<8;y++){
		lda CHAR_MAP + (y * $28) + (Y_SCROLLER_OFFSET * $28),x
		sta targetCharOffset: func_draw_scroller + ((y * $28) * speed_code_size) + char_original_byte_offset
		lda COLOR_MAP + (y * $28) + (Y_SCROLLER_OFFSET * $28),x
		sta targetColorOffset: func_draw_scroller + ((y * $28) * speed_code_size) + color_original_byte_offset
		clc
		lda targetCharOffset
		adc #speed_code_size
		sta targetCharOffset
		lda targetCharOffset + 1
		adc #$00
		sta targetCharOffset + 1
		clc
		lda targetColorOffset
		adc #speed_code_size
		sta targetColorOffset
		lda targetColorOffset + 1
		adc #$00
		sta targetColorOffset + 1
	}
	inx
	cpx #$28
	beq !done+
	jmp !loop-
!done:
	rts


//This is the real speedcode (part 1) that uses itself to lookup a luma and write to color maps
func_draw_scroller:
	.for(var y=0;y<8;y++){
		.for(var x=0;x<$28;x++){
			ldx #$00													//offsets
			lda COLOR_REAL,x												//+2 bytes + 2 = 4
			sta CHAR_MAP + x + (y * $28) + (Y_SCROLLER_OFFSET * $28)	//+3 bytes
			ldx #$00													//+3 bytes = base + 8
			lda COLOR_REAL,x												//+2 bytes
			sta COLOR_RAM + x + (y * $28) + (Y_SCROLLER_OFFSET * $28)	//+3 bytes																		//+3 bytes = base + 16
		}
	}
	rts

//scroll the speedcode by moving the luma lookups across the code itself 
//and then write appropriate luma's into the far right char using a 8x scroller technique
func_scroll_scroller:
	.for(var y=0;y<8;y++){
		.for(var x=0;x<$27;x++){
			lda func_draw_scroller + (((x + 1) + (y * $28)) * speed_code_size) + char_map_lda_offset
			sta func_draw_scroller + (((x + 0) + (y * $28)) * speed_code_size) + char_map_lda_offset
			lda func_draw_scroller + (((x + 1) + (y * $28)) * speed_code_size) + color_map_lda_offset
			sta func_draw_scroller + (((x + 0) + (y * $28)) * speed_code_size) + color_map_lda_offset
		}
	}
	ldx scrollBytePointer
	bne !currentChar+
	jmp !newChar+
!currentChar:
	inx
	cpx #$08
	bne !skip+
	//reset char
	ldx #$00
!skip:
	cpx #$01
	bne !+
	ldy #$00

//note: the shadow buffers are used for drawing the darker luma
!:
	stx scrollBytePointer
	.for (var i=0;i<8;i++){
		clc
		asl currentChar + i
		bcs !draw+
//could be transparent or in shadow
		lda shadowBufferB + i
		cmp #$01
		bne !+
		lda #>COLOR_LOW
		jmp !transdraw+
!:
		lda # >COLOR_REAL
!transdraw:
		sta func_draw_scroller + (($27 + (i * $28)) * speed_code_size) + char_map_lda_offset
		sta func_draw_scroller + (($27 + (i * $28)) * speed_code_size) + color_map_lda_offset
		lda #$00
		sta shadowBufferA + i + 1
		jmp !done+
!draw:
//switch to use color high/medium
		ldx ACTIVE_COLOR
		lda LUMA_HIGH,x
		//lda # >COLOR_HIGH
		sta func_draw_scroller + (($27 + (i * $28)) * speed_code_size) + char_map_lda_offset
		sta func_draw_scroller + (($27 + (i * $28)) * speed_code_size) + color_map_lda_offset
		lda #$01
		sta shadowBufferA + i + 1
!done:
		lda shadowBufferA + i
		sta shadowBufferB + i
	}
	rts
!newChar:
	lda #$00
	sta OffsetHi
	lda scrptr: SCROLLTEXT
	inc scrptr
	bne !+
	inc scrptr+1
!:
	cmp #$00 //scroll wrap
	bne !+
	lda #>SCROLLTEXT
	sta scrptr+1
	lda #<SCROLLTEXT
	sta scrptr
	lda #$20
!:
//Switch to compare with $80 or $81 in scrolltext to toggle color and inject space char
	cmp #$80
	bne !+
	lda #$00
	sta ACTIVE_COLOR
	lda #$20
!:
	cmp #$81
	bne !+
	lda #$01
	sta ACTIVE_COLOR
	lda #$20
!:
	clc
	asl 
	rol OffsetHi
	asl
	rol OffsetHi
	asl
	rol OffsetHi
	sta scrollFontLo
	clc
	lda OffsetHi: #$00
	adc #>FONT
	sta scrollFontHi
	ldy #$00
!loop:
	lda (scrollFontLo),y
	sta currentChar,y
	iny
	cpy #$08
	bne !loop-
	lda #$00
	sta currentChar,y
	ldx #$00
	jmp !currentChar-
	rts

ACTIVE_COLOR:
.byte $00

LUMA_HIGH:
.byte >COLOR_HIGH, >COLOR_MID

SCROLLTEXT:
.text " greets fly out to   ...   "
.byte $81
.text "chrome   "
.byte $80
.text "disaster area   "
.byte $81
.text "digital access   "
.byte $80
.text "cygnus oz   "
.byte $81
.text "duck and chicken   "
.byte $80
.text "funkentstort   "
.byte $81
.text "ikon visual   "
.byte $80
.text "jimage   "
.byte $81
.text "the force   "
.byte $80
.text "desire   "
.byte $81
.text "0f.digital   "
.byte $80
.text "niknak   "
.byte $81
.text "hedonist   "
.byte $80
.text "enduro   "
.byte $81
.text "evylz   "
.byte $80
.text "impbox   "
.byte $81
.text "glitter critter   "
.byte $80
.text "sexdata   "
.byte $81
.text "ttt   "
.byte $80
.text "reset   "
.byte $81
.text "uncle k   "
.byte $80
.text "jesder   "
.byte $81
.text "croy   "
.byte $80
.text "aday   "
.byte $81
.text "epicentre   "
.byte $80
.text " ...and"
.byte $81
.text "the"
.byte $80
.text "overseas" 
.byte $81
.text "fan"
.byte $80
.text "club....    "
.byte $81
.text "abyss connection   "
.byte $80
.text "amnesty   "
.byte $81
.text "artstate   "
.byte $80
.text "arise   "
.byte $81
.text "arsenic   "
.byte $80
.text "atlantis   "
.byte $81
.text "artline designs   "
.byte $80
.text "bonzai   "
.byte $81
.text "booze   "
.byte $80
.text "camelot   "
.byte $81
.text "censor   "
.byte $80
.text "chorus   "
.byte $81
.text "cosine   "
.byte $80
.text "crest   "
.byte $81
.text "dekadence   "
.byte $80
.text "digital excess   "
.byte $81
.text "delysid   "
.byte $80
.text "elysium   "
.byte $81
.text "excess   "
.byte $80
.text "extend   "
.byte $81
.text "exon   "
.byte $80
.text "fairlight   "
.byte $81
.text "focus   "
.byte $80
.text "fossil   "
.byte $81
.text "genesis-project   "
.byte $80
.text "hitmen   "
.byte $81
.text "hack n' trade   "
.byte $80
.text "hoaxers   "
.byte $81
.text "hokuto force   "
.byte $80
.text "laxity   "
.byte $81
.text "lepsi developments   "
.byte $80
.text "level 64   "
.byte $81
.text "maniacs of noise   "
.byte $80
.text "multistyle labs   "
.byte $81
.text "mayday   "
.byte $80
.text "noice   "
.byte $81
.text "nah kolor   "
.byte $80
.text "nostalgia   "
.byte $81
.text "offence   "
.byte $80
.text "origo dreamline   "
.byte $81
.text "oxyron   "
.byte $80
.text "padua   "
.byte $81
.text "panda design   "
.byte $80
.text "pegboard nerds   "
.byte $81
.text "plush   "
.byte $80
.text "prosonix   "
.byte $81
.text "resource   "
.byte $80
.text "role   "
.byte $81
.text "samar   "
.byte $80
.text "shape   "
.byte $81
.text "success + trc   "
.byte $80
.text "svenonacid   "
.byte $81
.text "the dreams   "
.byte $80
.text "the solution   "
.byte $81
.text "triad   "
.byte $80
.text "trsi   "
.byte $81
.text "vibrants   "
.byte $80
.text "vision   "
.byte $81
.text "viruz   "
.byte $80
.text "wrath   "
.byte $81
.text "x-ample ...      "
.byte $80
.text "see you at the siggraph event...     "
.byte $81
.text "17-20 november 2019 -  the bcec - brisbane - australia   "
.byte $80
.text "...   "
.byte $80
.text "   "
.text "   "
.text "   "
.text "   "
.byte $00

.align $100
.pc=* "FONT DATA"
FONT:
.import c64 "font-47.prg"
