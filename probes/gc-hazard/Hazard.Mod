MODULE Hazard;
  IMPORT SYSTEM, Fltk, Out, GC := GarbageCollectedHeap;
  TYPE Counter = POINTER TO RECORD n: LONGINT; win: Fltk.Widget END;
  VAR win, b: Fltk.Widget; i: LONGINT; data: SYSTEM.ADDRESS;

  PROCEDURE Click(w: Fltk.Widget; d: SYSTEM.ADDRESS);
    VAR k: Counter; s: ARRAY 32 OF CHAR;
  BEGIN
    Out.String("  user_data still allocated? "); IF GC.IsAllocated(d) THEN Out.String("yes") ELSE Out.String("NO") END; Out.Ln;
    k := SYSTEM.VAL(Counter, d); INC(k.n);
    Out.String("  clicked n="); Out.Int(k.n, 0); Out.Ln;
    s := "Clicks: 0"; s[8] := CHR(ORD("0") + k.n MOD 10); Fltk.CopyLabel(w, s)
  END Click;

  PROCEDURE Churn;
    VAR j: LONGINT; p: POINTER TO ARRAY OF CHAR;
  BEGIN FOR j := 1 TO 20000 DO NEW(p, 100) END; GC.Collect
  END Churn;

  PROCEDURE Tick(d: SYSTEM.ADDRESS);
  BEGIN
    INC(i); Churn; Out.String("tick "); Out.Int(i, 0); Out.String(" collections="); Out.Int(GC.CollectionCount(), 0); Out.Ln;
    Fltk.DoCallback(b);
    IF i < 3 THEN Fltk.AddTimeout(0.2, Tick, 0) ELSE Fltk.Hide(win) END
  END Tick;

  PROCEDURE Setup;
    VAR c: Counter;
  BEGIN
    NEW(c); c.n := 100; data := 0;
    Fltk.SetCallback(b, Click, SYSTEM.VAL(SYSTEM.ADDRESS, c))  (* only C holds c now *)
  END Setup;
BEGIN
  win := Fltk.WindowNew(300, 180, "GC hazard");
  b := Fltk.ButtonNew(50, 60, 200, 40, "Click me");
  Fltk.End(win); Setup;
  Fltk.Show(win); Fltk.AddTimeout(0.3, Tick, 0);
  i := 0; i := Fltk.Run(); Out.String("Run returned"); Out.Ln
END Hazard.
