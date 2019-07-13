//requires defines.asm to be loaded

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
.macro _insertStateMachinesInit(){
    fill_4K($00,$e000)
    fill_4K($00,$6000)
    fill_4K($00,$7000)

}

.macro _insertStateMachinesJsr(irqLoaderCall){
    //load the file
    jsr irqLoaderCall

redraw:
    //render
    lda #$01
    sta SM_COMPLETED
    .for(var i=0;i<sm_count;i++){
        ldx #i
        jsr sm00
        ldx #i
        jsr sm01
        ldx #i
        jsr sm02
        ldx #i
        jsr sm03
        ldx #i
        jsr sm04
        ldx #i
        jsr sm05
        ldx #i
        jsr sm06
        ldx #i
        jsr sm07
        ldx #i
        jsr sm08
        ldx #i
        jsr sm09
        ldx #i
        jsr sm10
        ldx #i
        jsr sm11
        ldx #i
        jsr sm12
        ldx #i
        jsr sm13
        ldx #i
        jsr sm14
        ldx #i
        jsr sm15
        ldx #i
        jsr sm16
        ldx #i
        jsr sm17
        ldx #i
        jsr sm18
        ldx #i
        jsr sm19
        ldx #i
        jsr sm20
        ldx #i
        jsr sm21
        ldx #i
        jsr sm22
        ldx #i
        jsr sm23
        ldx #i
        jsr sm24
    }
    lda SM_COMPLETED
    cmp #$01
    beq !+
    jmp redraw
!:

//delay between pictures being displayed
    jsr delay
    jsr delay
    jsr delay
    jsr delay
    jsr delay
    jsr delay
delay:
    ldy #$00
    ldx #$00
!l:
    dex
    bne !l-
    dey
    bne !l-
!l:
    dex
    bne !l-
    dey
    bne !l-
    rts

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
x register is the sm_count offset
*/
.macro _doStateMachine(row){

    //if we are done, don't change the SM_COMPLETED register
    lda SM_STEPS + (row * sm_count),x
    cmp #$00
    bne !+
    //delay for consistent framerate
    ldy #$02
!l1:
    ldx #$09
!l2:
    dex
    bne !l2-
    dey
    bne !l1-
    rts
!:
    lda #$00
    sta SM_COMPLETED 
    dec SM_DELAYS + (row * sm_count),x
    beq !+ //no more delay, skip
    rts
!:
    //reset standard interframe delay here
    lda #sm_delay
    sta SM_DELAYS + (row * sm_count),x

    //read the current position of the statemachine into y
    lda SM_OFFSETS + (row * sm_count),x
    tay

    //this is trying to be a switch statement 
    //by using the state, multiply by 4 and use
    //use that as the offset into a jump table 
    //which is why the NOPs are essential here
    lda SM_ITEM_CURRENT_STATE + (row * sm_count),x
    asl
    asl
    sta offset
    inc SM_ITEM_CURRENT_STATE + (row * sm_count),x // prep for next call
    clc
    bcc offset: !+ //this is irrelevent as it is replaced
!:
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

o75:
    lda r_colorram + (row * screen_width),y
    sta SM_COLOR_BUFFER + (row * screen_width),y
    tax
    lda COLOR_HIGH,x
    sta r_colorram + (row * screen_width),y

    lda r_screen + (row * screen_width),y
    sta SM_SCREEN_BUFFER + (row * screen_width),y
    tax
    lda COLOR_HIGH,x
    sta r_screen + (row * screen_width),y    
    rts

o50:
    lda SM_COLOR_BUFFER + (row * screen_width),y
    tax
    lda COLOR_MID,x
    sta r_colorram + (row * screen_width),y
    
    lda SM_SCREEN_BUFFER + (row * screen_width),y
    tax
    lda COLOR_MID,x
    sta r_screen + (row * screen_width),y  
    rts

o25:
    lda SM_COLOR_BUFFER + (row * screen_width),y
    tax
    lda COLOR_LOW,x
    sta r_colorram + (row * screen_width),y
    
    lda SM_SCREEN_BUFFER + (row * screen_width),y
    tax
    lda COLOR_LOW,x
    sta r_screen + (row * screen_width),y
    rts

swap:
    lda #$00
    sta r_colorram + (row * screen_width),y
    sta r_screen + (row * screen_width),y

    //set up base addresses for bitmap copy
    clc
    lda SM_BITMAP_OFFSETS_LO,y
    adc # <v_bitmap + (row * 8 * screen_width)
    sta map_src
    lda SM_BITMAP_OFFSETS_HI,y
    adc # >v_bitmap + (row * 8 * screen_width)
    sta map_src + 1

    clc
    lda SM_BITMAP_OFFSETS_LO,y
    adc # <r_bitmap + (row * 8 * screen_width)
    sta map_dst
    lda SM_BITMAP_OFFSETS_HI,y
    adc # >r_bitmap + (row * 8 * screen_width)
    sta map_dst + 1

    //copy bitmap data
    ldx #$00
!:
    lda map_src: $ffff,x //source 
    sta map_dst: $ffff,x //destination
    inx
    cpx #$08
    bne !-
    rts

n25:
    lda v_colorram + (row * screen_width),y
    tax
    lda COLOR_LOW,x
    sta r_colorram + (row * screen_width),y

    lda v_screen + (row * screen_width),y
    tax
    lda COLOR_LOW,x
    sta r_screen + (row * screen_width),y
    rts

n50:
    lda v_colorram + (row * screen_width),y
    tax
    lda COLOR_MID,x
    sta r_colorram + (row * screen_width),y

    lda v_screen + (row * screen_width),y
    tax
    lda COLOR_MID,x
    sta r_screen + (row * screen_width),y
    rts

n75:
    lda v_colorram + (row * screen_width),y
    tax
    lda COLOR_HIGH,x
    sta r_colorram + (row * screen_width),y
    lda v_screen + (row * screen_width),y
    tax
    lda COLOR_HIGH,x
    sta r_screen + (row * screen_width),y
    rts

n100:
    lda v_colorram + (row * screen_width),y
    sta r_colorram + (row * screen_width),y
    lda v_screen + (row * screen_width),y
    sta r_screen + (row * screen_width),y

    //now set up machine for next move
    lda #$00 //reset state machine to 
    sta SM_ITEM_CURRENT_STATE + (row * sm_count),x

    //we have completed a step
    dec SM_STEPS + (row * sm_count),x

    lda SM_DELTAS + (row * sm_count),x //
    and #%10000000
    bne backwards

forwards:
    clc
    lda SM_OFFSETS + (row * sm_count),x
    adc SM_DELTAS + (row * sm_count),x
    sta SM_OFFSETS + (row * sm_count),x
    rts

backwards:
    lda SM_DELTAS + (row * sm_count),x
    and #%01111111
    sta sub_val
    sec
    lda SM_OFFSETS + (row * sm_count),x
    sbc sub_val: #$00
    sta SM_OFFSETS + (row * sm_count),x
    rts
}
