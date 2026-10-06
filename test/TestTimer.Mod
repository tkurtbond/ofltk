MODULE TestTimer; (* Timers fire, repeat, move and are removed; pending ones survive collections *)

IMPORT GC := GarbageCollectedHeap, Fl, Check;

TYPE
  Counting = POINTER TO RECORD (Fl.TimerDesc)
    fired, times: INTEGER  (* repeat until fired = times *)
  END;

VAR
  once, moved, removed: Counting;
  fired: INTEGER;  (* every Fire of a Counting *)
  i: INTEGER;

PROCEDURE (t: Counting) Fire*;
BEGIN
  INC(t.fired); INC(fired);
  IF t.fired < t.times THEN Fl.RepeatTimeout(t, 0.01D0) END
END Fire;

(* A timer only Fl holds: made here, and gone from this frame on return. *)
PROCEDURE AddRepeating;
  VAR t: Counting;
BEGIN NEW(t); t.times := 3; Fl.AddTimeout(t, 0.01D0)
END AddRepeating;

PROCEDURE Churn;
  VAR j: INTEGER; p: POINTER TO ARRAY OF CHAR;
BEGIN
  FOR j := 1 TO 20000 DO NEW(p, 64) END;
  GC.Collect
END Churn;

(* Waits up to about a second for fired to reach n. *)
PROCEDURE WaitFor(n: INTEGER);
  VAR k: INTEGER;
BEGIN
  k := 0;
  WHILE (fired < n) & (k < 100) DO Fl.Wait(0.01D0); INC(k) END
END WaitFor;

BEGIN
  NEW(once); once.times := 1; Fl.AddTimeout(once, 0.01D0);
  Check.Check(once.Pending() & (Fl.PendingTimers() = 1), "an added timer is pending");
  WaitFor(1);
  Check.Check((once.fired = 1) & ~once.Pending() & (Fl.PendingTimers() = 0), "it fired once");

  fired := 0; AddRepeating; Churn;
  WaitFor(3);
  Check.Check((fired = 3) & (Fl.PendingTimers() = 0),
    "a timer only Fl holds survives a collection, and repeats from its Fire");

  fired := 0;
  NEW(moved); moved.times := 1; Fl.AddTimeout(moved, 10.0D0); Fl.AddTimeout(moved, 0.01D0);
  Check.Check(Fl.PendingTimers() = 1, "adding a pending timer moves it, not adds it");
  WaitFor(1);
  FOR i := 1 TO 5 DO Fl.Wait(0.01D0) END;
  Check.Check((moved.fired = 1) & (Fl.PendingTimers() = 0), "the moved timer fired once");

  fired := 0;
  NEW(removed); removed.times := 1; Fl.AddTimeout(removed, 0.01D0); Fl.RemoveTimeout(removed);
  Check.Check(~removed.Pending() & (Fl.PendingTimers() = 0), "a removed timer isn't pending");
  FOR i := 1 TO 5 DO Fl.Wait(0.01D0) END;
  Check.Check(removed.fired = 0, "and doesn't fire");
  Fl.RemoveTimeout(removed);
  Check.Check(Fl.PendingTimers() = 0, "removing it again does nothing");
  Check.Summary
END TestTimer.
