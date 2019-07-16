SPIN=spindle/spin

all:		disk.d64

invite.prg: invite.asm
		kick $<

rsrc/spritelogo.prg: rsrc/spritelogo.asm	 
		kick $<

rsrc/shadowscroller.prg: rsrc/shadowscroller.asm	 
		kick $<

rsrc/sm_effect_1.prg: rsrc/sm_effect_1.asm 
		kick $<

rsrc/sm_effect_2.prg: rsrc/sm_effect_2.asm 
		kick $<

rsrc/sm_effect_3.prg: rsrc/sm_effect_3.asm 
		kick $<

rsrc/sm_effect_4.prg: rsrc/sm_effect_4.asm 
		kick $<

rsrc/sm_effect_5.prg: rsrc/sm_effect_5.asm 
		kick $<

rsrc/sm_effect_6.prg: rsrc/sm_effect_6.asm 
		kick $<

rsrc/sm_effect_8.prg: rsrc/sm_effect_8.asm 
		kick $<

disk.d64:	script invite.prg rsrc/shadowscroller.prg rsrc/sm_effect_1.prg rsrc/sm_effect_2.prg rsrc/sm_effect_3.prg rsrc/sm_effect_4.prg rsrc/sm_effect_5.prg rsrc/sm_effect_6.prg rsrc/sm_effect_8.prg rsrc/spritelogo.prg
		${SPIN} -vv -o $@ -a dirart.txt -d 0 -t "SIGGRAPH 2019" -e 1000 $<

clean:
		rm *.sym *.prg *.d64
		rm rsrc/*.sym rsrc/sm_effect_*.prg
		rm rsrc/shadowscroller.prg rsrc/spritelogo.prg

run:	disk.d64
		x64 disk.d64 >/dev/null
