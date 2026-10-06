MODULE TestLiveness; (* Widgets held only by FLTK survive collections *)

(* The failure behind PLAN.md's registry: an Oberon object that only
   FLTK points to was collected, and its callback then ran on reused
   memory (probes/gc-hazard). Here the boxes are opened in a procedure
   whose variables die with it, so only Fl's registry and FLTK hold them;
   collections are forced, and each box must still be there, with its
   own fields, reached through FLTK (Child) and through its callback. *)

IMPORT SYSTEM, GC := GarbageCollectedHeap, Fl, Check;

CONST n = 20;

TYPE
  Counter = POINTER TO RECORD (Fl.BoxDesc)
    id, clicks: INTEGER;
    name: ARRAY 16 OF CHAR
  END;

VAR
  win: Fl.Window;
  addresses: ARRAY n OF SYSTEM.ADDRESS;  (* not pointers: they keep nothing *)
  clicked: INTEGER;

PROCEDURE (c: Counter) Callback*;
BEGIN INC(c.clicks); INC(clicked)
END Callback;

PROCEDURE Build;
  VAR i: INTEGER; c: Counter;
BEGIN
  NEW(win); Fl.OpenWindow(win, 200, 200, "TestLiveness");
  FOR i := 0 TO n - 1 DO
    NEW(c); c.id := i; c.name := "counter"; c.name[7] := CHR(ORD("A") + i);
    Fl.OpenBox(c, 0, i * 10, 200, 10, "");
    addresses[i] := SYSTEM.VAL(SYSTEM.ADDRESS, c)
  END;
  win.End
END Build;

(* Allocates garbage enough to reuse any freed block, then collects. *)
PROCEDURE Churn;
  VAR i: INTEGER; p: POINTER TO ARRAY OF CHAR;
BEGIN
  FOR i := 1 TO 20000 DO NEW(p, 64) END;
  GC.Collect
END Churn;

PROCEDURE CheckChildren(): BOOLEAN;
  VAR i: INTEGER; w: Fl.Widget; ok: BOOLEAN;
BEGIN
  ok := win.Children() = n;
  FOR i := 0 TO n - 1 DO
    w := win.Child(i);
    ok := ok & (w # NIL) & (SYSTEM.VAL(SYSTEM.ADDRESS, w) = addresses[i])
      & GC.IsAllocated(addresses[i]) & (w IS Counter);
    IF ok THEN
      WITH w: Counter DO
        ok := (w.id = i) & (w.name[7] = CHR(ORD("A") + i)) & (w.name[8] = 0X)
      END
    END
  END;
  RETURN ok
END CheckChildren;

PROCEDURE ClickAll;
  VAR i: INTEGER; w: Fl.Widget;
BEGIN
  FOR i := 0 TO n - 1 DO w := win.Child(i); w.DoCallback END
END ClickAll;

PROCEDURE ClicksAre(k: INTEGER): BOOLEAN;
  VAR i: INTEGER; w: Fl.Widget; ok: BOOLEAN;
BEGIN
  ok := TRUE;
  FOR i := 0 TO n - 1 DO
    w := win.Child(i); ok := ok & (w(Counter).clicks = k)
  END;
  RETURN ok
END ClicksAre;

PROCEDURE NoneAllocated(): BOOLEAN;
  VAR i: INTEGER; ok: BOOLEAN;
BEGIN
  ok := TRUE;
  FOR i := 0 TO n - 1 DO ok := ok & ~GC.IsAllocated(addresses[i]) END;
  RETURN ok
END NoneAllocated;

BEGIN
  Build;
  Check.Check(Fl.OpenWidgets() = n + 1, "the window and its boxes are open");
  Churn; Churn;
  Check.Check(CheckChildren(), "after collections each box is there, with its own fields");
  ClickAll; Churn; ClickAll;
  Check.Check((clicked = 2 * n) & ClicksAre(2), "each box's Callback ran twice, on its own object");
  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "deleting the window closed it and its boxes");
  win := NIL; GC.Collect;
  Check.Check(NoneAllocated(), "deleted widgets' objects are collected");
  Check.Summary
END TestLiveness.
