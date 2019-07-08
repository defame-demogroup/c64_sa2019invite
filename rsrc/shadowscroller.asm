/*
Parameters
*/
.var scrollYOffset = 8
/*
ZEROPAGE
*/
.var scrollTextPointer = $37
.var scrollBytePointer = $38

.var scrollFontLo = $39
.var scrollFontHi = $3a

currentChar:
.fill $09, $00

outputBuffer:
.fill $09, $0b

.pc=* "DEBUG"
funcScroller:
	ldx #$00
!:
	.for(var j=0;j<6;j++){
		lda $0400 + ((j+scrollYOffset) * $28) + 1,x
		sta $0400 + ((j+scrollYOffset) * $28),x
	}
	cpx #$28
	bne !-

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