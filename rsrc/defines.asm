.const v_bitmap = $8000
.const v_screen = v_bitmap + $1f40
.const v_border = v_bitmap + $2328
.const v_background = v_bitmap + $2329
.const v_colorram = v_bitmap + $2338 

.const sm_count = 6 //6 //state machine count per line - this affects the design of effect files!!!!
.const sm_delay = 1 //interframe delay for updates

.const r_screen = $4000
.const r_colorram = $d800
.const r_bitmap = $6000

.const screen_width = 40
.const screen_height = 25

//Values
.const logomask1 = %00011000
.const rasterLine = $08
.const rasterLine2 = $8f
.const rasterLine3 = $f8
.const rasterLine4 = $30 //needs high bit of $d011 set!
.const totalSpriteCount = 8 + 7
.const spriteShiftOffsets = $100/totalSpriteCount
.const spriteFontAddress = $4800
.const spriteFontPointerBase = (spriteFontAddress - $4000)/$40

//Zeropage
.const zp_base = $80
.const zp_spriteScrollCurrentColor = zp_base
.const zp_spriteScrollCurrentSpeed = zp_base + 1
.const zp_spriteScrollDelayTimer = zp_base + 2
.const zp_spriteScrollColorFlasherCounter = zp_base + 3
.const zp_spriteScrollOffsetPtr = zp_base + 4
.const zp_bitmask_controlchar = zp_base + 5
.const zp_bitmask_color = zp_base + 6
.const zp_bitmask_speed = zp_base + 7
