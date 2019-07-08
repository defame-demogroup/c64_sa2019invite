/********************************************
OVERWRITTEN DATASET - Spindle blows these up
*********************************************/
.label SM_OFFSETS = $a800 //x offset of each statemachine (sets initial start location and then updated per frame)
.label SM_STEPS = $a900 //number of steps for the state machine to run (through a full set of states)
.label SM_DELTAS = $aa00 //distance deltas of each state machine - high bit is subtraction
.label SM_DELAYS = $ab00 //initial frame delays for each state machine

/********************************************
NON LOADED DATASET
*********************************************/
//stash the current state value
.label SM_ITEM_CURRENT_STATE = $e800
.label SM_DISABLE = $e900
.label SM_COMPLETED = $e901 //endstate when stat machine is done
.label SM_SCREEN_BUFFER = $e000
.label SM_COLOR_BUFFER = $e400

/*************
LOOKUP DATASETS
**************/
.pc = $5700 "BM offsets"
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



