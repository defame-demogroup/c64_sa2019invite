.var bitmapData = List()
.var screenData = List()
.var d800Data = List()

.function _getC64Color(xPos, yPos, pic, rgb2c64) {
	.if (multiColorMode) .eval xPos = xPos*2
	.var rgb = pic.getPixel(xPos, yPos+1)
	.var c64Color = rgb2c64.get(rgb)
	.return c64Color
}
	
.function _getBlockColors(chrX, chrY, pic, rgb2c64, multiColorMode) {
	.var colorCounts = List()
	.for (var i=0; i<16; i++) .eval colorCounts.add(0)
	.for (var pixY=0; pixY<8; pixY++) {
	.for (var pixX=0; pixX<charWidth; pixX++) {
		.var c64Color = _getC64Color(chrX*charWidth + pixX, chrY*8 + pixY, pic, rgb2c64)
		.eval colorCounts.set(c64Color, colorCounts.get(c64Color) + 1)
	}}
	.if (multiColorMode) .eval colorCounts.set(bgColor,0)
	.for (var i=0; i<16; i++) .eval colorCounts.set(i, [colorCounts.get(i) << 4] | i)
	.eval colorCounts.sort()
	.eval colorCounts.reverse()
	.var blockColors = List()
	.for (var i=0; i<16; i++) .eval blockColors.add(0)
	.for (var i=0; i<numBlockColors; i++) {
		.var c64Color = colorCounts.get(i) & $0f
		.eval blockColors.set(c64Color, i+1)
	}
	.return blockColors
}

.function _getBlock(chrX, chrY, pic, rgb2c64, multiColorMode) {
	.var blockColors = _getBlockColors(chrX, chrY, pic, rgb2c64, multiColorMode)
	.var blockData = List()
	.for (var pixY=0; pixY<8; pixY++) {
		.var bitmapByte = 0
	.for (var pixX=0; pixX<charWidth; pixX++) {
		.var c64Color = _getC64Color(chrX*charWidth + pixX, chrY*8 + pixY, pic, rgb2c64)
		.var multiColor = blockColors.get(c64Color)
		.if (multiColorMode) .eval bitmapByte = bitmapByte | [multiColor << [6 - pixX*2]]
		.if (!multiColorMode) .eval bitmapByte = bitmapByte | [[[multiColor-1]^1] << [7 - pixX]]
	}
		.eval blockData.add(bitmapByte)
	}
	.for (var multiColor=1; multiColor<4; multiColor++) {
		.var c64Color = 0
		.for (var i=1; i<16; i++) {
			.if (blockColors.get(i) == multiColor) .eval c64Color = i
		}
		.eval blockData.add(c64Color)
	}
	.return blockData
}


.function _parseDoublePic(pic, rgb2c64, multiColorMode) {
    _parseMultiPic(pic,2,rgb2c64,multiColorMode)
}

.function _parsePic(pic, rgb2c64, multiColorMode) {
    .for (var chrY=0; chrY<25; chrY++) {
        .for (var chrX=0; chrX<40; chrX++) {
            .var block = _getBlock(chrX+picNo*40, chrY, pic, rgb2c64)
            .for (var i=0; i<8; i++) .eval bitmapData.add(block.get(i))
            .var scrColor = [block.get(8) << 4] | [block.get(9) & $f]
            .eval screenData.add(scrColor)
            .if (multiColorMode) .eval d800Data.add(block.get(10))
        }
    }
}

.function _parseMultiPic(pic, frames, rgb2c64, multiColorMode) {
	.for (var picNo=0; picNo<frames; picNo++) {
        .for (var chrY=0; chrY<25; chrY++) {
            .for (var chrX=0; chrX<40; chrX++) {
                .var block = _getBlock(chrX+picNo*40, chrY, pic, rgb2c64)
                .for (var i=0; i<8; i++) .eval bitmapData.add(block.get(i))
                .var scrColor = [block.get(8) << 4] | [block.get(9) & $f]
                .eval screenData.add(scrColor)
                .if (multiColorMode) .eval d800Data.add(block.get(10))
	        }
        }
    }
}

.function _initPalette(pngPic, multiColorMode) {
	.var rgb2c64 = Hashtable()
	.for (var i=0; i<16; i++) {
		.var xPos = i
		.if (multiColorMode) .eval xPos = i*2
		.var rgb = pngPic.getPixel(xPos,0)
		.eval rgb2c64.put(rgb, i)
	}
	.var bgRgb = pngPic.getPixel(32,0)
	.eval bgColor = rgb2c64.get(bgRgb)
	.if (borderColor == -1) .eval borderColor = bgColor
	.return rgb2c64
}