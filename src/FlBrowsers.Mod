MODULE FlBrowsers; (* Browsers: scrolling lists of lines to choose from, and trees *)

(* A Browser is FLTK's Fl_Browser: lines of text, numbered from 1, which
   the user may select: none (Browser), one (HoldBrowser, SelectBrowser),
   or several (MultiBrowser). A FileBrowser lists a directory; a
   CheckBrowser is a list of items with check boxes; a Tree, a hierarchy
   of items ("Trees", below). A browser line or item number
   outside 1 to the number there are halts (Fl.IndexOutOfRange).

   A line may start with formatting, each code starting with the format
   character ("@" to start with): "@b" bold, "@i" italic, "@c" centred,
   "@C" n color n, "@." no more formatting, and the others FLTK's
   Fl_Browser documents. The column character (Tab, 9X, to start with)
   divides a line into columns, of the widths SetColumnWidths gives.

   The Callback runs when the user selects or deselects a line: to start
   with, whenever the mouse button is released (Fl.WhenReleaseAlways),
   even with no change. A CheckBrowser's never does to start with
   (FLTK's FL_WHEN_NEVER); SetWhen(Fl.WhenChanged) makes it run as an
   item is checked or unchecked. The C++ part is FlBrowsers.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* which scrollbars a browser shows (BrowserBase.SetScrollbars) *)
  ScrollbarHorizontal* = 1;
  ScrollbarVertical* = 2;
  ScrollbarBoth* = 3;
  ScrollbarAlwaysOn* = 4;
  ScrollbarHorizontalAlways* = 5;
  ScrollbarVerticalAlways* = 6;
  ScrollbarBothAlways* = 7;

  (* how BrowserBase.Sort sorts *)
  SortAscending* = 0;
  SortDescending* = 1;
  SortCaseInsensitive* = 2;

  (* what a file browser lists (FileBrowser.SetFileType) *)
  Files* = 0;
  Directories* = 1;

  (* how a tree's items are selected (Tree.SetSelectMode) *)
  TreeSelectNone* = 0;
  TreeSelectSingle* = 1;
  TreeSelectMulti* = 2;
  TreeSelectSingleDraggable* = 3;

  (* where a tree adds an item among its siblings (Tree.SetSortOrder) *)
  TreeSortNone* = 0;
  TreeSortAscending* = 1;
  TreeSortDescending* = 2;

  (* the lines between a tree's items (Tree.SetConnectorStyle) *)
  ConnectorNone* = 0;
  ConnectorDotted* = 1;
  ConnectorSolid* = 2;

  (* whether clicking a selected item calls back (Tree.SetReselectMode) *)
  SelectableOnce* = 0;
  SelectableAlways* = 1;

  (* why a tree called back (Tree.CallbackReason) *)
  ReasonNone* = 0;
  ReasonSelected* = 1;
  ReasonDeselected* = 2;
  ReasonReselected* = 3;
  ReasonOpened* = 4;
  ReasonClosed* = 5;
  ReasonDragged* = 6;

  (* how an item with a widget is drawn (Tree.SetItemDrawMode); {} draws the widget alone *)
  ItemDrawLabelAndWidget* = {0};
  ItemHeightFromWidget* = {1};
(* END generated constants *)

  (* the classes, as ofl_browser_new numbers them *)
  plain = 0; hold = 1; multi = 2; select = 3; file = 4; check = 5;

  (* what ofl_browser_get and ofl_browser_set read or set *)
  textFont = 0; textSize = 1; textColor = 2; hasScrollbar = 3;
  scrollbarSize = 4; hPosition = 5; vPosition = 6;

TYPE
  (* FLTK's Fl_Browser_, what the others have in common; never opened. *)
  BrowserBase* = POINTER TO BrowserBaseDesc;
  BrowserBaseDesc* = RECORD (Fl.WidgetDesc) END;

  Browser* = POINTER TO BrowserDesc;
  BrowserDesc* = RECORD (BrowserBaseDesc) END;

  (* one line selected, which stays selected *)
  HoldBrowser* = POINTER TO HoldBrowserDesc;
  HoldBrowserDesc* = RECORD (BrowserDesc) END;

  (* any lines selected *)
  MultiBrowser* = POINTER TO MultiBrowserDesc;
  MultiBrowserDesc* = RECORD (BrowserDesc) END;

  (* one line selected while the mouse button is held *)
  SelectBrowser* = POINTER TO SelectBrowserDesc;
  SelectBrowserDesc* = RECORD (BrowserDesc) END;

  (* the files of a directory, with icons *)
  FileBrowser* = POINTER TO FileBrowserDesc;
  FileBrowserDesc* = RECORD (BrowserDesc) END;

  (* items with check boxes, the user checking them *)
  CheckBrowser* = POINTER TO CheckBrowserDesc;
  CheckBrowserDesc* = RECORD (BrowserBaseDesc) END;

  (* FLTK's Fl_Tree: items in a hierarchy, each with a label, which the
     user may open, close and select. *)
  Tree* = POINTER TO TreeDesc;
  TreeDesc* = RECORD (Fl.WidgetDesc) END;

  (* One of a tree's items. The tree makes and deletes its items, so a
     TreeItem is a reference to one, good until the item is removed:
     used after, it halts (Fl.ClosedResource). Two TreeItems may refer to
     the same item: compare them with Same.

     The program may make an item itself, of its own extension, and add
     it once (Tree.AddItem, TreeItem.Replace): then the tree's every
     reference to that item is the object itself, whose DrawContent
     draws it. *)
  TreeItem* = POINTER TO TreeItemDesc;
  TreeItemDesc* = RECORD
    tree-: Tree;
    p: SYSTEM.ADDRESS;
    serial: INTEGER;
    prev, next: TreeItem   (* the program's items in trees (made) *)
  END;

  DrawItemProc = PROCEDURE (self: SYSTEM.ADDRESS; render: SYSTEM.INT32): SYSTEM.INT32;
  ItemGoneProc = PROCEDURE (self: SYSTEM.ADDRESS);

VAR
  made: TreeItem;   (* the program's items in trees, which FLTK alone holds *)

PROCEDURE ["C", "ofl_browser_new"] CNew(class, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_browser_get"] CGet(b: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_browser_set"] CSet(b: SYSTEM.ADDRESS; what, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_browser_deselect"] CDeselect(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_browser_sort"] CSort(b: SYSTEM.ADDRESS; flags: SYSTEM.INT32);
PROCEDURE ["C", "ofl_browser_size"] CSize(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_browser_add"] CAdd(b: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_browser_insert"] CInsert(b: SYSTEM.ADDRESS; line: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_browser_remove"] CRemove(b: SYSTEM.ADDRESS; line: SYSTEM.INT32);
PROCEDURE ["C", "ofl_browser_move"] CMove(b: SYSTEM.ADDRESS; to, from: SYSTEM.INT32);
PROCEDURE ["C", "ofl_browser_swap"] CSwap(b: SYSTEM.ADDRESS; a, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_browser_clear"] CClear(b: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_browser_load"] CLoad(b: SYSTEM.ADDRESS; name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_browser_text"] CText(b: SYSTEM.ADDRESS; line: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_browser_set_text"] CSetText(b: SYSTEM.ADDRESS; line: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_browser_select"] CSelect(b: SYSTEM.ADDRESS; line, on: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_browser_selected"] CSelected(b: SYSTEM.ADDRESS; line: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_browser_value"] CValue(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_browser_lineposition"] CLinePosition(b: SYSTEM.ADDRESS; line, what: SYSTEM.INT32);
PROCEDURE ["C", "ofl_browser_topline"] CTopLine(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_browser_line"] CLine(b: SYSTEM.ADDRESS; what, line: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_browser_char"] CChar(b: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_browser_set_char"] CSetChar(b: SYSTEM.ADDRESS; what, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_browser_column_widths"] CColumnWidths(b: SYSTEM.ADDRESS; widths: ARRAY OF INTEGER; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_browser_load"] CFileLoad(b: SYSTEM.ADDRESS; dir: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_browser_filter"] CFilter(b: SYSTEM.ADDRESS; pattern: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_browser_get_filter"] CGetFilter(b: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_file_browser_type"] CFileType(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_browser_set_type"] CSetFileType(b: SYSTEM.ADDRESS; t: SYSTEM.INT32);
PROCEDURE ["C", "ofl_file_browser_iconsize"] CIconSize(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_browser_set_iconsize"] CSetIconSize(b: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_check_browser_add"] CCheckAdd(b: SYSTEM.ADDRESS; s: ARRAY OF CHAR; on: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_check_browser_remove"] CCheckRemove(b: SYSTEM.ADDRESS; item: SYSTEM.INT32);
PROCEDURE ["C", "ofl_check_browser_clear"] CCheckClear(b: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_check_browser_count"] CCount(b: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_check_browser_checked"] CChecked(b: SYSTEM.ADDRESS; item: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_check_browser_set_checked"] CSetChecked(b: SYSTEM.ADDRESS; item, on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_check_browser_check_all"] CCheckAll(b: SYSTEM.ADDRESS; on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_check_browser_text"] CCheckText(b: SYSTEM.ADDRESS; item: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);

PROCEDURE ["C", "ofl_tree_new"] CTreeNew(x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_live"] CTreeLive(t, p: SYSTEM.ADDRESS; serial: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_tree_item"] CTreeItem(t: SYSTEM.ADDRESS; what: SYSTEM.INT32; VAR serial: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_add"] CTreeAdd(t: SYSTEM.ADDRESS; path: ARRAY OF CHAR; VAR serial: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_find"] CTreeFind(t: SYSTEM.ADDRESS; path: ARRAY OF CHAR; VAR serial: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_clear"] CTreeClear(t: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_tree_get"] CTreeGet(t: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_tree_set"] CTreeSet(t: SYSTEM.ADDRESS; what, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_tree_set_root_label"] CSetRootLabel(t: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_tree_select_all"] CSelectAll(t: SYSTEM.ADDRESS; on: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_tree_item_item"] CItemItem(t, p: SYSTEM.ADDRESS; what: SYSTEM.INT32; VAR serial: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_item_swap"] CItemSwap(p: SYSTEM.ADDRESS; a, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_tree_item_child"] CItemChild(t, p: SYSTEM.ADDRESS; i: SYSTEM.INT32; VAR serial: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_item_add"] CItemAdd(t, p: SYSTEM.ADDRESS; what: SYSTEM.INT32; name: ARRAY OF CHAR; pos: SYSTEM.INT32; VAR serial: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_item_remove"] CItemRemove(t, p: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_tree_item_clear_children"] CItemClearChildren(t, p: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_tree_item_label"] CItemLabel(p: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_tree_item_set_label"] CItemSetLabel(t, p: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_tree_item_path"] CItemPath(t, p: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_tree_item_get"] CItemGet(t, p: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_tree_item_set"] CItemSet(t, p: SYSTEM.ADDRESS; what, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_tree_register"] CTreeRegister(drawItem: DrawItemProc; itemGone: ItemGoneProc);
PROCEDURE ["C", "ofl_tree_add_item"] CTreeAddItem(t: SYSTEM.ADDRESS; path, label: ARRAY OF CHAR; self: SYSTEM.ADDRESS; VAR serial: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_self"] CTreeSelf(p: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_item_replace"] CItemReplace(t, p: SYSTEM.ADDRESS; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS; VAR serial: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_item_draw_content"] CItemDrawContent(p: SYSTEM.ADDRESS; render: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_tree_item_widget"] CItemWidget(p: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tree_item_set_widget"] CItemSetWidget(t, p, w: SYSTEM.ADDRESS);

PROCEDURE Int(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Int;

PROCEDURE Open(b: BrowserBase; class, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(b, CNew(class, x, y, w, h, label, Fl.BeginOpen(b)))
END Open;

PROCEDURE OpenBrowser*(b: Browser; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, plain, x, y, w, h, label)
END OpenBrowser;

PROCEDURE OpenHoldBrowser*(b: HoldBrowser; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, hold, x, y, w, h, label)
END OpenHoldBrowser;

PROCEDURE OpenMultiBrowser*(b: MultiBrowser; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, multi, x, y, w, h, label)
END OpenMultiBrowser;

PROCEDURE OpenSelectBrowser*(b: SelectBrowser; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, select, x, y, w, h, label)
END OpenSelectBrowser;

PROCEDURE OpenFileBrowser*(b: FileBrowser; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, file, x, y, w, h, label)
END OpenFileBrowser;

PROCEDURE OpenCheckBrowser*(b: CheckBrowser; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, check, x, y, w, h, label)
END OpenCheckBrowser;

(* Every browser *)

PROCEDURE Get(b: BrowserBase; what: INTEGER): INTEGER;
BEGIN RETURN CGet(Fl.Live(b), what)
END Get;

PROCEDURE Set(b: BrowserBase; what, v: INTEGER);
BEGIN CSet(Fl.Live(b), what, v)
END Set;

(* The lines' font, size and color, Fl's. *)
PROCEDURE (b: BrowserBase) TextFont*(): INTEGER;
BEGIN RETURN Get(b, textFont)
END TextFont;

PROCEDURE (b: BrowserBase) SetTextFont*(f: INTEGER);
BEGIN Set(b, textFont, f)
END SetTextFont;

PROCEDURE (b: BrowserBase) TextSize*(): INTEGER;
BEGIN RETURN Get(b, textSize)
END TextSize;

PROCEDURE (b: BrowserBase) SetTextSize*(s: INTEGER);
BEGIN Set(b, textSize, s)
END SetTextSize;

PROCEDURE (b: BrowserBase) TextColor*(): INTEGER;
BEGIN RETURN Get(b, textColor)
END TextColor;

PROCEDURE (b: BrowserBase) SetTextColor*(c: INTEGER);
BEGIN Set(b, textColor, c)
END SetTextColor;

(* Which scrollbars are shown: one of the Scrollbar constants;
   ScrollbarBoth, shown when needed, to start with. *)
PROCEDURE (b: BrowserBase) Scrollbars*(): INTEGER;
BEGIN RETURN Get(b, hasScrollbar)
END Scrollbars;

PROCEDURE (b: BrowserBase) SetScrollbars*(s: INTEGER);
BEGIN Set(b, hasScrollbar, s)
END SetScrollbars;

(* The scrollbars' width; 0 for Fl's. *)
PROCEDURE (b: BrowserBase) ScrollbarSize*(): INTEGER;
BEGIN RETURN Get(b, scrollbarSize)
END ScrollbarSize;

PROCEDURE (b: BrowserBase) SetScrollbarSize*(n: INTEGER);
BEGIN Set(b, scrollbarSize, n)
END SetScrollbarSize;

(* How far the list is scrolled, in pixels, across and down. *)
PROCEDURE (b: BrowserBase) HPosition*(): INTEGER;
BEGIN RETURN Get(b, hPosition)
END HPosition;

PROCEDURE (b: BrowserBase) SetHPosition*(p: INTEGER);
BEGIN Set(b, hPosition, p)
END SetHPosition;

PROCEDURE (b: BrowserBase) VPosition*(): INTEGER;
BEGIN RETURN Get(b, vPosition)
END VPosition;

PROCEDURE (b: BrowserBase) SetVPosition*(p: INTEGER);
BEGIN Set(b, vPosition, p)
END SetVPosition;

(* Deselects every line, without calling back; TRUE if any was selected. *)
PROCEDURE (b: BrowserBase) Deselect*(): BOOLEAN;
BEGIN RETURN CDeselect(Fl.Live(b)) # 0
END Deselect;

(* Sorts the lines by their text: SortAscending or SortDescending, plus
   SortCaseInsensitive. *)
PROCEDURE (b: BrowserBase) Sort*(flags: INTEGER);
BEGIN CSort(Fl.Live(b), flags)
END Sort;

(* Browsers *)

(* b's handle, halting unless line is from first to b's count plus
   extra. *)
PROCEDURE L(b: Browser; line, first, extra: INTEGER): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(b); ASSERT((line >= first) & (line <= CSize(h) + extra), Fl.IndexOutOfRange);
  RETURN h
END L;

(* The number of lines. *)
PROCEDURE (b: Browser) Count*(): INTEGER;
BEGIN RETURN CSize(Fl.Live(b))
END Count;

PROCEDURE (b: Browser) Add*(text-: ARRAY OF CHAR);
BEGIN CAdd(Fl.Live(b), text)
END Add;

(* Inserts text as line, from 1 to Count() + 1. *)
PROCEDURE (b: Browser) Insert*(line: INTEGER; text-: ARRAY OF CHAR);
BEGIN CInsert(L(b, line, 1, 1), line, text)
END Insert;

PROCEDURE (b: Browser) Remove*(line: INTEGER);
BEGIN CRemove(L(b, line, 1, 0), line)
END Remove;

(* Moves line from to be line to. *)
PROCEDURE (b: Browser) Move*(to, from: INTEGER);
VAR h: SYSTEM.ADDRESS;
BEGIN h := L(b, to, 1, 0); h := L(b, from, 1, 0); CMove(h, to, from)
END Move;

PROCEDURE (b: Browser) Swap*(a, c: INTEGER);
VAR h: SYSTEM.ADDRESS;
BEGIN h := L(b, a, 1, 0); h := L(b, c, 1, 0); CSwap(h, a, c)
END Swap;

PROCEDURE (b: Browser) Clear*;
BEGIN CClear(Fl.Live(b))
END Clear;

(* Replaces the lines with a file's, a line for each newline and one
   after the last, so a file ending with one ends with an empty line, and
   a line longer than 1023 bytes split; FALSE, and no lines, if it
   couldn't be read. *)
PROCEDURE (b: Browser) Load*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CLoad(Fl.Live(b), name) # 0
END Load;

(* A line's text, truncated to fit. *)
PROCEDURE (b: Browser) GetText*(line: INTEGER; VAR text: ARRAY OF CHAR);
BEGIN CText(L(b, line, 1, 0), line, text, SHORT(LEN(text)))
END GetText;

PROCEDURE (b: Browser) SetText*(line: INTEGER; text-: ARRAY OF CHAR);
BEGIN CSetText(L(b, line, 1, 0), line, text)
END SetText;

(* Selects or deselects a line, without calling back; TRUE if it
   changed. A browser that selects one line deselects the others. *)
PROCEDURE (b: Browser) Select*(line: INTEGER; on: BOOLEAN): BOOLEAN;
BEGIN RETURN CSelect(L(b, line, 1, 0), line, Int(on)) # 0
END Select;

PROCEDURE (b: Browser) Selected*(line: INTEGER): BOOLEAN;
BEGIN RETURN CSelected(L(b, line, 1, 0), line) # 0
END Selected;

(* The line selected, or for a MultiBrowser the one last clicked; 0 for
   none. *)
PROCEDURE (b: Browser) Value*(): INTEGER;
BEGIN RETURN CValue(Fl.Live(b))
END Value;

(* Scrolls so that line is at the top, the bottom, or the middle. *)
PROCEDURE (b: Browser) SetTopLine*(line: INTEGER);
BEGIN CLinePosition(L(b, line, 1, 0), line, 0)
END SetTopLine;

PROCEDURE (b: Browser) SetBottomLine*(line: INTEGER);
BEGIN CLinePosition(L(b, line, 1, 0), line, 1)
END SetBottomLine;

PROCEDURE (b: Browser) SetMiddleLine*(line: INTEGER);
BEGIN CLinePosition(L(b, line, 1, 0), line, 2)
END SetMiddleLine;

(* The line at the top. *)
PROCEDURE (b: Browser) TopLine*(): INTEGER;
BEGIN RETURN CTopLine(Fl.Live(b))
END TopLine;

(* Hides or shows a line: a hidden line takes no space. *)
PROCEDURE (b: Browser) HideLine*(line: INTEGER);
VAR r: INTEGER;
BEGIN r := CLine(L(b, line, 1, 0), 0, line)
END HideLine;

PROCEDURE (b: Browser) ShowLine*(line: INTEGER);
VAR r: INTEGER;
BEGIN r := CLine(L(b, line, 1, 0), 1, line)
END ShowLine;

(* TRUE unless the line is hidden. *)
PROCEDURE (b: Browser) LineVisible*(line: INTEGER): BOOLEAN;
BEGIN RETURN CLine(L(b, line, 1, 0), 2, line) # 0
END LineVisible;

(* TRUE if the line is scrolled into view. *)
PROCEDURE (b: Browser) Displayed*(line: INTEGER): BOOLEAN;
BEGIN RETURN CLine(L(b, line, 1, 0), 3, line) # 0
END Displayed;

(* Scrolls as little as shows the line. *)
PROCEDURE (b: Browser) MakeVisible*(line: INTEGER);
VAR r: INTEGER;
BEGIN r := CLine(L(b, line, 1, 0), 4, line)
END MakeVisible;

PROCEDURE (b: Browser) FormatChar*(): CHAR;
BEGIN RETURN CHR(CChar(Fl.Live(b), 0))
END FormatChar;

(* 0X for no formatting. *)
PROCEDURE (b: Browser) SetFormatChar*(c: CHAR);
BEGIN CSetChar(Fl.Live(b), 0, ORD(c))
END SetFormatChar;

PROCEDURE (b: Browser) ColumnChar*(): CHAR;
BEGIN RETURN CHR(CChar(Fl.Live(b), 1))
END ColumnChar;

(* 0X for no columns. *)
PROCEDURE (b: Browser) SetColumnChar*(c: CHAR);
BEGIN CSetChar(Fl.Live(b), 1, ORD(c))
END SetColumnChar;

(* The width of each column but the last, which takes the rest; the
   first n of widths. *)
PROCEDURE (b: Browser) SetColumnWidths*(widths: ARRAY OF INTEGER; n: INTEGER);
BEGIN
  ASSERT((n >= 0) & (n <= LEN(widths)), Fl.IndexOutOfRange);
  ASSERT(CColumnWidths(Fl.Live(b), widths, n) # 0)  (* out of memory *)
END SetColumnWidths;

(* File browsers *)

(* Lists the subdirectories of dir, then its files matching the filter,
   each sorted; FALSE, and no lines, if dir couldn't be read. "" lists the
   file systems. *)
PROCEDURE (b: FileBrowser) LoadDirectory*(dir-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFileLoad(Fl.Live(b), dir) # 0
END LoadDirectory;

(* The files listed: a pattern, as "*.txt" or "*.{c,h}"; "*" to start
   with. *)
PROCEDURE (b: FileBrowser) SetFilter*(pattern-: ARRAY OF CHAR);
BEGIN ASSERT(CFilter(Fl.Live(b), pattern) # 0)  (* out of memory *)
END SetFilter;

PROCEDURE (b: FileBrowser) Filter*(VAR pattern: ARRAY OF CHAR);
BEGIN CGetFilter(Fl.Live(b), pattern, SHORT(LEN(pattern)))
END Filter;

(* Files, as to start with, lists files and directories; Directories,
   directories alone. *)
PROCEDURE (b: FileBrowser) FileType*(): INTEGER;
BEGIN RETURN CFileType(Fl.Live(b))
END FileType;

PROCEDURE (b: FileBrowser) SetFileType*(t: INTEGER);
BEGIN CSetFileType(Fl.Live(b), t)
END SetFileType;

(* The icons' size; SetTextSize sets it to one and a half times the
   text's. *)
PROCEDURE (b: FileBrowser) IconSize*(): INTEGER;
BEGIN RETURN CIconSize(Fl.Live(b))
END IconSize;

PROCEDURE (b: FileBrowser) SetIconSize*(s: INTEGER);
BEGIN CSetIconSize(Fl.Live(b), s)
END SetIconSize;

(* Check browsers *)

(* b's handle, halting unless item is one of b's. *)
PROCEDURE I(b: CheckBrowser; item: INTEGER): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(b); ASSERT((item >= 1) & (item <= CCount(h, 0)), Fl.IndexOutOfRange);
  RETURN h
END I;

(* Adds an item, checked or not, and returns its number. *)
PROCEDURE (b: CheckBrowser) Add*(text-: ARRAY OF CHAR; checked: BOOLEAN): INTEGER;
BEGIN RETURN CCheckAdd(Fl.Live(b), text, Int(checked))
END Add;

PROCEDURE (b: CheckBrowser) Remove*(item: INTEGER);
BEGIN CCheckRemove(I(b, item), item)
END Remove;

PROCEDURE (b: CheckBrowser) Clear*;
BEGIN CCheckClear(Fl.Live(b))
END Clear;

(* The number of items, and of those checked. *)
PROCEDURE (b: CheckBrowser) Count*(): INTEGER;
BEGIN RETURN CCount(Fl.Live(b), 0)
END Count;

PROCEDURE (b: CheckBrowser) CheckedCount*(): INTEGER;
BEGIN RETURN CCount(Fl.Live(b), 1)
END CheckedCount;

(* The item last clicked; 0 for none. *)
PROCEDURE (b: CheckBrowser) Value*(): INTEGER;
BEGIN RETURN CCount(Fl.Live(b), 2)
END Value;

PROCEDURE (b: CheckBrowser) Checked*(item: INTEGER): BOOLEAN;
BEGIN RETURN CChecked(I(b, item), item) # 0
END Checked;

PROCEDURE (b: CheckBrowser) SetChecked*(item: INTEGER; on: BOOLEAN);
BEGIN CSetChecked(I(b, item), item, Int(on))
END SetChecked;

PROCEDURE (b: CheckBrowser) CheckAll*;
BEGIN CCheckAll(Fl.Live(b), 1)
END CheckAll;

PROCEDURE (b: CheckBrowser) CheckNone*;
BEGIN CCheckAll(Fl.Live(b), 0)
END CheckNone;

PROCEDURE (b: CheckBrowser) GetText*(item: INTEGER; VAR text: ARRAY OF CHAR);
BEGIN CCheckText(I(b, item), item, text, SHORT(LEN(text)))
END GetText;

(* Trees *)

(* Tree items are named by paths, as menu items are: "Fruit/Apple",
   with "\/" for a slash in a label and "\\" for a backslash. The root
   is the item at the top, above the others, labelled "ROOT" to start
   with; SetShowRoot(FALSE) hides it, and leaves it out of paths. What
   the program does never calls back: Select, Open and the rest. *)

PROCEDURE OpenTree*(t: Tree; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(t, CTreeNew(x, y, w, h, label, Fl.BeginOpen(t)))
END OpenTree;

(* The TreeItem for p, NIL if p is 0: the program's own object for an
   item it made. *)
PROCEDURE Item(t: Tree; p: SYSTEM.ADDRESS; serial: SYSTEM.INT32): TreeItem;
  VAR i: TreeItem; self: SYSTEM.ADDRESS;
BEGIN
  IF p = 0 THEN RETURN NIL END;
  self := CTreeSelf(p);
  IF self # 0 THEN RETURN SYSTEM.VAL(TreeItem, self) END;
  NEW(i); i.tree := t; i.p := p; i.serial := serial;
  RETURN i
END Item;

(* Keeps item i, which the program made, from the collector while FLTK
   holds it. *)
PROCEDURE Hold(i: TreeItem);
BEGIN
  i.prev := NIL; i.next := made;
  IF made # NIL THEN made.prev := i END;
  made := i
END Hold;

(* i's tree's handle, halting unless i is still in it. *)
PROCEDURE T(i: TreeItem): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  ASSERT(i # NIL, Fl.NilArgument);
  h := Fl.Live(i.tree); ASSERT(CTreeLive(h, i.p, i.serial) # 0, Fl.ClosedResource);
  RETURN h
END T;

(* TRUE if a and b refer to the same item, or are both NIL. *)
PROCEDURE Same*(a, b: TreeItem): BOOLEAN;
BEGIN
  IF (a = NIL) OR (b = NIL) THEN RETURN a = b END;
  RETURN (a.p = b.p) & (a.serial = b.serial) & (a.tree = b.tree)
END Same;

(* TRUE unless i has been removed from its tree, or its tree deleted. *)
PROCEDURE (i: TreeItem) IsLive*(): BOOLEAN;
BEGIN RETURN (i.tree.h # 0) & (CTreeLive(i.tree.h, i.p, i.serial) # 0)
END IsLive;

PROCEDURE TreeItemOf(t: Tree; what: INTEGER): TreeItem;
  VAR p: SYSTEM.ADDRESS; serial: SYSTEM.INT32;
BEGIN p := CTreeItem(Fl.Live(t), what, serial); RETURN Item(t, p, serial)
END TreeItemOf;

(* The root; NIL after Clear, until the next Add. *)
PROCEDURE (t: Tree) Root*(): TreeItem;
BEGIN RETURN TreeItemOf(t, 0)
END Root;

(* The first item, the root; and the last, in the order Next goes. *)
PROCEDURE (t: Tree) First*(): TreeItem;
BEGIN RETURN TreeItemOf(t, 1)
END First;

PROCEDURE (t: Tree) Last*(): TreeItem;
BEGIN RETURN TreeItemOf(t, 2)
END Last;

PROCEDURE (t: Tree) FirstSelected*(): TreeItem;
BEGIN RETURN TreeItemOf(t, 3)
END FirstSelected;

(* In a Callback, the item the user acted on, and why (one of the Reason
   constants). *)
PROCEDURE (t: Tree) CallbackItem*(): TreeItem;
BEGIN RETURN TreeItemOf(t, 4)
END CallbackItem;

PROCEDURE (t: Tree) CallbackReason*(): INTEGER;
BEGIN RETURN CTreeGet(Fl.Live(t), 0)
END CallbackReason;

(* The item with the keyboard focus. *)
PROCEDURE (t: Tree) FocusItem*(): TreeItem;
BEGIN RETURN TreeItemOf(t, 5)
END FocusItem;

(* Adds an item at path, and the items above it that aren't there yet,
   and returns it. An item already at path is not reused: there are then
   two. *)
PROCEDURE (t: Tree) Add*(path-: ARRAY OF CHAR): TreeItem;
  VAR p: SYSTEM.ADDRESS; serial: SYSTEM.INT32;
BEGIN p := CTreeAdd(Fl.Live(t), path, serial); RETURN Item(t, p, serial)
END Add;

(* The first item at path; NIL if there is none. *)
PROCEDURE (t: Tree) Find*(path-: ARRAY OF CHAR): TreeItem;
  VAR p: SYSTEM.ADDRESS; serial: SYSTEM.INT32;
BEGIN p := CTreeFind(Fl.Live(t), path, serial); RETURN Item(t, p, serial)
END Find;

(* Removes every item, the root too. *)
PROCEDURE (t: Tree) Clear*;
BEGIN CTreeClear(Fl.Live(t))
END Clear;

PROCEDURE (t: Tree) SetRootLabel*(label-: ARRAY OF CHAR);
BEGIN CSetRootLabel(Fl.Live(t), label)
END SetRootLabel;

PROCEDURE (t: Tree) SelectAll*;
VAR r: INTEGER;
BEGIN r := CSelectAll(Fl.Live(t), 1)
END SelectAll;

PROCEDURE (t: Tree) DeselectAll*;
VAR r: INTEGER;
BEGIN r := CSelectAll(Fl.Live(t), 0)
END DeselectAll;

PROCEDURE TGet(t: Tree; what: INTEGER): INTEGER;
BEGIN RETURN CTreeGet(Fl.Live(t), what)
END TGet;

PROCEDURE TSet(t: Tree; what, v: INTEGER);
BEGIN CTreeSet(Fl.Live(t), what, v)
END TSet;

PROCEDURE (t: Tree) ShowRoot*(): BOOLEAN;
BEGIN RETURN TGet(t, 1) # 0
END ShowRoot;

PROCEDURE (t: Tree) SetShowRoot*(on: BOOLEAN);
BEGIN TSet(t, 1, Int(on))
END SetShowRoot;

(* One of the TreeSelect constants; TreeSelectSingle to start with. *)
PROCEDURE (t: Tree) SelectMode*(): INTEGER;
BEGIN RETURN TGet(t, 2)
END SelectMode;

PROCEDURE (t: Tree) SetSelectMode*(m: INTEGER);
BEGIN TSet(t, 2, m)
END SetSelectMode;

(* One of the TreeSort constants, for items added from now on;
   TreeSortNone, last among their siblings, to start with. *)
PROCEDURE (t: Tree) SortOrder*(): INTEGER;
BEGIN RETURN TGet(t, 3)
END SortOrder;

PROCEDURE (t: Tree) SetSortOrder*(s: INTEGER);
BEGIN TSet(t, 3, s)
END SetSortOrder;

(* One of the Connector constants. *)
PROCEDURE (t: Tree) ConnectorStyle*(): INTEGER;
BEGIN RETURN TGet(t, 4)
END ConnectorStyle;

PROCEDURE (t: Tree) SetConnectorStyle*(s: INTEGER);
BEGIN TSet(t, 4, s)
END SetConnectorStyle;

(* SelectableOnce or SelectableAlways (a click on a selected item calls
   back, with ReasonReselected). *)
PROCEDURE (t: Tree) ReselectMode*(): INTEGER;
BEGIN RETURN TGet(t, 5)
END ReselectMode;

PROCEDURE (t: Tree) SetReselectMode*(m: INTEGER);
BEGIN TSet(t, 5, m)
END SetReselectMode;

(* The label font, size and colors items are given when added. *)
PROCEDURE (t: Tree) ItemLabelFont*(): INTEGER;
BEGIN RETURN TGet(t, 6)
END ItemLabelFont;

PROCEDURE (t: Tree) SetItemLabelFont*(f: INTEGER);
BEGIN TSet(t, 6, f)
END SetItemLabelFont;

PROCEDURE (t: Tree) ItemLabelSize*(): INTEGER;
BEGIN RETURN TGet(t, 7)
END ItemLabelSize;

PROCEDURE (t: Tree) SetItemLabelSize*(s: INTEGER);
BEGIN TSet(t, 7, s)
END SetItemLabelSize;

PROCEDURE (t: Tree) ItemLabelColor*(): INTEGER;
BEGIN RETURN TGet(t, 8)
END ItemLabelColor;

PROCEDURE (t: Tree) SetItemLabelColor*(c: INTEGER);
BEGIN TSet(t, 8, c)
END SetItemLabelColor;

PROCEDURE (t: Tree) ItemLabelBgColor*(): INTEGER;
BEGIN RETURN TGet(t, 9)
END ItemLabelBgColor;

PROCEDURE (t: Tree) SetItemLabelBgColor*(c: INTEGER);
BEGIN TSet(t, 9, c)
END SetItemLabelBgColor;

PROCEDURE (t: Tree) ConnectorColor*(): INTEGER;
BEGIN RETURN TGet(t, 10)
END ConnectorColor;

PROCEDURE (t: Tree) SetConnectorColor*(c: INTEGER);
BEGIN TSet(t, 10, c)
END SetConnectorColor;

(* The scrollbars' width; 0 for Fl's. *)
PROCEDURE (t: Tree) ScrollbarSize*(): INTEGER;
BEGIN RETURN TGet(t, 11)
END ScrollbarSize;

PROCEDURE (t: Tree) SetScrollbarSize*(n: INTEGER);
BEGIN TSet(t, 11, n)
END SetScrollbarSize;

(* How far the tree is scrolled, in pixels, down and across. *)
PROCEDURE (t: Tree) VPosition*(): INTEGER;
BEGIN RETURN TGet(t, 12)
END VPosition;

PROCEDURE (t: Tree) SetVPosition*(p: INTEGER);
BEGIN TSet(t, 12, p)
END SetVPosition;

PROCEDURE (t: Tree) HPosition*(): INTEGER;
BEGIN RETURN TGet(t, 13)
END HPosition;

PROCEDURE (t: Tree) SetHPosition*(p: INTEGER);
BEGIN TSet(t, 13, p)
END SetHPosition;

(* Whether items with children show the box that opens and closes
   them. *)
PROCEDURE (t: Tree) ShowCollapse*(): BOOLEAN;
BEGIN RETURN TGet(t, 14) # 0
END ShowCollapse;

PROCEDURE (t: Tree) SetShowCollapse*(on: BOOLEAN);
BEGIN TSet(t, 14, Int(on))
END SetShowCollapse;

(* Spacing, in pixels: left of the items, above the first, and between
   them; and the width of the connectors. *)
PROCEDURE (t: Tree) MarginLeft*(): INTEGER;
BEGIN RETURN TGet(t, 15)
END MarginLeft;

PROCEDURE (t: Tree) SetMarginLeft*(n: INTEGER);
BEGIN TSet(t, 15, n)
END SetMarginLeft;

PROCEDURE (t: Tree) MarginTop*(): INTEGER;
BEGIN RETURN TGet(t, 16)
END MarginTop;

PROCEDURE (t: Tree) SetMarginTop*(n: INTEGER);
BEGIN TSet(t, 16, n)
END SetMarginTop;

PROCEDURE (t: Tree) LineSpacing*(): INTEGER;
BEGIN RETURN TGet(t, 17)
END LineSpacing;

PROCEDURE (t: Tree) SetLineSpacing*(n: INTEGER);
BEGIN TSet(t, 17, n)
END SetLineSpacing;

PROCEDURE (t: Tree) ConnectorWidth*(): INTEGER;
BEGIN RETURN TGet(t, 18)
END ConnectorWidth;

PROCEDURE (t: Tree) SetConnectorWidth*(n: INTEGER);
BEGIN TSet(t, 18, n)
END SetConnectorWidth;

(* How an item with a widget is drawn: {} for the widget in place of the
   label, or ItemDrawLabelAndWidget, and ItemHeightFromWidget for the
   item as high as its widget. *)
PROCEDURE (t: Tree) ItemDrawMode*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, TGet(t, 20))
END ItemDrawMode;

PROCEDURE (t: Tree) SetItemDrawMode*(m: SET);
BEGIN TSet(t, 20, ORD(m))
END SetItemDrawMode;

(* The space between an item's label and its widget. *)
PROCEDURE (t: Tree) WidgetMarginLeft*(): INTEGER;
BEGIN RETURN TGet(t, 21)
END WidgetMarginLeft;

PROCEDURE (t: Tree) SetWidgetMarginLeft*(n: INTEGER);
BEGIN TSet(t, 21, n)
END SetWidgetMarginLeft;

(* Adds i, an item the program made, labelled label, at path, as Add
   adds an item, making the parents missing; if the whole path is there
   already, i becomes that item's child, labelled label all the same.
   Returns FALSE, and adds nothing, for an empty path. An item is added
   once (Fl.OpenedTwice), and lasts until removed: from then on, every
   TreeItem the tree hands out for it is i. *)
PROCEDURE (t: Tree) AddItem*(path-: ARRAY OF CHAR; i: TreeItem; label-: ARRAY OF CHAR): BOOLEAN;
  VAR h: SYSTEM.ADDRESS; serial: SYSTEM.INT32;
BEGIN
  h := Fl.Live(t);
  ASSERT(i # NIL, Fl.NilArgument); ASSERT(i.p = 0, Fl.OpenedTwice);
  Hold(i); i.tree := t;
  i.p := CTreeAddItem(h, path, label, SYSTEM.VAL(SYSTEM.ADDRESS, i), serial);
  i.serial := serial;
  RETURN i.p # 0
END AddItem;

(* The box drawn behind a selected item: a box type of Fl's. *)
PROCEDURE (t: Tree) SelectBox*(): INTEGER;
BEGIN RETURN TGet(t, 19)
END SelectBox;

PROCEDURE (t: Tree) SetSelectBox*(b: INTEGER);
BEGIN TSet(t, 19, b)
END SetSelectBox;

(* Tree items *)

PROCEDURE ItemOf(i: TreeItem; what: INTEGER): TreeItem;
  VAR p: SYSTEM.ADDRESS; serial: SYSTEM.INT32;
BEGIN p := CItemItem(T(i), i.p, what, serial); RETURN Item(i.tree, p, serial)
END ItemOf;

(* The item above i, whose child it is; NIL for the root. *)
PROCEDURE (i: TreeItem) Parent*(): TreeItem;
BEGIN RETURN ItemOf(i, 0)
END Parent;

(* The item after i, and before, going down the tree as drawn, open or
   closed: an item's children follow it. NIL at the end. *)
PROCEDURE (i: TreeItem) Next*(): TreeItem;
BEGIN RETURN ItemOf(i, 1)
END Next;

PROCEDURE (i: TreeItem) Prev*(): TreeItem;
BEGIN RETURN ItemOf(i, 2)
END Prev;

(* The next item selected after i; NIL if none. *)
PROCEDURE (i: TreeItem) NextSelected*(): TreeItem;
BEGIN RETURN ItemOf(i, 3)
END NextSelected;

(* The item drawn below i, and above; NIL if none is shown. *)
PROCEDURE (i: TreeItem) NextVisible*(): TreeItem;
BEGIN RETURN ItemOf(i, 4)
END NextVisible;

PROCEDURE (i: TreeItem) PrevVisible*(): TreeItem;
BEGIN RETURN ItemOf(i, 5)
END PrevVisible;

PROCEDURE IGet(i: TreeItem; what: INTEGER): INTEGER;
BEGIN RETURN CItemGet(T(i), i.p, what)
END IGet;

PROCEDURE ISet(i: TreeItem; what, v: INTEGER);
BEGIN CItemSet(T(i), i.p, what, v)
END ISet;

PROCEDURE (i: TreeItem) Children*(): INTEGER;
BEGIN RETURN IGet(i, 0)
END Children;

(* Child n of i, from 0 to Children() - 1. *)
PROCEDURE (i: TreeItem) Child*(n: INTEGER): TreeItem;
  VAR h, p: SYSTEM.ADDRESS; serial: SYSTEM.INT32;
BEGIN
  h := T(i); ASSERT((n >= 0) & (n < CItemGet(h, i.p, 0)), Fl.IndexOutOfRange);
  p := CItemChild(h, i.p, n, serial); RETURN Item(i.tree, p, serial)
END Child;

(* Swaps i's children a and b, from 0 to Children() - 1: to sort them,
   say. The tree isn't redrawn. *)
PROCEDURE (i: TreeItem) SwapChildren*(a, b: INTEGER);
  VAR n: INTEGER;
BEGIN
  n := CItemGet(T(i), i.p, 0);
  ASSERT((a >= 0) & (a < n) & (b >= 0) & (b < n), Fl.IndexOutOfRange);
  CItemSwap(i.p, a, b)
END SwapChildren;

(* 0 for the root, 1 for its children, and so on. *)
PROCEDURE (i: TreeItem) Depth*(): INTEGER;
BEGIN RETURN IGet(i, 1)
END Depth;

PROCEDURE (i: TreeItem) IsRoot*(): BOOLEAN;
BEGIN RETURN IGet(i, 2) # 0
END IsRoot;

(* Adds a child labelled name, after the others (or as the tree's sort
   order puts it), and returns it. *)
PROCEDURE (i: TreeItem) Add*(name-: ARRAY OF CHAR): TreeItem;
  VAR p: SYSTEM.ADDRESS; serial: SYSTEM.INT32;
BEGIN p := CItemAdd(T(i), i.p, 0, name, 0, serial); RETURN Item(i.tree, p, serial)
END Add;

(* Inserts a child labelled name as child pos, from 0 to Children(),
   whatever the sort order, and returns it. *)
PROCEDURE (i: TreeItem) Insert*(name-: ARRAY OF CHAR; pos: INTEGER): TreeItem;
  VAR h, p: SYSTEM.ADDRESS; serial: SYSTEM.INT32;
BEGIN
  h := T(i); ASSERT((pos >= 0) & (pos <= CItemGet(h, i.p, 0)), Fl.IndexOutOfRange);
  p := CItemAdd(h, i.p, 1, name, pos, serial); RETURN Item(i.tree, p, serial)
END Insert;

(* Inserts an item labelled name just before i, among its siblings, and
   returns it; NIL for the root, which has none. *)
PROCEDURE (i: TreeItem) InsertAbove*(name-: ARRAY OF CHAR): TreeItem;
  VAR p: SYSTEM.ADDRESS; serial: SYSTEM.INT32;
BEGIN p := CItemAdd(T(i), i.p, 2, name, 0, serial); RETURN Item(i.tree, p, serial)
END InsertAbove;

(* Removes i and its children from the tree. Removing the root empties
   the tree, as Clear does. *)
PROCEDURE (i: TreeItem) Remove*;
BEGIN CItemRemove(T(i), i.p)
END Remove;

PROCEDURE (i: TreeItem) ClearChildren*;
BEGIN CItemClearChildren(T(i), i.p)
END ClearChildren;

(* Puts new, an item the program made, labelled label, in i's place, and
   removes i and its children. The root can't be replaced
   (Fl.Unsupported); new is added once, as Tree.AddItem adds it. *)
PROCEDURE (i: TreeItem) Replace*(new: TreeItem; label-: ARRAY OF CHAR);
  VAR h: SYSTEM.ADDRESS; serial: SYSTEM.INT32;
BEGIN
  h := T(i);
  ASSERT(new # NIL, Fl.NilArgument); ASSERT(new.p = 0, Fl.OpenedTwice);
  ASSERT(CItemGet(h, i.p, 2) = 0, Fl.Unsupported);
  Hold(new); new.tree := i.tree;
  new.p := CItemReplace(h, i.p, label, SYSTEM.VAL(SYSTEM.ADDRESS, new), serial);
  new.serial := serial
END Replace;

(* Draws i's content, right of its connectors and icons, in the label's
   place (LabelXYWH), if render; else only measures it. Returns the right
   edge of what it draws, for the tree's horizontal scrollbar. FLTK
   calls it for an item the program made; the default draws the label,
   or the widget, as for any item. *)
PROCEDURE (i: TreeItem) DrawContent*(render: BOOLEAN): INTEGER;
  VAR h: SYSTEM.ADDRESS; r: SYSTEM.INT32;
BEGIN
  h := T(i); r := 0;
  IF render THEN r := 1 END;
  RETURN CItemDrawContent(i.p, r)
END DrawContent;

(* Where i's label is drawn, as last drawn: the area DrawContent draws in. *)
PROCEDURE (i: TreeItem) LabelXYWH*(VAR x, y, w, h: INTEGER);
BEGIN x := IGet(i, 12); y := IGet(i, 13); w := IGet(i, 14); h := IGet(i, 15)
END LabelXYWH;

(* The colors for DrawContent to draw i's text and background in, which
   allow for its being selected or inactive. *)
PROCEDURE (i: TreeItem) DrawFgColor*(): INTEGER;
BEGIN RETURN IGet(i, 16)
END DrawFgColor;

PROCEDURE (i: TreeItem) DrawBgColor*(): INTEGER;
BEGIN RETURN IGet(i, 17)
END DrawBgColor;

(* i's widget, NIL for none. *)
PROCEDURE (i: TreeItem) Widget*(): Fl.Widget;
  VAR h, self: SYSTEM.ADDRESS;
BEGIN h := T(i); self := CItemWidget(i.p); RETURN SYSTEM.VAL(Fl.Widget, self)
END Widget;

(* Shows w, in i's place or beside its label (Tree.SetItemDrawMode), or
   nothing for NIL. w becomes the tree's child, which the tree moves to
   where i is drawn; a widget i had leaves the tree, still open; w leaves
   any item that had it. w is deleted with i, by Remove, Clear and the
   rest, as a group's children are; w deleted, or added to another group,
   leaves i. *)
PROCEDURE (i: TreeItem) SetWidget*(w: Fl.Widget);
  VAR h, wh: SYSTEM.ADDRESS;
BEGIN
  h := T(i); wh := 0;
  IF w # NIL THEN wh := Fl.Live(w) END;
  CItemSetWidget(h, i.p, wh)
END SetWidget;

(* i's label, truncated to fit. *)
PROCEDURE (i: TreeItem) GetLabel*(VAR label: ARRAY OF CHAR);
VAR h: SYSTEM.ADDRESS;
BEGIN h := T(i); CItemLabel(i.p, label, SHORT(LEN(label)))
END GetLabel;

PROCEDURE (i: TreeItem) SetLabel*(label-: ARRAY OF CHAR);
BEGIN CItemSetLabel(T(i), i.p, label)
END SetLabel;

(* i's path, as Find takes it; FALSE, and "", if it doesn't fit. *)
PROCEDURE (i: TreeItem) Path*(VAR path: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CItemPath(T(i), i.p, path, SHORT(LEN(path))) # 0
END Path;

(* Opens or closes i, showing or hiding its children. *)
PROCEDURE (i: TreeItem) Open*;
BEGIN ISet(i, 0, 1)
END Open;

PROCEDURE (i: TreeItem) Close*;
BEGIN ISet(i, 0, 0)
END Close;

PROCEDURE (i: TreeItem) IsOpen*(): BOOLEAN;
BEGIN RETURN IGet(i, 3) # 0
END IsOpen;

(* Selects or deselects i, leaving the others as they are, whatever the
   select mode. *)
PROCEDURE (i: TreeItem) Select*(on: BOOLEAN);
BEGIN ISet(i, 1, Int(on))
END Select;

(* Selects i and deselects the others. *)
PROCEDURE (i: TreeItem) SelectOnly*;
BEGIN ISet(i, 2, 1)
END SelectOnly;

PROCEDURE (i: TreeItem) IsSelected*(): BOOLEAN;
BEGIN RETURN IGet(i, 4) # 0
END IsSelected;

(* An inactive item is drawn grayed, and can't be selected by the
   user. *)
PROCEDURE (i: TreeItem) Activate*(on: BOOLEAN);
BEGIN ISet(i, 3, Int(on))
END Activate;

PROCEDURE (i: TreeItem) IsActive*(): BOOLEAN;
BEGIN RETURN IGet(i, 5) # 0
END IsActive;

(* TRUE unless an item above i is closed. *)
PROCEDURE (i: TreeItem) IsVisible*(): BOOLEAN;
BEGIN RETURN IGet(i, 6) # 0
END IsVisible;

(* TRUE if i is scrolled into view. *)
PROCEDURE (i: TreeItem) Displayed*(): BOOLEAN;
BEGIN RETURN IGet(i, 11) # 0
END Displayed;

(* Scrolls as little as shows i; or to put it at the top. *)
PROCEDURE (i: TreeItem) Show*;
BEGIN ISet(i, 9, 0)
END Show;

PROCEDURE (i: TreeItem) ShowAtTop*;
BEGIN ISet(i, 10, 0)
END ShowAtTop;

(* Gives i the keyboard focus, among the tree's items. *)
PROCEDURE (i: TreeItem) SetFocus*;
BEGIN ISet(i, 8, 0)
END SetFocus;

(* i's label font, size and colors. *)
PROCEDURE (i: TreeItem) LabelFont*(): INTEGER;
BEGIN RETURN IGet(i, 7)
END LabelFont;

PROCEDURE (i: TreeItem) SetLabelFont*(f: INTEGER);
BEGIN ISet(i, 4, f)
END SetLabelFont;

PROCEDURE (i: TreeItem) LabelSize*(): INTEGER;
BEGIN RETURN IGet(i, 8)
END LabelSize;

PROCEDURE (i: TreeItem) SetLabelSize*(s: INTEGER);
BEGIN ISet(i, 5, s)
END SetLabelSize;

PROCEDURE (i: TreeItem) LabelColor*(): INTEGER;
BEGIN RETURN IGet(i, 9)
END LabelColor;

PROCEDURE (i: TreeItem) SetLabelColor*(c: INTEGER);
BEGIN ISet(i, 6, c)
END SetLabelColor;

PROCEDURE (i: TreeItem) LabelBgColor*(): INTEGER;
BEGIN RETURN IGet(i, 10)
END LabelBgColor;

PROCEDURE (i: TreeItem) SetLabelBgColor*(c: INTEGER);
BEGIN ISet(i, 7, c)
END SetLabelBgColor;

PROCEDURE DrawItemD(self: SYSTEM.ADDRESS; render: SYSTEM.INT32): SYSTEM.INT32;
  VAR i: TreeItem;
BEGIN i := SYSTEM.VAL(TreeItem, self); RETURN i.DrawContent(render # 0)
END DrawItemD;

(* An item the program made is gone, deleted by FLTK: the collector may
   have it once the program lets go. *)
PROCEDURE ItemGoneD(self: SYSTEM.ADDRESS);
  VAR i: TreeItem;
BEGIN
  i := SYSTEM.VAL(TreeItem, self);
  IF i.prev # NIL THEN i.prev.next := i.next ELSE made := i.next END;
  IF i.next # NIL THEN i.next.prev := i.prev END;
  i.prev := NIL; i.next := NIL
END ItemGoneD;

BEGIN
  CTreeRegister(DrawItemD, ItemGoneD)
END FlBrowsers.
