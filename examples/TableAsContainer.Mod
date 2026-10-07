MODULE TableAsContainer; (* FLTK's examples/table-as-container.cxx: a table whose cells are widgets *)

IMPORT Err, OutStr, Fl, FlDraw, FlButtons, FlInputs, FlTable;

TYPE
  WidgetTable = POINTER TO RECORD (FlTable.TableDesc) END;

VAR
  win: Fl.DoubleWindow;
  table: WidgetTable;

PROCEDURE ButtonCb(w: Fl.Widget);
  VAR s: ARRAY 40 OF CHAR;
BEGIN w.GetLabel(s); Err.String("BUTTON: "); Err.String(s); Err.Ln
END ButtonCb;

PROCEDURE OpenWidgetTable(t: WidgetTable; x, y, w, h: INTEGER; label: ARRAY OF CHAR);
BEGIN
  FlTable.OpenTable(t, x, y, w, h, label);
  t.SetColHeader(TRUE);
  t.SetColResize(TRUE);
  t.SetColHeaderHeight(25);
  t.SetRowHeader(TRUE);
  t.SetRowResize(TRUE);
  t.SetRowHeaderWidth(80);
  t.End
END OpenWidgetTable;

(* Makes the table newRows by newCols, a widget in each cell: in odd
   columns an input, in even ones a light button. *)
PROCEDURE (t: WidgetTable) SetSize(newRows, newCols: INTEGER);
  VAR r, c, x, y, w, h: INTEGER; s: ARRAY 40 OF CHAR; in: FlInputs.Input; butt: FlButtons.LightButton;
BEGIN
  t.Clear;              (* the widgets before, if any *)
  t.SetRows(newRows);
  t.SetCols(newCols);
  t.Begin;              (* the widgets opened now are the table's *)
  FOR r := 0 TO newRows - 1 DO
    FOR c := 0 TO newCols - 1 DO
      IF t.FindCell(FlTable.ContextTable, r, c, x, y, w, h) THEN END;
      s := "";
      IF ODD(c) THEN
        OutStr.Int(r, 0, s); OutStr.Char(".", s); OutStr.Int(c, 0, s);
        NEW(in); FlInputs.OpenInput(in, x, y, w, h, "");
        in.SetValue(s)
      ELSE
        OutStr.Int(r, 0, s); OutStr.Char("/", s); OutStr.Int(c, 0, s); OutStr.Char(" ", s);
        NEW(butt); FlButtons.OpenLightButton(butt, x, y, w, h, s);
        butt.SetAlign(Fl.AlignCenter + Fl.AlignInside);
        butt.action := ButtonCb;
        butt.SetValue(ODD((r + c * 2) DIV 4))
      END
    END
  END;
  t.End
END SetSize;

PROCEDURE (t: WidgetTable) DrawCell*(context, r, c, x, y, w, h: INTEGER);
  VAR s: ARRAY 40 OF CHAR; i, cx, cy, cw, ch: INTEGER; child: Fl.Widget;
BEGIN
  s := "";
  CASE context OF
  | FlTable.ContextStartPage:
    FlDraw.SetFont(Fl.Helvetica, 12)       (* the font of every header *)
  | FlTable.ContextRCResize:
    (* A row or column resized: each widget is moved to its cell. *)
    i := 0;
    FOR r := 0 TO t.Rows() - 1 DO
      FOR c := 0 TO t.Cols() - 1 DO
        IF i < t.Children() THEN
          IF t.FindCell(FlTable.ContextTable, r, c, cx, cy, cw, ch) THEN END;
          child := t.Child(i); child.Resize(cx, cy, cw, ch); INC(i)
        END
      END
    END;
    t.InitSizes                              (* the group's sizes are these now *)
  | FlTable.ContextRowHeader:
    FlDraw.PushClip(x, y, w, h);
    OutStr.String("Row ", s); OutStr.Int(r, 0, s);
    FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, t.RowHeaderColor());
    FlDraw.SetColor(Fl.Black);
    FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
    FlDraw.PopClip
  | FlTable.ContextColHeader:
    FlDraw.PushClip(x, y, w, h);
    OutStr.String("Column ", s); OutStr.Int(c, 0, s);
    FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, t.ColHeaderColor());
    FlDraw.SetColor(Fl.Black);
    FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
    FlDraw.PopClip
  ELSE                                       (* FLTK draws the cells' widgets *)
  END
END DrawCell;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 940, 500, "Table As Container");
  NEW(table); OpenWidgetTable(table, 20, 20, win.W() - 40, win.H() - 40, "FLTK widget table");
  table.SetSize(50, 50);
  win.End;
  win.SetResizable(table);
  win.Show;
  Fl.Run
END TableAsContainer.
