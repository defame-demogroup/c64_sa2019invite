.import source "libs/lib.asm"
.import source "libs/easingLib.asm"
.import source "libs/const.asm"
.import source "rsrc/defines.asm"
.import source "rsrc/bmstatemachine.asm"
.import source "rsrc/smdata.asm"
.import source "rsrc/scrolltext.asm"
.import source "rsrc/colorquads.asm"
.import source "rsrc/spritedata.asm"

.var music = LoadSid("rsrc/Very_Bland.sid")

_outputMusicInfo()

/*
MEMORY MAP:
$0400-$0800 *FREE WORKING MEM
$0800-$1000 SPINDLE
$1000-$3717 Program
$3718-$3fff *FREE
$4000-$43ff CHAR RAM
$4400-$47ff *FREE
$4800-$56ff sprite font
$5700-$574f BM offsets
$5800-$5fff *FREE
$6000-$7fff BITMAP
$8000-$a7ff OCP BUFFER
$ac00-$aeff ColorQuads LUTs
$af00-$b34f SPRITE DATASETS
$b400-$bfff scrolltext and FREE
$c000-$cb93 Music

$a800-$abff loaded transition data
$e000-$e3ff screen working buffer
$e400-$e7ff color working buffer
$e800-$ea00 working data for state machines



*/



//addresses

/*
.pc = $0801 "Basic Upstart"
:BasicUpstart(start) // 10 sys$0810
*/
.pc = $1000 "Program"
start:
	:mov #$00: $d020
	:mov #$00: $d021
    :fill_1K($00, $0400) //remove this later - used for debug
	:fill_1K($00, $d800)
    jsr funcInitData
    sei
    lda #$35
    sta $01
    cli
	:setupInterrupt(irq1, rasterLine) // last six chars (with a few raster lines to stabalize raster)
//!loop:
.pc = * "DEBUG MAIN LOOP"
    _insertStateMachinesWork($0c90)

//    jmp !loop-

/********************************************
MAIN INTERRUPT LOOP
*********************************************/

irq1:
	:startInterrupt()
//	:doubleIRQ(rasterLine)

    jsr funcDisplaySpriteSplitA
    lda #$ff
    sta REG_SPRITE_ENABLE

    lda $d016
    ora #%00010000
    sta $d016

	:mov #<irq2: $fffe
    :mov #>irq2: $ffff
	:mov #rasterLine2:$d012
	:mov #$ff: $d019
	:endInterrupt()

irq2:
	:startInterrupt()
    jsr funcDisplaySpriteSplitB
    //setup bottom border
    lda #%00111011
    sta $d011

	:mov #<irq3: $fffe
    :mov #>irq3: $ffff
	:mov #rasterLine3:$d012
	:mov #$ff: $d019
	:endInterrupt()


irq3:
	:startInterrupt()
    //pop bottom border
    lda #%00110011 //$13
    sta $d011

    //handle multispeed scroller
    ldy zp_spriteScrollCurrentSpeed
    bne !loop+
    jsr funcRenderSpriteScroller
    jmp !skip+
!loop:
    jsr funcRenderSpriteScroller
    dey
    bne !loop- 
!skip:
    
    jsr funcFlashSpriteColors
    jsr music.play

	:mov #<irq4: $fffe
    :mov #>irq4: $ffff
	:mov #$30:$d012
    lda $d011
    ora #%10000000
    sta $d011
	:mov #$ff: $d019
	:endInterrupt()


irq4:
	:startInterrupt()
    //stop sprite ghosts appearing at top of screen
    lda #$00
    sta REG_SPRITE_ENABLE
	:mov #<irq1: $fffe
    :mov #>irq1: $ffff
	:mov #rasterLine:$d012
    lda $d011
    and #%01111111
    sta $d011
	:mov #$ff: $d019
	:endInterrupt()

/********************************************
FUNCTIONS
*********************************************/

