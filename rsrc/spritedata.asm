//used for plotting the logo
.pc = $b000 "SPRITE DATASETS"
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