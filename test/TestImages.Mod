MODULE TestImages; (* FlImages: images from pixels, files and memory; labels, drawing, surfaces *)

IMPORT SYSTEM, GC := GarbageCollectedHeap, Files, Fl, FlDraw, FlBrowsers, FlMenus, FlImages, Check, Probe;

TYPE
  (* Draws its image at its top left, on white. *)
  Picture = POINTER TO RECORD (Fl.BoxDesc) img: FlImages.Image END;

VAR
  win: Fl.Window;
  box: Fl.Box;
  pic: Picture;
  br: FlBrowsers.Browser;
  ml, ml2: FlImages.MultiLabel;
  choice: FlMenus.Choice;
  label: ARRAY 64 OF CHAR;
  new, open, file, k: INTEGER;
  i, j: FlImages.Image;
  s, t: FlImages.Surface;
  bits: ARRAY 64 OF CHAR;
  data: ARRAY 4096 OF CHAR;
  xpm: ARRAY 5, 16 OF CHAR;
  n, x, y, white, red, blue: INTEGER;
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

(* Whether w, w by h, has red in it, the first (by rows) at x, y. *)
PROCEDURE FindRed(w: Fl.Widget; VAR x, y: INTEGER): BOOLEAN;
  VAR found: BOOLEAN;
