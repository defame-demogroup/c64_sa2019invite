/*
this gets replaced by loaded datasets!
*/

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