/*
Interactive tool for doing this and building custom curves:
http://www.timotheegroleau.com/Flash/experiments/easing_function_generator.htm

Parameters:
t = current time
b = start value
c = change in value (delta)
d = duration total time

Converted to Kick Assembler functions by Zig/Defame
Contact: joe@pixolut.com 

Consider time parameters as 'steps' in the case of building typical datasets

EXAMPLES:
.fill $100,linearTween(i,$00,$80,$100)
fill $100 bytes from values $00 to $80 with linear tweening

.fill $100,easeInOutQuad(i,$80,-$10,$100)
fill $100 bytes with a quadratic tweening between $80 and $70 

I don't take credit for any of the math in this code! 
*/

//simple linear tweening - no easing, no acceleration
.function linearTween(t, b, c, d) {
    .return c*t/d+b
}

// sinusoidal easing in - accelerating from zero velocity
.function easeIn(t, b, c, d) {
    .return round(-c * cos(t/d * (PI/2)) + c + b)
}


// sinusoidal easing out - decelerating to zero velocity
.function easeOut(t, b, c, d) {
    .return round(c * sin(t/d * (PI/2)) + b)
}

// sinusoidal easing in/out - accelerating until halfway, then decelerating
.function easeInOut(t, b, c, d) {
    .return round(-c/2 * (cos(PI*t/d) - 1) + b)
}