funcInitData:
    lda #%10000000
    sta zp_bitmask_controlchar
    lda #%01000000
    sta zp_bitmask_color
    lda #%00100000
    sta zp_bitmask_speed

    lda #$01
    sta zp_spriteScrollCurrentColor
    sta zp_spriteScrollCurrentSpeed

    lda #$00
    sta zp_spriteScrollDelayTimer
    sta zp_spriteScrollColorFlasherCounter
    sta zp_spriteScrollOffsetPtr

    lda #<SCROLLTEXT
    sta <mem_spriteScolltextOffsetPtr
    lda #>SCROLLTEXT
    sta >mem_spriteScolltextOffsetPtr


    //set the bank to #2 with SPINDLE resident
    lda #$3d
    sta $dd02 

    lda #%00001000 //set screen mem to $0000 and bitmap to $2000 (+ bank)
    sta $d018

    ldx #$00
    ldy #$00
    lda #music.startSong-1
    jsr music.init

    lda #$c0
!loop:
    cmp $d012
    bne !loop-
    rts


    
//SPRITE SCROLLER
funcRenderSpriteScroller:
    lda zp_spriteScrollDelayTimer
    beq !skip+
    inc zp_spriteScrollDelayTimer
    bne !noReset+
    lda #$01
    sta zp_spriteScrollCurrentSpeed
!noReset:
    rts
!skip:
    ldx zp_spriteScrollOffsetPtr
    inx
    cpx #spriteShiftOffsets
    beq !skip+
    stx zp_spriteScrollOffsetPtr
    rts
!skip:
    lda #$00
    sta zp_spriteScrollOffsetPtr
    .for(var i=(totalSpriteCount-1);i>0;i--){
        lda SPRITE_POINTERS+i-1
        sta SPRITE_POINTERS+i
        lda SPRITE_COLORS+i-1
        sta SPRITE_COLORS+i
    }
    jsr funcGetNextScrollTextChar
    bit zp_bitmask_controlchar
    beq !skip+ //not a control char, just act normal
    bit zp_bitmask_color
    beq !next+
    jsr funcGetNextScrollTextChar
    sta zp_spriteScrollCurrentColor
    jmp !finish+
!next:
    bit zp_bitmask_speed
    beq !next+
    and #%00001111
    sta zp_spriteScrollCurrentSpeed
    cmp #$00
    bne !finish+
    lda #$80
    sta zp_spriteScrollDelayTimer
    jmp !finish+
!next:

!finish:  
    /*get a real char - no two control chars next to each other!*/
    jsr funcGetNextScrollTextChar
!skip:
    clc
    /*
    sbc #$20 = the start of our font is at space char
    adc #$c0 = sprite pointers are at $3000
    */
    adc #(spriteFontPointerBase - $20)
    sta SPRITE_POINTERS
    lda zp_spriteScrollCurrentColor
    sta SPRITE_COLORS
    rts

funcFlashSpriteColors:
    ldy #$00
    ldx zp_spriteScrollColorFlasherCounter
!loop:
    lda SPRITE_COLORS,y
    and #%11110000
    cmp #$00
    beq !skip+
    sta flashPtr //base offset of zero
    lda flashPtr: SPRITE_FLASH_COLORS,x
    sta SPRITE_COLORS,y
!skip:
    iny
    cpy #totalSpriteCount
    bne !loop-
    inx
    cpx #$10
    bne !skip+
    ldx #$00
!skip:
    stx zp_spriteScrollColorFlasherCounter
    rts

/*
called by renderSpriteScroller
*/
funcGetNextScrollTextChar:
    lda mem_spriteScolltextOffsetPtr: SCROLLTEXT
    bne !skip+
    lda #<SCROLLTEXT
    sta mem_spriteScolltextOffsetPtr
    lda #>SCROLLTEXT
    sta mem_spriteScolltextOffsetPtr + 1
    lda SCROLLTEXT
!skip:
    inc mem_spriteScolltextOffsetPtr
    bne !skip+
    inc mem_spriteScolltextOffsetPtr + 1
!skip:
    rts

.var bitmasks = List()
.eval bitmasks.add(%00000001)  
.eval bitmasks.add(%00000010)  
.eval bitmasks.add(%00000100)  
.eval bitmasks.add(%00001000)  
.eval bitmasks.add(%00010000)  
.eval bitmasks.add(%00100000)  
.eval bitmasks.add(%01000000)  
.eval bitmasks.add(%10000000)  

funcDisplaySpriteSplitA:
    lda #$00
    sta REG_SPRITE_X_MSB
    ldx zp_spriteScrollOffsetPtr
