MODULE TableSpreadsheetWithKeyboardNav; (* FLTK's examples/table-spreadsheet-with-keyboard-nav.cxx: a spreadsheet, edited with the mouse or the keys *)

IMPORT OutStr, Fl, FlDraw, FlInputs, FlValuators, FlTable;

CONST
  maxCols = 26;
  maxRows = 500;

TYPE
  Spreadsheet = POINTER TO RECORD (FlTable.TableDesc)
    input: FlInputs.IntInput;                    (* the one input, moved to the cell edited *)
    values: ARRAY maxRows, maxCols OF INTEGER;   (* the cells' values *)
    rowEdit, colEdit: INTEGER;                   (* the cell edited *)
    sLeft, sTop, sRight, sBottom: INTEGER        (* the selection, from the keys or the mouse *)
  END;

  (* The input's table, for its callback. *)
  CellInput = POINTER TO RECORD (FlInputs.IntInputDesc) table: Spreadsheet END;

  SizeSlider = POINTER TO RECORD (FlValuators.ValueSliderDesc) table: Spreadsheet END;

VAR
  win: Fl.DoubleWindow;
  table: Spreadsheet;
  setRows, setCols: SizeSlider;

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
  IF t.FindCell(FlTable.ContextCell, r, c, x, y, w, h) THEN END;
  t.input.Resize(x, y, w, h);                           (* the input moved there *)
  s := ""; OutStr.Int(t.values[r, c], 0, s);            (* with the cell's value *)
  t.input.SetValue(s);
  n := 0; WHILE s[n] # 0X DO INC(n) END;
  t.input.Select(0, n);                                 (* all of it selected *)
  t.input.Show;
  IF t.input.TakeFocus() THEN END
END StartEditing;

PROCEDURE (t: Spreadsheet) DoneEditing;
BEGIN
  IF t.input.Visible() THEN t.SetValueHide END          (* an edit in progress ends *)
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
  VAR s: ARRAY 30 OF CHAR;
BEGIN
  s := "";
  CASE context OF
  | FlTable.ContextStartPage:                           (* the table is about to be redrawn *)
    t.GetSelection(t.sTop, t.sLeft, t.sBottom, t.sRight)
  | FlTable.ContextColHeader:
    IF c = t.Cols() - 1 THEN s := "TOTAL" ELSE OutStr.Char(CHR(ORD("A") + c), s) END;
    t.Header(s, x, y, w, h, t.ColHeaderColor())
  | FlTable.ContextRowHeader:
    IF r = t.Rows() - 1 THEN s := "TOTAL" ELSE OutStr.Int(r + 1, 0, s) END;
    t.Header(s, x, y, w, h, t.RowHeaderColor())
  | FlTable.ContextCell:
    IF (r = t.rowEdit) & (c = t.colEdit) & t.input.Visible() THEN RETURN END;  (* the input is over it *)
    IF (r >= t.sTop) & (r <= t.sBottom) & (c >= t.sLeft) & (c <= t.sRight) THEN
      FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, Fl.Yellow)
    ELSIF (c < t.Cols() - 1) & (r < t.Rows() - 1) THEN
      FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, Fl.White)
    ELSE
      FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, Fl.RGB(0BBH, 0DDH, 0BBH))  (* money green *)
    END;
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
    IF t.input.Visible() & t.FindCell(FlTable.ContextTable, t.rowEdit, t.colEdit, x, y, w, h)
      & ((x # t.input.X()) OR (y # t.input.Y()) OR (w # t.input.W()) OR (h # t.input.H())) THEN
      t.input.Resize(x, y, w, h)
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
      IF (c = t.Cols() - 1) OR (r = t.Rows() - 1) THEN RETURN END;  (* the totals aren't edited *)
      t.DoneEditing;
      t.SetSelection(r, c, r, c);                       (* the cell selected *)
      t.StartEditing(r, c);
      Fl.EventText(text);
      IF text[0] # 0DX THEN IF t.input.Handle(Fl.Event()) THEN END END  (* the key to the input *)
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
  i.Hide;
  i.SetWhen(Fl.WhenEnterKeyAlways);                    (* the callback on Enter *)
  i.SetMaximumSize(5);
  t.input := i;
  t.rowEdit := 0; t.colEdit := 0;
  t.sLeft := 0; t.sTop := 0; t.sRight := 0; t.sBottom := 0;
  FOR c := 0 TO maxCols - 1 DO
    FOR r := 0 TO maxRows - 1 DO t.values[r, c] := (r + 2) * (c + 3) END
  END;
  t.End
END OpenSpreadsheet;

PROCEDURE (s: SizeSlider) Callback*;
  VAR n: INTEGER;
BEGIN
  n := SHORT(ENTIER(s.Value())) + 1;
  IF s = setCols THEN s.table.SetCols(n) ELSE s.table.SetRows(n) END;
  s.table.Redraw
END Callback;

PROCEDURE OpenSizeSlider(s: SizeSlider; t: Spreadsheet; x, y, w, h, kind, max, value: INTEGER);
BEGIN
  FlValuators.OpenValueSlider(s, x, y, w, h, ""); s.table := t;
  s.SetKind(kind);
  s.SetBounds(2, max);
  s.SetStep(1);
  s.SetValue(value);
  s.SetWhen(Fl.WhenChanged);
  s.SetVisibleFocus(FALSE)
END OpenSizeSlider;

BEGIN
  Fl.SetOption(Fl.OptionArrowFocus, TRUE);              (* the arrow keys move between the table's widgets *)
  NEW(win); Fl.OpenDoubleWindow(win, 922, 382, "Table Spreadsheet with Keyboard Navigation");
  NEW(table); OpenSpreadsheet(table, 20, 20, win.W() - 80, win.H() - 80);
  table.SetRowHeader(TRUE);
  table.SetRowHeaderWidth(70);
  table.SetRowResize(TRUE);
  table.SetRows(11);
  table.SetRowHeightAll(25);
  table.SetColHeader(TRUE);
  table.SetColHeaderHeight(25);
  table.SetColResize(TRUE);
  table.SetCols(11);
  table.SetColWidthAll(70);
  table.SetSelection(0, 0, 0, 0);                       (* the top left cell selected *)
  win.Begin;
  NEW(setRows); OpenSizeSlider(setRows, table, win.W() - 40, 20, 20, win.H() - 80,
    FlValuators.VertNiceSlider, maxRows, table.Rows() - 1);
  NEW(setCols); OpenSizeSlider(setCols, table, 20, win.H() - 40, win.W() - 80, 20,
    FlValuators.HorNiceSlider, maxCols, table.Cols() - 1);
  win.End;
  win.SetResizable(table);
  win.Show;
  Fl.Run
END TableSpreadsheetWithKeyboardNav.
