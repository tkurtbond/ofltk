MODULE HaltDeleted; (* A method of a deleted widget halts with Fl.NotOpen, 70 *)
IMPORT Fl;
VAR b: Fl.Box;
BEGIN NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, ""); b.Delete; b.Redraw
END HaltDeleted.
