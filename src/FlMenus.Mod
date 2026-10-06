MODULE FlMenus; (* Menus: menu bars, pop-up menu buttons, and choices *)

(* A menu is a list of items, each with a label, a shortcut, flags and an
   action. Items are named by their index in FLTK's array of them, which
   holds each submenu's items after its title, followed by an end that is
   not an item; so Length counts the ends too, and an index that names one
   halts (Fl.IndexOutOfRange), as one outside the array does. Inserting or
   removing items changes the indexes after them.

   When the user picks an item, the menu's Callback runs, and by default
   calls the item's action, or if it has none, the menu's own (Fl.Widget's
   action). Value is then the item picked. An extension may override
   Callback to handle every item itself.

   An item's label is a path: "File/Open" is the item Open in the submenu
   File, made if it isn't there. Adding a path that is already there
   changes that item rather than adding another. In each part "&" marks
   the letter underlined, a leading "_" draws a line after the item, and
   "\" makes the next character ordinary, as "\/" for a slash.

   The C++ part is FlMenus.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* a menu item's flags (Menu.Add, Menu.ItemFlags); not FL_SUBMENU_POINTER *)
  MenuInactive* = {0};
  MenuToggle* = {1};
  MenuValue* = {2};
  MenuRadio* = {3};
  MenuInvisible* = {4};
  Submenu* = {6};
  MenuDivider* = {7};

  (* kinds of menu button (MenuButton.SetKind): the mouse buttons that pop it up *)
  Popup1* = 1;
  Popup2* = 2;
  Popup12* = 3;
  Popup3* = 4;
  Popup13* = 5;
  Popup23* = 6;
  Popup123* = 7;
(* END generated constants *)

  (* the classes, as ofl_menu_new numbers them *)
  menuBar = 0; menuButton = 1; choice = 2;

  (* what ofl_menu_style reads or sets *)
  textFont = 0; textSize = 1; textColor = 2; downBox = 3; menuBox = 4;

  keyMask = 10000H;  (* FL_KEY_MASK + 1: a shortcut's key is below it *)

TYPE
  (* What an item does when picked; it is given the menu. A widget's
     action may be one too. *)
  Action* = PROCEDURE (w: Fl.Widget);

  (* FLTK's Fl_Menu_, what the others have in common; never opened. *)
  Menu* = POINTER TO MenuDesc;
  MenuDesc* = RECORD (Fl.WidgetDesc) END;

  (* a bar of submenus, as across the top of a window *)
  MenuBar* = POINTER TO MenuBarDesc;
  MenuBarDesc* = RECORD (MenuDesc) END;

  (* a button that pops up its menu, or a menu that pops up at the mouse
     when given a Kind (Popup1 and the rest) *)
  MenuButton* = POINTER TO MenuButtonDesc;
  MenuButtonDesc* = RECORD (MenuDesc) END;

  (* a button showing the item chosen, which pops up the menu to choose
     another *)
  Choice* = POINTER TO ChoiceDesc;
  ChoiceDesc* = RECORD (MenuDesc) END;

PROCEDURE ["C", "ofl_menu_new"] CNew(class, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_menu_size"] CSize(m: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_is_item"] CIsItem(m: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_insert"] CInsert(m: SYSTEM.ADDRESS; index: SYSTEM.INT32; label: ARRAY OF CHAR; shortcut: SYSTEM.INT32; action: SYSTEM.ADDRESS; flags: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_remove"] CRemove(m: SYSTEM.ADDRESS; i: SYSTEM.INT32);
PROCEDURE ["C", "ofl_menu_clear"] CClear(m: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_menu_clear_submenu"] CClearSubmenu(m: SYSTEM.ADDRESS; i: SYSTEM.INT32);
PROCEDURE ["C", "ofl_menu_value"] CValue(m: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_set_value"] CSetValue(m: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_pick"] CPick(m: SYSTEM.ADDRESS; i: SYSTEM.INT32);
PROCEDURE ["C", "ofl_menu_setonly"] CSetOnly(m: SYSTEM.ADDRESS; i: SYSTEM.INT32);
PROCEDURE ["C", "ofl_menu_label"] CLabel(m: SYSTEM.ADDRESS; i: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_menu_set_label"] CSetLabel(m: SYSTEM.ADDRESS; i: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_menu_pathname"] CPathname(m: SYSTEM.ADDRESS; i: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_find_index"] CFindIndex(m: SYSTEM.ADDRESS; path: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_flags"] CFlags(m: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_set_flags"] CSetFlags(m: SYSTEM.ADDRESS; i, flags: SYSTEM.INT32);
PROCEDURE ["C", "ofl_menu_shortcut"] CShortcut(m: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_set_shortcut"] CSetShortcut(m: SYSTEM.ADDRESS; i, s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_menu_action"] CAction(m: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_menu_set_action"] CSetAction(m: SYSTEM.ADDRESS; i: SYSTEM.INT32; a: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_menu_style"] CStyle(m: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_set_style"] CSetStyle(m: SYSTEM.ADDRESS; what, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_menu_global"] CGlobal(m: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_menu_popup"] CPopup(m: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_type"] CType(m: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_menu_set_type"] CSetType(m: SYSTEM.ADDRESS; t: SYSTEM.INT32);

PROCEDURE Open(m: Menu; class, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(m, CNew(class, x, y, w, h, label, Fl.BeginOpen(m)))
END Open;

PROCEDURE OpenMenuBar*(m: MenuBar; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(m, menuBar, x, y, w, h, label)
END OpenMenuBar;

PROCEDURE OpenMenuButton*(m: MenuButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(m, menuButton, x, y, w, h, label)
END OpenMenuButton;

PROCEDURE OpenChoice*(m: Choice; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(m, choice, x, y, w, h, label)
END OpenChoice;

(* m's handle, halting unless i is an item of m. *)
PROCEDURE Item(m: Menu; i: INTEGER): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(m); ASSERT(CIsItem(h, i) # 0, Fl.IndexOutOfRange);
  RETURN h
END Item;

PROCEDURE Shortcut(key: INTEGER; state: SET): INTEGER;
BEGIN RETURN key + SYSTEM.VAL(INTEGER, state)
END Shortcut;

(* Items *)

(* Inserts an item before index, or at the end of the menu if index is
   -1, and returns its index. A label with a path is put in its submenu,
   wherever index is. key and state are its shortcut, as Button's: a
   character's code or one of Fl's Key constants, and a set of Fl's
   Shift, Ctrl, Alt, Meta and Command; key 0 is none. action may be NIL.
   flags is a set of the Menu constants: Submenu makes the item a
   submenu's title, to which items may be added by path. *)
PROCEDURE (m: Menu) Insert*(index: INTEGER; label-: ARRAY OF CHAR; key: INTEGER; state: SET; action: Action; flags: SET): INTEGER;
  VAR h: SYSTEM.ADDRESS; n: INTEGER;
BEGIN
  h := Fl.Live(m); n := CSize(h);
  ASSERT((index = -1) OR (index >= 0) & ((index = 0) OR (index < n)), Fl.IndexOutOfRange);
  RETURN CInsert(h, index, label, Shortcut(key, state), SYSTEM.VAL(SYSTEM.ADDRESS, action), SYSTEM.VAL(SYSTEM.INT32, flags))
END Insert;

(* Insert at the end. *)
PROCEDURE (m: Menu) Add*(label-: ARRAY OF CHAR; key: INTEGER; state: SET; action: Action; flags: SET): INTEGER;
BEGIN RETURN m.Insert(-1, label, key, state, action, flags)
END Add;

(* Removes item i, and if it is a submenu's title, the submenu. *)
PROCEDURE (m: Menu) Remove*(i: INTEGER);
BEGIN CRemove(Item(m, i), i)
END Remove;

(* Removes every item. Not while FLTK is showing the menu: FLTK's rule,
   although clearing a menu in its own Callback is safe in FLTK 1.4.5. *)
PROCEDURE (m: Menu) Clear*;
BEGIN CClear(Fl.Live(m))
END Clear;

(* Removes the items of the submenu whose title is item i. *)
PROCEDURE (m: Menu) ClearSubmenu*(i: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Item(m, i); ASSERT(Submenu * SYSTEM.VAL(SET, CFlags(h, i)) # {}, Fl.IndexOutOfRange);
  CClearSubmenu(h, i)
END ClearSubmenu;

(* The length of FLTK's array: the items, and the end of the menu and of
   each submenu; 0 for a menu never given an item. *)
PROCEDURE (m: Menu) Length*(): INTEGER;
BEGIN RETURN CSize(Fl.Live(m))
END Length;

(* TRUE if i names an item of m, not an end or outside the array. *)
PROCEDURE (m: Menu) IsItem*(i: INTEGER): BOOLEAN;
BEGIN RETURN CIsItem(Fl.Live(m), i) # 0
END IsItem;

(* The index of the item with this path ("File/Open", as FLTK would show
   it, without "&"), or -1. *)
PROCEDURE (m: Menu) FindIndex*(path-: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CFindIndex(Fl.Live(m), path)
END FindIndex;

(* The item picked last, or chosen by SetValue; -1 for none. A choice
   shows it. Inserting and removing other items keeps it; removing it
   leaves none. *)
PROCEDURE (m: Menu) Value*(): INTEGER;
BEGIN RETURN CValue(Fl.Live(m))
END Value;

(* Chooses item i, or none if i is -1, without calling back. TRUE if
   that changed it. *)
PROCEDURE (m: Menu) SetValue*(i: INTEGER): BOOLEAN;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  IF i = -1 THEN h := Fl.Live(m) ELSE h := Item(m, i) END;
  RETURN CSetValue(h, i) # 0
END SetValue;

(* As if the user picked item i: a toggle item changes, a radio item is
   turned on, Value becomes i, and the Callback runs (if the menu's When
   allows). *)
PROCEDURE (m: Menu) Pick*(i: INTEGER);
BEGIN CPick(Item(m, i), i)
END Pick;

(* Item i's label, without its path; truncated to fit. *)
PROCEDURE (m: Menu) ItemLabel*(i: INTEGER; VAR label: ARRAY OF CHAR);
BEGIN CLabel(Item(m, i), i, label, SHORT(LEN(label)))
END ItemLabel;

(* Copies label, which is not a path: a "/" in it is a slash. *)
PROCEDURE (m: Menu) SetItemLabel*(i: INTEGER; label-: ARRAY OF CHAR);
BEGIN CSetLabel(Item(m, i), i, label)
END SetItemLabel;

(* Item i's path ("File/Open"); FALSE, with path "", if it doesn't fit. *)
PROCEDURE (m: Menu) ItemPath*(i: INTEGER; VAR path: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CPathname(Item(m, i), i, path, SHORT(LEN(path))) # 0
END ItemPath;

(* A set of the Menu constants. Submenu can't be changed. MenuValue is
   whether a toggle or radio item is on; SetOnly turns a radio item on and
   the others of its group off. *)
PROCEDURE (m: Menu) ItemFlags*(i: INTEGER): SET;
BEGIN RETURN SYSTEM.VAL(SET, CFlags(Item(m, i), i))
END ItemFlags;

PROCEDURE (m: Menu) SetItemFlags*(i: INTEGER; flags: SET);
BEGIN CSetFlags(Item(m, i), i, SYSTEM.VAL(SYSTEM.INT32, flags))
END SetItemFlags;

(* Turns radio item i on, and the other radio items next to it off: a
   group ends at a divider or an item that isn't a radio item. *)
PROCEDURE (m: Menu) SetOnly*(i: INTEGER);
BEGIN CSetOnly(Item(m, i), i)
END SetOnly;

(* Item i's shortcut, as Insert's. *)
PROCEDURE (m: Menu) ItemShortcut*(i: INTEGER; VAR key: INTEGER; VAR state: SET);
  VAR s: INTEGER;
BEGIN
  s := CShortcut(Item(m, i), i);
  key := s MOD keyMask; state := SYSTEM.VAL(SET, s - key)
END ItemShortcut;

PROCEDURE (m: Menu) SetItemShortcut*(i, key: INTEGER; state: SET);
BEGIN CSetShortcut(Item(m, i), i, Shortcut(key, state))
END SetItemShortcut;

PROCEDURE (m: Menu) ItemAction*(i: INTEGER): Action;
BEGIN RETURN SYSTEM.VAL(Action, CAction(Item(m, i), i))
END ItemAction;

PROCEDURE (m: Menu) SetItemAction*(i: INTEGER; action: Action);
BEGIN CSetAction(Item(m, i), i, SYSTEM.VAL(SYSTEM.ADDRESS, action))
END SetItemAction;

(* Calls the action of the item picked (Value), or if it has none, the
   menu's own, as Fl.Widget's Callback does. *)
PROCEDURE (m: Menu) Callback*;
  VAR h: SYSTEM.ADDRESS; i: INTEGER; a: Action;
BEGIN
  h := Fl.Live(m); i := CValue(h); a := NIL;
  IF i >= 0 THEN a := SYSTEM.VAL(Action, CAction(h, i)) END;
  IF a # NIL THEN a(m) ELSE m.Callback^ END
END Callback;

(* Makes m's shortcuts work in every window, as long as m is open and no
   modal window is shown. Only one menu at a time is global: the last
   given. *)
PROCEDURE (m: Menu) Global*;
BEGIN CGlobal(Fl.Live(m))
END Global;

(* How the items look: a font of Fl's, its size, a color; the box drawn
   behind the item under the mouse, and the box of the pop-up menu. *)

PROCEDURE (m: Menu) TextFont*(): INTEGER;
BEGIN RETURN CStyle(Fl.Live(m), textFont)
END TextFont;

PROCEDURE (m: Menu) SetTextFont*(f: INTEGER);
BEGIN CSetStyle(Fl.Live(m), textFont, f)
END SetTextFont;

PROCEDURE (m: Menu) TextSize*(): INTEGER;
BEGIN RETURN CStyle(Fl.Live(m), textSize)
END TextSize;

PROCEDURE (m: Menu) SetTextSize*(s: INTEGER);
BEGIN CSetStyle(Fl.Live(m), textSize, s)
END SetTextSize;

PROCEDURE (m: Menu) TextColor*(): INTEGER;
BEGIN RETURN CStyle(Fl.Live(m), textColor)
END TextColor;

PROCEDURE (m: Menu) SetTextColor*(c: INTEGER);
BEGIN CSetStyle(Fl.Live(m), textColor, c)
END SetTextColor;

PROCEDURE (m: Menu) DownBox*(): INTEGER;
BEGIN RETURN CStyle(Fl.Live(m), downBox)
END DownBox;

PROCEDURE (m: Menu) SetDownBox*(b: INTEGER);
BEGIN CSetStyle(Fl.Live(m), downBox, b)
END SetDownBox;

PROCEDURE (m: Menu) MenuBox*(): INTEGER;
BEGIN RETURN CStyle(Fl.Live(m), menuBox)
END MenuBox;

PROCEDURE (m: Menu) SetMenuBox*(b: INTEGER);
BEGIN CSetStyle(Fl.Live(m), menuBox, b)
END SetMenuBox;

(* Menu buttons *)

(* Pops up the menu at the mouse (for a Kind other than 0) or below the
   button, and waits until the user picks an item, or closes it. Returns
   the item picked, after its Callback, or -1 if none was. *)
PROCEDURE (m: MenuButton) Popup*(): INTEGER;
BEGIN RETURN CPopup(Fl.Live(m))
END Popup;

(* 0, a button; or Popup1 to Popup123, a menu with no button, which pops
   up where those mouse buttons are pushed over m. *)
PROCEDURE (m: MenuButton) Kind*(): INTEGER;
BEGIN RETURN CType(Fl.Live(m))
END Kind;

PROCEDURE (m: MenuButton) SetKind*(k: INTEGER);
BEGIN CSetType(Fl.Live(m), k)
END SetKind;

END FlMenus.
