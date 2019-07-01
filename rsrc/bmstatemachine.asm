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

.label sm_count = 2 //state machine count per line

.label r_screen = $4000
.label r_colorram = $d800
.label r_bitmap = $6000







    /*
  read delay
    count down
    not done? return

  read state
    if 1
        75
    if 2
        50
    if 3 
        25
    if 4
        0 + swap bitmap
    if 5
        25
    if 6
        50
    if 7
        75
    if 8
        100
    if 9    
        add offset
        at finish?
        no? reset delay
        yes? set done.
    */
.macro _transitionStateMachine(row,smIndex){
    ldx delay: #$00
    dex
    beq !+
    stx delay
    rts
!:
    //reset delat here 

    ldx SM_OFFSETS + (25 * sm_count) + row

    lda state: #$00
    asl
    asl
    sta offset
    clc
    bcc offset: !+
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
    
    lda r_colorram (row * 40),x
    sta originalColorRam50
    sta originalColorRam25
    tay
    lda COLOR_HIGH,y
    sta r_colorram + (row * 40),x

    lda r_screen + (row * 40),x
    sta originalScreen50
    sta originalScreen25
    tay
    lda COLOR_HIGH,y
    sta r_screen + (row * 40),x
    
    inc state
    rts
o50:
    lda originalColorRam50: #$00 
    tay
    lda COLOR_MID,y
    sta r_colorram + (row * 40),x
    
    lda originalScreen50: #$00
    tay
    lda COLOR_MID,y
    sta r_screen + (row * 40),x
    
    inc state
    rts
o25:
    lda originalColorRam25: #$00 
    tay
    lda COLOR_LOW,y
    sta r_colorram + (row * 40),x
    
    lda originalScreen25: #$00
    tay
    lda COLOR_LOW,y
    sta r_screen + (row * 40),x

    inc state
    rts
swap:
    lda #$00
    sta r_colorram + (row * 40),x
    sta r_screen + (row * 40),x

//todo swap bitmap

    inc state
    rts
n25:
    lda v_colorram (row * 40),x
    tay
    lda COLOR_LOW,y
    sta r_colorram + (row * 40),x

    lda v_screen + (row * 40),x
    tay
    lda COLOR_LOW,y
    sta r_screen + (row * 40),x

    inc state
    rts
n50:
    lda v_colorram (row * 40),x
    tay
    lda COLOR_MID,y
    sta r_colorram + (row * 40),x

    lda v_screen + (row * 40),x
    tay
    lda COLOR_MID,y
    sta r_screen + (row * 40),x

    inc state
    rts
n75:
    lda v_colorram (row * 40),x
    tay
    lda COLOR_HIGH,y
    sta r_colorram + (row * 40),x

    lda v_screen + (row * 40),x
    tay
    lda COLOR_HIGH,y
    sta r_screen + (row * 40),x

    inc state
    rts
n100:
    lda v_colorram (row * 40),x
    sta r_colorram + (row * 40),x

    lda v_screen + (row * 40),x
    sta r_screen + (row * 40),x

//update offset using delta here

    lda #$00
    sta state
    rts
}

//how to trigger the state machines in a cascade so you get fades etc?


/********************************************
DATASETS
*********************************************/
.align $100
.pc = * "state machine number"
SM_OFFSETS:
.for(var i=0;i<(25 * sm_count);i++){
    .byte $00
}

SM_DELTAS:
.for(var i=0;i<(25 * sm_count);i++){
    .byte $00
}

SM_BITMAP_OFFSET_HI:
.

SM_BITMAP_OFFSET_LO:


