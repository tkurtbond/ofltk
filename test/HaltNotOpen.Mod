MODULE HaltNotOpen; (* A method of a widget never opened halts with Fl.NotOpen, 70 *)
IMPORT Fl;
VAR b: Fl.Box;
BEGIN NEW(b); b.Redraw
END HaltNotOpen.