BEGIN
  found := FALSE;
  IF Probe.Capture(w) THEN
    y := 0;
    WHILE ~found & (y < w.H()) DO
      x := 0;
      WHILE (x < w.W()) & (Probe.Pixel(x, y) # red) DO INC(x) END;
      IF x < w.W() THEN found := TRUE ELSE INC(y) END
    END
  END;
  RETURN found
END FindRed;

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

  (* An XPM's lines, from an Oberon array *)
  xpm[0] := "4 2 2 1"; xpm[1] := "r c #FF0000"; xpm[2] := "b c #0000FF";
  xpm[3] := "rrbb"; xpm[4] := "rrbb";
  NEW(j); Check.Check(FlImages.OpenXPM(j, xpm, 5) & IsRedBlue(j), "OpenXPM");
  xpm[3] := "xxxx";
  Check.Check(IsRedBlue(j), "OpenXPM copies the lines");
  j.Close;
  xpm[3] := "rrbb";
  NEW(j); Check.Check(~FlImages.OpenXPM(j, xpm, 4) & ~j.IsOpen(), "OpenXPM: too few lines is FALSE");
  xpm[4] := "rrb";
  Check.Check(~FlImages.OpenXPM(j, xpm, 5), "OpenXPM: a short row is FALSE");
  FOR n := 0 TO LEN(xpm, 1) - 1 DO xpm[4, n] := "r" END;
  Check.Check(~FlImages.OpenXPM(j, xpm, 5), "OpenXPM: a row without its 0X is FALSE");
  xpm[4] := "rrbb"; xpm[0] := "4 2 2 3";
  Check.Check(~FlImages.OpenXPM(j, xpm, 5), "OpenXPM: 3 characters a pixel is FALSE");
  xpm[0] := "4 2";
  Check.Check(~FlImages.OpenXPM(j, xpm, 5) & ~j.IsOpen(), "OpenXPM: a short first line is FALSE");

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

  (* A browser line's icon, kept by the browser while a line shows it *)
  NEW(br); FlBrowsers.OpenBrowser(br, 0, 0, 100, 100, "");
  br.Add("One"); br.Add("Two"); br.Add("Three");
  NEW(j); i.Copy(j, 8, 20);
  FlImages.SetLineIcon(br, 2, j); FlImages.SetLineIcon(br, 3, j);
  j.Close; j := NIL; Churn;
  Check.Check(FindRed(br, x, y) & (y > 10) & (Probe.Pixel(x + 4, y) = blue) & (Probe.Pixel(x + 3, y + 19) = red)
    & (Probe.Pixel(x, y + 20) # red), "SetLineIcon: drawn on the line, after the program closed it");
  Probe.Release;
  Check.Check(Probe.Kept(br) = 1, "held once for two lines");
  br.Remove(2);
  Check.Check(FindRed(br, x, y) & (Probe.Kept(br) = 1), "kept while a line shows it");
  Probe.Release;
  FlImages.SetLineIcon(br, 2, NIL);
  Check.Check(~FindRed(br, x, y) & (Probe.Kept(br) = 0), "SetLineIcon NIL: released");
  Probe.Release;
  NEW(j); i.Copy(j, 8, 20); FlImages.SetLineIcon(br, 1, j); j.Close;
  NEW(j); i.Copy(j, 8, 20); FlImages.SetLineIcon(br, 1, j); j.Close;
  Check.Check(Probe.Kept(br) = 1, "another icon on the line: the first released");
  br.Clear;
  Check.Check(Probe.Kept(br) = 0, "Clear: released");
  NEW(j); i.Copy(j, 8, 20); br.Add("One"); FlImages.SetLineIcon(br, 1, j); j.Close;
  br.Delete;  (* and the image with it *)

  (* Multi-labels *)
  NEW(ml); FlImages.OpenMultiLabel(ml);
  NEW(j); i.Copy(j, 8, 8); ml.SetImage(0, j); j.Close; j := NIL;
  ml.SetText(1, "Hi", Fl.NormalLabel);
  NEW(box); Fl.OpenBox(box, 0, 0, 60, 20, "x"); box.SetBoxType(Fl.FlatBox); box.SetColor(Fl.White);
  box.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  FlImages.SetMultiLabel(box, ml);
  n := FlImages.openMultiLabels;
  ml.Close; ml := NIL; Churn;
  Check.Check(FlImages.openMultiLabels = n - 1, "a multi-label closed by the program");
  ok := FindRed(box, x, y);
  Check.Check(ok & (Probe.Pixel(x + 4, y) = blue), "is still drawn: its widget holds it, and it its image");
  k := x + 8; n := 0;
  WHILE k < 60 DO
    IF Probe.Pixel(k, 10) # white THEN INC(n) END;
    INC(k)
  END;
  Check.Check(n > 0, "with its text after the image");
  Probe.Release;
  box.GetLabel(label);
  Check.Check(label = "", "GetLabel of a multi-label is empty");
  box.SetLabelType(Fl.ShadowLabel);
  Check.Check(box.LabelType() = 5, "SetLabelType keeps a multi-label");
  box.SetLabel("text"); box.GetLabel(label);
  Check.Check((label = "text") & (box.LabelType() = Fl.NormalLabel) & ~FindRed(box, x, y),
    "SetLabel gives it text again");  (* and lets the multi-label go: valgrind would see it *)
  Probe.Release;
  NEW(ml); FlImages.OpenMultiLabel(ml); NEW(ml2); FlImages.OpenMultiLabel(ml2);
  ml2.SetText(0, "a", Fl.NormalLabel); ml.SetMulti(1, ml2); ml.SetText(0, "b", Fl.EngravedLabel);
  ml2.Close; FlImages.SetMultiLabel(box, ml); ml.Close;
  FlImages.SetMultiLabel(box, NIL); box.GetLabel(label);
  Check.Check((label = "") & (box.LabelType() = Fl.NormalLabel), "SetMultiLabel NIL: no label");
  NEW(ml); FlImages.OpenMultiLabel(ml); FlImages.SetMultiLabel(box, ml); ml.Close;
  box.Delete;  (* and the multi-label with it *)

  (* A menu item's image and multi-label *)
  NEW(choice); FlMenus.OpenChoice(choice, 0, 0, 100, 25, "");
  new := choice.Add("File/New", 0, {}, NIL, {});
  open := choice.Add("File/Open", 0, {}, NIL, {});
  file := choice.FindIndex("File");
  NEW(j); i.Copy(j, 8, 8);
  FlImages.SetItemImage(choice, new, j); FlImages.SetItemImage(choice, file, j);
  NEW(ml); FlImages.OpenMultiLabel(ml); ml.SetImage(0, j); ml.SetText(1, "Open", Fl.NormalLabel);
  FlImages.SetItemMultiLabel(choice, open, ml); ml.Close; j.Close;
  Check.Check(Probe.Kept(choice) = 3, "each item showing an image keeps it");
  choice.ItemLabel(new, label);
  Check.Check(label = "New", "an item showing an image keeps its text");
  Check.Check(choice.ItemPath(new, label) & (label = "File/New"), "and its path");
  Check.Check((choice.FindIndex("File/New") = new) & (choice.FindIndex("File/Open") = open), "FindIndex finds it");
  ok := choice.SetValue(open);
  n := choice.Length();
  k := choice.Add("File/Save", 0, {}, NIL, {});
  Check.Check((k = open + 1) & (choice.Length() = n + 1), "Insert finds a submenu whose title shows an image");
  Check.Check(choice.Value() = open, "and keeps the item chosen");
  choice.Remove(k);
  Check.Check(FindRed(choice, x, y), "a choice shows its item's image");
  Probe.Release;
  FlImages.SetItemImage(choice, new, NIL); choice.ItemLabel(new, label);
  Check.Check((label = "New") & (Probe.Kept(choice) = 2), "SetItemImage NIL: text again, the image let go");
  NEW(j); i.Copy(j, 8, 8); FlImages.SetItemImage(choice, new, j); FlImages.SetItemImage(choice, new, j); j.Close;
  Check.Check(Probe.Kept(choice) = 3, "another image on the item: the first let go");
  choice.SetItemLabel(new, "Neu"); choice.ItemLabel(new, label);
  Check.Check((label = "Neu") & (Probe.Kept(choice) = 2), "SetItemLabel: text, the image let go");
  choice.Remove(open);
  Check.Check((Probe.Kept(choice) = 1) & (choice.Value() = -1), "Remove lets its image go");
  choice.Remove(file);
  Check.Check((Probe.Kept(choice) = 0) & (choice.Length() = 1), "Remove of a submenu, and its title's image");
  new := choice.Add("New", 0, {}, NIL, {});
  NEW(j); i.Copy(j, 8, 8); FlImages.SetItemImage(choice, new, j);
  choice.Clear;
  Check.Check(Probe.Kept(choice) = 0, "Clear lets them go");
  new := choice.Add("New", 0, {}, NIL, {});
  FlImages.SetItemImage(choice, new, j); j.Close;
  choice.Delete;  (* and the image with it *)

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
  Check.Check((FlImages.openImages = 0) & (FlImages.openSurfaces = 0) & (FlImages.openMultiLabels = 0)
    & (Fl.OpenWidgets() = 0), "every image, surface, multi-label and widget closed");
  Check.Summary
END TestImages.
