.pc = $8000 "Shadow Scroller"

//NOTE: this is compiled separately from the rest of the code - expects colorquads at $ac00
.label COLOR_HIGH = $ac00
.label COLOR_MID = $ad00
.label COLOR_LOW = $ae00

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

//init: copy charmap and colormap to speedcode

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

.var char_map_lda_offset = 4 //hi byte of the lda color mid!
.var color_map_lda_offset = 13
.var speed_code_size = 16

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
	}
	.for (var i=0;i<8;i++){
		clc
		asl currentChar + i
		bcs !draw+
		lda #$00
		sta 
		jmp !done+
!draw:
		lda #$01
		sta $0400 + ((i+scrollYOffset) * $28) + $27
!done:
	}

	.for (var i=0;i<9;i++){
		lda shadowBuffer + i
		sta $d800 + ((i+scrollYOffset) * $28) + $27
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
.import c64 "font.prg"