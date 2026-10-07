MODULE TreeOfTables; (* FLTK's examples/tree-of-tables.cxx: tables in a tree's items *)

(* Each item shows a table of a function of its row and column, beside
   its label (TreeItem.SetWidget, Tree.SetItemDrawMode). The numbers are
   written as printf writes them ("%d", "%.2f", "%g"), from RealDigits'
   exact digits, rounded as printf rounds them. *)

IMPORT SYSTEM, Fl, FlDraw, FlTable, FlBrowsers, MathL, RealDigits, OutStr;

CONST
  Pi = 3.14159D0;

TYPE
  Mode = ARRAY 16 OF CHAR;

  MyTable = POINTER TO RECORD (FlTable.TableDesc)
    mode: Mode
  END;

VAR
  win: Fl.DoubleWindow;
  tree: FlBrowsers.Tree;

(* "-" if v is negative, -0 too, as printf writes it. *)
PROCEDURE Sign(VAR v: LONGREAL; VAR s: ARRAY OF CHAR);
BEGIN
  IF SYSTEM.VAL(HUGEINT, v) < 0 THEN OutStr.Char("-", s); v := -v END
END Sign;

(* v as "%.2f" writes it. *)
PROCEDURE Fixed2(v: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 40 OF CHAR; count, e, p: INTEGER;

  PROCEDURE Digit(p: INTEGER);   (* the digit of 10^p *)
  BEGIN
    IF (e - p >= 0) & (e - p < count) THEN OutStr.Char(d[e - p], s) ELSE OutStr.Char("0", s) END
  END Digit;

BEGIN
  s[0] := 0X; Sign(v, s);
  IF v = 0.0D0 THEN count := 0; e := 0 ELSE RealDigits.Fixed(v, 2, 30, d, count, e) END;
  p := e; IF p < 0 THEN p := 0 END;
  WHILE p >= 0 DO Digit(p); DEC(p) END;
  OutStr.Char(".", s); Digit(-1); Digit(-2)
END Fixed2;

(* v as "%g" writes it: six significant digits, trailing zeros dropped,
   in exponential form for an exponent below -4 or above 5. *)
PROCEDURE General(v: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 8 OF CHAR; e, n, i: INTEGER;
BEGIN
  s[0] := 0X; Sign(v, s);
  IF v = 0.0D0 THEN OutStr.Char("0", s); RETURN END;
  RealDigits.Digits(v, 6, d, e);
  n := 6; WHILE (n > 1) & (d[n - 1] = "0") DO DEC(n) END;   (* significant digits *)
  IF (e < -4) OR (e >= 6) THEN
    OutStr.Char(d[0], s);
    IF n > 1 THEN OutStr.Char(".", s); FOR i := 1 TO n - 1 DO OutStr.Char(d[i], s) END END;
    OutStr.Char("e", s);
    IF e < 0 THEN OutStr.Char("-", s); e := -e ELSE OutStr.Char("+", s) END;
    IF e < 10 THEN OutStr.Char("0", s) END;
    OutStr.Int(e, 0, s)
  ELSIF e < 0 THEN
    OutStr.String("0.", s);
    FOR i := 1 TO -e - 1 DO OutStr.Char("0", s) END;
    FOR i := 0 TO n - 1 DO OutStr.Char(d[i], s) END
  ELSE
    FOR i := 0 TO e DO
      IF i < n THEN OutStr.Char(d[i], s) ELSE OutStr.Char("0", s) END
    END;
    IF n > e + 1 THEN
      OutStr.Char(".", s);
      FOR i := e + 1 TO n - 1 DO OutStr.Char(d[i], s) END
    END
  END
END General;

(* r to the power c, as powf gives it: exact in LONGREAL for these small
   numbers, then rounded once to a REAL. *)
PROCEDURE Power(r, c: INTEGER): REAL;
  VAR p: LONGREAL; i: INTEGER;
BEGIN
  p := 1.0D0;
  FOR i := 1 TO c DO p := p * r END;
  RETURN SHORT(p)
END Power;

PROCEDURE OpenMyTable(t: MyTable; x, y, w, h: INTEGER; mode: ARRAY OF CHAR);
BEGIN
  FlTable.OpenTable(t, x, y, w, h, "");
  t.SetRows(11); t.SetRowHeightAll(20); t.SetRowHeader(TRUE);
  t.SetCols(11); t.SetColWidthAll(60); t.SetColHeader(TRUE);
  t.SetColResize(TRUE);                       (* enable column resizing *)
  COPY(mode, t.mode);
  t.End
END OpenMyTable;

PROCEDURE (t: MyTable) Resize*(x, y, w, h: INTEGER);
BEGIN
  IF w > 718 THEN w := 718 END;               (* don't exceed 700 in width *)
  t.Resize^(x, y, w, t.H())                   (* disallow changes in height *)
END Resize;

(* Handle drawing table's cells: Fl_Table calls this to draw each visible
   cell in the table. *)
PROCEDURE (t: MyTable) DrawCell*(context, row, col, x, y, w, h: INTEGER);
  VAR s: ARRAY 40 OF CHAR; val, c: INTEGER; f: REAL;
BEGIN
  CASE context OF
  | FlTable.ContextStartPage:                 (* before page is drawn.. *)
    FlDraw.SetFont(Fl.Helvetica, 10)          (* set the font for our drawing operations *)
  | FlTable.ContextColHeader, FlTable.ContextRowHeader:   (* drawing column/row headers *)
    IF context = FlTable.ContextColHeader THEN val := col; c := t.ColHeaderColor()
    ELSE val := row; c := t.RowHeaderColor()
    END;
    FlDraw.PushClip(x, y, w, h);
    IF t.mode = "SinCos" THEN Fixed2(val / 10.0D0 * Pi, s)
    ELSE s := ""; OutStr.Int(val, 0, s)
    END;
    FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, c);
    FlDraw.SetColor(Fl.Black);
    FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
    FlDraw.PopClip
  | FlTable.ContextCell:                      (* draw data in cells *)
    IF t.IsSelected(row, col) THEN c := Fl.Yellow ELSE c := Fl.White END;
    FlDraw.PushClip(x, y, w, h);
    s := "";
    IF t.mode = "Addition" THEN OutStr.Int(row + col, 0, s)
    ELSIF t.mode = "Subtract" THEN OutStr.Int(row - col, 0, s)
    ELSIF t.mode = "Multiply" THEN OutStr.Int(row * col, 0, s)
    ELSIF t.mode = "Divide" THEN
      IF col = 0 THEN s := "N/A"
      ELSE f := row; f := f / col; Fixed2(f, s)   (* in REAL, as C's floats *)
      END
    ELSIF t.mode = "Exponent" THEN General(Power(row, col), s)
    ELSIF t.mode = "SinCos" THEN Fixed2(MathL.sin(row / 10.0D0 * Pi) * MathL.cos(col / 10.0D0 * Pi), s)
    ELSE s := "???"
    END;
    FlDraw.SetColor(c); FlDraw.RectF(x, y, w, h);                              (* bg *)
    FlDraw.SetColor(Fl.Gray0); FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);   (* text *)
    FlDraw.SetColor(t.Color()); FlDraw.Rect(x, y, w, h);                       (* box *)
    FlDraw.PopClip
  ELSE
  END
END DrawCell;

(* Makes a table, and an item at path showing it. *)
PROCEDURE AddTable(path, mode: ARRAY OF CHAR);
  VAR table: MyTable; item: FlBrowsers.TreeItem;
BEGIN
  NEW(table); OpenMyTable(table, 0, 0, 500, 156, mode);
  item := tree.Add(path);
  item.SetWidget(table)
END AddTable;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 700, 400, "Tree of tables");
  (* Create tree *)
  NEW(tree); FlBrowsers.OpenTree(tree, 10, 10, win.W() - 20, win.H() - 20, "");
  tree.SetRootLabel("Math Tables");
  tree.SetItemLabelFont(Fl.Courier);           (* font to use for items *)
  tree.SetLineSpacing(4);                      (* extra space between items *)
  tree.SetItemDrawMode(tree.ItemDrawMode()
    + FlBrowsers.ItemDrawLabelAndWidget        (* draw item with its widget next to it *)
    + FlBrowsers.ItemHeightFromWidget);        (* make item height follow table's height *)
  tree.SetSelectMode(FlBrowsers.TreeSelectNone);
  tree.SetWidgetMarginLeft(12);                (* space between item and table *)
  tree.SetConnectorStyle(FlBrowsers.ConnectorDotted);

  (* Create tables, assign each a tree item *)
  AddTable("Arithmetic/Addition", "Addition");
  AddTable("Arithmetic/Subtract", "Subtract");
  AddTable("Arithmetic/Multiply", "Multiply");
  AddTable("Arithmetic/Divide  ", "Divide");
  AddTable("Misc/Exponent", "Exponent");
  AddTable("Misc/Sin*Cos ", "SinCos");
  win.End;
  win.SetResizable(win);
  win.ShowArgs;
  Fl.Run
END TreeOfTables.
