MODULE FlTable; (* Fl_Table and Fl_Table_Row: rows and columns of cells the program draws *)

(* A Table is a grid of rows and columns, with optional row and column
   headers, scrolled when it doesn't fit. It holds no data: FLTK calls
   its DrawCell for each cell and header on screen, with FlDraw set up to
   draw there, and the program draws what the cell holds. A TableRow is a
   table whose rows can be selected.

   A table is a group, and the widgets opened while it is the current
   group (from OpenTable until End) go in its cells: place each at its
   cell (FindCell). Group's Child, Children, Add and the rest reach these
   widgets, not the table's scrollbars.

   The table calls its Callback for clicks and resizes, as When says:
   CallbackRow, CallbackCol and CallbackContext say where. The C++ part
   is FlTable.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* what DrawCell draws, and where a Callback's event was (Table.CallbackContext) *)
  ContextNone* = 0;
  ContextStartPage* = 1;
  ContextEndPage* = 2;
  ContextRowHeader* = 4;
  ContextColHeader* = 8;
  ContextCell* = 16;
  ContextTable* = 32;
  ContextRCResize* = 64;

  (* how a table row's rows are selected (TableRow.SetSelectMode) *)
  SelectNone* = 0;
  SelectSingle* = 1;
  SelectMulti* = 2;
(* END generated constants *)

  (* the classes, as ofl_table_new numbers them *)
  table = 0; tableRow = 1;

TYPE
  Table* = POINTER TO TableDesc;
  TableDesc* = RECORD (Fl.GroupDesc) END;

  TableRow* = POINTER TO TableRowDesc;
  TableRowDesc* = RECORD (TableDesc) END;

  DrawCellProc = PROCEDURE (self: SYSTEM.ADDRESS; context, r, c, x, y, w, h: SYSTEM.INT32);

PROCEDURE ["C", "ofl_table_register"] CRegister(drawCell: DrawCellProc);
PROCEDURE ["C", "ofl_table_new"] CNew(class, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_table_get"] CGet(t: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_table_set"] CSet(t: SYSTEM.ADDRESS; what, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_table_size"] CSize(t: SYSTEM.ADDRESS; what, i: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_table_set_size"] CSetSize(t: SYSTEM.ADDRESS; what, i, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_table_visible_cells"] CVisibleCells(t: SYSTEM.ADDRESS; VAR r1, r2, c1, c2: SYSTEM.INT32);
PROCEDURE ["C", "ofl_table_is_selected"] CIsSelected(t: SYSTEM.ADDRESS; r, c: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_table_get_selection"] CGetSelection(t: SYSTEM.ADDRESS; VAR top, left, bottom, right: SYSTEM.INT32);
PROCEDURE ["C", "ofl_table_set_selection"] CSetSelection(t: SYSTEM.ADDRESS; top, left, bottom, right: SYSTEM.INT32);
PROCEDURE ["C", "ofl_table_move_cursor"] CMoveCursor(t: SYSTEM.ADDRESS; r, c, shift: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_table_find_cell"] CFindCell(t: SYSTEM.ADDRESS; context, r, c: SYSTEM.INT32; VAR x, y, w, h: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_table_redraw_range"] CRedrawRange(t: SYSTEM.ADDRESS; r1, r2, c1, c2: SYSTEM.INT32);
PROCEDURE ["C", "ofl_table_row_selected"] CRowSelected(t: SYSTEM.ADDRESS; r: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_table_select_row"] CSelectRow(t: SYSTEM.ADDRESS; r, flag: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_table_select_all_rows"] CSelectAllRows(t: SYSTEM.ADDRESS; flag: SYSTEM.INT32);

PROCEDURE Int(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Int;

PROCEDURE Open(t: Table; class, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(t, CNew(class, x, y, w, h, label, Fl.BeginOpen(t)))
END Open;

(* Opens t with no rows or columns, and no headers, as the current group,
   as a Group is: End it. *)
PROCEDURE OpenTable*(t: Table; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(t, table, x, y, w, h, label)
END OpenTable;

(* The same, its rows selectable: SelectMulti to start with. *)
PROCEDURE OpenTableRow*(t: TableRow; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(t, tableRow, x, y, w, h, label)
END OpenTableRow;

(* Draws what context names, at x, y, w, h, in the table's window: a
   cell (ContextCell) or header (ContextRowHeader, ContextColHeader) of
   row r and column c, or nothing, before (ContextStartPage) or after
   (ContextEndPage) the cells are drawn. Drawing isn't clipped to the
   cell: clip it with FlDraw.PushClip. The default draws nothing. *)
PROCEDURE (t: Table) DrawCell*(context, r, c, x, y, w, h: INTEGER);
END DrawCell;

PROCEDURE Get(t: Table; what: INTEGER): INTEGER;
BEGIN RETURN CGet(Fl.Live(t), what)
END Get;

PROCEDURE Set(t: Table; what, v: INTEGER);
BEGIN CSet(Fl.Live(t), what, v)
END Set;

PROCEDURE (t: Table) SetRows*(n: INTEGER);
BEGIN ASSERT(n >= 0, Fl.IndexOutOfRange); Set(t, 0, n)
END SetRows;

PROCEDURE (t: Table) Rows*(): INTEGER;
BEGIN RETURN Get(t, 0)
END Rows;

PROCEDURE (t: Table) SetCols*(n: INTEGER);
BEGIN ASSERT(n >= 0, Fl.IndexOutOfRange); Set(t, 1, n)
END SetCols;

PROCEDURE (t: Table) Cols*(): INTEGER;
BEGIN RETURN Get(t, 1)
END Cols;

PROCEDURE (t: Table) SetRowHeader*(on: BOOLEAN);
BEGIN Set(t, 2, Int(on))
END SetRowHeader;

PROCEDURE (t: Table) RowHeader*(): BOOLEAN;
BEGIN RETURN Get(t, 2) # 0
END RowHeader;

PROCEDURE (t: Table) SetColHeader*(on: BOOLEAN);
BEGIN Set(t, 3, Int(on))
END SetColHeader;

PROCEDURE (t: Table) ColHeader*(): BOOLEAN;
BEGIN RETURN Get(t, 3) # 0
END ColHeader;

PROCEDURE (t: Table) SetRowHeaderWidth*(w: INTEGER);
BEGIN Set(t, 4, w)
END SetRowHeaderWidth;

PROCEDURE (t: Table) RowHeaderWidth*(): INTEGER;
BEGIN RETURN Get(t, 4)
END RowHeaderWidth;

PROCEDURE (t: Table) SetColHeaderHeight*(h: INTEGER);
BEGIN Set(t, 5, h)
END SetColHeaderHeight;

PROCEDURE (t: Table) ColHeaderHeight*(): INTEGER;
BEGIN RETURN Get(t, 5)
END ColHeaderHeight;

PROCEDURE (t: Table) SetRowHeaderColor*(c: INTEGER);
BEGIN Set(t, 6, c)
END SetRowHeaderColor;

PROCEDURE (t: Table) RowHeaderColor*(): INTEGER;
BEGIN RETURN Get(t, 6)
END RowHeaderColor;

PROCEDURE (t: Table) SetColHeaderColor*(c: INTEGER);
BEGIN Set(t, 7, c)
END SetColHeaderColor;

PROCEDURE (t: Table) ColHeaderColor*(): INTEGER;
BEGIN RETURN Get(t, 7)
END ColHeaderColor;

(* Whether the user may resize rows (columns) by dragging their edges in
   the header. *)
PROCEDURE (t: Table) SetRowResize*(on: BOOLEAN);
BEGIN Set(t, 8, Int(on))
END SetRowResize;

PROCEDURE (t: Table) RowResize*(): BOOLEAN;
BEGIN RETURN Get(t, 8) # 0
END RowResize;

PROCEDURE (t: Table) SetColResize*(on: BOOLEAN);
BEGIN Set(t, 9, Int(on))
END SetColResize;

PROCEDURE (t: Table) ColResize*(): BOOLEAN;
BEGIN RETURN Get(t, 9) # 0
END ColResize;

(* The least height (width) the user can drag a row (column) to. *)
PROCEDURE (t: Table) SetRowResizeMin*(h: INTEGER);
BEGIN Set(t, 10, h)
END SetRowResizeMin;

PROCEDURE (t: Table) RowResizeMin*(): INTEGER;
BEGIN RETURN Get(t, 10)
END RowResizeMin;

PROCEDURE (t: Table) SetColResizeMin*(w: INTEGER);
BEGIN Set(t, 11, w)
END SetColResizeMin;

PROCEDURE (t: Table) ColResizeMin*(): INTEGER;
BEGIN RETURN Get(t, 11)
END ColResizeMin;

(* Scrolls to put row r at the top. *)
PROCEDURE (t: Table) SetRowPosition*(r: INTEGER);
BEGIN Set(t, 12, r)
END SetRowPosition;

PROCEDURE (t: Table) RowPosition*(): INTEGER;
BEGIN RETURN Get(t, 12)
END RowPosition;

(* Scrolls to put column c at the left. *)
PROCEDURE (t: Table) SetColPosition*(c: INTEGER);
BEGIN Set(t, 13, c)
END SetColPosition;

PROCEDURE (t: Table) ColPosition*(): INTEGER;
BEGIN RETURN Get(t, 13)
END ColPosition;

(* The box drawn around the cells, Fl.NoBox to start with. *)
PROCEDURE (t: Table) SetTableBox*(b: INTEGER);
BEGIN Set(t, 14, b)
END SetTableBox;

PROCEDURE (t: Table) TableBox*(): INTEGER;
BEGIN RETURN Get(t, 14)
END TableBox;

(* The scrollbars' width; 0 for FLTK's default. *)
PROCEDURE (t: Table) SetScrollbarSize*(w: INTEGER);
BEGIN Set(t, 15, w)
END SetScrollbarSize;

PROCEDURE (t: Table) ScrollbarSize*(): INTEGER;
BEGIN RETURN Get(t, 15)
END ScrollbarSize;

(* In a Callback: the row, column and context (ContextCell and the rest)
   of the event that called it. *)
PROCEDURE (t: Table) CallbackRow*(): INTEGER;
BEGIN RETURN Get(t, 16)
END CallbackRow;

PROCEDURE (t: Table) CallbackCol*(): INTEGER;
BEGIN RETURN Get(t, 17)
END CallbackCol;

PROCEDURE (t: Table) CallbackContext*(): INTEGER;
BEGIN RETURN Get(t, 18)
END CallbackContext;

(* Whether the user is dragging a row or column's edge. *)
PROCEDURE (t: Table) IsInteractiveResize*(): BOOLEAN;
BEGIN RETURN Get(t, 19) # 0
END IsInteractiveResize;

PROCEDURE CheckRow(t: Table; r: INTEGER);
BEGIN ASSERT((r >= 0) & (r < Get(t, 0)), Fl.IndexOutOfRange)
END CheckRow;

PROCEDURE CheckCol(t: Table; c: INTEGER);
BEGIN ASSERT((c >= 0) & (c < Get(t, 1)), Fl.IndexOutOfRange)
END CheckCol;

(* Row r's height, r from 0 to Rows() - 1. *)
PROCEDURE (t: Table) SetRowHeight*(r, h: INTEGER);
BEGIN CheckRow(t, r); CSetSize(Fl.Live(t), 0, r, h)
END SetRowHeight;

PROCEDURE (t: Table) RowHeight*(r: INTEGER): INTEGER;
BEGIN CheckRow(t, r); RETURN CSize(Fl.Live(t), 0, r)
END RowHeight;

(* Column c's width, c from 0 to Cols() - 1. *)
PROCEDURE (t: Table) SetColWidth*(c, w: INTEGER);
BEGIN CheckCol(t, c); CSetSize(Fl.Live(t), 1, c, w)
END SetColWidth;

PROCEDURE (t: Table) ColWidth*(c: INTEGER): INTEGER;
BEGIN CheckCol(t, c); RETURN CSize(Fl.Live(t), 1, c)
END ColWidth;

(* Every row's height, and the height of rows added later. *)
PROCEDURE (t: Table) SetRowHeightAll*(h: INTEGER);
BEGIN CSetSize(Fl.Live(t), 0, -1, h)
END SetRowHeightAll;

PROCEDURE (t: Table) SetColWidthAll*(w: INTEGER);
BEGIN CSetSize(Fl.Live(t), 1, -1, w)
END SetColWidthAll;

(* The rows r1 to r2 and columns c1 to c2 on screen, at least partly. *)
PROCEDURE (t: Table) VisibleCells*(VAR r1, r2, c1, c2: INTEGER);
  VAR a, b, c, d: SYSTEM.INT32;
BEGIN CVisibleCells(Fl.Live(t), a, b, c, d); r1 := a; r2 := b; c1 := c; c2 := d
END VisibleCells;

(* The cells selected by the user's drag or SetSelection; for a
   TableRow, use RowSelected. *)
PROCEDURE (t: Table) IsSelected*(r, c: INTEGER): BOOLEAN;
BEGIN RETURN CIsSelected(Fl.Live(t), r, c) # 0
END IsSelected;

(* The block of cells selected: top to bottom and left to right; -1 for
   none. *)
PROCEDURE (t: Table) GetSelection*(VAR top, left, bottom, right: INTEGER);
  VAR a, b, c, d: SYSTEM.INT32;
BEGIN CGetSelection(Fl.Live(t), a, b, c, d); top := a; left := b; bottom := c; right := d
END GetSelection;

PROCEDURE (t: Table) SetSelection*(top, left, bottom, right: INTEGER);
BEGIN CSetSelection(Fl.Live(t), top, left, bottom, right)
END SetSelection;

(* Moves the cursor cell to row r, column c (clamped to the table),
   extending the selection if shift; TRUE if it moved. *)
PROCEDURE (t: Table) MoveCursor*(r, c: INTEGER; shift: BOOLEAN): BOOLEAN;
BEGIN RETURN CMoveCursor(Fl.Live(t), r, c, Int(shift)) # 0
END MoveCursor;

(* Where context's cell of row r, column c is: ContextCell, a header, or
   ContextTable for the area the cells are in. FALSE if it isn't on
   screen. *)
PROCEDURE (t: Table) FindCell*(context, r, c: INTEGER; VAR x, y, w, h: INTEGER): BOOLEAN;
  VAR a, b, cc, d: SYSTEM.INT32;
BEGIN
  IF CFindCell(Fl.Live(t), context, r, c, a, b, cc, d) = 0 THEN RETURN FALSE END;
  x := a; y := b; w := cc; h := d; RETURN TRUE
END FindCell;

(* Redraws the cells of rows r1 to r2, columns c1 to c2. *)
PROCEDURE (t: Table) RedrawRange*(r1, r2, c1, c2: INTEGER);
BEGIN CRedrawRange(Fl.Live(t), r1, r2, c1, c2)
END RedrawRange;

(* Table rows *)

(* SelectNone, SelectSingle or SelectMulti. *)
PROCEDURE (t: TableRow) SetSelectMode*(mode: INTEGER);
BEGIN
  ASSERT((mode >= SelectNone) & (mode <= SelectMulti), Fl.IndexOutOfRange);
  Set(t, 20, mode)
END SetSelectMode;

PROCEDURE (t: TableRow) SelectMode*(): INTEGER;
BEGIN RETURN Get(t, 20)
END SelectMode;

PROCEDURE (t: TableRow) RowSelected*(r: INTEGER): BOOLEAN;
BEGIN CheckRow(t, r); RETURN CRowSelected(Fl.Live(t), r) = 1
END RowSelected;

(* Selects row r, or not; TRUE if that changed it. Under SelectSingle,
   selecting a row deselects the rest; under SelectNone nothing
   changes. *)
PROCEDURE (t: TableRow) SelectRow*(r: INTEGER; on: BOOLEAN): BOOLEAN;
BEGIN CheckRow(t, r); RETURN CSelectRow(Fl.Live(t), r, Int(on)) = 1
END SelectRow;

PROCEDURE (t: TableRow) SelectAllRows*(on: BOOLEAN);
BEGIN CSelectAllRows(Fl.Live(t), Int(on))
END SelectAllRows;

PROCEDURE DrawCellD(self: SYSTEM.ADDRESS; context, r, c, x, y, w, h: SYSTEM.INT32);
  VAR t: Table;
BEGIN t := SYSTEM.VAL(Table, self); t.DrawCell(context, r, c, x, y, w, h)
END DrawCellD;

BEGIN
  CRegister(DrawCellD)
END FlTable.
