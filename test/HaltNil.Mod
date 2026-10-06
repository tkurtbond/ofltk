MODULE HaltNil; (* Opening NIL halts with Fl.NilArgument, 72 *)
IMPORT Fl;
VAR b: Fl.Box;
BEGIN b := NIL; Fl.OpenBox(b, 0, 0, 10, 10, "")
END HaltNil.
