SPIN=spindle/spin

all:		disk.d64

invite.prg:	invite.asm
		kick $<

spindle:	
		cd spindle && make

disk.d64:	script invite.prg
		${SPIN} -vv -o $@ -a dirart.txt -d 0 -t "SIGGRAPH 2019" -e 1000 $<

clean:
		rm *.sym *.prg *.d64

run:	invite.prg
		x64 $< >/dev/null

		


