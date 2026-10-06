MODULE Hello;
  IMPORT SYSTEM, Fltk, Out, GC := GarbageCollectedHeap;
  TYPE Counter = POINTER TO RECORD n: LONGINT; win: Fltk.Widget END;
  VAR win, b: Fltk.Widget; c: Counter; i: LONGINT; junk: POINTER TO ARRAY OF CHAR;

  PROCEDURE Click(w: Fltk.Widget; data: SYSTEM.ADDRESS);
    VAR k: Counter; s: ARRAY 32 OF CHAR;
  BEGIN
    k := SYSTEM.VAL(Counter, data); INC(k.n);
    Out.String("clicked "); Out.Int(k.n, 0); Out.Ln;
    s := "Clicks: 0"; s[8] := CHR(ORD("0") + k.n MOD 10);
    Fltk.CopyLabel(w, s);
    IF k.n = 3 THEN Fltk.Hide(k.win) END
  END Click;
BEGIN
  win := Fltk.WindowNew(300, 180, "Oberon + FLTK");
  b := Fltk.ButtonNew(50, 60, 200, 40, "Click me");
  Fltk.End(win);
  NEW(c); c.win := win;
  Fltk.SetCallback(b, Click, SYSTEM.VAL(SYSTEM.ADDRESS, c));
  Fltk.Show(win);
  i := Fltk.Run()
END Hello.
