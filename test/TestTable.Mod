MODULE TestTable; (* FlTable: cells drawn by DrawCell, clicks, selection, and widgets in cells *)

IMPORT Fl, FlDraw, FlButtons, FlTable, Check, Probe;

TYPE
  (* Fills cell 0, 0 red and 1, 1 blue, the rest white, and counts what
     it is asked to draw. *)
  Grid = POINTER TO RECORD (FlTable.TableRowDesc)
    cells, headers, pages, calls: INTEGER;
    row, col, context: INTEGER  (* of the last Callback *)
  END;

VAR
  win: Fl.Window;
  t: Grid;
  plain: FlTable.Table;
  b, b2: FlButtons.Button;
  x, y, w, h, r1, r2, c1, c2, ax, ay, aw, ah: INTEGER;
  ok: BOOLEAN;

PROCEDURE (g: Grid) DrawCell*(context, r, c, x, y, w, h: INTEGER);
BEGIN
  CASE context OF
  | FlTable.ContextCell:
    INC(g.cells);
    IF (r = 0) & (c = 0) THEN FlDraw.SetColor(Fl.Red)
    ELSIF (r = 1) & (c = 1) THEN FlDraw.SetColor(Fl.Blue)
    ELSE FlDraw.SetColor(Fl.White)
    END;
    FlDraw.RectF(x, y, w, h)
  | FlTable.ContextRowHeader, FlTable.ContextColHeader:
    INC(g.headers);
    FlDraw.SetColor(Fl.Green); FlDraw.RectF(x, y, w, h)
  | FlTable.ContextStartPage, FlTable.ContextEndPage: INC(g.pages)
  ELSE
  END
END DrawCell;

PROCEDURE (g: Grid) Callback*;
BEGIN
  INC(g.calls); g.row := g.CallbackRow(); g.col := g.CallbackCol();
  g.context := g.CallbackContext()
END Callback;

PROCEDURE Click(x, y: INTEGER);
BEGIN
  ok := Probe.Mouse(win, Fl.EvPush, x, y, Fl.LeftMouse, Fl.Button1, 0);
  ok := Probe.Mouse(win, Fl.EvRelease, x, y, Fl.LeftMouse, {}, 0)
END Click;

