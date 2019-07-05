
/*
Virtual Bitmap Addresses:
Advanced Art Studio
load address: is normally $2000 but we are loading to $8000
$2000 - $3F3F   Bitmap
$3F40 - $4327   Screen RAM
$4328           Border
$4329           Background
$4338 - $471F   Color RAM
*/


//use this to insert OUTSIDE IRQ
.macro _insertStateMachinesWork(irqLoaderCall){
loop:
    //clear the finished state of all chars on screen
    lda #$00
    ldx #screen_width
!:
    .for(var i=0;i<screen_height;i++){
        sta SM_FINISHED + (screen_width * i) - 1,x
    }
    dex
    bne !-
    //load the file
    jsr irqLoaderCall

!:
    //render
    lda #$01
    sta SM_COMPLETED
    .for(var i=0;i<sm_count;i++){
        ldy #i
        jsr sm00
        ldy #i
        jsr sm01
        ldy #i
        jsr sm02
        ldy #i
        jsr sm03
        ldy #i
        jsr sm04
        ldy #i
        jsr sm05
        ldy #i
        jsr sm06
        ldy #i
        jsr sm07
        ldy #i
        jsr sm08
        ldy #i
        jsr sm09
        ldy #i
        jsr sm10
        ldy #i
        jsr sm11
        ldy #i
        jsr sm12
        ldy #i
        jsr sm13
        ldy #i
        jsr sm14
        ldy #i
        jsr sm15
        ldy #i
        jsr sm16
        ldy #i
        jsr sm17
        ldy #i
        jsr sm18
        ldy #i
        jsr sm19
        ldy #i
        jsr sm20
        ldy #i
        jsr sm21
        ldy #i
        jsr sm22
        ldy #i
        jsr sm23
        ldy #i
        jsr sm24
    }
    lda SM_COMPLETED
    bne !+
    jmp !-
!:
    jmp loop

sm00:
_doStateMachine(00)
sm01:
_doStateMachine(01)
sm02:
_doStateMachine(02)
sm03:
_doStateMachine(03)
sm04:
_doStateMachine(04)
sm05:
_doStateMachine(05)
sm06:
_doStateMachine(06)
sm07:
_doStateMachine(07)
sm08:
_doStateMachine(08)
sm09:
_doStateMachine(09)
sm10:
_doStateMachine(10)
sm11:
_doStateMachine(11)
sm12:
_doStateMachine(12)
sm13:
_doStateMachine(13)
sm14:
_doStateMachine(14)
sm15:
_doStateMachine(15)
sm16:
_doStateMachine(16)
sm17:
_doStateMachine(17)
sm18:
_doStateMachine(18)
sm19:
_doStateMachine(19)
sm20:
_doStateMachine(20)
sm21:
_doStateMachine(21)
sm22:
_doStateMachine(22)
sm23:
_doStateMachine(23)
sm24:
_doStateMachine(24)
}



