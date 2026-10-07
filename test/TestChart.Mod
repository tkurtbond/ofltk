MODULE TestChart; (* FlValuators.Chart: entries, their limit, bounds, kinds, drawing *)

IMPORT Fl, FlValuators, Check, Probe;

CONST w = 200; h = 100;

VAR
  win: Fl.Window;
  c, d: FlValuators.Chart;
  min, max: LONGREAL;
  pixels: ARRAY w * h OF INTEGER;
  i: INTEGER;
  label: ARRAY 32 OF CHAR;
  ok: BOOLEAN;

(* Keeps chart k's pixels in pixels. *)
PROCEDURE Keep(k: FlValuators.Chart);
  VAR x, y: INTEGER;
BEGIN
  ok := Probe.Capture(k);
  FOR y := 0 TO h - 1 DO FOR x := 0 TO w - 1 DO pixels[y * w + x] := Probe.Pixel(x, y) END END;
  Probe.Release
END Keep;

(* Whether chart k's pixels are those kept. *)
PROCEDURE Same(k: FlValuators.Chart): BOOLEAN;
  VAR x, y: INTEGER; same: BOOLEAN;
BEGIN
  ok := Probe.Capture(k); same := TRUE;
  FOR y := 0 TO h - 1 DO FOR x := 0 TO w - 1 DO
    IF pixels[y * w + x] # Probe.Pixel(x, y) THEN same := FALSE END
  END END;
  Probe.Release;
  RETURN same
END Same;

(* Whether pixel x, y of chart k is red. *)
PROCEDURE Red(k: FlValuators.Chart; x, y: INTEGER): BOOLEAN;
  VAR red: BOOLEAN;
BEGIN ok := Probe.Capture(k); red := Probe.Pixel(x, y) = Fl.RGB(255, 0, 0); Probe.Release; RETURN red
END Red;

BEGIN
  NEW(win); Fl.OpenWindow(win, 2 * w, h, "TestChart");
  NEW(c); FlValuators.OpenChart(c, 0, 0, w, h, "");
  NEW(d); FlValuators.OpenChart(d, w, 0, w, h, "");
  win.End;

  (* Settings *)
  Check.Check((c.Count() = 0) & (c.MaxCount() = 0) & c.Autosize() & (c.Kind() = FlValuators.BarChart)
    & (c.TextFont() = Fl.Helvetica) & (c.TextSize() = 10) & (c.TextColor() = Fl.ForegroundColor),
    "a chart starts empty, unlimited, autosized bars, in Helvetica 10");
  c.SetKind(FlValuators.PieChart); c.SetAutosize(FALSE); c.SetTextFont(Fl.Courier);
  c.SetTextSize(14); c.SetTextColor(Fl.Blue);
  Check.Check((c.Kind() = FlValuators.PieChart) & ~c.Autosize() & (c.TextFont() = Fl.Courier)
    & (c.TextSize() = 14) & (c.TextColor() = Fl.Blue), "its settings read back");
  c.SetKind(FlValuators.BarChart); c.SetAutosize(TRUE); c.SetTextFont(Fl.Helvetica);
  c.SetTextSize(10); c.SetTextColor(Fl.ForegroundColor);

  (* Entries and their limit *)
  FOR i := 1 TO 5 DO c.Add(i, "", Fl.Red) END;
  Check.Check(c.Count() = 5, "Add");
  c.SetMaxCount(3);
  Check.Check((c.Count() = 3) & (c.MaxCount() = 3), "SetMaxCount drops entries beyond it");
  c.Add(6.0D0, "", Fl.Red); c.Insert(1, 0.0D0, "", Fl.Red); c.Insert(4, 0.0D0, "", Fl.Red);
  Check.Check(c.Count() = 3, "Add and Insert keep to it");
  c.SetMaxCount(0); c.Insert(4, 1.0D0, "", Fl.Red); c.Replace(4, 2.0D0, "", Fl.Red);
  Check.Check(c.Count() = 4, "Insert at the end, and Replace");

  (* Bounds *)
  c.Clear;
  c.Add(3.0D0, "", Fl.Red); c.Add(5.0D0, "", Fl.Red);
  c.Bounds(min, max);
  Check.Check((c.Count() = 2) & (min = 0.0D0) & (max = 0.0D0), "Clear, and bounds 0 and 0");
  ok := Probe.Capture(c); Probe.Release;
  c.Bounds(min, max);
  Check.Check((min = 0.0D0) & (max = 5.0D0), "become 0 and the greatest value when drawn");
  c.Clear; c.Add(-2.0D0, "", Fl.Red); c.Add(5.0D0, "", Fl.Red);
  ok := Probe.Capture(c); Probe.Release;
  c.Bounds(min, max);
  Check.Check((min = -2.0D0) & (max = 5.0D0), "or the least, below 0");
  c.SetBounds(-10.0D0, 10.0D0); c.Bounds(min, max);
  Check.Check((min = -10.0D0) & (max = 10.0D0), "SetBounds");

  (* Drawing *)
  c.Clear; c.SetBounds(0.0D0, 10.0D0); c.Add(10.0D0, "", Fl.Red);
  Check.Check(Red(c, w DIV 2, h DIV 2), "a bar, in its color");
  c.SetKind(FlValuators.PieChart);
  (* its center is on the slice's outline *)
  Check.Check(Red(c, w DIV 2, h DIV 2 - 10), "a pie");
  c.SetKind(FlValuators.BarChart); c.Replace(1, 10.0D0, "", Fl.Blue);
  Check.Check(~Red(c, w DIV 2, h DIV 2), "Replace changes the color");

  (* A label is cut to 18 bytes, before a UTF-8 character crossing the
     18th: 17 a's then an e acute are drawn as 17 a's. *)
  c.Clear; c.Add(10.0D0, "aaaaaaaaaaaaaaaaa", Fl.Red);
  label := "aaaaaaaaaaaaaaaaa"; label[17] := 0C3X; label[18] := 0A9X; label[19] := 0X;
  d.SetBounds(0.0D0, 10.0D0); d.Add(10.0D0, label, Fl.Red);
  Keep(c);
  Check.Check(Same(d), "a label cut before a character crossing its 18th byte");
  d.Replace(1, 10.0D0, "aaaaaaaaaaaaaaaaaa", Fl.Red);
  Check.Check(~Same(d), "and not one that fits");

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestChart.
