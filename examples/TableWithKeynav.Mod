MODULE TableWithKeynav; (* FLTK's examples/table-with-keynav.cxx: selecting cells with the mouse or the keys, and their sum *)

IMPORT OutStr, Fl, FlDraw, FlButtons, FlInputs, FlTable;

TYPE
  MyTable = POINTER TO RECORD (FlTable.TableRowDesc) END;

VAR
  win: Fl.DoubleWindow;
  rowSelect: FlButtons.ToggleButton;  (* selects rows, not cells *)
  table: MyTable;
  sum: FlInputs.Output;               (* the sum of the selected cells *)

PROCEDURE (t: MyTable) Selected(r, c: INTEGER): BOOLEAN;
BEGIN
  IF rowSelect.Value() THEN RETURN t.RowSelected(r) ELSE RETURN t.IsSelected(r, c) END
END Selected;

PROCEDURE (t: MyTable) DrawCell*(context, r, c, x, y, w, h: INTEGER);
  VAR s: ARRAY 30 OF CHAR; color: INTEGER;
BEGIN
  s := "";
  IF (context = FlTable.ContextColHeader) OR (context = FlTable.ContextRowHeader) THEN
    FlDraw.SetFont(Fl.Helvetica + Fl.Bold, 14);
    FlDraw.PushClip(x, y, w, h);
    IF context = FlTable.ContextColHeader THEN color := t.ColHeaderColor(); OutStr.Int(c, 0, s)
    ELSE color := t.RowHeaderColor(); OutStr.Int(r, 0, s)
    END;
    FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, color);
    FlDraw.SetColor(Fl.Black);
    FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
    FlDraw.PopClip
  ELSIF context = FlTable.ContextCell THEN
    IF t.Selected(r, c) THEN color := Fl.Yellow ELSE color := Fl.White END;
    FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, color);
    FlDraw.PushClip(x + 3, y + 3, w - 6, h - 6);
    FlDraw.SetFont(Fl.Helvetica, 14);
    FlDraw.SetColor(Fl.Black);
    OutStr.Int(r * c, 0, s);                (* the row times the column *)
    FlDraw.TextAligned(s, x + 3, y + 3, w - 6, h - 6, Fl.AlignRight);
    FlDraw.PopClip
  END
END DrawCell;

PROCEDURE OpenMyTable(t: MyTable; x, y, w, h: INTEGER; label: ARRAY OF CHAR);
BEGIN
  FlTable.OpenTableRow(t, x, y, w, h, label);
  t.SetRowHeader(TRUE);
  t.SetRowHeaderWidth(70);
  t.SetRowResize(TRUE);
  t.SetRows(11);
  t.SetRowHeightAll(20);
  t.SetColHeader(TRUE);
  t.SetColHeaderHeight(20);
  t.SetColResize(TRUE);
  t.SetCols(11);
  t.SetColWidthAll(70);
  t.End
END OpenMyTable;

(* The sum of the selected cells, or -1 if none is. *)
PROCEDURE (t: MyTable) SelectionSum(): INTEGER;
  VAR sum, r, c: INTEGER;
BEGIN
  sum := -1;
  FOR r := 0 TO t.Rows() - 1 DO
    FOR c := 0 TO t.Cols() - 1 DO
      IF t.Selected(r, c) THEN
        IF sum = -1 THEN sum := 0 END;
        INC(sum, r * c)
      END
    END
  END;
  RETURN sum
END SelectionSum;

PROCEDURE (t: MyTable) UpdateSum;
  VAR s, old: ARRAY 80 OF CHAR; n: INTEGER;
BEGIN
  n := t.SelectionSum(); s := "";
  IF n = -1 THEN s := "(nothing selected)"; sum.SetColor(48)
  ELSE OutStr.Int(n, 0, s); sum.SetColor(Fl.White)
  END;
  sum.Value(old);
  IF s # old THEN sum.SetValue(s); sum.Redraw END
END UpdateSum;

PROCEDURE (t: MyTable) Handle*(e: INTEGER): BOOLEAN;
  VAR ret: BOOLEAN;
BEGIN
  ret := t.Handle^(e);
  IF (e = Fl.EvKeyDown) & (Fl.EventKey() = Fl.KeyEscape) THEN win.Hide END;  (* Escape quits *)
  IF (e = Fl.EvPush) OR (e = Fl.EvRelease) OR (e = Fl.EvKeyUp) OR (e = Fl.EvKeyDown) OR (e = Fl.EvDrag) THEN
    t.UpdateSum;
    t.Redraw
  ELSIF (e = Fl.EvFocus) OR (e = Fl.EvUnfocus) THEN  (* TRUE: the table wants the keys *)
    ret := TRUE
  END;
  RETURN ret
END Handle;

PROCEDURE RowSelectCb(w: Fl.Widget);
BEGIN
  win.Redraw;          (* redrawn with the change *)
  table.UpdateSum
END RowSelectCb;

PROCEDURE Build;
  VAR tip: ARRAY 100 OF CHAR;
BEGIN
  Fl.SetOption(Fl.OptionArrowFocus, FALSE);  (* the arrow keys move between cells, not widgets *)
  NEW(win); Fl.OpenDoubleWindow(win, 862, 312, "Table With Keynav");
  NEW(table); OpenMyTable(table, 10, 30, win.W() - 20, win.H() - 70, "Times Table");
  tip := "Use mouse or Shift + Arrow Keys to make selections."; OutStr.Ln(tip);
  OutStr.String("Sum of selected values is shown.", tip);
  table.SetTooltip(tip);
  NEW(rowSelect); FlButtons.OpenToggleButton(rowSelect, 140, 10, 12, 12, "Row selection");
  rowSelect.SetAlign(Fl.AlignLeft);
  rowSelect.SetValue(FALSE);
  rowSelect.SetSelectionColor(Fl.Yellow);
  rowSelect.action := RowSelectCb;
  rowSelect.SetTooltip("Click to toggle row vs. row/col selection");
  NEW(sum); FlInputs.OpenOutput(sum, 140, table.Y() + table.H() + 10, 160, 25, "Selection Sum:");
  sum.SetValue("(nothing selected)");
  sum.SetColor(48);
  sum.SetTooltip("This field shows the sum of the selected cells in the table");
  win.End;
  win.SetResizable(table)
END Build;

BEGIN
  Build;
  win.Show;
  Fl.Run
END TableWithKeynav.
