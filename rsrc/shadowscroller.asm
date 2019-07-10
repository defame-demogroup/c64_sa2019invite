.pc = $8000 "Shadow Scroller"
jmp func_map_to_speedcode
jmp func_draw_scroller
jmp func_scroll_scroller


//NOTE: this is compiled separately from the rest of the code - expects colorquads at $ac00
.label COLOR_HIGH = $ac00
.label COLOR_MID = $ad00
.label COLOR_LOW = $ae00
.label COLOR_REAL = $af00

.label CHAR_MAP = $4000
.label COLOR_MAP = $d800
.var Y_SCROLLER_OFFSET = $00
.var scrollFontLo = $39
.var scrollFontHi = $3a

currentChar:
.fill $09, $00

outputBuffer:
.fill $09, $0b


scrollTextPointer:
.byte $00

scrollBytePointer:
.byte $00

//speedcode params
.var char_map_lda_offset = 4 //hi byte of the lda color mid!
.var color_map_lda_offset = 13
.var speed_code_size = 16
.var char_original_byte_offset = 1
.var color_original_byte_offset = 9


//init: copy charmap and colormap to speedcode
func_map_to_speedcode:
	ldx #$00
!loop:
	.for(var y=0;y<8;y++){
		lda CHAR_MAP + (y * $28),x
		sta targetCharOffset: func_draw_scroller + ((y * $28) * speed_code_size) + char_original_byte_offset
		lda COLOR_MAP + (y * $28),x
		sta targetColorOffset: func_draw_scroller + ((y * $28) * speed_code_size) + color_original_byte_offset
		clc
		lda targetCharOffset
		adc #$10
		sta targetCharOffset
		lda targetCharOffset + 1
		adc #$00
		sta targetCharOffset + 1
		clc
		lda targetColorOffset
		adc #$10
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


//run: 
//draw charmap and colormap using speedcode
//scroll the speedcode and render new char into speedcode
func_draw_scroller:
.for(var x=0;x<$28;x++){
	.for(var y=0;y<8;y++){
		ldx #$00													//offsets
		lda COLOR_MID,x												//+2 bytes + 2 = 4
		sta CHAR_MAP + x + (y * $28) + (Y_SCROLLER_OFFSET * $28)	//+3 bytes
		ldx #$00													//+3 bytes = base + 8
		lda COLOR_MID,x												//+2 bytes
		sta COLOR_MAP + x + (y * $28) + (Y_SCROLLER_OFFSET * $28)	//+3 bytes
																	//+3 bytes = base + 16
	}
}
	rts


func_scroll_scroller:
	.for(var x=0;x<$27;x++){
		.for(var y=0;y<8;y++){
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
	stx scrollBytePointer
	.for (var i=0;i<8;i++){
		clc
		asl currentChar + i
		bcs !draw+
		lda # >COLOR_REAL
		sta func_draw_scroller + (($27 + (i * $28)) * speed_code_size) + char_map_lda_offset
		sta func_draw_scroller + (($27 + (i * $28)) * speed_code_size) + color_map_lda_offset
		jmp !done+
!draw:
		lda # >COLOR_MID
		sta func_draw_scroller + (($27 + (i * $28)) * speed_code_size) + char_map_lda_offset
		sta func_draw_scroller + (($27 + (i * $28)) * speed_code_size) + color_map_lda_offset
!done:
	}
	rts
!newChar:
	lda #$00
	sta OffsetHi
	ldx scrollTextPointer
	inc scrollTextPointer
	lda SCROLLTEXT,x
	bne !skip+
	ldx #$00
	sta scrollTextPointer
	lda SCROLLTEXT,x
!skip:
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

SCROLLTEXT:
.text "                       plasmatoy by zig of defame.   music by wisdom.     thanks to conjuror from onslaught for the plasma ideas.       greetz to all lovely peeps we know.   use f-keys to play with settings.  press other keys to hide scroller.   "
.byte $00

.align $100
.pc=* "FONT DATA"
FONT:
.import c64 "delta.prg"
