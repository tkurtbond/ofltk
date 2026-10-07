MODULE HaltChartEntry; (* Replace of an entry a chart hasn't halts with Fl.IndexOutOfRange (74) *)

IMPORT Fl, FlValuators;

VAR c: FlValuators.Chart;

BEGIN
  NEW(c); FlValuators.OpenChart(c, 0, 0, 100, 100, "");
  c.Add(1.0D0, "one", Fl.Red);
  c.Replace(2, 2.0D0, "two", Fl.Red)
END HaltChartEntry.
