.label black = 0
.label white = 1
.label red = 2
.label cyan = 3
.label purple = 4
.label green = 5
.label blue = 6
.label yellow = 7
.label orange = 8
.label brown = 9
.label pink = 10
.label dgrey = 11
.label grey = 12
.label lgreen = 13
.label lblue = 14
.label lgrey = 15

// common register definitions
.label REG_INTSERVICE_LOW      = $0314              // interrupt service routine low byte
.label REG_INTSERVICE_HIGH     = $0315              // interrupt service routine high byte
.label REG_SPRITE_DATA_PTR_0   = $07f8              // sprite data pointer address start
.label REG_SPRITE_X_0          = $d000              // sprite 0 x position
.label REG_SPRITE_Y_0          = $d001              // sprite 0 y position
.label REG_SPRITE_X_1          = $d002              // sprite 1 x position
.label REG_SPRITE_Y_1          = $d003              // sprite 1 y position
.label REG_SPRITE_X_2          = $d004              // sprite 2 x position
.label REG_SPRITE_Y_2          = $d005              // sprite 2 y position
.label REG_SPRITE_X_3          = $d006              // sprite 3 x position
.label REG_SPRITE_Y_3          = $d007              // sprite 3 y position
.label REG_SPRITE_X_4          = $d008              // sprite 4 x position
.label REG_SPRITE_Y_4          = $d009              // sprite 4 y position
.label REG_SPRITE_X_5          = $d00a              // sprite 5 x position
.label REG_SPRITE_Y_5          = $d00b              // sprite 5 y position
.label REG_SPRITE_X_6          = $d00c              // sprite 6 x position
.label REG_SPRITE_Y_6          = $d00d              // sprite 6 y position
.label REG_SPRITE_X_7          = $d00e              // sprite 7 x position
.label REG_SPRITE_Y_7          = $d00f              // sprite 7 y position
.label REG_SPRITE_X_MSB        = $d010              // sprite 0-7 X position bit 8
.label REG_SCREENCTL_1         = $d011              // screen control register #1
.label REG_RASTERLINE          = $d012              // raster line position 
.label REG_SPRITE_ENABLE       = $d015              // enable sprites
.label REG_SCREENCTL_2         = $d016              // screen control register #2
.label REG_MEMSETUP            = $d018              // memory setup register
.label REG_INTFLAG             = $d019              // interrupt flag register
.label REG_INTCONTROL          = $d01a              // interrupt control register
.label REG_SPRITE_MULTICOLOUR  = $d01c              // sprite multicolour enable
.label REG_SPRITE_D_HEIGHT     = $d017              // double width sprites
.label REG_SPRITE_D_WIDTH      = $d01d              // double width sprites
.label REG_BORCOLOUR           = $d020              // border colour register
.label REG_BGCOLOUR            = $d021              // background colour register
.label REG_SPRITE_MC_1         = $d025              // extra sprite colour 1
.label REG_SPRITE_MC_2         = $d026              // extra sprite colour 2
.label REG_SPRITE_COLOUR_0     = $d027              // sprite 0 colour
.label REG_SPRITE_COLOUR_1     = $d028              // sprite 1 colour
.label REG_SPRITE_COLOUR_2     = $d029              // sprite 2 colour
.label REG_SPRITE_COLOUR_3     = $d02a              // sprite 3 colour
.label REG_SPRITE_COLOUR_4     = $d02b              // sprite 4 colour
.label REG_SPRITE_COLOUR_5     = $d02c              // sprite 5 colour
.label REG_SPRITE_COLOUR_6     = $d02d              // sprite 6 colour
.label REG_SPRITE_COLOUR_7     = $d02e              // sprite 7 colour
.label REG_INTSTATUS_1         = $dc0d              // interrupt control and status register #1
.label REG_INTSTATUS_2         = $dd0d              // interrupt control and status register #2
.label BASE_COLOUR_RAM         = $d800              // colour ram

.label BASE_CHAR_RAM = $0400
.label SCREEN_WIDTH = $28
