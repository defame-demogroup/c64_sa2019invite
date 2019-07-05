
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


//use this to inder INSIDE IRQ
.macro _insertStateMachinesIRQ(){
    lda SM_DISABLE
    beq !+
    //disabled, just return
    rts
!:
    lda #$01
    sta SM_COMPLETED
    .for(var i=0;i<screen_height;i++){
        .for(var j=0;j<sm_count;j++){
            _doStateMachine(i,j)
        }
    }
    lda SM_COMPLETED
    beq !+
    lda #$01
    sta SM_DISABLE
!:  
    rts
}

//use this to insert OUTSIDE IRQ
.macro _insertStateMachinesWork(irqLoaderCall){
}

/*
macro to insert a state machine
don't call this!
*/
.macro _doStateMachine(row){
    /*
    loop through sm_count
    in y reg
    jsr to sm 
    */
    ldy #$00
    jsr func_callLineStateMachine


func_callLineStateMachine:
    ldx delay: #$01
    dex
    beq !+ //no more delay, skip
    stx delay
    rts
!:
    //reset delay here
    ldx #sm_delay
    stx delay

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
    sta state
    //I need to set myself as finished.
    lda #sm_done_flag
    sta SM_OFFSETS + (screen_height * smIndex) + row
    rts

!:
    //tell all other SM's that this block is taken!
    lda #$01
    sta SM_FINISHED,x

    //this is trying to be a switch statement 
    //by using the state, multiply by 4 and use
    //use that as the offset into a jump table 
    //which is why the NOPs are essential here
    lda state: #$00
    asl
    asl
    sta offset
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
    lda SM_DELAYS + (screen_height * smIndex) + row
    sta delay

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
    
    inc state
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
    
    inc state
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

    inc state
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

    inc state
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

    inc state
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

    inc state
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

    inc state
    rts
n100:
    lda v_colorram + (row * screen_width),x
    sta r_colorram + (row * screen_width),x

    lda v_screen + (row * screen_width),x
    sta r_screen + (row * screen_width),x

    //now set up machine for next move
    lda  SM_DELTAS + (screen_height * smIndex) + row
    and #%10000000
    beq backwards

forwards:
    clc
    lda SM_OFFSETS + (screen_height * smIndex) + row
    adc SM_DELTAS + (screen_height * smIndex) + row
    sta SM_OFFSETS + (screen_height * smIndex) + row
    jmp finished

backwards:
    sec
    lda SM_OFFSETS + (screen_height * smIndex) + row
    sbc SM_DELTAS + (screen_height * smIndex) + row
    sta SM_OFFSETS + (screen_height * smIndex) + row

finished:
    lda #$01 //never use zero as that is for first frame init only
    sta state
    
    lda #$00
    sta SM_COMPLETED //negate a complete flag
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
