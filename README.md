# c64_sa2019invite

There is finally going to be a *demoscene* event at SIGGRAPH. 

Siggraph Asia 2019
https://sa2019.siggraph.org

This is the Commodore 64 invitro for the event.

**Huge thank you to FLIPSIDE for this great soundtrack**

**Special thank you to GLOOM for his help**

**Greets to the rest of the Defame and Onslaught crew**

---

# To Build This Code

You need the following tools in your path:
* Make
* gcc 
* xa65 
* Kick assembler (using a wrapper so it can be called using `kick` on the command line)
* VICE (using `x64` on the command line)


You should use `make` from the `./spindle` directory first so that you can build Spindle toolchain


Then you should be able to just call `make` from the `./` top level of the project to build the invitro. It will generate a `disk.d64` file as well as the intermediate `.prg` files. You cannot really run the PRG standalone, you should run the demo by simply typing `x64 disk.d64` and then the magic happens!

There is also `make clean` to reset the invitro working directories (not Spindle)

---

# Special Developer Notes

Apologies for the messy code, this was hacked together in a hurry and so there is plenty of room for improvement. Some notable notes are:

* Sprite scroller is a simple multiplexer that also tracks colors in top and bottom borders
* The transitions between bitmaps are actually 150 indepoendent state machines that are provided a trajectory and started on each bitmap load
* Transitions use luna-ramps to determine appropriate 75%, 50% and 25% values for any given color (or combination of colors) based on Aaron Bell's "Secret Colors" article http://www.aaronbell.com/secret-colours-of-the-commodore-64/
* I used the same luma ramps for the shadow scroller effect at the end
* This is my first proper 'multi loader' demo I have really ever done - all my old demos had used the 'Street Gang' IRQ loader and once the drive code was loaded I simply loaded the next file and jumped to it - this demo is actually _timed_ and uses shared memory resources. Spindle is _the shizzle_...
* Shadow scroller is simple, yet hard to wrap your head around. Step 1: copy color values from bitmap (screen mem and color ram) to 'loads' in the scroller speed code (thats why there are all those 'offsets' and offset comments in the code) Step 2: the speedcode uses those values to lookup a luma Step 3: when you 'scroll' you actually scroll the high byte offset of the luma table lookups across the speedcode! It is a concept that came to me and once I got it - its a great way to speed up any big block-move a LOT. Especially this kind of indirect lookup-based kind.
* Shadow scroller concept 
