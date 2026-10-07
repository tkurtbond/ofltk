MODULE DrawAnX; (* FLTK's examples/howto-draw-an-x.cxx: a widget that draws an X, filling its space *)

IMPORT Fl, FlDraw;

TYPE
  DrawX = POINTER TO RECORD (Fl.BoxDesc) END;

VAR
  win: Fl.DoubleWindow;
  drawX: DrawX;

PROCEDURE (d: DrawX) Draw*;
  VAR x1, y1, x2, y2: INTEGER;
BEGIN
  FlDraw.SetColor(Fl.White); FlDraw.RectF(d.X(), d.Y(), d.W(), d.H());
  FlDraw.SetColor(Fl.Black);
  x1 := d.X(); y1 := d.Y();
  x2 := d.X() + d.W() - 1; y2 := d.Y() + d.H() - 1;
  FlDraw.Line(x1, y1, x2, y2);
  FlDraw.Line(x1, y2, x2, y1)
END Draw;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 200, 200, "Draw X");
  NEW(drawX); Fl.OpenBox(drawX, 10, 10, win.W() - 20, win.H() - 20, "");  (* 10 pixels within the window's edges *)
  drawX.SetColor(Fl.White);                                               (* a white background *)
  win.SetResizable(drawX);
  win.End;
  win.Show;
  Fl.Run
END DrawAnX.
