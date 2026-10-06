MODULE HaltRepeat; (* RepeatTimeout outside the timer's Fire halts with Fl.NotFiring, 75 *)
IMPORT Fl;
VAR t: Fl.Timer;
BEGIN NEW(t); Fl.RepeatTimeout(t, 1.0D0)
END HaltRepeat.
