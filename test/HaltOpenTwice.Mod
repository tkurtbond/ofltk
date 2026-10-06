MODULE HaltOpenTwice; (* Opening a widget twice halts with Fl.OpenedTwice, 71 *)
IMPORT Fl;
VAR b: Fl.Box;
BEGIN NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, ""); Fl.OpenBox(b, 0, 0, 10, 10, "")
END HaltOpenTwice.