/*
macro to insert a state machine
don't call this!
*/
.macro _doStateMachine(row){
//Y contains state machine index for the line
func_callLineStateMachine:
    tya
    tax
    dec SM_ITEM_CURRENT_DELAY + (row * sm_count),x
    beq !+ //no more delay, skip
    rts
!:
    //reset delay here
    lda #sm_delay
    sta SM_ITEM_CURRENT_DELAY + (row * sm_count),y

    //read the current position of the statemachine into X
    lda SM_OFFSETS + (row * sm_count),y
    tax
    
    //check if this state machine is finished
    cpx #sm_done_flag
    bne !+ //not done - skip
    rts //state machine is done and waiting for others to finish
!:

    //Am I done - as in, have I collided with anyone already?
    lda SM_FINISHED,x
    beq !+ //not done, skip
    //reset the state machine for next use
    lda #$00
    sta SM_ITEM_CURRENT_STATE + (row * sm_count),y
    //I need to set myself as finished.
    lda #sm_done_flag
    sta SM_OFFSETS + (row * sm_count),y //
    rts

!:
    //tell all other SM's that this block is taken!
    lda #$01
    sta SM_FINISHED,x
    lda #$00
    sta SM_COMPLETED //negate the complete flag so we know a state machine is still running 

    //this is trying to be a switch statement 
    //by using the state, multiply by 4 and use
    //use that as the offset into a jump table 
    //which is why the NOPs are essential here
    lda SM_ITEM_CURRENT_STATE + (row * sm_count),y //
    asl
    asl
    sta offset
    stx tmp_x
    tya
    tax
    inc SM_ITEM_CURRENT_STATE + (row * sm_count),x // prep for next call
    ldx tmp_x: #$00
    clc
    bcc offset: !+ //this is irrelevent as it is replaced
!:
    jmp init
    nop
    jmp o75
    nop
    jmp o50
    nop
    jmp o25
    nop
    jmp swap
    nop
    jmp n25
    nop
    jmp n50
    nop
    jmp n75
    nop
    jmp n100
init:
    //initial offset
    lda SM_DELAYS + (row * sm_count),y //
    sta SM_ITEM_CURRENT_DELAY + (row * sm_count),y
    rts

o75:
    lda r_colorram + (row * screen_width),x
    sta originalColorRam50
    sta originalColorRam25
    tay
    lda COLOR_HIGH,y
    sta r_colorram + (row * screen_width),x
    lda r_screen + (row * screen_width),x
    sta originalScreen50
    sta originalScreen25
    tay
    lda COLOR_HIGH,y
    sta r_screen + (row * screen_width),x    
    rts

o50:
    lda originalColorRam50: #$00 
    tay
    lda COLOR_MID,y
    sta r_colorram + (row * screen_width),x
    
    lda originalScreen50: #$00
    tay
    lda COLOR_MID,y
    sta r_screen + (row * screen_width),x    
    rts

o25:
    lda originalColorRam25: #$00 
    tay
    lda COLOR_LOW,y
    sta r_colorram + (row * screen_width),x
    
    lda originalScreen25: #$00
    tay
    lda COLOR_LOW,y
    sta r_screen + (row * screen_width),x
    rts

swap:
    lda #$00
    sta r_colorram + (row * screen_width),x
    sta r_screen + (row * screen_width),x

    //set up base addresses for bitmap copy
    clc
    lda SM_BITMAP_OFFSETS_LO,x
    adc # <v_bitmap + (row * 8 * screen_width)
    sta map_src
    lda SM_BITMAP_OFFSETS_HI,x
    adc # >v_bitmap + (row * 8 * screen_width)
    sta map_src + 1

    clc
    lda SM_BITMAP_OFFSETS_LO,x
    adc # <r_bitmap + (row * 8 * screen_width)
    sta map_dst
    lda SM_BITMAP_OFFSETS_HI,x
    adc # >r_bitmap + (row * 8 * screen_width)
    sta map_dst + 1

    //copy bitmap data
    ldy #$00
!:
    lda map_src: $ffff,y //source 
    sta map_dst: $ffff,y //destination
    iny
    cpy #$08
    bne !-
    rts

n25:
    lda v_colorram + (row * screen_width),x
    tay
    lda COLOR_LOW,y
    sta r_colorram + (row * screen_width),x

    lda v_screen + (row * screen_width),x
    tay
    lda COLOR_LOW,y
    sta r_screen + (row * screen_width),x
    rts

n50:
    lda v_colorram + (row * screen_width),x
    tay
    lda COLOR_MID,y
    sta r_colorram + (row * screen_width),x

    lda v_screen + (row * screen_width),x
    tay
    lda COLOR_MID,y
    sta r_screen + (row * screen_width),x
    rts

n75:
    lda v_colorram + (row * screen_width),x
    tay
    lda COLOR_HIGH,y
    sta r_colorram + (row * screen_width),x
    lda v_screen + (row * screen_width),x
    tay
    lda COLOR_HIGH,y
    sta r_screen + (row * screen_width),x
    rts

n100:
    lda v_colorram + (row * screen_width),x
    sta r_colorram + (row * screen_width),x
    lda v_screen + (row * screen_width),x
    sta r_screen + (row * screen_width),x

    //now set up machine for next move
    lda #$01 //never use zero as that is for first frame init only
    sta SM_ITEM_CURRENT_STATE + (row * sm_count),y
    lda SM_DELTAS + (row * sm_count),y //
    and #%10000000
    beq backwards

forwards:
    clc
    lda SM_OFFSETS + (row * sm_count),y
    adc SM_DELTAS + (row * sm_count),y
    sta SM_OFFSETS + (row * sm_count),y
    rts

backwards:
    sec
    lda SM_OFFSETS + (row * sm_count),y
    sbc SM_DELTAS + (row * sm_count),y
    sta SM_OFFSETS + (row * sm_count),y
    rts
}


//how to trigger the state machines in a cascade so you get fades etc?



/*
EFFECT_1:
SM_OFFSETS: //x offset of each statemachine (sets initial start location and then updated per frame)
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
.byte $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02

SM_DELTAS: //distance deltas of each state machine - high bit is subtraction
.byte $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
.byte $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
.byte $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03

SM_DELAYS: //initial frame delays for each state machine
.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
.byte $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
.byte $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
*/
