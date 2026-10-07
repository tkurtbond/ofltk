MODULE TreeCustomSort; (* FLTK's examples/tree-custom-sort.cxx: a tree's items sorted by number, with SwapChildren *)

(* FLTK's example labels the items with numbers from rand(), seeded by
   the time. poc has no rand, so this has its own generator, with a fixed
   seed: the same numbers each run. *)

IMPORT OutStr, Fl, FlButtons, FlBrowsers;

TYPE
  SortButton = POINTER TO RECORD (FlButtons.ButtonDesc) dir: INTEGER END;  (* 1 forward, -1 reverse *)

VAR
  win: Fl.DoubleWindow;
  tree: FlBrowsers.Tree;
  seed: LONGINT;
  ok: BOOLEAN;

(* A number from 0 to 999999: a linear congruential generator's. *)
PROCEDURE Random(): LONGINT;
BEGIN
  seed := (seed * 1103515245 + 12345) MOD 80000000H;
  RETURN seed DIV 100H MOD 1000000
END Random;

(* The number an item's label starts with. *)
PROCEDURE Number(i: FlBrowsers.TreeItem): LONGINT;
  VAR s: ARRAY 50 OF CHAR; n: LONGINT; k: INTEGER;
BEGIN
  i.GetLabel(s); n := 0; k := 0;
  WHILE (s[k] >= "0") & (s[k] <= "9") DO n := n * 10 + ORD(s[k]) - ORD("0"); INC(k) END;
  RETURN n
END Number;

(* Sorts the root's children by their numbers, in b's direction. *)
PROCEDURE (b: SortButton) Callback*;
  VAR i, ca, cb: FlBrowsers.TreeItem; ax, bx: INTEGER; x, y: LONGINT;
BEGIN
  i := tree.Root();
  FOR ax := 0 TO i.Children() - 1 DO
    FOR bx := ax + 1 TO i.Children() - 1 DO
      ca := i.Child(ax); cb := i.Child(bx);
      x := Number(ca); y := Number(cb);
      IF (b.dir = 1) & (x > y) OR (b.dir = -1) & (x < y) THEN i.SwapChildren(ax, bx) END
    END
  END;
  tree.Redraw
END Callback;

PROCEDURE Build;
  VAR word: ARRAY 50 OF CHAR; t: INTEGER; but: SortButton; item: FlBrowsers.TreeItem;
BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 250, 600, "Numeric Sort Tree");
  NEW(tree); FlBrowsers.OpenTree(tree, 10, 10, win.W() - 20, win.H() - 60, "");
  tree.SetShowRoot(FALSE);
  FOR t := 0 TO 199 DO
    word := ""; OutStr.Int(Random(), 0, word);
    item := tree.Add(word)
  END;
  NEW(but); FlButtons.OpenButton(but, 10, win.H() - 40, 80, 20, "Fwd"); but.dir := 1;
  NEW(but); FlButtons.OpenButton(but, 20 + 80, win.H() - 40, 80, 20, "Rev"); but.dir := -1;
  win.End;
  win.SetResizable(win)
END Build;

BEGIN
  seed := 1;
  ok := Fl.SetScheme("gtk+");
  Build;
  win.Show;
  Fl.Run
END TreeCustomSort.
