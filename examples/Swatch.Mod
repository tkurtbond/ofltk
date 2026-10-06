MODULE Swatch; (* A custom-drawn box and a button that changes it: the prototype's demo *)

(* The swatch is a Box extension whose Draw fills it with its colour and
   writes on it; the button's Callback moves it to the next colour of
   FLTK's first eight, and asks for a redraw. *)

IMPORT Fl, FlDraw, FlButtons;

TYPE
  Swatch = POINTER TO RECORD (Fl.BoxDesc) color: INTEGER END;
  Next = POINTER TO RECORD (FlButtons.ButtonDesc) target: Swatch END;

VAR
  window: Fl.Window;

PROCEDURE (s: Swatch) Draw*;
BEGIN
  FlDraw.SetColor(s.color); FlDraw.RectF(s.X(), s.Y(), s.W(), s.H());
  FlDraw.SetColor(Fl.Contrast(Fl.Black, s.color));
  FlDraw.SetFont(Fl.Helvetica, 14);
  FlDraw.Text("drawn by Oberon", s.X() + 10, s.Y() + 20)
END Draw;

PROCEDURE (n: Next) Callback*;
BEGIN
  n.target.color := (n.target.color + 1) MOD 8; n.target.Redraw
END Callback;

(* Locals only: Fl keeps the widgets alive while FLTK has them. *)
PROCEDURE Build;
  VAR s: Swatch; n: Next;
BEGIN
  NEW(window); Fl.OpenWindow(window, 320, 200, "Swatch");
  NEW(s); s.color := 1 (* red *); Fl.OpenBox(s, 10, 10, 300, 120, "");
  NEW(n); n.target := s; FlButtons.OpenButton(n, 10, 140, 300, 40, "Next colour");
  window.End
END Build;

BEGIN
  Build; window.Show; Fl.Run
END Swatch.
