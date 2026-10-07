MODULE TableSpreadsheet; (* FLTK's examples/table-spreadsheet.cxx: a spreadsheet with totals, Tab moving between cells *)

IMPORT OutStr, Fl, FlDraw, FlInputs, FlTable;

CONST
  maxCols = 10;
  maxRows = 10;

TYPE
  Spreadsheet = POINTER TO RECORD (FlTable.TableDesc)
    input: FlInputs.IntInput;                    (* the one input, moved to the cell edited *)
    values: ARRAY maxRows, maxCols OF INTEGER;   (* the cells' values *)
    rowEdit, colEdit: INTEGER                    (* the cell edited *)
  END;

  (* The input's table, for its callback. *)
  CellInput = POINTER TO RECORD (FlInputs.IntInputDesc) table: Spreadsheet END;

VAR
  win: Fl.DoubleWindow;
  table: Spreadsheet;

PROCEDURE (t: Spreadsheet) SetValueHide;
BEGIN
  t.values[t.rowEdit, t.colEdit] := t.input.IntValue();
  t.input.Hide;
  win.SetCursor(Fl.CursorDefault)   (* else the cursor can disappear *)
END SetValueHide;

(* Enter in the input. *)
PROCEDURE (i: CellInput) Callback*;
BEGIN i.table.SetValueHide
END Callback;

PROCEDURE (t: Spreadsheet) StartEditing(r, c: INTEGER);
  VAR x, y, w, h, n: INTEGER; s: ARRAY 30 OF CHAR;
BEGIN
  t.rowEdit := r;                                       (* the cell edited now *)
  t.colEdit := c;
  t.SetSelection(r, c, r, c);                           (* any selection of more cells cleared *)
  IF t.FindCell(FlTable.ContextCell, r, c, x, y, w, h) THEN END;
  t.input.Resize(x, y, w, h);                           (* the input moved there *)
  s := ""; OutStr.Int(t.values[r, c], 0, s);            (* with the cell's value *)
  t.input.SetValue(s);
  n := 0; WHILE s[n] # 0X DO INC(n) END;
  t.input.Select(0, n);                                 (* all of it selected *)
  t.input.Show;
  IF t.input.TakeFocus() THEN END                       (* the keys go to the input *)
END StartEditing;

PROCEDURE (t: Spreadsheet) DoneEditing;
BEGIN
  IF t.input.Visible() THEN                             (* an edit in progress ends *)
    t.SetValueHide;
    t.rowEdit := 0;                                     (* until the next *)
    t.colEdit := 0
  END
END DoneEditing;

(* The sum of column c, or of row r, or of all, without the totals. *)
PROCEDURE (t: Spreadsheet) SumRows(c: INTEGER): INTEGER;
  VAR sum, r: INTEGER;
BEGIN
  sum := 0; FOR r := 0 TO t.Rows() - 2 DO INC(sum, t.values[r, c]) END;
  RETURN sum
END SumRows;

PROCEDURE (t: Spreadsheet) SumCols(r: INTEGER): INTEGER;
  VAR sum, c: INTEGER;
BEGIN
  sum := 0; FOR c := 0 TO t.Cols() - 2 DO INC(sum, t.values[r, c]) END;
  RETURN sum
END SumCols;

PROCEDURE (t: Spreadsheet) SumAll(): INTEGER;
  VAR sum, r, c: INTEGER;
BEGIN
  sum := 0;
  FOR c := 0 TO t.Cols() - 2 DO
    FOR r := 0 TO t.Rows() - 2 DO INC(sum, t.values[r, c]) END
  END;
  RETURN sum
END SumAll;

PROCEDURE (t: Spreadsheet) Header(s-: ARRAY OF CHAR; x, y, w, h, color: INTEGER);
BEGIN
  FlDraw.SetFont(Fl.Helvetica + Fl.Bold, 14);           (* headings in bold *)
  FlDraw.PushClip(x, y, w, h);
  FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, color);
  FlDraw.SetColor(Fl.Black);
  FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
  FlDraw.PopClip
END Header;

PROCEDURE (t: Spreadsheet) DrawCell*(context, r, c, x, y, w, h: INTEGER);
  VAR s: ARRAY 30 OF CHAR; color: INTEGER;
BEGIN
  s := "";
  CASE context OF
  | FlTable.ContextColHeader:
    IF c = t.Cols() - 1 THEN s := "TOTAL" ELSE OutStr.Char(CHR(ORD("A") + c), s) END;
    t.Header(s, x, y, w, h, t.ColHeaderColor())
  | FlTable.ContextRowHeader:
    IF r = t.Rows() - 1 THEN s := "TOTAL" ELSE OutStr.Int(r + 1, 0, s) END;
    t.Header(s, x, y, w, h, t.RowHeaderColor())
  | FlTable.ContextCell:
    IF (r = t.rowEdit) & (c = t.colEdit) & t.input.Visible() THEN RETURN END;  (* the input is over it *)
    IF (c < t.Cols() - 1) & (r < t.Rows() - 1) THEN
      IF t.IsSelected(r, c) THEN color := Fl.Yellow ELSE color := Fl.White END
    ELSIF t.IsSelected(r, c) THEN color := Fl.RGB(0DDH, 0FFH, 0DDH)
    ELSE color := Fl.RGB(0BBH, 0DDH, 0BBH)               (* money green *)
    END;
    FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, color);
    FlDraw.PushClip(x + 3, y + 3, w - 6, h - 6);
    FlDraw.SetColor(Fl.Black);
    IF (c = t.Cols() - 1) OR (r = t.Rows() - 1) THEN    (* a total, in bold *)
      FlDraw.SetFont(Fl.Helvetica + Fl.Bold, 14);
      IF (c = t.Cols() - 1) & (r = t.Rows() - 1) THEN OutStr.Int(t.SumAll(), 0, s)
      ELSIF c = t.Cols() - 1 THEN OutStr.Int(t.SumCols(r), 0, s)
      ELSE OutStr.Int(t.SumRows(c), 0, s)
      END
    ELSE
      FlDraw.SetFont(Fl.Helvetica, 14);
      OutStr.Int(t.values[r, c], 0, s)
    END;
    FlDraw.TextAligned(s, x + 3, y + 3, w - 6, h - 6, Fl.AlignRight);
    FlDraw.PopClip
  | FlTable.ContextRCResize:                            (* a row or column resized *)
    IF t.input.Visible() THEN
      IF t.FindCell(FlTable.ContextTable, t.rowEdit, t.colEdit, x, y, w, h) THEN END;
      t.input.Resize(x, y, w, h);
      t.InitSizes
    END
  ELSE
  END
END DrawCell;

(* An event on the table. *)
PROCEDURE (t: Spreadsheet) Callback*;
  VAR r, c: INTEGER; text: ARRAY 8 OF CHAR;
BEGIN
  r := t.CallbackRow(); c := t.CallbackCol();
  CASE t.CallbackContext() OF
  | FlTable.ContextCell:
    IF Fl.Event() = Fl.EvPush THEN                      (* a click *)
      t.DoneEditing;                                    (* the edit before ends *)
      IF (r # t.Rows() - 1) & (c # t.Cols() - 1) THEN t.StartEditing(r, c) END  (* not the totals *)
    ELSIF Fl.Event() = Fl.EvKeyDown THEN                (* a key *)
      IF Fl.EventKey() = Fl.KeyEscape THEN win.Hide; RETURN END;  (* Escape quits *)
      t.DoneEditing;
      IF (c = t.Cols() - 1) OR (r = t.Rows() - 1) THEN RETURN END;  (* the totals aren't edited *)
      Fl.EventText(text);
      CASE text[0] OF
      | "0" .. "9", "+", "-":                           (* a new edit, starting with the key *)
        t.StartEditing(r, c);
        IF t.input.Handle(Fl.Event()) THEN END
      | 0DX, 0AX:                                       (* Enter edits the cell *)
        t.StartEditing(r, c)
      ELSE
      END
    END
  | FlTable.ContextTable, FlTable.ContextRowHeader, FlTable.ContextColHeader:
    t.DoneEditing                                       (* on a header or past the cells *)
  ELSE
  END
END Callback;

PROCEDURE OpenSpreadsheet(t: Spreadsheet; x, y, w, h: INTEGER);
  VAR i: CellInput; r, c: INTEGER;
BEGIN
  FlTable.OpenTable(t, x, y, w, h, "");
  t.SetWhen(Fl.WhenNotChanged + t.When());
  NEW(i); FlInputs.OpenIntInput(i, w DIV 2, h DIV 2, 0, 0, ""); i.table := t;
  i.Hide;                                              (* until it is needed *)
  i.SetWhen(Fl.WhenEnterKeyAlways);                    (* the callback on Enter *)
  i.SetMaximumSize(5);
  i.SetColor(Fl.Yellow);                               (* to stand out while editing *)
  t.input := i;
  FOR c := 0 TO maxCols - 1 DO
    FOR r := 0 TO maxRows - 1 DO t.values[r, c] := c + r * maxCols END
  END;
  t.End;
  t.rowEdit := 0; t.colEdit := 0;
  t.SetSelection(0, 0, 0, 0)
END OpenSpreadsheet;

PROCEDURE Build;
  VAR tip: ARRAY 80 OF CHAR;
BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 862, 322, "Table Spreadsheet");
  NEW(table); OpenSpreadsheet(table, 10, 10, win.W() - 20, win.H() - 20);
  table.SetTabCellNav(TRUE);                            (* Tab moves between cells, not widgets *)
  tip := "Use keyboard to navigate cells:"; OutStr.Ln(tip); OutStr.String("Arrow keys or Tab/Shift-Tab", tip);
  table.SetTooltip(tip);
  table.SetRowHeader(TRUE);
  table.SetRowHeaderWidth(70);
  table.SetRowResize(TRUE);
  table.SetRows(maxRows + 1);                           (* and the totals' row *)
  table.SetRowHeightAll(25);
  table.SetColHeader(TRUE);
  table.SetColHeaderHeight(25);
  table.SetColResize(TRUE);
  table.SetCols(maxCols + 1);                           (* and the totals' column *)
  table.SetColWidthAll(70);
  win.End;
  win.SetResizable(table)
END Build;

BEGIN
  Build;
  win.Show;
  Fl.Run
END TableSpreadsheet.
