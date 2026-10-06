MODULE TestDraw; (* Draw overrides and FlDraw, checked by their pixels *)

(* Each widget is drawn into an image (Probe.Capture), as FLTK would draw
   it in its window, which is never shown, and its pixels checked. *)

IMPORT Fl, FlDraw, Check, Probe;

TYPE
  (* red, with a blue square at 10, 10 and a green line along y = 30 *)
  Swatch = POINTER TO RECORD (Fl.BoxDesc) draws: INTEGER END;
  (* a blue square clipped to the top left 10 by 10 *)
  Clipped = POINTER TO RECORD (Fl.BoxDesc)
    inside, outside: BOOLEAN;
    cx, cy, cw, ch, ix, iy, iw, ih, ow, oh: INTEGER
  END;
  (* a black disc of radius 10 at 20, 20, as a transformed path *)
  Disc = POINTER TO RECORD (Fl.BoxDesc) END;
  (* "MMM" in black *)
  Texty = POINTER TO RECORD (Fl.BoxDesc) font, size, height: INTEGER END;
  (* FLTK's box and label, under a black dot of its own at 2, 2 *)
  Framed = POINTER TO RECORD (Fl.BoxDesc) END;

VAR
  win: Fl.Window;
  sw: Swatch; cl: Clipped; disc: Disc; tx: Texty; fr: Framed;
  plain: Fl.Box;
  r, g, b, x, y, dark, w, h: INTEGER;
  white, black: INTEGER;
  two: ARRAY 4 OF CHAR;

PROCEDURE (s: Swatch) Draw*;
BEGIN
  INC(s.draws);
  FlDraw.SetColor(Fl.Red); FlDraw.RectF(s.X(), s.Y(), s.W(), s.H());
  FlDraw.SetColor(Fl.Blue); FlDraw.RectF(s.X() + 10, s.Y() + 10, 10, 10);
  FlDraw.SetRGB(0, 255, 0); FlDraw.XYLine(s.X(), s.Y() + 30, s.X() + s.W() - 1)
END Draw;

PROCEDURE (c: Clipped) Draw*;
BEGIN
  FlDraw.PushClip(c.X(), c.Y(), 10, 10);
  c.inside := FlDraw.NotClipped(c.X() + 2, c.Y() + 2, 4, 4);
  c.outside := FlDraw.NotClipped(c.X() + 20, c.Y() + 20, 4, 4);
  FlDraw.ClipBox(c.X(), c.Y(), 20, 20, c.cx, c.cy, c.cw, c.ch);
  FlDraw.ClipBox(c.X() + 2, c.Y() + 3, 4, 5, c.ix, c.iy, c.iw, c.ih);
  FlDraw.ClipBox(c.X() + 20, c.Y() + 20, 4, 4, c.ix, c.iy, c.ow, c.oh);
  FlDraw.SetColor(Fl.Blue); FlDraw.RectF(c.X(), c.Y(), c.W(), c.H());
  FlDraw.PopClip
END Draw;

PROCEDURE (d: Disc) Draw*;
BEGIN
  FlDraw.PushMatrix;
  FlDraw.Translate(d.X() + 20, d.Y() + 20);
  FlDraw.SetColor(Fl.Black);
  FlDraw.BeginPolygon; FlDraw.Circle(0, 0, 10); FlDraw.EndPolygon;
  FlDraw.PopMatrix
END Draw;

PROCEDURE (t: Texty) Draw*;
BEGIN
  FlDraw.SetFont(Fl.Helvetica + Fl.Bold, 20);
  t.font := FlDraw.Font(); t.size := FlDraw.Size(); t.height := FlDraw.Height();
  FlDraw.SetColor(Fl.Black);
  FlDraw.Text("MMM", t.X() + 2, t.Y() + 20)
END Draw;

PROCEDURE (f: Framed) Draw*;
BEGIN
  f.DrawBox; f.DrawLabel;
  FlDraw.SetColor(Fl.Black); FlDraw.RectF(f.X() + 2, f.Y() + 2, 2, 2)
END Draw;

(* The number of pixels in x0 .. x1 - 1, y0 .. y1 - 1 that aren't white. *)
PROCEDURE NotWhite(x0, y0, x1, y1: INTEGER): INTEGER;
  VAR n, x, y: INTEGER;
BEGIN
  n := 0;
  FOR y := y0 TO y1 - 1 DO
    FOR x := x0 TO x1 - 1 DO
      IF Probe.Pixel(x, y) # white THEN INC(n) END
    END
  END;
  RETURN n
END NotWhite;

BEGIN
  white := Fl.RGB(255, 255, 255); black := Fl.RGB(0, 0, 0);
  NEW(win); Fl.OpenWindow(win, 400, 300, "TestDraw");
  NEW(sw); Fl.OpenBox(sw, 10, 10, 50, 40, "");
  NEW(cl); Fl.OpenBox(cl, 70, 10, 30, 30, "");
  NEW(disc); Fl.OpenBox(disc, 110, 10, 40, 40, "");
  NEW(tx); Fl.OpenBox(tx, 160, 10, 80, 30, "");
  NEW(fr); Fl.OpenBox(fr, 10, 60, 60, 30, "");
  NEW(plain); Fl.OpenBox(plain, 80, 60, 30, 20, "");
  win.End;

  (* a Draw override, drawing in the window's coordinates *)
  Check.Check(Probe.Capture(sw) & (sw.draws = 1), "a Draw override runs, once per capture");
  Check.Check((Probe.Pixel(0, 0) = Fl.RGB(255, 0, 0)) & (Probe.Pixel(49, 39) = Fl.RGB(255, 0, 0)),
    "FlDraw.RectF fills the whole widget with an indexed color (Fl.Red)");
  Fl.GetRGB(Fl.Blue, r, g, b);
  Check.Check((Probe.Pixel(10, 10) = Fl.RGB(r, g, b)) & (Probe.Pixel(19, 19) = Fl.RGB(r, g, b))
    & (Probe.Pixel(20, 20) = Fl.RGB(255, 0, 0)) & (Probe.Pixel(9, 9) = Fl.RGB(255, 0, 0)),
    "a filled square exactly where drawn, relative to the widget");
  Check.Check((Probe.Pixel(0, 30) = Fl.RGB(0, 255, 0)) & (Probe.Pixel(49, 30) = Fl.RGB(0, 255, 0))
    & (Probe.Pixel(25, 31) = Fl.RGB(255, 0, 0)),
    "FlDraw.XYLine in an RGB color, one pixel high, end to end");

  (* clipping *)
  Check.Check(Probe.Capture(cl), "capture a clipped Draw");
  Check.Check((Probe.Pixel(0, 0) = Fl.RGB(r, g, b)) & (Probe.Pixel(9, 9) = Fl.RGB(r, g, b))
    & (Probe.Pixel(10, 10) = white) & (Probe.Pixel(29, 0) = white),
    "PushClip: only the clip rectangle is drawn");
  Check.Check(cl.inside & ~cl.outside, "NotClipped: TRUE inside the clip, FALSE outside");
  Check.Check((cl.cx = cl.X()) & (cl.cy = cl.Y()) & (cl.cw = 10) & (cl.ch = 10),
    "ClipBox gives the visible part of a rectangle partly clipped");
  Check.Check((cl.iw = 4) & (cl.ih = 5) & ((cl.ow = 0) OR (cl.oh = 0)),
    "ClipBox: all of a rectangle inside the clip, none of one outside");

  (* a path, transformed *)
  Check.Check(Probe.Capture(disc), "capture a transformed path");
  Check.Check((Probe.Pixel(20, 20) = black) & (Probe.Pixel(14, 20) = black) & (Probe.Pixel(20, 26) = black)
    & (Probe.Pixel(2, 2) = white) & (Probe.Pixel(37, 37) = white) & (Probe.Pixel(32, 20) = white),
    "Circle in a polygon, translated: black inside, white outside");

  (* text *)
  Check.Check(Probe.Capture(tx), "capture text");
  dark := NotWhite(0, 0, 80, 30);
  Check.Check((dark > 50) & (NotWhite(0, 0, 80, 3) = 0),
    "Text draws ink, below the top of the widget");
  Check.Check((tx.font = Fl.HelveticaBold) & (tx.size = 20) & (tx.height >= 20),
    "the font set reads back; its height is at least its size");
  FlDraw.SetFont(Fl.Helvetica, 20);
  Check.Check((FlDraw.Width("MMM") > FlDraw.Width("M")) & (FlDraw.Width("M") > 5.0D0)
    & (FlDraw.Width("") = 0.0D0), "Width measures, outside any Draw");
  w := 0; FlDraw.Measure("MMM", w, h);
  Check.Check((ABS(w - ENTIER(FlDraw.Width("MMM") + 0.5D0)) <= 1) & (h = FlDraw.Height()),
    "Measure gives one line's width and height");
  two := "a b"; two[1] := 0AX; w := 0; FlDraw.Measure(two, w, h);
  Check.Check(h = 2 * FlDraw.Height(), "Measure counts lines");

  (* FLTK's own box and label, from an override *)
  fr.SetBoxType(Fl.FlatBox); fr.SetColor(Fl.RGB(255, 255, 0));
  fr.SetLabel("x"); fr.SetLabelColor(Fl.Black); fr.SetAlign(Fl.AlignInside + Fl.AlignRight);
  Check.Check(Probe.Capture(fr), "capture a Draw using DrawBox and DrawLabel");
  Check.Check((Probe.Pixel(2, 2) = black) & (Probe.Pixel(10, 15) = Fl.RGB(255, 255, 0))
    & (Probe.Pixel(59, 29) = Fl.RGB(255, 255, 0)),
    "DrawBox fills the box in the widget's color, under the override's own drawing");
  Check.Check(NotWhite(0, 0, 60, 30) > 0, "the capture isn't blank");
  dark := 0;
  FOR y := 0 TO 29 DO FOR x := 30 TO 59 DO
    IF Probe.Pixel(x, y) # Fl.RGB(255, 255, 0) THEN INC(dark) END
  END END;
  Check.Check(dark > 0, "DrawLabel draws the label, on the right");

  (* the default Draw: FLTK's *)
  plain.SetBoxType(Fl.FlatBox); plain.SetColor(Fl.DarkGreen);
  Fl.GetRGB(Fl.DarkGreen, r, g, b);
  Check.Check(Probe.Capture(plain) & (Probe.Pixel(0, 0) = Fl.RGB(r, g, b))
    & (Probe.Pixel(29, 19) = Fl.RGB(r, g, b)),
    "a Box's own Draw: a flat box in its color");

  (* damage *)
  plain.Redraw;
  Check.Check(Fl.DamageAll * plain.Damage() = Fl.DamageAll, "Redraw sets DamageAll");

  Probe.Release;
  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestDraw.
