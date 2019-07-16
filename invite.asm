.import source "libs/lib.asm"
.import source "libs/easingLib.asm"
.import source "libs/const.asm"
.import source "rsrc/defines.asm"
.import source "rsrc/bmstatemachine.asm"
.import source "rsrc/smdata.asm"
.import source "rsrc/scrolltext.asm"
.import source "rsrc/colorquads.asm"
.import source "rsrc/spritedata.asm"

/*
MEMORY MAP:
$0400-$0800 *FREE WORKING MEM
$0800-$1000 SPINDLE
$1000-$3717 Program
$3718-$3fff *FREE
$4000-$43ff CHAR RAM
$4400-$47ff *FREE
    $4400 - $4600 working data for SM
$4800-$56ff sprite font
$5700-$574f BM offsets
$5800-$5fff *FREE
    $5800 - $5bff screen working
    $5c00 - $5fff color working
$6000-$7fff BITMAP
$8000-$a7ff OCP BUFFER
$ac00-$afff ColorQuads LUTs
$b000-$b44f SPRITE DATASETS
$b500-$bfff scrolltext and FREE
$c000-$cb93 Music

$a800-$abff loaded transition data

$e000-$fxxx music

TODO:
Music to $e000
Update memory map
$b000 - $c000 -> $c000 - $cfff
make scroller work on 1 x 2 chars - scrolling 16 chars 


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
    :fill_1K($20, $0400) //remove this later - used for debug
	:fill_1K($00, $d800)
    jsr funcInitData
	:setupInterrupt(irq1, rasterLine) // last six chars (with a few raster lines to stabalize raster)
    //interrupts and memory are setup, now load music.
    jsr $0c90
    _injectMusicReset()
    lda #$01
    sta CallMusicFlag //allow interrupts to play music now

//!loop:
.pc = * "DEBUG MAIN LOOP"
    _insertStateMachinesInit()
    //one for each image
    jsr stateMachineWork
    jsr stateMachineWork
    jsr stateMachineWork
    jsr stateMachineWork
    jsr stateMachineWork
    jsr stateMachineWork
    jsr stateMachineWork
    jsr stateMachineWork

    //copy last colormap to $0400
    ldx #$00
!:
    .for(var i=0;i<25;i++){
        lda v_colorram + (i * $28),x
        sta $0400 + (i * $28),x
    }
    inx
    cpx #$28
    beq !+
    jmp !-
!:
    lda #$00
    sta endSpriteEnable
    jsr $0c90 //call the shadow scroller
    jsr $8000 //init shadow scroller
    lda #$01
    sta CallShadowScrollerFlag
    jsr $0c90 //load sprites 
    jsr $4a00 //init sprite setup
    lda #$ff
    sta endSpriteEnable
    lda #$01
    sta CallSpriteLogoFlag
!:
    jmp !-

stateMachineWork:
    _insertStateMachinesJsr($0c90)

CallShadowScrollerFlag:
.byte $00

CallMusicFlag:
.byte $00

.macro _injectMusicReset(){
    lda #$00
    jsr $e000
}

.macro _injectMusicMain(debugColor){
    lda CallMusicFlag
    beq !+
    // lda #debugColor
    // sta $d020
    jsr $e003
    // lda #$00
    // sta $d020
!:
}

.macro _injectMusicSpeed(debugColor){
    lda CallMusicFlag
    beq !+
    // lda #debugColor
    // sta $d020
    jsr $e006
    // lda #$00
    // sta $d020
!:
}

//    jmp !loop-

/********************************************
MAIN INTERRUPT LOOP
*********************************************/


//this is the interrupt call when we are running shadowscroller

irqFinal:
    :startInterrupt()
    lda endSpriteEnable: #$00
    sta REG_SPRITE_ENABLE
    //setup bottom border
    lda #%00111011 //$1b
    sta $d011
_injectMusicMain($01)
    jsr $8006
    lda CallSpriteLogoFlag: #$00
    cmp #$01
    bne !+
    jsr $4c00 
!:
_injectMusicSpeed($02)
!:
    lda $d012
    cmp #$f8
    bne !-
    lda #%00110011 //$13
    sta $d011
_injectMusicSpeed($03)
    jsr $8003
_injectMusicSpeed($04)
    :mov #$ff: $d019
    :endInterrupt()

//these are the interrupt chains for running the sprite multiplexer

irq1:
	:startInterrupt()
//	:doubleIRQ(rasterLine)

    jsr funcDisplaySpriteSplitA
    lda #$ff
    sta REG_SPRITE_ENABLE

    lda $d016
    ora #%00010000
    sta $d016

_injectMusicMain($01)



    //flag to toggle interrupt chains so it points to shadowscroller
    lda CallShadowScrollerFlag
    cmp #$01
    bne !+
    :mov #<irqFinal: $fffe
    :mov #>irqFinal: $ffff
    :mov #$60:$d012
    :mov #$ff: $d019
    :endInterrupt()
!:
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
_injectMusicSpeed($02)
    ldx #$00
    !:
    dex
    bne !-
_injectMusicSpeed($04)
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

_injectMusicSpeed($03)


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

    lda #$ff
    sta REG_SPRITE_MULTICOLOUR

    lda #$0c
    sta REG_SPRITE_MC_1
    lda #$0b
    sta REG_SPRITE_MC_2


    //set the bank to #2 with SPINDLE resident
    lda #$3d
    sta $dd02 

    lda #%00001000 //set screen mem to $0000 and bitmap to $2000 (+ bank)
    sta $d018

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

_spriteFontReader("rsrc/spritefont2.png",spriteFontAddress,60)

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
    .var pic = LoadPicture(filename, List().add($ffffff,$c0c0c0,$000000,$505050))
    .for (var char=0; char<charCount; char++) {
        .for (var row=0; row<21; row++) {
            .eval spriteData.add(pic.getMulticolorByte((char * 3), row))
            .eval spriteData.add(pic.getMulticolorByte((char * 3)+1, row))
            .eval spriteData.add(pic.getMulticolorByte((char * 3)+2, row))
        }
        .eval spriteData.add(0)
    }
    .pc = startAdr "sprite font"
    .fill spriteData.size(), spriteData.get(i)
}

