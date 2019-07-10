# c64_sa2019invite

There is finally going to be a *demoscene* event at SIGGRAPH. 

Siggraph Asia 2019
https://sa2019.siggraph.org

This is the Commodore 64 invitro for the event.

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
