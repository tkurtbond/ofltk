MODULE TableSort; (* FLTK's examples/table-sort.cxx: a directory listing, sorted by the column clicked *)

(* The table is ls -l of the current directory, read through Pipe. A
   click on a column's heading sorts by it; another click on the same
   one reverses the sort. Numbers sort as numbers, and the rest as text. *)

IMPORT Fl, FlDraw, FlTable, Pipe;

CONST
  Margin = 20;
  DirCmd = "ls -l";
  HeaderFontFace = Fl.HelveticaBold; HeaderFontSize = 16;
  RowFontFace = Fl.Helvetica; RowFontSize = 16;
  MaxCols = 16;

TYPE
  Text = ARRAY 256 OF CHAR;
  Row = POINTER TO RECORD
    n: INTEGER;                     (* the columns it has *)
    cols: ARRAY MaxCols OF Text
  END;
  Rows = POINTER TO ARRAY OF Row;

  MyTable = POINTER TO RECORD (FlTable.TableRowDesc)
    rowdata: Rows;                  (* the data of each row *)
    nrows: INTEGER;
    sortReverse: BOOLEAN;
    sortLastcol: INTEGER
  END;

VAR
  win: Fl.DoubleWindow;
  table: MyTable;
  header: ARRAY 9 OF Text;

PROCEDURE IsDigit(c: CHAR): BOOLEAN;
BEGIN RETURN (c >= "0") & (c <= "9")
END IsDigit;

(* The number s starts with (sscanf's %d, for s starting with a digit). *)
PROCEDURE Number(s-: ARRAY OF CHAR): LONGINT;
  VAR n: LONGINT; i: INTEGER;
BEGIN
  n := 0; i := 0;
  WHILE IsDigit(s[i]) DO n := n * 10 + ORD(s[i]) - ORD("0"); INC(i) END;
  RETURN n
END Number;

(* Whether row a goes before row b, sorted by column col: FLTK's
   SortColumn, numbers largest first unless reverse, text in order
   unless reverse. *)
PROCEDURE Before(a, b: Row; col: INTEGER; reverse: BOOLEAN): BOOLEAN;
  VAR ap, bp: Text; av, bv: LONGINT;
BEGIN
  ap := ""; bp := "";
  IF col < a.n THEN ap := a.cols[col] END;
  IF col < b.n THEN bp := b.cols[col] END;
  IF IsDigit(ap[0]) & IsDigit(bp[0]) THEN   (* cheesy detection of numbers *)
    av := Number(ap); bv := Number(bp);
    IF reverse THEN RETURN av < bv ELSE RETURN bv < av END
  ELSIF reverse THEN RETURN ap > bp
  ELSE RETURN ap < bp
  END
END Before;

(* Sorts the rows by col: an insertion sort, stable. *)
PROCEDURE (t: MyTable) SortColumn(col: INTEGER; reverse: BOOLEAN);
  VAR i, j: INTEGER; r: Row;
BEGIN
  FOR i := 1 TO t.nrows - 1 DO
    r := t.rowdata[i]; j := i;
    WHILE (j > 0) & Before(r, t.rowdata[j - 1], col, reverse) DO
      t.rowdata[j] := t.rowdata[j - 1]; DEC(j)
    END;
    t.rowdata[j] := r
  END;
  t.Redraw
END SortColumn;

PROCEDURE (t: MyTable) DrawSortArrow(x, y, w, h: INTEGER);
  VAR xlft, xctr, xrit, ytop, ybot: INTEGER;
BEGIN
  xlft := x + (w - 6) - 8; xctr := x + (w - 6) - 4; xrit := x + (w - 6);
  ytop := y + h DIV 2 - 4; ybot := y + h DIV 2 + 4;
  IF t.sortReverse THEN                     (* an engraved down arrow *)
    FlDraw.SetColor(Fl.White);
    FlDraw.Line(xrit, ytop, xctr, ybot);
    FlDraw.SetColor(41);                    (* dark gray *)
    FlDraw.Line(xlft, ytop, xrit, ytop);
    FlDraw.Line(xlft, ytop, xctr, ybot)
  ELSE                                      (* an engraved up arrow *)
    FlDraw.SetColor(Fl.White);
    FlDraw.Line(xrit, ybot, xctr, ytop);
    FlDraw.Line(xrit, ybot, xlft, ybot);
    FlDraw.SetColor(41);
    FlDraw.Line(xlft, ybot, xctr, ytop)
  END
END DrawSortArrow;

PROCEDURE (t: MyTable) DrawCell*(context, r, c, x, y, w, h: INTEGER);
  VAR s: Text; bgcolor: INTEGER;
BEGIN
  s := "";
  IF (r < t.nrows) & (c < t.rowdata[r].n) THEN s := t.rowdata[r].cols[c] END;
  CASE context OF
  | FlTable.ContextColHeader:
    FlDraw.PushClip(x, y, w, h);
    FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, Fl.BackgroundColor);
    IF c < 9 THEN
      FlDraw.SetFont(HeaderFontFace, HeaderFontSize);
      FlDraw.SetColor(Fl.Black);
      FlDraw.TextAligned(header[c], x + 2, y, w, h, Fl.AlignLeft);   (* +2: a pad at the left *)
      IF c = t.sortLastcol THEN t.DrawSortArrow(x, y, w, h) END
    END;
    FlDraw.PopClip
  | FlTable.ContextCell:
    FlDraw.PushClip(x, y, w, h);
    IF t.RowSelected(r) THEN bgcolor := t.SelectionColor() ELSE bgcolor := Fl.White END;
    FlDraw.SetColor(bgcolor); FlDraw.RectF(x, y, w, h);
    FlDraw.SetFont(RowFontFace, RowFontSize);
    FlDraw.SetColor(Fl.Black); FlDraw.TextAligned(s, x + 2, y, w, h, Fl.AlignLeft);
    FlDraw.SetColor(Fl.Light2); FlDraw.Rect(x, y, w, h);   (* the border *)
    FlDraw.PopClip
  ELSE
  END
END DrawCell;

(* Each column as wide as its widest text, heading or cell, and pad. *)
PROCEDURE (t: MyTable) Autowidth(pad: INTEGER);
  VAR r, c, w, h: INTEGER;
BEGIN
  FlDraw.SetFont(HeaderFontFace, HeaderFontSize);
  FOR c := 0 TO LEN(header) - 1 DO
    w := 0; FlDraw.Measure(header[c], w, h);
    t.SetColWidth(c, w + pad)
  END;
  FlDraw.SetFont(RowFontFace, RowFontSize);
  FOR r := 0 TO t.nrows - 1 DO
    FOR c := 0 TO t.rowdata[r].n - 1 DO
      w := 0; FlDraw.Measure(t.rowdata[r].cols[c], w, h);
      IF w + pad > t.ColWidth(c) THEN t.SetColWidth(c, w + pad) END
    END
  END;
  t.Redraw
END Autowidth;

(* The window as wide as the table with every column showing. *)
PROCEDURE (t: MyTable) ResizeWindow;
  VAR width, c, sb: INTEGER;
BEGIN
  width := 2;                                 (* the table's borders *)
  FOR c := 0 TO t.Cols() - 1 DO INC(width, t.ColWidth(c)) END;
  sb := t.ScrollbarSize();
  IF sb = 0 THEN sb := Fl.ScrollbarSize() END;
  INC(width, sb);                             (* the scrollbar *)
  INC(width, Margin * 2);
  IF (width < 200) OR (width > Fl.ScreenW()) THEN RETURN END;
  win.Resize(win.X(), win.Y(), width, win.H())
END ResizeWindow;

PROCEDURE (t: MyTable) AddRow(): Row;
  VAR more: Rows; i: INTEGER; r: Row;
BEGIN
  IF t.nrows = LEN(t.rowdata^) THEN
    NEW(more, 2 * LEN(t.rowdata^));
    FOR i := 0 TO t.nrows - 1 DO more[i] := t.rowdata[i] END;
    t.rowdata := more
  END;
  NEW(r); r.n := 0; t.rowdata[t.nrows] := r; INC(t.nrows);
  RETURN r
END AddRow;

(* The output of cmd, a row a line, a column a word. *)
PROCEDURE (t: MyTable) LoadCommand(cmd: ARRAY OF CHAR);
  VAR p: Pipe.Pipe; s: ARRAY 512 OF CHAR; line, i, k, status: INTEGER; row: Row;
BEGIN
  NEW(p);
  IF ~Pipe.Open(p, cmd) THEN RETURN END;
  t.SetCols(0);
  line := 0;
  WHILE p.ReadLine(s) DO
    IF (line = 0) & (s[0] = "t") & (s[1] = "o") & (s[2] = "t") & (s[3] = "a") & (s[4] = "l") & (s[5] = " ") THEN
      (* ls's total *)
    ELSE
      row := t.AddRow();
      i := 0;
      LOOP                                    (* the words, as strtok finds them *)
        WHILE (s[i] = " ") OR (s[i] = 09X) OR (s[i] = 0AX) DO INC(i) END;
        IF (s[i] = 0X) OR (row.n = MaxCols) THEN EXIT END;
        k := 0;
        WHILE (s[i] # 0X) & (s[i] # " ") & (s[i] # 09X) & (s[i] # 0AX) DO
          IF k < LEN(row.cols[0]) - 1 THEN row.cols[row.n][k] := s[i]; INC(k) END;
          INC(i)
        END;
        row.cols[row.n][k] := 0X; INC(row.n)
      END;
      IF row.n > t.Cols() THEN t.SetCols(row.n) END   (* the most columns *)
    END;
    INC(line)
  END;
  status := p.Close();
  t.SetRows(t.nrows);
  t.Autowidth(20)                             (* a 20 pixel pad *)
END LoadCommand;

(* A heading clicked with the left button sorts by its column, reversed
   if it was the last sorted by. *)
PROCEDURE (t: MyTable) Callback*;
  VAR col: INTEGER;
BEGIN
  col := t.CallbackCol();
  IF (t.CallbackContext() = FlTable.ContextColHeader)
    & (Fl.Event() = Fl.EvRelease) & (Fl.EventButton() = Fl.LeftMouse) THEN
    IF t.sortLastcol = col THEN t.sortReverse := ~t.sortReverse   (* the same column: reverse *)
    ELSE t.sortReverse := FALSE
    END;
    t.SortColumn(col, t.sortReverse);
    t.sortLastcol := col
  END
END Callback;

BEGIN
  header[0] := "Perms"; header[1] := "#L"; header[2] := "Own"; header[3] := "Group";
  header[4] := "Size"; header[5] := "Date"; header[6] := ""; header[7] := ""; header[8] := "Filename";
  NEW(win); Fl.OpenDoubleWindow(win, 900, 500, "Table Sort");
  NEW(table); FlTable.OpenTableRow(table, Margin, Margin, win.W() - Margin * 2, win.H() - Margin * 2, "");
  NEW(table.rowdata, 64); table.nrows := 0;
  table.sortReverse := FALSE; table.sortLastcol := -1;
  table.End;
  table.SetSelectionColor(Fl.Yellow);
  table.SetColHeader(TRUE);
  table.SetColResize(TRUE);
  table.SetWhen(Fl.WhenRelease);          (* the table's events on release *)
  table.LoadCommand(DirCmd);              (* a directory listing *)
  table.SetRowHeightAll(18);
  table.SetTooltip("Click on column headings to toggle column sorting");
  table.SetColor(Fl.White);
  win.End;
  win.SetResizable(table);
  table.ResizeWindow;
  win.Show;
  Fl.Run
END TableSort.
