.macro _loadHiresCharsFromPicture(filename, numberOfChars , bgcolor, color0) {
	.var charsetPic = LoadPicture(filename, List().add(bgcolor, color0))
	.for ( var x = 0 ; x < numberOfChars ; x++) {
		.for( var y = 0; y < 8; y++) {
			.byte charsetPic.getSinglecolorByte(x,y)
		}
	}
}

.macro _equalCharPack(filename, screenAdr, charsetAdr) {
	.var charMap = Hashtable()
	.var charNo = 0
	.var screenData = List()
	.var charsetData = List()
	.var pic = LoadPicture(filename)

	// Graphics should fit in 8x8 Single collor / 4 x 8 Multi collor blocks
	.var PictureSizeX = pic.width/8
	.var PictureSizeY = pic.height/8

	.for (var charY=0; charY<PictureSizeY; charY++) {
		.for (var charX=0; charX<PictureSizeX; charX++) {
			.var currentCharBytes = List()
			.var key = ""
			.for (var i=0; i<8; i++) {
				.var byteVal = pic.getSinglecolorByte(charX, charY*8 + i)
				.eval key = key + toHexString(byteVal) + ","
				.eval currentCharBytes.add(byteVal)
			}
			.var currentChar = charMap.get(key)
			.if (currentChar == null) {
				.eval currentChar = charNo
				.eval charMap.put(key, charNo)
				.eval charNo++
				.for (var i=0; i<8; i++) {
					.eval charsetData.add(currentCharBytes.get(i))
				}
			}
			.eval screenData.add(currentChar)
		}
	}
	.pc = screenAdr "screen"
	.fill screenData.size(), screenData.get(i)
	.pc = charsetAdr "charset"
	.fill charsetData.size(), charsetData.get(i)
}

.macro _equalCharPackSpecial(filename, screenAdr, charsetAdr) {
	.var charMap = Hashtable()
	.var charNo = 0
	.var screenData = List()
	.var charsetData = List()
	.var pic = LoadPicture(filename)

	// Graphics should fit in 8x8 Single collor / 4 x 8 Multi collor blocks
	.var PictureSizeX = pic.width/8
	.var PictureSizeY = pic.height/8

	.for (var charY=0; charY<PictureSizeY; charY++) {
		.for (var charX=0; charX<PictureSizeX; charX++) {
			.var currentCharBytes = List()
			.var key = ""
			.for (var i=0; i<8; i++) {
				.var byteVal = pic.getSinglecolorByte(charX, charY*8 + i) ^ $ff
				.eval key = key + toHexString(byteVal) + ","
				.eval currentCharBytes.add(byteVal)
			}
			.var currentChar = charMap.get(key)
			.if (currentChar == null) {
				.eval currentChar = charNo
				.eval charMap.put(key, charNo)
				.eval charNo++
				.for (var i=0; i<8; i++) {
					.eval charsetData.add(currentCharBytes.get(i))
				}
			}
			.eval screenData.add(currentChar)
		}
	}
	.pc = screenAdr "logomatrix"
    .for(var rows=0;rows<12;rows++){
    .align $100
        .for(var x=0;x<15;x++)
            .byte $ff

        .for(var x=0;x<40;x++)
            .byte screenData.get(x+(rows*40))

        .for(var x=0;x<15;x++)
            .byte $ff
    }
	.pc = charsetAdr "charset"
	.fill charsetData.size(), charsetData.get(i)

	.pc = charsetAdr + $800 "charset2"
    .for(var i=0;i<charsetData.size();i++){
        .if(mod(i,2)==0){
            .byte charsetData.get(i) & %10101010
        }
        else{
            .byte charsetData.get(i) & %01010101
        }
    }

    .pc = charsetAdr + $800 + $800 - $08 "blank filler char"
    .fill $08, $00
    .pc = charsetAdr + $800 + $800 - $10 "blank filler char"
    .fill $08, $ff
    .pc = charsetAdr + $800 - $08 "blank filler char"
    .fill $08, $00
    .pc = charsetAdr + $800 - $10 "blank filler char"
    .fill $08, $ff
 
    }
}


