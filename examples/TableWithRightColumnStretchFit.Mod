MODULE TableWithRightColumnStretchFit; (* FLTK's examples/table-with-right-column-stretch-fit.cxx: the last column fills the table *)

IMPORT OutStr, Fl, FlDraw, FlButtons, FlTable;

TYPE
  MyTable = POINTER TO RECORD (FlTable.TableDesc) END;

VAR
  win: Fl.DoubleWindow;
  table: MyTable;
  more, less: FlButtons.Button;

PROCEDURE (t: MyTable) DrawHeader(s-: ARRAY OF CHAR; x, y, w, h: INTEGER);
BEGIN
  FlDraw.PushClip(x, y, w, h);
  FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, t.RowHeaderColor());
  FlDraw.SetColor(Fl.Black);
  FlDraw.TextAligned(s, x, y, w, h, Fl.AlignLeft);
  FlDraw.PopClip
END DrawHeader;

PROCEDURE (t: MyTable) DrawData(s-: ARRAY OF CHAR; x, y, w, h: INTEGER);
BEGIN
  FlDraw.PushClip(x, y, w, h);
  FlDraw.SetColor(Fl.White); FlDraw.RectF(x, y, w, h);
  FlDraw.SetColor(Fl.Gray0); FlDraw.TextAligned(s, x, y, w, h, Fl.AlignLeft);
  FlDraw.SetColor(t.Color()); FlDraw.Rect(x, y, w, h);
  FlDraw.PopClip
END DrawData;

PROCEDURE (t: MyTable) DrawCell*(context, r, c, x, y, w, h: INTEGER);
  VAR s: ARRAY 40 OF CHAR;
BEGIN
  CASE context OF
  | FlTable.ContextStartPage: FlDraw.SetFont(Fl.Helvetica, 14)  (* before the page is drawn *)
  | FlTable.ContextColHeader:
    IF c = 0 THEN t.DrawHeader(" #Id", x, y, w, h) ELSE t.DrawHeader(" Date / Time", x, y, w, h) END
  | FlTable.ContextCell:
    IF c = 0 THEN s := " #"; OutStr.Int(r, 0, s)
    ELSE s := " 2017-01-02 / 09:20:25."; OutStr.Int(r, 0, s)
    END;
    t.DrawData(s, x, y, w, h)
  ELSE
  END
END DrawCell;

(* Makes the right column end where the cells' area does. *)
PROCEDURE (t: MyTable) FixColumnSize;
  VAR x, y, w, h, ax, ay, aw, ah: INTEGER;
BEGIN
  IF t.Rows() = 0 THEN RETURN END;                   (* no rows to work with *)
  IF t.FindCell(FlTable.ContextCell, 0, 1, x, y, w, h) THEN END;  (* the right column's first cell *)
  t.Area(FlTable.AreaCells, ax, ay, aw, ah);
  t.SetColWidth(1, t.ColWidth(1) - ((x + w) - (ax + aw)))  (* less how far past the area it ends *)
END FixColumnSize;

PROCEDURE (t: MyTable) Resize*(x, y, w, h: INTEGER);
BEGIN
  t.Resize^(x, y, w, h);
  t.FixColumnSize          (* the right column fitted to the new size *)
END Resize;

PROCEDURE OpenMyTable(t: MyTable; x, y, w, h: INTEGER);
BEGIN
  FlTable.OpenTable(t, x, y, w, h, "");
  t.SetRows(10);              (* how many rows *)
  t.SetRowHeader(FALSE);      (* no headers along the left *)
  t.SetRowHeightAll(20);      (* each row's height *)
  t.SetRowResize(FALSE);      (* rows can't be resized *)
  t.SetCols(2);               (* how many columns *)
  t.SetColHeader(TRUE);       (* headers along the top *)
  t.SetColWidth(0, 50);       (* the left column's width *)
  t.SetColWidth(1, 300);      (* the right column's, until FixColumnSize *)
  t.SetColResize(FALSE);      (* columns can't be resized *)
  t.End;
  t.FixColumnSize
END OpenMyTable;

PROCEDURE MoreCb(w: Fl.Widget);
BEGIN table.SetRows(table.Rows() + 1); table.FixColumnSize
END MoreCb;

PROCEDURE LessCb(w: Fl.Widget);
BEGIN
  IF table.Rows() > 0 THEN table.SetRows(table.Rows() - 1) END;
  table.FixColumnSize
END LessCb;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 500, 400, "Table With Right Column Stretch Fit");
  NEW(table); OpenMyTable(table, 10, 10, win.W() - 20, 340);
  NEW(more); FlButtons.OpenButton(more, 10, 360, 100, 25, "+ Row"); more.action := MoreCb;
  NEW(less); FlButtons.OpenButton(less, 220, 360, 100, 25, "- Row"); less.action := LessCb;
  win.End;
  win.SetResizable(table);
  win.Show;
  Fl.Run
END TableWithRightColumnStretchFit.
