MODULE HaltBoxType; (* A box type past 255 halts with Fl.IndexOutOfRange, 74: FLTK would read past its table *)
IMPORT Fl;
VAR n: INTEGER;
BEGIN
  n := Fl.BoxDX(256)
END HaltBoxType.
