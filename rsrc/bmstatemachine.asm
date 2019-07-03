
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
.label v_bitmap = $8000
.label v_screen = v_bitmap + $1f40
.label v_border = v_bitmap + $2328
.label v_background = v_bitmap + $2329
.label v_colorram = v_bitmap + $2338 

.label sm_count = 6 //state machine count per line - this affects the design of effect files!!!!
.label sm_delay = 2 //interframe delay for updates
.label sm_done_flag = $ff

.label r_screen = $4000
.label r_colorram = $d800
.label r_bitmap = $6000

.label screen_width = 40
.label screen_height = 25


.function setupBitmapOffsets(){
    .var bitmap_offsets = List()
    .for(var i=0;i<screen_width;i++){
        .eval bitmap_offsets.add(i * 8)
    }
    .return bitmap_offsets
}


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
start:
    lda SM_DISABLE
    beq start
    //clear the finished state of all chars on screen
    lda #$00
    //fastest loop with a comparison (-1 approach)
    ldx #screen_width
loop:

    .for(var i=0;i<screen_height;i++){
        sta SM_FINISHED + (screen_width * i) - 1,x
    }

    dex
    bne loop
    jsr irqLoaderCall
    lda #$00
    sta SM_DISABLE
    jmp start
}

/*
macro to insert a state machine
don't call this!
*/
.macro _doStateMachine(row,smIndex){
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
    ldx SM_OFFSETS + (screen_height * smIndex) + row
    //check if this state machine is finished
    cpx #sm_done_flag
    bne !+ //not done - skip
    rts //state machine is done and waiting for others to finish
!:

    //Am I done?
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


/********************************************
DATASETS
*********************************************/
SM_FINISHED: //mark completed states
.for(var i=0;i<(screen_height);i++){
    .for(var j=0;j<screen_width;j++){
        .byte $00
    }
}


SM_DISABLE:
    .byte $00

SM_COMPLETED: //endstate when stat machine is done
    .byte $00
//set to $01 initially and SM only set to zero if not done

.var bitmap_offsets = setupBitmapOffsets()

SM_BITMAP_OFFSETS_LO:
.for(var i=0; i<screen_width;i++){
    .byte <bitmap_offsets.get(i)
}

SM_BITMAP_OFFSETS_HI:
.for(var i=0; i<screen_width;i++){
    .byte >bitmap_offsets.get(i)
}

/*
this gets replaced by loaded datasets!
*/
.align $100
.pc = $a800 "state machine buffer"
SM_OFFSETS: //x offset of each statemachine (sets initial start location and then updated per frame)
.for(var i=0;i<(screen_height * sm_count);i++){
    .byte $00
}

.align $100
SM_DELTAS: //distance deltas of each state machine - high bit is subtraction
.for(var i=0;i<(screen_height * sm_count);i++){
    .byte $00
}

.align $100
SM_DELAYS: //initial frame delays for each state machine
.for(var i=0;i<(screen_height * sm_count);i++){
    .byte $00
}


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
