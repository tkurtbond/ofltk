MODULE GridSimple; (* FLTK's examples/grid-simple.cxx: a 3x3 grid of buttons *)

IMPORT Fl, FlButtons, FlLayout;

VAR
  win: Fl.DoubleWindow;
  grid: FlLayout.Grid;

(* A button at row, col of the grid, filling its cell. *)
PROCEDURE Button(label: ARRAY OF CHAR; row, col: INTEGER);
  VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, 0, 0, 0, 0, label);
  grid.Place(b, row, col, FlLayout.GridFill)
END Button;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 320, 180, "3x3 Fl_Grid with Buttons");
  NEW(grid); FlLayout.OpenGrid(grid, 0, 0, 320, 180, "");
  grid.SetLayout(3, 3);
  grid.SetMargins(10, 10, 10, 10); grid.SetGap(10, 10);
  grid.SetColor(Fl.White);
  Button("New", 0, 0); Button("Options", 0, 2); Button("About", 1, 1);
  Button("Help", 2, 0); Button("Quit", 2, 2);
  grid.End;
  win.End;
  win.SetResizable(grid);
  win.SizeRange(300, 100, 0, 0);
  win.Show;
  Fl.Run
END GridSimple.
