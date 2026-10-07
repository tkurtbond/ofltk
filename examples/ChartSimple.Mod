MODULE ChartSimple; (* FLTK's examples/chart-simple.cxx: a sine wave as a chart, of a kind chosen *)

IMPORT SYSTEM, Fl, FlValuators, FlMenus, MathL, RealDigits, OutStr;

VAR
  win: Fl.Window;
  chart: FlValuators.Chart;
  choice: FlMenus.Choice;
  t, val: LONGREAL;
  valStr: ARRAY 20 OF CHAR;
  i: INTEGER;
  ok: BOOLEAN;

(* v as "%.0f" writes it, from RealDigits' exact digits, rounded as
   printf rounds them. *)
PROCEDURE Fixed0(v: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 40 OF CHAR; count, e, p: INTEGER;
BEGIN
  s[0] := 0X;
  IF SYSTEM.VAL(HUGEINT, v) < 0 THEN OutStr.Char("-", s); v := -v END;  (* -0 too *)
  IF v = 0.0D0 THEN count := 0; e := 0 ELSE RealDigits.Fixed(v, 0, 30, d, count, e) END;
  p := e; IF p < 0 THEN p := 0 END;
  WHILE p >= 0 DO
    IF (e - p >= 0) & (e - p < count) THEN OutStr.Char(d[e - p], s) ELSE OutStr.Char("0", s) END;
    DEC(p)
  END
END Fixed0;

(* The choice's items are the kinds of chart, in order. *)
PROCEDURE ChartTypeCB(w: Fl.Widget);
BEGIN chart.SetKind(choice.Value()); chart.Redraw
END ChartTypeCB;

BEGIN
  NEW(win); Fl.OpenWindow(win, 1000, 510, "Chart Simple");
  (* a chart of a sin() wave *)
  NEW(chart); FlValuators.OpenChart(chart, 20, 20, win.W() - 40, win.H() - 80, "Chart");
  chart.SetBounds(-125.0D0, 125.0D0);
  t := 1.5D0;
  WHILE t < 1.5D0 + 15.1D0 DO
    val := MathL.sin(t) * 125.0D0;
    Fixed0(val, valStr);
    IF val < 0.0D0 THEN chart.Add(val, valStr, Fl.Red) ELSE chart.Add(val, valStr, Fl.Green) END;
    t := t + 0.5D0
  END;
  (* the user changes the chart's kind *)
  NEW(choice); FlMenus.OpenChoice(choice, 140, 470, 200, 25, "Chart Type: ");
  i := choice.Add("FL_BAR_CHART", 0, {}, ChartTypeCB, {});
  i := choice.Add("FL_HORBAR_CHART", 0, {}, ChartTypeCB, {});
  i := choice.Add("FL_LINE_CHART", 0, {}, ChartTypeCB, {});
  i := choice.Add("FL_FILL_CHART", 0, {}, ChartTypeCB, {});
  i := choice.Add("FL_SPIKE_CHART", 0, {}, ChartTypeCB, {});
  i := choice.Add("FL_PIE_CHART", 0, {}, ChartTypeCB, {});
  i := choice.Add("FL_SPECIALPIE_CHART", 0, {}, ChartTypeCB, {});
  ok := choice.SetValue(0);
  win.End;
  win.SetResizable(win);
  win.Show;
  Fl.Run
END ChartSimple.
