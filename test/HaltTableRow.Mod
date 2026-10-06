MODULE HaltTableRow; (* A table row out of range halts with Fl.IndexOutOfRange, 74 *)
IMPORT Fl, FlTable;
VAR win: Fl.Window; t: FlTable.Table; h: INTEGER;
BEGIN
  NEW(win); Fl.OpenWindow(win, 100, 100, "HaltTableRow");
  NEW(t); FlTable.OpenTable(t, 0, 0, 100, 100, ""); t.End;
  win.End;
  t.SetRows(5);
  h := t.RowHeight(5)
END HaltTableRow.
