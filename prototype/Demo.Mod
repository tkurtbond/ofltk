MODULE Demo;
  IMPORT FL, Out, SYSTEM, GC := GarbageCollectedHeap;
  TYPE
    Swatch = POINTER TO RECORD (FL.BoxDesc) color: LONGINT; draws: LONGINT END;
    Next = POINTER TO RECORD (FL.ButtonDesc) target: Swatch END;
  VAR win: FL.Window; ticks: LONGINT; nb: Next;

  PROCEDURE (s: Swatch) Draw*;
    VAR x, y, w, h: LONGINT;
  BEGIN
    INC(s.draws); s.Geometry(x, y, w, h);
    FL.Color(SHORT(s.color)); FL.RectF(SHORT(x), SHORT(y), SHORT(w), SHORT(h));
    FL.Color(0); FL.Text("drawn by Oberon", SHORT(x) + 10, SHORT(y) + 20)
  END Draw;

  PROCEDURE (n: Next) Clicked*;
  BEGIN
    n.target.color := (n.target.color + 1) MOD 8; n.target.Redraw;
    Out.String("Clicked: color now "); Out.Int(n.target.color, 0); Out.Ln
  END Clicked;

  PROCEDURE Build;  (* locals only: the registry must keep these alive *)
    VAR s: Swatch;
  BEGIN
    NEW(win); FL.OpenWindow(win, 320, 200, "Oberon FLTK");
    NEW(s); s.color := 1; FL.OpenBox(s, 10, 10, 300, 120);
    NEW(nb); nb.target := s; FL.OpenButton(nb, 10, 140, 300, 40, "Next colour");
    win.End; win.Show
  END Build;

  PROCEDURE Tick(d: SYSTEM.ADDRESS);
    VAR j: LONGINT; junk: POINTER TO ARRAY OF CHAR;
  BEGIN
    FOR j := 1 TO 20000 DO NEW(junk, 100) END; GC.Collect;
    INC(ticks); nb.DoCallback;
    IF ticks = 3 THEN
      Out.String("draws so far "); Out.Int(nb.target.draws, 0); Out.String(", live "); Out.Int(FL.LiveCount(), 0); Out.Ln;
      nb.target.Delete
    END;
    IF ticks < 4 THEN FL.AddTimeout(0.25, Tick, 0)
    ELSE Out.String("after delete: live "); Out.Int(FL.LiveCount(), 0); Out.Ln; win.Hide END
  END Tick;
BEGIN
  Build; FL.AddTimeout(0.4, Tick, 0); FL.Run
END Demo.
