MODULE TableWithRightClickMenu; (* FLTK's examples/table-with-right-click-menu.cxx: a menu popped up over a table's cells *)

IMPORT Out, OutStr, Fl, FlDraw, FlMenus, FlTable;

CONST
  maxRows = 30;
  maxCols = 26;  (* A to Z *)

TYPE
  MyTable = POINTER TO RECORD (FlTable.TableDesc) END;

VAR
  win: Fl.DoubleWindow;
  table: MyTable;

(* A menu, made for a right click on a cell or a column's header and
   deleted after it. *)
PROCEDURE (t: MyTable) PostContextMenu;
  VAR context, i: INTEGER; s: ARRAY 80 OF CHAR; menu: FlMenus.MenuButton;
BEGIN
  context := t.CallbackContext();
  IF (context = FlTable.ContextColHeader) OR (context = FlTable.ContextCell) THEN
    IF context = FlTable.ContextCell THEN
      s := "Cell "; OutStr.Char(CHR(ORD("A") + t.CallbackCol()), s); OutStr.Int(t.CallbackRow(), 0, s)
    ELSE
      s := "Column "; OutStr.Char(CHR(ORD("A") + t.CallbackCol()), s)
    END;
    NEW(menu); FlMenus.OpenMenuButton(menu, Fl.EventX(), Fl.EventY(), 80, 1, "");
    i := menu.Add(s, 0, {}, NIL, FlMenus.MenuDivider + FlMenus.MenuInactive);
    i := menu.Add("Item 1", 0, {}, NIL, {});
    i := menu.Add("Item 2", 0, {}, NIL, {});
    i := menu.Popup();
    IF i >= 0 THEN menu.ItemLabel(i, s); Out.String("You chose '"); Out.String(s); Out.Char("'"); Out.Ln END;
    menu.Delete
  END
END PostContextMenu;

PROCEDURE (t: MyTable) Callback*;
BEGIN
  IF Fl.EventButton() = Fl.RightMouse THEN t.PostContextMenu END
END Callback;

PROCEDURE (t: MyTable) DrawHeader(s-: ARRAY OF CHAR; x, y, w, h: INTEGER);
BEGIN
  FlDraw.PushClip(x, y, w, h);
  FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, t.RowHeaderColor());
  FlDraw.SetColor(Fl.Black);
  FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
  FlDraw.PopClip
END DrawHeader;

PROCEDURE (t: MyTable) DrawData(s-: ARRAY OF CHAR; x, y, w, h: INTEGER);
BEGIN
  FlDraw.PushClip(x, y, w, h);
  FlDraw.SetColor(Fl.White); FlDraw.RectF(x, y, w, h);                                  (* the background *)
  FlDraw.SetColor(Fl.Gray0); FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);         (* the text *)
  FlDraw.SetColor(t.Color()); FlDraw.Rect(x, y, w, h);                                  (* the border *)
  FlDraw.PopClip
END DrawData;

PROCEDURE (t: MyTable) DrawCell*(context, r, c, x, y, w, h: INTEGER);
  VAR s: ARRAY 40 OF CHAR;
BEGIN
  s := "";
  CASE context OF
  | FlTable.ContextStartPage: FlDraw.SetFont(Fl.Helvetica, 16)   (* before the page is drawn *)
  | FlTable.ContextColHeader:                                     (* "A", "B", "C" and so on *)
    OutStr.Char(CHR(ORD("A") + c), s); t.DrawHeader(s, x, y, w, h)
  | FlTable.ContextRowHeader:                                     (* "001:", "002:" and so on *)
    OutStr.Int(r DIV 100, 0, s); OutStr.Int(r DIV 10 MOD 10, 0, s); OutStr.Int(r MOD 10, 0, s);
    OutStr.Char(":", s); t.DrawHeader(s, x, y, w, h)
  | FlTable.ContextCell:
    OutStr.Char(CHR(ORD("A") + c), s); OutStr.Int(r, 0, s); t.DrawData(s, x, y, w, h)
  ELSE
  END
END DrawCell;

PROCEDURE OpenMyTable(t: MyTable; x, y, w, h: INTEGER);
BEGIN
  FlTable.OpenTable(t, x, y, w, h, "");
  t.SetRows(maxRows);         (* how many rows *)
  t.SetRowHeader(TRUE);       (* headers along the left *)
  t.SetRowHeightAll(20);      (* each row's height *)
  t.SetRowResize(FALSE);      (* rows can't be resized *)
  t.SetCols(maxCols);         (* how many columns *)
  t.SetColHeader(TRUE);       (* headers along the top *)
  t.SetColWidthAll(80);       (* each column's width *)
  t.SetColResize(TRUE);       (* columns can be resized *)
  t.End
END OpenMyTable;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 900, 400, "Table Simple");
  NEW(table); OpenMyTable(table, 10, 10, 880, 380);
  win.End;
  win.SetResizable(table);
  win.Show;
  Fl.Run
END TableWithRightClickMenu.
