MODULE TestLoop; (* The event loop: idle callbacks, file descriptors' watches, the event dispatch, event handlers *)

IMPORT GC := GarbageCollectedHeap, Fl, FlButtons, FlInputs, Check, Probe;

TYPE
  (* Counts its runs, and removes itself after stopAt of them. *)
  Counter = POINTER TO RECORD (Fl.IdleDesc) runs, stopAt: INTEGER END;

  (* Reads what its pipe has, and counts the times it was ready. *)
  Reader = POINTER TO RECORD (Fl.FdWatchDesc) ready: INTEGER; got: ARRAY 64 OF CHAR END;

VAR
  counter: Counter;
  lostRuns: INTEGER;
  reader, other: Reader;
  r, w, k, n: INTEGER;
  win: Fl.Window;
  button: FlButtons.Button;
  input: FlInputs.Input;
  box: Fl.Box;
  pressed, seen, counted, taken, once: INTEGER;
  windowSeen: Fl.Window;
  pass, deleteBox: BOOLEAN;
  s: ARRAY 64 OF CHAR;
  ok: BOOLEAN;

PROCEDURE (c: Counter) Run*;
BEGIN
  INC(c.runs);
  IF c.runs = c.stopAt THEN Fl.RemoveIdle(c) END
END Run;

(* An idle whose only reference is Fl's list, removed after 3 runs. *)
PROCEDURE CountLost(i: Fl.Idle);
BEGIN
  INC(lostRuns);
  IF lostRuns = 3 THEN Fl.RemoveIdle(i) END
END CountLost;

PROCEDURE AddLost;
  VAR i: Fl.Idle;
BEGIN NEW(i); i.action := CountLost; Fl.AddIdle(i)
END AddLost;

PROCEDURE (rd: Reader) Ready*;
BEGIN INC(rd.ready); n := Probe.Read(rd.fd, rd.got)
END Ready;

(* Waits until reader has been ready k times, up to a generous limit. *)
PROCEDURE WaitReady(rd: Reader; k: INTEGER);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (rd.ready < k) & (i < 500) DO Fl.Wait(0.01D0); INC(i) END
END WaitReady;

PROCEDURE Press(b: Fl.Widget);
BEGIN INC(pressed)
END Press;

(* Counts pushes and releases (Wayland sends others too, such as
   EvScreenConfigurationChanged); passes events on if pass; deletes box on a push if
   deleteBox; makes a keypad key type its character. *)
PROCEDURE Dispatch(event: INTEGER; wd: Fl.Window): BOOLEAN;
  VAR key: INTEGER; text: ARRAY 2 OF CHAR;
BEGIN
  IF (event = Fl.EvPush) OR (event = Fl.EvRelease) THEN INC(seen); windowSeen := wd END;
  IF deleteBox & (event = Fl.EvPush) THEN box.Delete END;
  IF (event = Fl.EvKeyDown) OR (event = Fl.EvKeyUp) THEN
    key := Fl.EventOriginalKey();
    IF (key >= Fl.KeyKP) & (key <= Fl.KeyKPLast) THEN
      text[0] := CHR(key - Fl.KeyKP); text[1] := 0X;
      Fl.SetEventText(text); Fl.SetEventKey(key)
    END
  END;
  RETURN pass & Fl.HandleDefault(event)
END Dispatch;

(* Counts shortcuts, and uses none. *)
PROCEDURE Count(event: INTEGER): BOOLEAN;
BEGIN IF event = Fl.EvShortcut THEN INC(counted) END; RETURN FALSE
END Count;

(* Uses a shortcut g. *)
PROCEDURE TakeG(event: INTEGER): BOOLEAN;
BEGIN
  IF (event = Fl.EvShortcut) & (Fl.EventKey() = ORD("g")) THEN INC(taken); RETURN TRUE END;
  RETURN FALSE
END TakeG;

(* Removes itself at its first shortcut, and the handler Count. *)
PROCEDURE Once(event: INTEGER): BOOLEAN;
BEGIN
  IF event = Fl.EvShortcut THEN INC(once); Fl.RemoveHandler(Once); Fl.RemoveHandler(Count) END;
  RETURN FALSE
END Once;

BEGIN
  (* Idle callbacks *)
  NEW(counter); counter.stopAt := 5;
  Fl.AddIdle(counter); Fl.AddIdle(counter);
  Check.Check(counter.Added(), "AddIdle");
  k := 0;
  WHILE counter.Added() & (k < 500) DO Fl.Wait(0.01D0); INC(k) END;
  Check.Check(~counter.Added() & (counter.runs = 5), "runs while added, once each time, and can remove itself");
  FOR k := 1 TO 5 DO Fl.Wait(0.01D0) END;
  Check.Check(counter.runs = 5, "and doesn't run once removed");
  AddLost; GC.Collect;
  k := 0;
  WHILE (lostRuns < 3) & (k < 500) DO Fl.Wait(0.01D0); INC(k) END;
  FOR k := 1 TO 5 DO Fl.Wait(0.01D0) END;
  Check.Check(lostRuns = 3, "an idle added is kept from the collector");
  counter.runs := 0; counter.stopAt := -1;
  Fl.AddIdle(counter); Fl.Wait(0.01D0); Fl.RemoveIdle(counter); Fl.RemoveIdle(counter);
  n := counter.runs; Fl.Wait(0.01D0);
  Check.Check((n >= 1) & (counter.runs = n) & ~counter.Added(), "RemoveIdle, twice");

  (* File descriptors *)
  Check.Check(Probe.Pipe(r, w), "a pipe");
  NEW(reader); Fl.WatchFd(reader, r, Fl.FdRead);
  Check.Check(reader.Watching() & (reader.fd = r) & (reader.when = Fl.FdRead), "WatchFd");
  FOR k := 1 TO 5 DO Fl.Wait(0.01D0) END;
  Check.Check(reader.ready = 0, "not ready with nothing to read");
  n := Probe.Write(w, "hello");
  WaitReady(reader, 1);
  Check.Check((reader.ready = 1) & (reader.got = "hello"), "Ready when there is");
  GC.Collect;
  n := Probe.Write(w, "again");
  WaitReady(reader, 2);
  Check.Check((reader.ready = 2) & (reader.got = "again"), "and again, kept from the collector");
  NEW(other); Fl.WatchFd(other, r, Fl.FdRead + Fl.FdExcept);
  Check.Check(~reader.Watching() & other.Watching(), "another watch for the same takes it");
  n := Probe.Write(w, "third");
  WaitReady(other, 1);
  Check.Check((other.ready = 1) & (reader.ready = 2), "and is ready instead");
  Fl.UnwatchFd(other); Fl.UnwatchFd(other);
  n := Probe.Write(w, "fourth");
  FOR k := 1 TO 5 DO Fl.Wait(0.01D0) END;
  Check.Check(~other.Watching() & (other.ready = 1), "UnwatchFd, twice");
  Probe.Close(r); Probe.Close(w);

  (* The event dispatch *)
  NEW(win); Fl.OpenWindow(win, 200, 100, "TestLoop");
  NEW(button); FlButtons.OpenButton(button, 10, 10, 80, 25, "b"); button.action := Press;
  NEW(input); FlInputs.OpenInput(input, 10, 40, 80, 25, "");
  NEW(box); Fl.OpenBox(box, 100, 10, 80, 25, "box");
  win.End;
  Fl.SetEventDispatch(Dispatch);
  pass := TRUE;
  ok := Probe.Mouse(win, Fl.EvPush, 20, 20, Fl.LeftMouse, Fl.Button1, 0);
  ok := Probe.Mouse(win, Fl.EvRelease, 20, 20, Fl.LeftMouse, {}, 0);
  Check.Check((seen = 2) & (windowSeen = win) & (pressed = 1), "the dispatch sees each event, with its window, and hands it on");
  pass := FALSE;
  ok := Probe.Mouse(win, Fl.EvPush, 20, 20, Fl.LeftMouse, Fl.Button1, 0);
  ok := Probe.Mouse(win, Fl.EvRelease, 20, 20, Fl.LeftMouse, {}, 0);
  Check.Check((seen = 4) & (pressed = 1), "or keeps it from the widgets");
  pass := TRUE;
  Fl.SetFocus(input);
  ok := Probe.HandleKey(win, Fl.EvKeyDown, Fl.KeyKP + ORD("5"), {}, "");
  input.Value(s);
  Check.Check(s = "5", "SetEventText and SetEventKey remap a key");
  deleteBox := TRUE;
  ok := Probe.Mouse(win, Fl.EvPush, 120, 20, Fl.LeftMouse, Fl.Button1, 0);
  deleteBox := FALSE;
  Check.Check(box.IsOpen(), "a widget deleted in the dispatch is deleted later");
  ok := Probe.Mouse(win, Fl.EvRelease, 120, 20, Fl.LeftMouse, {}, 0);
  ok := Fl.Check();
  Check.Check(~box.IsOpen(), "at the next Check");
  Fl.SetEventDispatch(NIL);
  n := seen;
  ok := Probe.Mouse(win, Fl.EvPush, 20, 20, Fl.LeftMouse, Fl.Button1, 0);
  ok := Probe.Mouse(win, Fl.EvRelease, 20, 20, Fl.LeftMouse, {}, 0);
  Check.Check((seen = n) & (pressed = 2), "SetEventDispatch NIL: FLTK's own again");
  win.Delete;

  (* Event handlers: a shortcut no widget takes (deleting win cleared
     Fl.BelowMouse, as sending one needs: doc/fltk-issues.md, 3) *)
  NEW(win); Fl.OpenWindow(win, 100, 100, "TestLoop handlers");
  NEW(box); Fl.OpenBox(box, 10, 10, 80, 25, "box");
  win.End;
  Fl.AddHandler(TakeG); Fl.AddHandler(Count);
  ok := Probe.HandleKey(win, Fl.EvShortcut, ORD("g"), {}, "g");
  Check.Check(ok & (counted = 1) & (taken = 1), "handlers see a shortcut no widget took, newest first");
  ok := Probe.HandleKey(win, Fl.EvShortcut, ORD("h"), {}, "h");
  Check.Check(~ok & (counted = 2) & (taken = 1), "and pass on what they don't use");
  Fl.AddHandler(Once);
  ok := Probe.HandleKey(win, Fl.EvShortcut, ORD("g"), {}, "g");
  Check.Check(ok & (once = 1) & (counted = 2) & (taken = 2),
    "a handler may remove itself, and the next, which isn't called");
  ok := Probe.HandleKey(win, Fl.EvShortcut, ORD("g"), {}, "g");
  Check.Check(ok & (once = 1) & (counted = 2) & (taken = 3), "RemoveHandler");
  Fl.RemoveHandler(TakeG); Fl.RemoveHandler(TakeG);
  ok := Probe.HandleKey(win, Fl.EvShortcut, ORD("g"), {}, "g");
  Check.Check(~ok & (taken = 3), "with none, FLTK's own");
  win.Delete;

  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestLoop.
