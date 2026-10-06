MODULE HaltGridRange; (* A grid cell outside the grid halts with Fl.IndexOutOfRange *)

IMPORT Fl, FlLayout;

VAR g: FlLayout.Grid; b: Fl.Box;

BEGIN
  NEW(g); FlLayout.OpenGrid(g, 0, 0, 100, 100, "");
  NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, "");
  g.End; g.SetLayout(2, 2);
  g.Place(b, 2, 0, FlLayout.GridFill)  (* row 2 of 0 .. 1 *)
END HaltGridRange.
