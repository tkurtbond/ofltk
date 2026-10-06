MODULE TestImages; (* FlImages: images from pixels, files and memory; labels, drawing, surfaces *)

IMPORT SYSTEM, GC := GarbageCollectedHeap, Files, Fl, FlDraw, FlImages, Check, Probe;

TYPE
  (* Draws its image at its top left, on white. *)
  Picture = POINTER TO RECORD (Fl.BoxDesc) img: FlImages.Image END;

VAR
  win: Fl.Window;
  box: Fl.Box;
  pic: Picture;
  i, j: FlImages.Image;
  s, t: FlImages.Surface;
  bits: ARRAY 64 OF CHAR;
  data: ARRAY 4096 OF CHAR;
  n, white, red, blue: INTEGER;
  ok: BOOLEAN;

PROCEDURE (p: Picture) Draw*;
BEGIN
  FlDraw.SetColor(Fl.White); FlDraw.RectF(p.X(), p.Y(), p.W(), p.H());
  p.img.Draw(p.X(), p.Y())
END Draw;

PROCEDURE Churn;
  VAR i: INTEGER; p: POINTER TO ARRAY OF CHAR;
BEGIN
  FOR i := 1 TO 200 DO NEW(p, 1000); p[0] := "x" END;
  GC.Collect
END Churn;

(* Makes an image, and loses it. *)
PROCEDURE Lose;
  VAR i: FlImages.Image;
BEGIN NEW(i); FlImages.OpenRGB(i, bits, 1, 1, 3, 0)
END Lose;

(* bits: 4 by 2 RGB pixels, the left half red and the right blue. *)
PROCEDURE RedBlue;
  VAR x, y, p: INTEGER;
BEGIN
  FOR y := 0 TO 1 DO
    FOR x := 0 TO 3 DO
      p := (y * 4 + x) * 3;
      IF x < 2 THEN bits[p] := 0FFX; bits[p + 2] := 0X ELSE bits[p] := 0X; bits[p + 2] := 0FFX END;
      bits[p + 1] := 0X
    END
  END
END RedBlue;

(* Whether c is near color want: within 8 in each of red, green and blue,
   for a lossy format. *)
PROCEDURE Near(c, want: INTEGER): BOOLEAN;
  VAR k: INTEGER;
BEGIN
  FOR k := 1 TO 3 DO
    IF ABS(SYSTEM.LSH(c, -8 * k) MOD 100H - SYSTEM.LSH(want, -8 * k) MOD 100H) > 8 THEN RETURN FALSE END
  END;
  RETURN TRUE
END Near;

(* Whether i is 4 by 2, red on the left and blue on the right. *)
PROCEDURE IsRedBlue(i: FlImages.Image): BOOLEAN;
BEGIN
  RETURN (i.DataW() = 4) & (i.DataH() = 2) & Near(i.Pixel(0, 0), red) & Near(i.Pixel(1, 1), red)
    & Near(i.Pixel(2, 0), blue) & Near(i.Pixel(3, 1), blue)
END IsRedBlue;

PROCEDURE Loads(name: ARRAY OF CHAR; kind: INTEGER): BOOLEAN;
  VAR i: FlImages.Image; ok: BOOLEAN;
BEGIN
  NEW(i); ok := FlImages.Load(i, name) & (i.Kind() = kind) & IsRedBlue(i);
  IF i.IsOpen() THEN i.Close END;
  RETURN ok
END Loads;

