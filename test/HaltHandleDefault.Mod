MODULE HaltHandleDefault; (* HandleDefault outside the event dispatch halts with Fl.NotFiring, 75 *)
IMPORT Fl;
VAR used: BOOLEAN;
BEGIN
  used := Fl.HandleDefault(Fl.EvPush)
END HaltHandleDefault.
