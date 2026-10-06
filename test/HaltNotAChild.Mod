MODULE HaltNotAChild; (* Placing a widget that isn't the grid's child halts with Fl.NotAChild *)

IMPORT Fl, FlLayout;

VAR g: FlLayout.Grid; b: Fl.Box;

BEGIN
  NEW(g); FlLayout.OpenGrid(g, 0, 0, 100, 100, "");
  g.End; g.SetLayout(2, 2);
  NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, "");
  g.Place(b, 0, 0, FlLayout.GridFill)
END HaltNotAChild.