(* The bytes of file name into data; their number, -1 if it can't be read. *)
PROCEDURE Read(name: ARRAY OF CHAR): INTEGER;
  VAR f: Files.File; r: Files.Rider; n: INTEGER;
BEGIN
  f := Files.Old(name);
  IF f = NIL THEN RETURN -1 END;
  n := SHORT(Files.Length(f)); ASSERT(n <= LEN(data));
  Files.Set(r, f, 0); Files.ReadBytes(r, data, n); Files.Close(f);
  RETURN n
END Read;

BEGIN
  NEW(win); Fl.OpenWindow(win, 100, 100, "TestImages");
  RedBlue; white := Fl.RGB(255, 255, 255); red := Fl.RGB(255, 0, 0); blue := Fl.RGB(0, 0, 255);

  (* An image lost is closed by the collector; first, while the stack is
     shallow (TestText's note). *)
  Lose; Churn;
  Check.Check(FlImages.openImages = 0, "an image the program loses is closed by the collector");

  (* From pixels *)
  NEW(i); FlImages.OpenRGB(i, bits, 4, 2, 3, 0);
  Check.Check(i.IsOpen() & (i.Kind() = FlImages.RGB) & (i.Depth() = 3) & (i.W() = 4) & (i.H() = 2),
    "OpenRGB");
  Check.Check(IsRedBlue(i) & (i.Pixel(0, 0) = red) & (i.Alpha(0, 0) = 255), "its pixels, copied");
  bits[0] := 0X;
  Check.Check(i.Pixel(0, 0) = red, "and not kept");
  RedBlue;
  bits[0] := 0FFX; bits[1] := 80X; bits[2] := 0X; bits[3] := 40X;
  NEW(j); FlImages.OpenRGB(j, bits, 1, 1, 4, 0);
  Check.Check((j.Pixel(0, 0) = Fl.RGB(255, 128, 0)) & (j.Alpha(0, 0) = 40H), "RGBA");
  j.Close;
  bits[0] := 80X; bits[1] := 7X;
  NEW(j); FlImages.OpenRGB(j, bits, 1, 1, 2, 0);
  Check.Check((j.Pixel(0, 0) = Fl.RGB(128, 128, 128)) & (j.Alpha(0, 0) = 7) & (j.Depth() = 2), "gray and alpha");
  j.Close;
  RedBlue;

  NEW(j); i.Copy(j, 8, 4);
  Check.Check((j.DataW() = 8) & (j.DataH() = 4) & (j.Pixel(0, 0) = red) & (j.Pixel(7, 3) = blue), "Copy, scaled");
  j.Close;
  i.Scale(8, 4, FALSE, TRUE);
  Check.Check((i.W() = 8) & (i.H() = 4) & (i.DataW() = 4), "Scale changes the size drawn, not the data");
  i.Scale(4, 2, FALSE, TRUE);

  (* Files, in each format FLTK reads *)
  Check.Check(i.SavePNG("../build/TestImages.png"), "SavePNG");
  Check.Check(Loads("../build/TestImages.png", FlImages.RGB), "Load: PNG");
  Check.Check(Loads("images/rb.jpg", FlImages.RGB), "JPEG (near)");
  Check.Check(Loads("images/rb.bmp", FlImages.RGB), "BMP, with a palette");
  Check.Check(Loads("images/rb.ppm", FlImages.RGB), "PNM");
  Check.Check(Loads("images/rb.svg", FlImages.RGB), "SVG, rasterized");
  Check.Check(Loads("images/rb.gif", FlImages.Pixmap), "GIF, a pixmap");
  Check.Check(Loads("images/rb.xpm", FlImages.Pixmap), "XPM");
  NEW(j);
  Check.Check(~FlImages.Load(j, "images/none.png") & ~j.IsOpen(), "a missing file is FALSE");
  Check.Check(~FlImages.Load(j, "Check.Mod") & ~j.IsOpen(), "and a file that isn't an image");
  n := Read("../build/TestImages.png");
  Check.Check((n > 0) & FlImages.LoadData(j, data, n) & IsRedBlue(j), "LoadData: PNG");
  j.Close;
  n := Read("images/rb.svg");
  Check.Check((n > 0) & FlImages.LoadData(j, data, n) & IsRedBlue(j), "SVG text");
  j.Close;
  Check.Check(~FlImages.LoadData(j, data, 10) & ~j.IsOpen(), "data cut short is FALSE");

  (* Changing pixels *)
  NEW(j); i.Copy(j, 4, 2);
  j.Desaturate;
  n := j.Pixel(0, 0);
  Check.Check((SYSTEM.LSH(n, -24) MOD 100H = SYSTEM.LSH(n, -16) MOD 100H) & (n # red), "Desaturate");
  j.Close;
  NEW(j); i.Copy(j, 4, 2);
  j.ColorAverage(Fl.Black, 0.5);
  Check.Check(Near(j.Pixel(0, 0), Fl.RGB(128, 0, 0)), "ColorAverage");
  j.Close;
  NEW(j); ok := FlImages.Load(j, "images/rb.gif");
  j.ColorAverage(Fl.Black, 0.5);
  Check.Check(Near(j.Pixel(0, 0), Fl.RGB(128, 0, 0)), "a pixmap's pixels read again after a change");
  j.Close;

  (* An image drawn in Draw *)
  NEW(pic); Fl.OpenBox(pic, 0, 0, 10, 10, ""); pic.img := i;
  Check.Check(Probe.Capture(pic) & (Probe.Pixel(0, 0) = red) & (Probe.Pixel(3, 1) = blue)
    & (Probe.Pixel(4, 0) = white), "Draw");
  Probe.Release;

  (* A label image, kept by its widget *)
  NEW(box); Fl.OpenBox(box, 20, 0, 20, 20, ""); box.SetBoxType(Fl.FlatBox); box.SetColor(Fl.White);
  NEW(j); i.Copy(j, 4, 2);
  FlImages.SetImage(box, j);
  n := FlImages.openImages;
  j.Close; j := NIL; Churn;
  Check.Check(FlImages.openImages = n - 1, "a label image closed by the program");
  Check.Check(Probe.Capture(box) & (Probe.Pixel(8, 9) = red) & (Probe.Pixel(11, 9) = blue),
    "is still drawn: its widget holds it");
  Probe.Release;
  NEW(j); i.Copy(j, 4, 2); j.Desaturate;
  FlImages.SetInactiveImage(box, j); j.Close;
  box.Deactivate;
  ok := Probe.Capture(box); n := Probe.Pixel(8, 9); Probe.Release;
  Check.Check(SYSTEM.LSH(n, -24) MOD 100H = SYSTEM.LSH(n, -16) MOD 100H, "SetInactiveImage");
  box.Activate;
  FlImages.SetImage(box, NIL);
  Check.Check(Probe.Capture(box) & (Probe.Pixel(8, 9) = white), "SetImage NIL");
  Probe.Release;
  NEW(j); i.Copy(j, 4, 2); FlImages.SetImage(box, j); j.Close;
  box.Delete;  (* and the image with it: valgrind would see a leak *)

  (* Surfaces *)
  NEW(s); FlImages.OpenSurface(s, 20, 10);
  s.Begin;
  FlDraw.SetColor(Fl.Blue); FlDraw.RectF(0, 0, 20, 10);
  FlDraw.SetColor(Fl.Red); FlDraw.RectF(5, 5, 2, 2);
  NEW(j); Check.Check(FlImages.ReadImage(j, 4, 4, 4, 4, FALSE), "ReadImage on a surface");
  Check.Check((j.Pixel(0, 0) = blue) & (j.Pixel(1, 1) = red) & (j.Depth() = 3), "reads its pixels");
  j.Close;
  s.DrawWidget(pic, 10, 0);
  s.End;
  NEW(j); s.GetImage(j);
  Check.Check((j.DataW() = 20) & (j.Pixel(0, 0) = blue) & (j.Pixel(5, 5) = red) & (j.Pixel(10, 0) = red)
    & (j.Pixel(12, 1) = blue) & (j.Pixel(14, 0) = white), "GetImage, with a widget drawn");
  j.Close;
  NEW(t); FlImages.OpenSurface(t, 2, 2);
  s.Begin; t.Begin; FlDraw.SetColor(Fl.Red); FlDraw.RectF(0, 0, 2, 2); t.End;
  FlDraw.SetColor(Fl.Black); FlDraw.RectF(0, 0, 1, 1); s.End;
  NEW(j); t.GetImage(j);
  Check.Check(j.Pixel(1, 1) = red, "surfaces nest");
  j.Close; NEW(j); s.GetImage(j);
  Check.Check(j.Pixel(0, 0) = Fl.RGB(0, 0, 0), "drawing goes to the one before after End");
  j.Close;
  t.Begin; t.Close;
  Check.Check(~t.IsOpen() & (FlImages.openSurfaces = 1), "Close ends a surface begun");
  s.Close; s.Close;

  i.Close; i.Close;
  pic.img := NIL;
  win.Delete;
  Check.Check((FlImages.openImages = 0) & (FlImages.openSurfaces = 0) & (Fl.OpenWidgets() = 0),
    "every image, surface and widget closed");
  Check.Summary
END TestImages.