.for(var i=0;i<8;i++){
        .var baseline = 0
        .var off = ((i+baseline)*($100/totalSpriteCount))
        lda SPRITE_SCROLL_X_LO + off,x
        sta REG_SPRITE_X_0 + (i*2)
        lda SPRITE_SCROLL_X_HI + off,x
        beq !skip+
        lda REG_SPRITE_X_MSB
        ora #bitmasks.get(i)
        sta REG_SPRITE_X_MSB
    !skip:
        lda SPRITE_SCROLL_Y + off,x
        sta REG_SPRITE_Y_0 + (i*2)
        lda SPRITE_POINTERS + i + baseline
        sta REG_SPRITE_DATA_PTR_0 + $4000 - $0400 + i
        lda SPRITE_COLORS + i + baseline
        and #%00001111
        sta REG_SPRITE_COLOUR_0 + i
}
    rts

funcDisplaySpriteSplitB:
    lda #$00
    sta REG_SPRITE_X_MSB
    ldx zp_spriteScrollOffsetPtr
.for(var i=0;i<7;i++){ //don't use sp8 as the overlap sprite is sp8
        .var baseline = 8
        .var off = ((i+baseline)*($100/totalSpriteCount))
        lda SPRITE_SCROLL_X_LO + off,x
        sta REG_SPRITE_X_0 + (i*2)
        lda SPRITE_SCROLL_X_HI + off,x
        beq !skip+
        lda REG_SPRITE_X_MSB
        ora #bitmasks.get(i)
        sta REG_SPRITE_X_MSB
    !skip:
        lda SPRITE_SCROLL_Y + off,x
        sta REG_SPRITE_Y_0 + (i*2)
        lda SPRITE_POINTERS + i + baseline
        sta REG_SPRITE_DATA_PTR_0 + $4000 - $0400 + i
        lda SPRITE_COLORS + i + baseline
        and #%00001111
        sta REG_SPRITE_COLOUR_0 + i
}
    rts



/********************************************
DATASETS
*********************************************/

/*
Set up the rest of the memory map here!
*/

.pc = $4000 "CHAR RAM"
.fill $0400, $00

.pc = $6000 "BITMAP"
.fill $2000, $00

.pc = $8000 "OCP BUFFER"
.fill $2800, $00



.pc=music.location "Music"
.fill music.size, music.getData(i)

_spriteFontReader("rsrc/spritefont.gif",spriteFontAddress,60)




/********************************************
MACROS
*********************************************/
/*
These macros work with the scroller
*/
.macro scrollSpeed(speed){
    .byte %10100000 | speed
}

.macro scrollColor(color){
    .byte %11000000 
    .byte color
}

.macro scrollRaster(){
    .byte %10010000 
}

.macro _spriteFontReader(filename, startAdr, charCount) {
    .var spriteData = List()
    .var pic = LoadPicture(filename)
    .for (var char=0; char<charCount; char++) {
        .for (var row=0; row<21; row++) {
            .eval spriteData.add(pic.getSinglecolorByte((char * 3), row) ^ $ff)
            .eval spriteData.add(pic.getSinglecolorByte((char * 3)+1, row) ^ $ff)
            .eval spriteData.add(pic.getSinglecolorByte((char * 3)+2, row) ^ $ff)
        }
        .eval spriteData.add(0)
    }
    .pc = startAdr "sprite font"
    .fill spriteData.size(), spriteData.get(i)
}


.macro _outputMusicInfo(){
    //----------------------------------------------------------
// Print the music info while assembling
.print ""
.print "SID Data"
.print "--------"
.print "location=$"+toHexString(music.location)
.print "init=$"+toHexString(music.init)
.print "play=$"+toHexString(music.play)
.print "songs="+music.songs
.print "startSong="+music.startSong
.print "size=$"+toHexString(music.size)
.print "name="+music.name
.print "author="+music.author
.print "copyright="+music.copyright
.print ""
.print "Additional tech data"
.print "--------------------"
.print "header="+music.header
.print "header version="+music.version
.print "flags="+toBinaryString(music.flags)
.print "speed="+toBinaryString(music.speed)
.print "startpage="+music.startpage
.print "pagelength="+music.pagelength
}
