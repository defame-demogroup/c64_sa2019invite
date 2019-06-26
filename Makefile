SPIN=spindle/spin

all:		disk.d64

invite.prg:	invite.asm
		kick $<

disk.d64:	script invite.prg
		${SPIN} -vv -o $@ -a dirart.txt -d 2 -e 5000 $<

clean:
		rm *.sym *.prg *.d64


run:		invite.prg
		x64 $< >/dev/null

		


