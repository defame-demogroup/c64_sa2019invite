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
_loadSpritesFromPicture(siggraph_url_sprites.png,#000000,#ffffff)

.pc = $4a00 "logo animation entry point"
lda #$10
sta REG_SPRITE_Y_0
sta REG_SPRITE_Y_1
sta REG_SPRITE_Y_2
sta REG_SPRITE_Y_3
sta REG_SPRITE_Y_4
sta REG_SPRITE_Y_5
sta REG_SPRITE_Y_6
sta REG_SPRITE_Y_7
rts
