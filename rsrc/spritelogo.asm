//load to $4800 to replace the sprite font!
.import source "../libs/const.asm"

.macro _loadSpritesFromPicture( filename, bgcolor, fgcolor ) {

    .var picture  = LoadPicture( filename, List().add(bgcolor, fgcolor) )
    .var xsprites = floor( picture.width  / [ 3 * 8 ] )
    .var ysprites = floor( picture.height / 21 )

    .for (var ysprite = 0; ysprite < ysprites; ysprite++) {
        .for (var xsprite = 0; xsprite < xsprites; xsprite++) {
            .for (var i = 0; i < [3 * 21]; i++) {
                .byte picture.getSinglecolorByte(
                    [[xsprite * 3]  + mod(i, 3)],
                    [[ysprite * 21] + floor(i / 3)]
                )
            }
            .byte 0
        }
    }
}


.pc = $4800 "siggraph url sprites"
_loadSpritesFromPicture("siggraph_url_sprites.png", $000000, $ffffff)
.pc = * "end sprites"

//ripped from the invite.asm
.const spriteFontAddress = $4800
.const spriteFontPointerBase = (spriteFontAddress - $4000)/$40
.const x_min = $35

.pc = $4a00 "init logo animation entry point"
.for(var i=0;i<8;i++){
    lda #spriteFontPointerBase + i
    sta REG_SPRITE_DATA_PTR_0 + $4000 - $0400 + i
}

lda #$10
sta REG_SPRITE_Y_0
sta REG_SPRITE_Y_1
sta REG_SPRITE_Y_2
sta REG_SPRITE_Y_3
sta REG_SPRITE_Y_4
sta REG_SPRITE_Y_5
sta REG_SPRITE_Y_6
sta REG_SPRITE_Y_7
lda #$00
sta REG_SPRITE_MULTICOLOUR

rts

.pc = $4c00 "irq logo animation entry point"
    lda data_prt: #$00 
    tax
    tay
    jsr func_moveto
    ldx color_prt: #$00
    lda SPRITE_COLORS,x
    sta REG_SPRITE_COLOUR_0
    inx 
    lda SPRITE_COLORS,x
    sta REG_SPRITE_COLOUR_1
    inx 
    lda SPRITE_COLORS,x
    sta REG_SPRITE_COLOUR_2
    inx 
    lda SPRITE_COLORS,x
    sta REG_SPRITE_COLOUR_3
    inx 
    lda SPRITE_COLORS,x
    sta REG_SPRITE_COLOUR_4
    inx 
    lda SPRITE_COLORS,x
    sta REG_SPRITE_COLOUR_5
    inx 
    lda SPRITE_COLORS,x
    sta REG_SPRITE_COLOUR_6
    inx 
    lda SPRITE_COLORS,x
    sta REG_SPRITE_COLOUR_7
    inc data_prt
    inc color_prt
rts


//set the x and y
func_moveto:
    lda SPRITE_Y_PATH,y    
    sta REG_SPRITE_Y_0
    sta REG_SPRITE_Y_1
    sta REG_SPRITE_Y_2
    sta REG_SPRITE_Y_3
    sta REG_SPRITE_Y_4
    sta REG_SPRITE_Y_5
    sta REG_SPRITE_Y_6
    sta REG_SPRITE_Y_7
    lda SPRITE_X_MSB,x
    sta REG_SPRITE_X_MSB
    clc
    lda SPRITE_X_PATH,x
    adc #x_min
    sta REG_SPRITE_X_0
    clc
    adc #24 //sprite width
    sta REG_SPRITE_X_1
    clc
    adc #24 //sprite width
    sta REG_SPRITE_X_2
    clc
    adc #24 //sprite width
    sta REG_SPRITE_X_3
    clc
    adc #24 //sprite width
    sta REG_SPRITE_X_4
    clc
    adc #24 //sprite width
    sta REG_SPRITE_X_5
    clc
    adc #24 //sprite width
    sta REG_SPRITE_X_6
    clc
    adc #24 //sprite width
    sta REG_SPRITE_X_7
    rts

.pc = * "Sprite Non-IRQ entry point"
    
    rts

func_plot_black:
    

