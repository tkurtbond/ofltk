MODULE FlLayout; (* Groups that place their children: flex, grid, pack, scroll, tabs, tile, wizard *)

(* Each type is FLTK's class of the same name, an Fl.Group, opened by its
   own Open procedure, which begins it as Fl.OpenGroup does: widgets
   opened next are its children, until its End.

   Flex and Grid are FLTK 1.4's layouts: a flex puts its children in one
   row or column, sharing the space between those not given a fixed
   size; a grid puts each child in a cell of its rows and columns. Pack
   stacks its children at their own sizes. Scroll shows part of its
   children, with scrollbars; Tabs and Wizard show one child at a time;
   Tile lets the user drag the borders between its children.

   Methods that name a child halt with Fl.NotAChild if it isn't one, and
   a grid's rows and columns are checked (Fl.IndexOutOfRange).

   The C++ part is FlLayout.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* kinds of flex (Flex.SetKind): one column, or one row *)
  Column* = 0;
  Row* = 1;

  (* kinds of pack (Pack.SetKind) *)
  PackVertical* = 0;
  PackHorizontal* = 1;

  (* kinds of scroll (Scroll.SetKind): which scrollbars, shown when needed or Always *)
  ScrollHorizontal* = 1;
  ScrollVertical* = 2;
  ScrollBoth* = 3;
  ScrollAlwaysOn* = 4;
  ScrollHorizontalAlways* = 5;
  ScrollVerticalAlways* = 6;
  ScrollBothAlways* = 7;

  (* a widget's place in its grid cell (Grid.Place) *)
  GridCenter* = {};
  GridTop* = {0};
  GridBottom* = {1};
  GridLeft* = {2};
  GridRight* = {3};
  GridHorizontal* = {4};
  GridVertical* = {5};
  GridFill* = {4, 5};
  GridProportional* = {6};
  GridTopLeft* = {0, 2};
  GridTopRight* = {0, 3};
  GridBottomLeft* = {1, 2};
  GridBottomRight* = {1, 3};

  (* what tabs do when there are too many to fit (Tabs.HandleOverflow) *)
  OverflowCompress* = 0;
  OverflowClip* = 1;
  OverflowPulldown* = 2;
  OverflowDrag* = 3;
(* END generated constants *)

  (* the classes, as ofl_layout_new numbers them *)
  flex = 0; grid = 1; pack = 2; scroll = 3; tabs = 4; tile = 5; wizard = 6;

  (* what ofl_grid_col and ofl_grid_row get and set *)
  size = 0; weight = 1; gap = 2; computed = 3;

TYPE
  Flex* = POINTER TO FlexDesc;
  FlexDesc* = RECORD (Fl.GroupDesc) END;

  Grid* = POINTER TO GridDesc;
  GridDesc* = RECORD (Fl.GroupDesc) END;

  Pack* = POINTER TO PackDesc;
  PackDesc* = RECORD (Fl.GroupDesc) END;

  (* Its scrollbars are children FLTK made: Children counts them, and
     Child gives NIL for them. *)
  Scroll* = POINTER TO ScrollDesc;
  ScrollDesc* = RECORD (Fl.GroupDesc) END;

  (* Each child is a tab, usually a group, labelled with its label. *)
  Tabs* = POINTER TO TabsDesc;
  TabsDesc* = RECORD (Fl.GroupDesc) END;

  Tile* = POINTER TO TileDesc;
  TileDesc* = RECORD (Fl.GroupDesc) END;

  (* Each child is a page; one is shown at a time. *)
  Wizard* = POINTER TO WizardDesc;
  WizardDesc* = RECORD (Fl.GroupDesc) END;

PROCEDURE ["C", "ofl_layout_new"] CNew(class, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_layout_type"] CType(g: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_layout_set_type"] CSetType(g: SYSTEM.ADDRESS; t: SYSTEM.INT32);
PROCEDURE ["C", "ofl_flex_fixed"] CFixed(f, w: SYSTEM.ADDRESS; size: SYSTEM.INT32);
PROCEDURE ["C", "ofl_flex_is_fixed"] CIsFixed(f, w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_flex_margins"] CFlexMargins(f: SYSTEM.ADDRESS; VAR l, t, r, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_flex_set_margins"] CFlexSetMargins(f: SYSTEM.ADDRESS; l, t, r, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_flex_gap"] CFlexGap(f: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_flex_set_gap"] CFlexSetGap(f: SYSTEM.ADDRESS; g: SYSTEM.INT32);
PROCEDURE ["C", "ofl_flex_layout"] CFlexLayout(f: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_grid_set_layout"] CGridSetLayout(g: SYSTEM.ADDRESS; rows, cols: SYSTEM.INT32);
PROCEDURE ["C", "ofl_grid_layout"] CGridLayout(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_grid_clear_layout"] CGridClearLayout(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_grid_rows"] CRows(g: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_grid_cols"] CCols(g: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_grid_widget"] CPlace(g, w: SYSTEM.ADDRESS; row, col, rowspan, colspan, align: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_grid_margins"] CGridMargins(g: SYSTEM.ADDRESS; VAR l, t, r, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_grid_set_margins"] CGridSetMargins(g: SYSTEM.ADDRESS; l, t, r, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_grid_gap"] CGridGap(g: SYSTEM.ADDRESS; VAR rowGap, colGap: SYSTEM.INT32);
PROCEDURE ["C", "ofl_grid_set_gap"] CGridSetGap(g: SYSTEM.ADDRESS; rowGap, colGap: SYSTEM.INT32);
PROCEDURE ["C", "ofl_grid_col"] CCol(g: SYSTEM.ADDRESS; what, col: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_grid_set_col"] CSetCol(g: SYSTEM.ADDRESS; what, col, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_grid_row"] CRow(g: SYSTEM.ADDRESS; what, row: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_grid_set_row"] CSetRow(g: SYSTEM.ADDRESS; what, row, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_grid_show_grid"] CShowGrid(g: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_pack_spacing"] CSpacing(p: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_pack_set_spacing"] CSetSpacing(p: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_scroll_xposition"] CXPosition(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_scroll_yposition"] CYPosition(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_scroll_to"] CScrollTo(s: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_scroll_scrollbar_size"] CScrollbarSize(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_scroll_set_scrollbar_size"] CSetScrollbarSize(s: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_tabs_value"] CTabsValue(t: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tabs_set_value"] CTabsSetValue(t, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_tabs_tab_align"] CTabAlign(t: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_tabs_set_tab_align"] CSetTabAlign(t: SYSTEM.ADDRESS; a: SYSTEM.INT32);
PROCEDURE ["C", "ofl_tabs_handle_overflow"] CHandleOverflow(t: SYSTEM.ADDRESS; ov: SYSTEM.INT32);
PROCEDURE ["C", "ofl_tabs_client_area"] CClientArea(t: SYSTEM.ADDRESS; VAR x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_wizard_value"] CWizardValue(z: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_wizard_set_value"] CWizardSetValue(z, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_wizard_next"] CNext(z: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_wizard_prev"] CPrev(z: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_tile_size_range"] CSizeRange(t, w: SYSTEM.ADDRESS; minw, minh, maxw, maxh: SYSTEM.INT32);
PROCEDURE ["C", "ofl_tile_init_size_range"] CInitSizeRange(t: SYSTEM.ADDRESS; minw, minh: SYSTEM.INT32);
PROCEDURE ["C", "ofl_tile_move_intersection"] CMoveIntersection(t: SYSTEM.ADDRESS; oldx, oldy, newx, newy: SYSTEM.INT32);

PROCEDURE Open(g: Fl.Group; class, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(g, CNew(class, x, y, w, h, label, Fl.BeginOpen(g)))
END Open;

(* The handle of w, which must be a child of g. *)
PROCEDURE Child(g: Fl.Group; w: Fl.Widget): SYSTEM.ADDRESS;
BEGIN
  ASSERT(w # NIL, Fl.NilArgument); ASSERT(g.Find(w) >= 0, Fl.NotAChild);
  RETURN Fl.Live(w)
END Child;

(* Opening each type. x, y are relative to the window, as FLTK's are; the
   label is copied. *)

PROCEDURE OpenFlex*(g: Flex; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(g, flex, x, y, w, h, label)
END OpenFlex;

PROCEDURE OpenGrid*(g: Grid; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(g, grid, x, y, w, h, label)
END OpenGrid;

PROCEDURE OpenPack*(g: Pack; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(g, pack, x, y, w, h, label)
END OpenPack;

PROCEDURE OpenScroll*(g: Scroll; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(g, scroll, x, y, w, h, label)
END OpenScroll;

PROCEDURE OpenTabs*(g: Tabs; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(g, tabs, x, y, w, h, label)
END OpenTabs;

PROCEDURE OpenTile*(g: Tile; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(g, tile, x, y, w, h, label)
END OpenTile;

PROCEDURE OpenWizard*(g: Wizard; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(g, wizard, x, y, w, h, label)
END OpenWizard;

(* Flex *)

(* Column, to start with, or Row. *)
PROCEDURE (f: Flex) Kind*(): INTEGER;
BEGIN RETURN CType(Fl.Live(f))
END Kind;

PROCEDURE (f: Flex) SetKind*(k: INTEGER);
BEGIN CSetType(Fl.Live(f), k)
END SetKind;

(* Gives child w a fixed height in a column, or width in a row; the
   others share what is left. 0 shares it again. *)
PROCEDURE (f: Flex) SetFixed*(w: Fl.Widget; size: INTEGER);
BEGIN CFixed(Fl.Live(f), Child(f, w), size)
END SetFixed;

PROCEDURE (f: Flex) Fixed*(w: Fl.Widget): BOOLEAN;
BEGIN RETURN CIsFixed(Fl.Live(f), Child(f, w)) # 0
END Fixed;

(* The space inside f's edges: left, top, right, bottom; 0 to start
   with. *)
PROCEDURE (f: Flex) Margins*(VAR left, top, right, bottom: INTEGER);
  VAR l, t, r, b: SYSTEM.INT32;
BEGIN
  CFlexMargins(Fl.Live(f), l, t, r, b); left := l; top := t; right := r; bottom := b
END Margins;

PROCEDURE (f: Flex) SetMargins*(left, top, right, bottom: INTEGER);
BEGIN CFlexSetMargins(Fl.Live(f), left, top, right, bottom)
END SetMargins;

(* The space between children; 0 to start with. *)
PROCEDURE (f: Flex) Gap*(): INTEGER;
BEGIN RETURN CFlexGap(Fl.Live(f))
END Gap;

PROCEDURE (f: Flex) SetGap*(g: INTEGER);
BEGIN CFlexSetGap(Fl.Live(f), g)
END SetGap;

(* Places the children now; FLTK otherwise does when f is next resized
   or drawn. *)
PROCEDURE (f: Flex) Layout*;
BEGIN CFlexLayout(Fl.Live(f))
END Layout;

(* Grid *)

(* Gives g rows and columns, keeping the children whose cells are still
   in it. *)
PROCEDURE (g: Grid) SetLayout*(rows, cols: INTEGER);
BEGIN CGridSetLayout(Fl.Live(g), rows, cols)
END SetLayout;

PROCEDURE (g: Grid) Rows*(): INTEGER;
BEGIN RETURN CRows(Fl.Live(g))
END Rows;

PROCEDURE (g: Grid) Cols*(): INTEGER;
BEGIN RETURN CCols(Fl.Live(g))
END Cols;

(* Places the children now, as Flex.Layout does. *)
PROCEDURE (g: Grid) Layout*;
BEGIN CGridLayout(Fl.Live(g))
END Layout;

(* Takes every child out of its cell, and g's rows and columns away. *)
PROCEDURE (g: Grid) ClearLayout*;
BEGIN CGridClearLayout(Fl.Live(g))
END ClearLayout;

(* Puts child w in the cell at row, col (from 0), and spanning rows and
   cols cells from there, placed in them by align, a set of the Grid
   constants: GridFill to fill them. FLTK's Fl_Grid::widget. *)
PROCEDURE (g: Grid) PlaceSpan*(w: Fl.Widget; row, col, rows, cols: INTEGER; align: SET);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(g);
  ASSERT((row >= 0) & (rows >= 1) & (row + rows <= CRows(h))
    & (col >= 0) & (cols >= 1) & (col + cols <= CCols(h)), Fl.IndexOutOfRange);
  ASSERT(CPlace(h, Child(g, w), row, col, rows, cols, SYSTEM.VAL(SYSTEM.INT32, align)) # 0, Fl.NotAChild)
END PlaceSpan;

PROCEDURE (g: Grid) Place*(w: Fl.Widget; row, col: INTEGER; align: SET);
BEGIN g.PlaceSpan(w, row, col, 1, 1, align)
END Place;

(* The space inside g's edges, and between rows and columns; 0 to start
   with. *)
PROCEDURE (g: Grid) Margins*(VAR left, top, right, bottom: INTEGER);
  VAR l, t, r, b: SYSTEM.INT32;
BEGIN
  CGridMargins(Fl.Live(g), l, t, r, b); left := l; top := t; right := r; bottom := b
END Margins;

PROCEDURE (g: Grid) SetMargins*(left, top, right, bottom: INTEGER);
BEGIN CGridSetMargins(Fl.Live(g), left, top, right, bottom)
END SetMargins;

PROCEDURE (g: Grid) Gap*(VAR rowGap, colGap: INTEGER);
  VAR r, c: SYSTEM.INT32;
BEGIN CGridGap(Fl.Live(g), r, c); rowGap := r; colGap := c
END Gap;

PROCEDURE (g: Grid) SetGap*(rowGap, colGap: INTEGER);
BEGIN CGridSetGap(Fl.Live(g), rowGap, colGap)
END SetGap;

PROCEDURE GridCol(g: Grid; what, col: INTEGER): INTEGER;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(g); ASSERT((col >= 0) & (col < CCols(h)), Fl.IndexOutOfRange);
  RETURN CCol(h, what, col)
END GridCol;

PROCEDURE SetGridCol(g: Grid; what, col, v: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(g); ASSERT((col >= 0) & (col < CCols(h)), Fl.IndexOutOfRange);
  CSetCol(h, what, col, v)
END SetGridCol;

PROCEDURE GridRow(g: Grid; what, row: INTEGER): INTEGER;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(g); ASSERT((row >= 0) & (row < CRows(h)), Fl.IndexOutOfRange);
  RETURN CRow(h, what, row)
END GridRow;

PROCEDURE SetGridRow(g: Grid; what, row, v: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(g); ASSERT((row >= 0) & (row < CRows(h)), Fl.IndexOutOfRange);
  CSetRow(h, what, row, v)
END SetGridRow;

(* A column's minimum width; its weight, its share of space left over
   (50 to start with; 0 for none); the gap after it, -1 for the grid's;
   and the width it was given by the last layout. *)
PROCEDURE (g: Grid) ColWidth*(col: INTEGER): INTEGER;
BEGIN RETURN GridCol(g, size, col)
END ColWidth;

PROCEDURE (g: Grid) SetColWidth*(col, w: INTEGER);
BEGIN SetGridCol(g, size, col, w)
END SetColWidth;

PROCEDURE (g: Grid) ColWeight*(col: INTEGER): INTEGER;
BEGIN RETURN GridCol(g, weight, col)
END ColWeight;

PROCEDURE (g: Grid) SetColWeight*(col, w: INTEGER);
BEGIN SetGridCol(g, weight, col, w)
END SetColWeight;

PROCEDURE (g: Grid) ColGap*(col: INTEGER): INTEGER;
BEGIN RETURN GridCol(g, gap, col)
END ColGap;

PROCEDURE (g: Grid) SetColGap*(col, w: INTEGER);
BEGIN SetGridCol(g, gap, col, w)
END SetColGap;

PROCEDURE (g: Grid) ComputedColWidth*(col: INTEGER): INTEGER;
BEGIN RETURN GridCol(g, computed, col)
END ComputedColWidth;

(* The same for a row. *)
PROCEDURE (g: Grid) RowHeight*(row: INTEGER): INTEGER;
BEGIN RETURN GridRow(g, size, row)
END RowHeight;

PROCEDURE (g: Grid) SetRowHeight*(row, h: INTEGER);
BEGIN SetGridRow(g, size, row, h)
END SetRowHeight;

PROCEDURE (g: Grid) RowWeight*(row: INTEGER): INTEGER;
BEGIN RETURN GridRow(g, weight, row)
END RowWeight;

PROCEDURE (g: Grid) SetRowWeight*(row, w: INTEGER);
BEGIN SetGridRow(g, weight, row, w)
END SetRowWeight;

PROCEDURE (g: Grid) RowGap*(row: INTEGER): INTEGER;
BEGIN RETURN GridRow(g, gap, row)
END RowGap;

PROCEDURE (g: Grid) SetRowGap*(row, h: INTEGER);
BEGIN SetGridRow(g, gap, row, h)
END SetRowGap;

PROCEDURE (g: Grid) ComputedRowHeight*(row: INTEGER): INTEGER;
BEGIN RETURN GridRow(g, computed, row)
END ComputedRowHeight;

(* Draws the cells' outlines, to see the layout. *)
PROCEDURE (g: Grid) ShowGrid*(show: BOOLEAN);
BEGIN
  IF show THEN CShowGrid(Fl.Live(g), 1) ELSE CShowGrid(Fl.Live(g), 0) END
END ShowGrid;

(* Pack *)

(* PackVertical, to start with, or PackHorizontal. *)
PROCEDURE (p: Pack) Kind*(): INTEGER;
BEGIN RETURN CType(Fl.Live(p))
END Kind;

PROCEDURE (p: Pack) SetKind*(k: INTEGER);
BEGIN CSetType(Fl.Live(p), k)
END SetKind;

(* The space between children; 0 to start with. *)
PROCEDURE (p: Pack) Spacing*(): INTEGER;
BEGIN RETURN CSpacing(Fl.Live(p))
END Spacing;

PROCEDURE (p: Pack) SetSpacing*(s: INTEGER);
BEGIN CSetSpacing(Fl.Live(p), s)
END SetSpacing;

(* Scroll *)

(* Which scrollbars: ScrollBoth, to start with, or another Scroll kind. *)
PROCEDURE (s: Scroll) Kind*(): INTEGER;
BEGIN RETURN CType(Fl.Live(s))
END Kind;

PROCEDURE (s: Scroll) SetKind*(k: INTEGER);
BEGIN CSetType(Fl.Live(s), k)
END SetKind;

(* How far the children are scrolled, across and down. *)
PROCEDURE (s: Scroll) XPosition*(): INTEGER;
BEGIN RETURN CXPosition(Fl.Live(s))
END XPosition;

PROCEDURE (s: Scroll) YPosition*(): INTEGER;
BEGIN RETURN CYPosition(Fl.Live(s))
END YPosition;

PROCEDURE (s: Scroll) ScrollTo*(x, y: INTEGER);
BEGIN CScrollTo(Fl.Live(s), x, y)
END ScrollTo;

(* The scrollbars' width; 0, to start with, for Fl's ScrollbarSize. *)
PROCEDURE (s: Scroll) ScrollbarSize*(): INTEGER;
BEGIN RETURN CScrollbarSize(Fl.Live(s))
END ScrollbarSize;

PROCEDURE (s: Scroll) SetScrollbarSize*(n: INTEGER);
BEGIN CSetScrollbarSize(Fl.Live(s), n)
END SetScrollbarSize;

(* Tabs *)

(* The tab shown, or NIL. *)
PROCEDURE (t: Tabs) Value*(): Fl.Widget;
BEGIN RETURN SYSTEM.VAL(Fl.Widget, CTabsValue(Fl.Live(t)))
END Value;

(* Shows child w's tab, without calling the Callback. *)
PROCEDURE (t: Tabs) SetValue*(w: Fl.Widget);
BEGIN CTabsSetValue(Fl.Live(t), Child(t, w))
END SetValue;

(* Where the tabs' labels go in them: a set of Fl's Align constants. *)
PROCEDURE (t: Tabs) TabAlign*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CTabAlign(Fl.Live(t)))
END TabAlign;

PROCEDURE (t: Tabs) SetTabAlign*(a: SET);
BEGIN CSetTabAlign(Fl.Live(t), SYSTEM.VAL(SYSTEM.INT32, a))
END SetTabAlign;

(* What to do with tabs too many to fit: OverflowCompress, to start with,
   or another Overflow constant. *)
PROCEDURE (t: Tabs) HandleOverflow*(ov: INTEGER);
BEGIN CHandleOverflow(Fl.Live(t), ov)
END HandleOverflow;

(* The area below (or above) the tabs where a child goes, from the tabs'
   children's sizes. *)
PROCEDURE (t: Tabs) ClientArea*(VAR x, y, w, h: INTEGER);
  VAR X, Y, W, H: SYSTEM.INT32;
BEGIN CClientArea(Fl.Live(t), X, Y, W, H); x := X; y := Y; w := W; h := H
END ClientArea;

(* Wizard *)

(* The page shown, or NIL. *)
PROCEDURE (z: Wizard) Value*(): Fl.Widget;
BEGIN RETURN SYSTEM.VAL(Fl.Widget, CWizardValue(Fl.Live(z)))
END Value;

PROCEDURE (z: Wizard) SetValue*(w: Fl.Widget);
BEGIN CWizardSetValue(Fl.Live(z), Child(z, w))
END SetValue;

(* Shows the next page, or the one before; nothing at the last or first. *)
PROCEDURE (z: Wizard) Next*;
BEGIN CNext(Fl.Live(z))
END Next;

PROCEDURE (z: Wizard) Prev*;
BEGIN CPrev(Fl.Live(z))
END Prev;

(* Tile *)

(* The sizes the user may drag child w to; MAX(INTEGER) for no maximum. *)
PROCEDURE (t: Tile) SizeRange*(w: Fl.Widget; minw, minh, maxw, maxh: INTEGER);
BEGIN CSizeRange(Fl.Live(t), Child(t, w), minw, minh, maxw, maxh)
END SizeRange;

(* Gives every child the same minimum size, and no maximum. *)
PROCEDURE (t: Tile) InitSizeRange*(minw, minh: INTEGER);
BEGIN CInitSizeRange(Fl.Live(t), minw, minh)
END InitSizeRange;

(* Moves the border between children at oldx (or oldy) to newx (or
   newy), as the user's drag does; resizing the children each side. *)
PROCEDURE (t: Tile) MoveIntersection*(oldx, oldy, newx, newy: INTEGER);
BEGIN CMoveIntersection(Fl.Live(t), oldx, oldy, newx, newy)
END MoveIntersection;

END FlLayout.
