.pc = $1000 "SM EFFECT DEFINITION"
SM_OFFSETS: //x offset of each statemachine (sets initial start location and then updated per frame)
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05
.byte $27,$26,$25,$24,$23,$22
.byte $00,$01,$02,$03,$04,$05

.align $100
SM_STEPS: //number of steps the sm should do before it dies
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06
.byte $07,$07,$07,$07,$06,$06

.align $100
SM_DELTAS: //distance deltas of each state machine - high bit is subtraction
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06
.byte $86,$86,$86,$86,$86,$86
.byte $06,$06,$06,$06,$06,$06

.align $100
SM_DELAYS: //initial frame delays for each state machine
.byte $01,$03,$05,$07,$09,$0b
.byte $01,$03,$05,$07,$09,$0b
.byte $11,$13,$15,$17,$19,$1b
.byte $11,$13,$15,$17,$19,$1b
.byte $21,$23,$25,$27,$29,$2b
.byte $21,$23,$25,$27,$29,$2b
.byte $31,$33,$35,$37,$39,$3b
.byte $31,$33,$35,$37,$39,$3b
.byte $41,$43,$45,$47,$49,$4b
.byte $41,$43,$45,$47,$49,$4b
.byte $51,$53,$55,$57,$59,$5b
.byte $51,$53,$55,$57,$59,$5b
.byte $61,$63,$65,$67,$69,$6b
.byte $61,$63,$65,$67,$69,$6b
.byte $71,$73,$75,$77,$79,$7b
.byte $71,$73,$75,$77,$79,$7b
.byte $81,$83,$85,$87,$89,$8b
.byte $81,$83,$85,$87,$89,$8b
.byte $91,$93,$95,$97,$99,$9b
.byte $91,$93,$95,$97,$99,$9b
.byte $a1,$a3,$a5,$a7,$a9,$ab
.byte $a1,$a3,$a5,$a7,$a9,$ab
.byte $b1,$b3,$b5,$b7,$b9,$bb
.byte $b1,$b3,$b5,$b7,$b9,$bb
.byte $c1,$b3,$c5,$c7,$c9,$cb
