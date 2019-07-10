SPIN=spindle/spin

all:		disk.d64

invite.prg:	invite.asm
		kick $<

effects: 
		kick rsrc/shadowscroller.asm
		kick rsrc/sm_effect_1.asm
		kick rsrc/sm_effect_2.asm
		kick rsrc/sm_effect_3.asm
		kick rsrc/sm_effect_4.asm
		kick rsrc/sm_effect_5.asm
		kick rsrc/sm_effect_6.asm
		kick rsrc/sm_effect_7.asm
		kick rsrc/sm_effect_8.asm
		kick rsrc/sm_effect_9.asm

disk.d64:	script invite.prg effects
		${SPIN} -vv -o $@ -a dirart.txt -d 0 -t "SIGGRAPH 2019" -e 1000 $<

clean:
		rm *.sym *.prg *.d64
		rm rsrc/*.sym rsrc/sm_effect_*.prg

run:	invite.prg
		x64 $< >/dev/null

		


