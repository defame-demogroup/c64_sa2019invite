/********************************************
OVERWRITTEN DATASET - Spindle blows these up
*********************************************/

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

/********************************************
NON OVERWRITTEN DATASET
*********************************************/
.pc = $b800 "SM LOCAL DATA"
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

.function setupBitmapOffsets(){
    .var bitmap_offsets = List()
    .for(var i=0;i<screen_width;i++){
        .eval bitmap_offsets.add(i * 8)
    }
    .return bitmap_offsets
}
.var bitmap_offsets = setupBitmapOffsets()

SM_BITMAP_OFFSETS_LO:
.for(var i=0; i<screen_width;i++){
    .byte <bitmap_offsets.get(i)
}

SM_BITMAP_OFFSETS_HI:
.for(var i=0; i<screen_width;i++){
    .byte >bitmap_offsets.get(i)
}


SM_ITEM_DELAY:
.for(var i=0;i<screen_height;i++){
	
}

SM_ITEM_STATE:




