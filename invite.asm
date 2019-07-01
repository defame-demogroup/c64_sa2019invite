.import source "libs/lib.asm"
.import source "libs/easingLib.asm"
.import source "libs/const.asm"

.var music = LoadSid("rsrc/Very_Bland.sid")

_outputMusicInfo()

/*
MEMORY MAP:
$0400 - $0800 ???
$0800 - $1000 SPINDLE
$1000 - $4000 Code and Data 
$4000 - $4800 SCREEN RAM
$4800 - $5800 Sprite Font
$5800 - $6000 More Code or Data
$6000 - $8000 BITMAP
$8000 - $A800 BUFFER
$A800 - $B000 scroll text
$B000 - $CFFF Code and Data and MUSIC
*/


//Values
.label logomask1 = %00011000
.label rasterLine = $08
.label totalSpriteCount = 8 + 7
.label spriteShiftOffsets = $100/totalSpriteCount
.label spriteFontAddress = $4800
.label spriteFontPointerBase = (spriteFontAddress - $4000)/$40

//Zeropage
.label zp_base = $80
.label zp_spriteScrollCurrentColor = zp_base
.label zp_spriteScrollCurrentSpeed = zp_base + 1
.label zp_spriteScrollDelayTimer = zp_base + 2
.label zp_spriteScrollColorFlasherCounter = zp_base + 3
.label zp_spriteScrollOffsetPtr = zp_base + 4
.label zp_bitmask_controlchar = zp_base + 5
.label zp_bitmask_color = zp_base + 6
.label zp_bitmask_speed = zp_base + 7


//addresses

/*
.pc = $0801 "Basic Upstart"
:BasicUpstart(start) // 10 sys$0810
*/
.pc =$1000 "Program"
start:
	:mov #$00: $d020
	:mov #$0c: $d021
	:fill_1K($00, $d800)
    :fill_1K($21, $0400) //clear screen with blank chars
    jsr funcInitData
    sei
    lda #$36
    sta $01
    cli
	:setupInterrupt(irq, rasterLine) // last six chars (with a few raster lines to stabalize raster)
!loop:
    jmp !loop-

/********************************************
MAIN INTERRUPT LOOP
*********************************************/

irq:
	:startInterrupt()
	:doubleIRQ(rasterLine)

lda #$06
sta $d020
    jsr funcDisplaySpriteSplitA
lda #$00
sta $d020
    lda #$ff
    sta REG_SPRITE_ENABLE

!loop:
    lda $d012
    cmp #$8f
    bne !loop-
lda #$04
sta $d020
    jsr funcDisplaySpriteSplitB
lda #$00
sta $d020

    //pop bottom border
    lda #%00111011
    sta $d011

!loop:
    lda $d012
    cmp #$f8
    bne !loop-

    lda #%00110011 //$13
    sta $d011

lda #$09
sta $d020
    jsr music.play
lda #$00
sta $d020     

lda #$07
sta $d020
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
lda #$00
sta $d020

!loop:
    lda $d011
    and #%10000000
    beq !loop-
    lda $d012
    cmp #$30
    bne !loop-
inc $d020
dec $d020
lda #$00
sta REG_SPRITE_ENABLE

//----------------------------------------------

	:mov #<irq: $fffe
	:mov #rasterLine:$d012
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


funcDrawBitmap:
//todo: insert bmstatemachine and insert the calls for each sm per line


/********************************************
DATASETS
*********************************************/

//used for plotting the logo
.align $100
.pc = * "SPRITE SCROLLER DATASETS"
SPRITE_SCROLL_Y:
.fill $10,$10
.fill $70,easeIn(i,$10,$80,$70)
.fill $70,easeOut(i,$90,$80,$70)
.fill $10,$10



.align $100
SPRITE_SCROLL_X_LO:
.for(var i=$100;i>0;i--){
    .byte <(i/$100*346)
}

.align $100
SPRITE_SCROLL_X_HI:
.for(var i=$100;i>0;i--){
    .byte >(i/$100*346)
}

.align $100
.pc = * "SPRITE POINTERS"
SPRITE_POINTERS:
.fill $20, spriteFontPointerBase //fill sprites with spaces

SPRITE_COLORS:
.fill $20, $01

.align $100
SPRITE_FLASH_COLORS:
.byte $00, $06, $0e, $0f, $03, $01, $01, $01, $03, $0f, $0e, $06, $00, $00, $00, $00 //first line never gets used
.byte $10, $16, $1e, $1f, $13, $11, $11, $11, $13, $1f, $1e, $16, $10, $10, $10, $10
.byte $20, $2b, $2c, $2f, $21, $2f, $2c, $2b, $20, $2b, $2c, $2f, $21, $2f, $2c, $2b
.byte $3b, $34, $3b, $34, $36, $34, $36, $34, $3b, $34, $3b, $34, $36, $34, $36, $34
.byte $40, $4b, $49, $42, $47, $41, $47, $42, $49, $4b, $46, $4e, $41, $4e, $46, $40

.import source "rsrc/colorquads.asm"



//SCROLLER!!!
.align $100
.pc = $a800 "scrolltext"
SCROLLTEXT:
.text " HELLO THIS IS AN EXAMPLE WELCOME TO THIS EXAMPLE WELCOME TO THIS EXAMPLE "
.byte $00
scrollColor($01)
.text " HELLO "
scrollSpeed($02)
.text "  PARTY PEOPLE "
scrollColor($04)
.text "WE NEED SOME         "
scrollColor($21)
.text "     RASTER BARS!"
scrollSpeed($00)
.text "  "
scrollSpeed($02)
.text "  "
scrollSpeed($03)
.text "  "
scrollColor($04)
.text "  WE "
scrollColor($21)
.text " LOVE " 
scrollColor($04)
.text " OLD SKOOL EFFECTS... "
scrollSpeed($02)
.text " ...AND THAT IS WHAT I HAVE FOR YOU TODAY LADIES AND GENTLEMEN..."
scrollColor($02)
.text "  "
scrollSpeed($03)
.text " COME AND GATHER ROUND BOYS AND GIRLS WHILE I TELL YOU ABOUT PARTYSCROLLERS FROM THE OLD DAYS."
scrollColor($31)
.text "  "
scrollSpeed($02)
.text "...AND NOW FOR SOME MESSAGES FROM PARTYPEOPLE AT SYNTAX..."
scrollSpeed($01)
.text " ARE YOU READY? "
scrollColor($05)
.text "  "
scrollSpeed($02)
.text "EVILEYE I AM ON THE BIG SCREEN!! LUL"
scrollColor($07)
.text "  "
scrollSpeed($03)
.text "AZRYL SEZ LIFE SUX WHEN YOUR GIRLFRIEND DOESNT :)"
scrollColor($0a)
.text "  "
scrollSpeed($02)
.text "STYLE/CHROME HERE."
scrollSpeed($03)
.text " I DONT KNOW WHAT THIS DEMO IS, BUT IT MUST RULE BECAUSE SCROLLTEXTS. UPVOTE FOR SURE."
scrollColor($01)
.text "  (CENSORED)  "
scrollColor($0a)
.text "  PEACE OUT!"
scrollColor($0d)
.text "  "
scrollSpeed($03)
.text "VOLTAGE ON THE KEYS AT "
scrollColor($11)
.text "  SYNTAX 2018  "
 scrollColor($0d)
.text "  !!!!!!!  OHHHH YEAH...  SHOUTOUTS TO ALL THE RAD SCENERS OUT THERE.  BLERG.. I'M ALREADY HUNGOVER, BUT BACK ON THE BAD BOYS AGAIN. I'LL GROW UP LATER, MAYBE.  STAY FROSTY.  VOLT OUT."
scrollColor($21)
.text "  "
scrollSpeed($02)
.text "  RELOAD HERE, WE ARE BACK! DEMO OR DIE!  "
scrollColor($01)
.text "  "
scrollSpeed($03)
.text "  MIKNIK DOWN HERE IN VIC AGAIN, CHEERS EVERYONE!  "
scrollColor($0e)
.text "  "
scrollSpeed($02)
.text "  JAZZCAT HERE ON THE KEYS... "
scrollSpeed($03)
.text "SO, HERE WE ARE AT FUCKING SYNTAX MAN... OOOH YEAHHHH.. NOTHING BEATS A SWEET SCROLLER, THIS IS WHERE IT IS AT, THIS IS WHERE IT ALL BEGAN. ANYWAY, HANDING OVER TO SOMEONE ELSE SO I CAN DOWN SOME MORE BEERZ... SEE YOU NEXT TIME!  "
scrollColor($11)
.text "  "
scrollSpeed($02)
.text "  ZIG HERE... ITS BEEN DECADES SINCE I DID ANY SERIOUS C64 CODE.  CREDITS GO TO 4-MATT FOR THE GREAT TUNE."
scrollColor($01)
.text "  "
scrollSpeed($03)
.text "  I JUST LOVE THIS MACHINE AND THE DEMOSCENE CULTURE AROUND IT. AS CRAZY AS THIS WORLD BECOMES, 8 BITS MAKES IT FUN...  "
scrollColor($41)
.text "  "
scrollSpeed($01)
.text "  ...GREETINGS TO EVERYONE IN DEFAME, THE SYNTAX CREW, AND ALL YOU GREAT SYNTAX PARTY PEOPLE.  "
.byte $00

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


 .pc=music.location "Music"
 .fill music.size, music.getData(i)

/********************************************
CALLING MACROS (to fixed address outputs)
*********************************************/

/*
startAdr = base address of the d011 frames. Each frame contains frameSize of $d011 values and (max) logoCharRows 
lutAdr = double-byte LUT address (lo/hi) of the frames
frameCount = total number of frames to render
frameSize = number of raster lines in each frame
maxSplitSize = total raster lines to use in FLD total 
*/
_spriteFontReader("rsrc/spritefont.gif",spriteFontAddress,60)

/********************************************
MACROS
*********************************************/

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



/*
Advanced Art Studio
load address: $2000 - $471F
$2000 - $3F3F	Bitmap
$3F40 - $4327	Screen RAM
$4328	Border
$4329	Background
$4338 - $471F	Color RAM
*/

