.macro _loadMCSpritesFromPicture( filename, bgcolor, color0, color1, color2 ) {

    .var picture  = LoadPicture( filename, List().add(bgcolor, color0, color1, color2) )
    .var xsprites = floor( picture.width  / [ 3 * 8 ] )
    .var ysprites = floor( picture.height / 21 )

    .for (var ysprite = 0; ysprite < ysprites; ysprite++) {
        .for (var xsprite = 0; xsprite < xsprites; xsprite++) {
            .for (var i = 0; i < [3 * 21]; i++) {
                .byte picture.getMulticolorByte(
                    [[xsprite * 3]  + mod(i, 3)],
                    [[ysprite * 21] + floor(i / 3)]
                )
            }
            .byte 0
        }
    }
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