BEGIN
  NEW(win); Fl.OpenWindow(win, 300, 200, "TestTable");
  NEW(t); FlTable.OpenTableRow(t, 0, 0, 300, 200, "");
  (* a widget in a cell: opened while the table is the current group *)
  NEW(b); FlButtons.OpenButton(b, 0, 0, 10, 10, "in a cell");
  t.End;
  win.End;

  (* The table's children are the widgets in its cells. *)
  Check.Check((t.Children() = 1) & (t.Child(0) = b) & (t.Find(b) = 0), "Children: the widgets in its cells alone");
  Check.Check(win.Children() = 1, "End: the window is the current group again");
  NEW(b2); FlButtons.OpenButton(b2, 0, 0, 10, 10, "added");
  win.Remove(b2); t.Add(b2);
  Check.Check((t.Children() = 2) & (t.Child(1) = b2), "Add");
  t.Remove(b2); t.Insert(b2, 0);
  Check.Check((t.Child(0) = b2) & (t.Child(1) = b), "Remove, Insert");
  t.Clear;
  Check.Check((t.Children() = 0) & ~b.IsOpen() & ~b2.IsOpen(), "Clear deletes them");

  (* Rows, columns, headers *)
  Check.Check((t.Rows() = 0) & (t.Cols() = 0) & ~t.RowHeader() & ~t.ColHeader(), "empty to start with");
  t.SetRows(5); t.SetCols(4);
  t.SetRowHeader(TRUE); t.SetRowHeaderWidth(40);
  t.SetColHeader(TRUE); t.SetColHeaderHeight(25);
  t.SetRowHeightAll(20); t.SetColWidthAll(50);
  t.SetColWidth(3, 60); t.SetRowHeight(4, 30);
  Check.Check((t.Rows() = 5) & (t.Cols() = 4) & t.RowHeader() & t.ColHeader()
    & (t.RowHeaderWidth() = 40) & (t.ColHeaderHeight() = 25), "SetRows, SetCols, the headers");
  Check.Check((t.RowHeight(0) = 20) & (t.RowHeight(4) = 30) & (t.ColWidth(0) = 50) & (t.ColWidth(3) = 60),
    "row heights and column widths");
  t.SetRowHeaderColor(Fl.Yellow); t.SetColHeaderColor(Fl.Cyan);
  Check.Check((t.RowHeaderColor() = Fl.Yellow) & (t.ColHeaderColor() = Fl.Cyan), "header colors");
  t.SetRowResize(TRUE); t.SetColResize(TRUE); t.SetRowResizeMin(5); t.SetColResizeMin(7);
  Check.Check(t.RowResize() & t.ColResize() & (t.RowResizeMin() = 5) & (t.ColResizeMin() = 7), "resizing");
  t.SetTableBox(Fl.NoBox); t.SetScrollbarSize(12);
  Check.Check((t.TableBox() = Fl.NoBox) & (t.ScrollbarSize() = 12) & ~t.IsInteractiveResize(), "SetTableBox, SetScrollbarSize");

  (* Drawing *)
  ok := Probe.Capture(t);
  Check.Check(ok & (t.cells > 0) & (t.headers > 0) & (t.pages = 2), "DrawCell: cells, headers, start and end");
  Check.Check(t.FindCell(FlTable.ContextCell, 0, 0, x, y, w, h)
    & (x = 41) & (y = 26) & (w = 50) & (h = 20), "FindCell: past the headers and the frame");
  t.Area(FlTable.AreaWidget, ax, ay, aw, ah);
  Check.Check((ax = 1) & (ay = 1) & (aw = 298) & (ah = 198), "Area: inside the table's frame");
  t.Area(FlTable.AreaCells, ax, ay, aw, ah);
  Check.Check((ax = 41) & (ay = 26) & (aw = 258) & (ah = 173), "Area: the cells', beside the headers");
  t.Area(FlTable.AreaCellsInner, ax, ay, aw, ah);
  Check.Check((ax = 41) & (ay = 26) & (aw = 258) & (ah = 173), "Area: inside the cells' box, NoBox");
  Check.Check((Probe.Pixel(x + 25, y + 10) = Fl.RGB(255, 0, 0))
    & (Probe.Pixel(x + 75, y + 30) = Fl.RGB(0, 0, 255))
    & (Probe.Pixel(x + 75, y + 10) = Fl.RGB(255, 255, 255)), "DrawCell draws each cell where it is");
  Check.Check(Probe.Pixel(20, y + 10) = Fl.RGB(0, 255, 0), "and the headers");
  Probe.Release;
  t.VisibleCells(r1, r2, c1, c2);
  Check.Check((r1 = 0) & (r2 = 4) & (c1 = 0) & (c2 = 3), "VisibleCells");
  t.SetTableBox(Fl.ThinDownFrame);
  t.Area(FlTable.AreaCellsInner, ax, ay, aw, ah);
  Check.Check((ax = 42) & (ay = 27) & (aw = 256) & (ah = 171), "Area: inside the cells' box");
  t.SetRows(50);
  t.Area(FlTable.AreaCells, ax, ay, aw, ah);
  Check.Check((ax = 41) & (aw = 258 - 12), "Area: beside the scrollbar");
  t.SetRows(5); t.SetTableBox(Fl.NoBox);

  (* A click in a cell selects its row and calls back. *)
  Click(x + 75, y + 30);
  Check.Check((t.calls > 0) & (t.row = 1) & (t.col = 1) & (t.context = FlTable.ContextCell),
    "a click: CallbackRow, CallbackCol, CallbackContext");
  Check.Check(t.RowSelected(1) & ~t.RowSelected(0), "a click selects its row");
  Check.Check(t.SelectMode() = FlTable.SelectMulti, "SelectMulti to start with");
  Check.Check(t.SelectRow(3, TRUE) & ~t.SelectRow(3, TRUE) & t.RowSelected(3) & t.RowSelected(1), "SelectRow");
  t.SetSelectMode(FlTable.SelectSingle);
  Check.Check(t.SelectRow(0, TRUE) & t.RowSelected(0) & ~t.RowSelected(1) & ~t.RowSelected(3), "SelectSingle");
  t.SetSelectMode(FlTable.SelectMulti);
  t.SelectAllRows(TRUE);
  Check.Check(t.RowSelected(2) & t.RowSelected(4), "SelectAllRows");
  t.SelectAllRows(FALSE);
  Check.Check(~t.RowSelected(0), "and none");

  (* Cell selection and scrolling *)
  t.SetSelection(1, 1, 2, 3);
  t.GetSelection(r1, c1, r2, c2);
  Check.Check((r1 = 1) & (c1 = 1) & (r2 = 2) & (c2 = 3) & t.IsSelected(2, 2) & ~t.IsSelected(0, 0),
    "SetSelection, GetSelection, IsSelected");
  Check.Check(t.MoveCursor(2, 2, FALSE), "MoveCursor");

  (* Tab: the next widget, or with TabCellNav the next cell *)
  Check.Check(~t.TabCellNav(), "TabCellNav: off to start with");
  Fl.SetFocus(t); t.SetSelection(1, 1, 1, 1);
  Check.Check(~Probe.Key(Fl.EvKeyDown, Fl.KeyTab, {}, 09X), "Tab: the table leaves it to FLTK");
  t.SetTabCellNav(TRUE);
  Check.Check(t.TabCellNav() & Probe.Key(Fl.EvKeyDown, Fl.KeyTab, {}, 09X), "SetTabCellNav: the table takes Tab");
  t.GetSelection(r1, c1, r2, c2);
  Check.Check((r1 = 1) & (c1 = 2) & (r2 = 1) & (c2 = 2), "and moves to the next cell");
  ok := Probe.Key(Fl.EvKeyDown, Fl.KeyTab, Fl.Shift, 09X);
  t.GetSelection(r1, c1, r2, c2);
  Check.Check(ok & (r1 = 1) & (c1 = 1), "Shift-Tab: the cell before");
  t.SetTabCellNav(FALSE); Fl.SetFocus(NIL);
  t.SetRows(100);
  t.SetRowPosition(50);
  Check.Check(t.RowPosition() = 50, "SetRowPosition");
  t.RedrawRange(0, 1, 0, 1);

  (* A plain table, and one deleted with its window *)
  NEW(plain); FlTable.OpenTable(plain, 0, 0, 100, 100, ""); plain.End;
  Check.Check((plain.Rows() = 0) & (plain.Children() = 0), "OpenTable");
  plain.Delete;
  win.Delete;
  Check.Check(~t.IsOpen() & (Fl.OpenWidgets() = 0), "every widget deleted");
  Check.Summary
END TestTable.