func_plot_image:



BITMASKS:
    .byte %10000000, %01000000, %00100000, %00010000, %00001000, %00000100, %00000010, %00000001


.pc = * "Datasets"
.align $100
SPRITE_Y_PATH:
    .fill 256, round(13 + 13*cos(toRadians(i*360/256)))

.align $100
SPRITE_X_PATH:
    .fill 256, round(32 + 32*sin(toRadians(i*360/256)))

.align $100
SPRITE_X_MSB:
.for(var i=0;i<256;i++)
{
    .var data = round(32 + 32*sin(toRadians(i*360/256)))
    .var msb = %00000000
    .if (data + x_min > 255){
        .eval msb = msb | %00000001
    }
    .if (data + x_min + (1 * 24) > 255){
        .eval msb = msb | %00000010
    }
    .if (data + x_min + (2 * 24) > 255){
        .eval msb = msb | %00000100
    }
    .if (data + x_min + (3 * 24) > 255){
        .eval msb = msb | %00001000
    }
    .if (data + x_min + (4 * 24) > 255){
        .eval msb = msb | %00010000
    }
    .if (data + x_min + (5 * 24) > 255){
        .eval msb = msb | %00100000
    }
    .if (data + x_min + (6 * 24) > 255){
        .eval msb = msb | %01000000
    }
    .if (data + x_min + (7 * 24) > 255){
        .eval msb = msb | %10000000
    }
    .byte msb
}

.align $100
SPRITE_COLORS:
    .byte $0b,$0b,$0b,$0b,$0c,$0c,$0c,$0c
    .byte $0f,$0f,$0f,$0f,$01,$01,$01,$01
    .byte $0f,$0f,$0f,$0f,$0c,$0c,$0c,$0c
    .byte $0b,$0b,$0b,$0b,$09,$09,$09,$09
    .byte $02,$02,$02,$02,$08,$08,$08,$08
    .byte $0a,$0a,$0a,$0a,$07,$07,$07,$07
    .byte $0a,$0a,$0a,$0a,$08,$08,$08,$08
    .byte $02,$02,$02,$02,$09,$09,$09,$09

    .byte $06,$06,$06,$06,$04,$04,$04,$04
    .byte $0e,$0e,$0e,$0e,$03,$03,$03,$03
    .byte $0d,$0d,$0d,$0d,$03,$03,$03,$03
    .byte $0e,$0e,$0e,$0e,$04,$04,$04,$04
    .byte $06,$06,$06,$06,$09,$09,$09,$09
    .byte $0b,$0b,$0b,$0b,$05,$05,$05,$05
    .byte $0d,$0d,$0d,$0d,$05,$05,$05,$05
    .byte $0b,$0b,$0b,$0b,$09,$09,$09,$09

    .byte $0b,$0b,$0b,$0b,$0c,$0c,$0c,$0c
    .byte $0f,$0f,$0f,$0f,$01,$01,$01,$01
    .byte $0f,$0f,$0f,$0f,$0c,$0c,$0c,$0c
    .byte $0b,$0b,$0b,$0b,$09,$09,$09,$09
    .byte $02,$02,$02,$02,$08,$08,$08,$08
    .byte $0a,$0a,$0a,$0a,$07,$07,$07,$07
    .byte $0a,$0a,$0a,$0a,$08,$08,$08,$08
    .byte $02,$02,$02,$02,$09,$09,$09,$09

    .byte $06,$06,$06,$06,$04,$04,$04,$04
    .byte $0e,$0e,$0e,$0e,$03,$03,$03,$03
    .byte $0d,$0d,$0d,$0d,$03,$03,$03,$03
    .byte $0e,$0e,$0e,$0e,$04,$04,$04,$04
    .byte $06,$06,$06,$06,$09,$09,$09,$09
    .byte $0b,$0b,$0b,$0b,$05,$05,$05,$05
    .byte $0d,$0d,$0d,$0d,$05,$05,$05,$05
    .byte $0b,$0b,$0b,$0b,$09,$09,$09,$09

.align $100
SPRITE_ORIGINAL:
_loadSpritesFromPicture("siggraph_url_sprites.png", $000000, $ffffff)

