
.pc = $ac00 "ColorQuads LUTs"
/*
http://www.aaronbell.com/secret-colours-of-the-commodore-64/
LUMA RAMP:
0
6
9
2
11
4
8
14
12
5
10
3
15
7
13
1

The following 16 color 'quad ramp' gives 
*/
.struct ColorBlend{originalColor, highColor,midColor,lowColor}
.var colorSubs = List(16)
.eval colorSubs.set(0,ColorBlend(0,0,0,0))
.eval colorSubs.set(1,ColorBlend(1,15,12,11))
.eval colorSubs.set(2,ColorBlend(2,9,6,0))
.eval colorSubs.set(3,ColorBlend(3,12,4,6))
.eval colorSubs.set(4,ColorBlend(4,11,6,0))
.eval colorSubs.set(5,ColorBlend(5,8,9,0))
.eval colorSubs.set(6,ColorBlend(6,6,0,0))
.eval colorSubs.set(7,ColorBlend(7,10,8,2))
.eval colorSubs.set(8,ColorBlend(8,11,9,0))
.eval colorSubs.set(9,ColorBlend(9,9,0,0))
.eval colorSubs.set(10,ColorBlend(10,8,9,0))
.eval colorSubs.set(11,ColorBlend(11,11,9,0))
.eval colorSubs.set(12,ColorBlend(12,8,11,9))
.eval colorSubs.set(13,ColorBlend(13,3,14,6))
.eval colorSubs.set(14,ColorBlend(14,4,11,6))
.eval colorSubs.set(15,ColorBlend(15,12,11,6))

.align $100
COLOR_HIGH:
.for (var colora=0;colora < $10; colora++){
    .for (var colorb=0;colorb < $10; colorb++){
        .var hi = (colorSubs.get(colora)).highColor
        .var lo = (colorSubs.get(colorb)).highColor
        .byte ((hi<<4)|lo)
    }
}

.align $100
COLOR_MID:
.for (var colora=0;colora < $10; colora++){
    .for (var colorb=0;colorb < $10; colorb++){
        .var hi = (colorSubs.get(colora)).midColor
        .var lo = (colorSubs.get(colorb)).midColor
        .byte ((hi<<4)|lo)
    }
}

.align $100
COLOR_LOW:
.for (var colora=0;colora < $10; colora++){
    .for (var colorb=0;colorb < $10; colorb++){
        .var hi = (colorSubs.get(colora)).lowColor
        .var lo = (colorSubs.get(colorb)).lowColor
        .byte ((hi<<4)|lo)
    }
}

.align $100
COLOR_REAL:
.fill $100,i
