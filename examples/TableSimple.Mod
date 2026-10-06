MODULE TableSimple; (* FLTK's examples/table-simple.cxx: a table of numbers, drawn cell by cell *)

IMPORT OutStr, Fl, FlDraw, FlTable;

CONST
  maxRows = 30;
  maxCols = 26;  (* A to Z *)

TYPE
  MyTable = POINTER TO RECORD (FlTable.TableDesc)
    data: ARRAY maxRows, maxCols OF INTEGER
  END;

VAR
  win: Fl.DoubleWindow;
  table: MyTable;

(* A row or column heading: dark, raised, its text centered. *)
PROCEDURE (t: MyTable) DrawHeader(s-: ARRAY OF CHAR; x, y, w, h: INTEGER);
BEGIN
  FlDraw.PushClip(x, y, w, h);
  FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, t.RowHeaderColor());
  FlDraw.SetColor(Fl.Black);
  FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
  FlDraw.PopClip
END DrawHeader;

(* A cell: dark gray text on white, with a subtle border. *)
PROCEDURE (t: MyTable) DrawData(s-: ARRAY OF CHAR; x, y, w, h: INTEGER);
BEGIN
  FlDraw.PushClip(x, y, w, h);
  FlDraw.SetColor(Fl.White); FlDraw.RectF(x, y, w, h);
  FlDraw.SetColor(Fl.Gray0); FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
  FlDraw.SetColor(t.Color()); FlDraw.Rect(x, y, w, h);
  FlDraw.PopClip
END DrawData;

PROCEDURE (t: MyTable) DrawCell*(context, r, c, x, y, w, h: INTEGER);
  VAR s: ARRAY 40 OF CHAR;
BEGIN
  s := "";
  CASE context OF
  | FlTable.ContextStartPage: FlDraw.SetFont(Fl.Helvetica, 16)
  | FlTable.ContextColHeader:
    OutStr.Char(CHR(ORD("A") + c), s); t.DrawHeader(s, x, y, w, h)
  | FlTable.ContextRowHeader:
    IF r < 100 THEN OutStr.Char("0", s) END;
    IF r < 10 THEN OutStr.Char("0", s) END;
    OutStr.Int(r, 0, s); OutStr.Char(":", s); t.DrawHeader(s, x, y, w, h)
  | FlTable.ContextCell:
    OutStr.Int(t.data[r, c], 0, s); t.DrawData(s, x, y, w, h)
  ELSE
  END
END DrawCell;

PROCEDURE OpenMyTable(t: MyTable; x, y, w, h: INTEGER);
  VAR r, c: INTEGER;
BEGIN
  FlTable.OpenTable(t, x, y, w, h, "");
  FOR r := 0 TO maxRows - 1 DO
    FOR c := 0 TO maxCols - 1 DO t.data[r, c] := 1000 + r * 1000 + c END
  END;
  t.SetRows(maxRows); t.SetRowHeader(TRUE); t.SetRowHeightAll(20); t.SetRowResize(FALSE);
  t.SetCols(maxCols); t.SetColHeader(TRUE); t.SetColWidthAll(80); t.SetColResize(TRUE);
  t.End
END OpenMyTable;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 900, 400, "Table Simple");
  NEW(table); OpenMyTable(table, 10, 10, 880, 380);
  win.End;
  win.SetResizable(table);
  win.Show;
  Fl.Run
END TableSimple.
