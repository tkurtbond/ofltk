MODULE TestMenus; (* FlMenus: items, picking, shortcuts, choices, a global menu and a pop-up *)

IMPORT Fl, FlMenus, Check, Probe;

TYPE
  (* Answers a pop-up menu: Down and Enter to pick its first item, or
     Escape to close it. *)
  Answer = POINTER TO RECORD (Fl.TimerDesc) pick: BOOLEAN END;

VAR
  win: Fl.Window;
  bar, other: FlMenus.MenuBar;
  choice: FlMenus.Choice;
  schemes: FlMenus.SchemeChoice;
  button: FlMenus.MenuButton;
  answer: Answer;
  last: Fl.Widget;
  opened, quitted, barCalls, cleared, n: INTEGER;
  file, open, save, quit, edit, copy, grid, small, large, danger, i: INTEGER;
  key: INTEGER; state: SET;
  s: ARRAY 64 OF CHAR;
  ok: BOOLEAN;
  action: FlMenus.Action;

PROCEDURE Open(w: Fl.Widget);
BEGIN INC(opened); last := w
END Open;

PROCEDURE Quit(w: Fl.Widget);
BEGIN INC(quitted)
END Quit;

PROCEDURE BarCallback(w: Fl.Widget);
BEGIN INC(barCalls)
END BarCallback;

PROCEDURE ClearMenu(w: Fl.Widget);
BEGIN w(FlMenus.Menu).Clear; INC(cleared)
END ClearMenu;

PROCEDURE (a: Answer) Fire*;
  VAR ok: BOOLEAN;
BEGIN
  IF a.pick THEN
    ok := Probe.HandleKey(win, Fl.EvKeyDown, Fl.KeyDown, {}, "");
    ok := Probe.HandleKey(win, Fl.EvKeyDown, Fl.KeyEnter, {}, 0DX)
  ELSE
    ok := Probe.HandleKey(win, Fl.EvKeyDown, Fl.KeyEscape, {}, 1BX)
  END
END Fire;

PROCEDURE Is(m: FlMenus.Menu; i: INTEGER; label: ARRAY OF CHAR): BOOLEAN;
  VAR s: ARRAY 64 OF CHAR;
BEGIN m.ItemLabel(i, s); RETURN s = label
END Is;

BEGIN
  NEW(win); Fl.OpenWindow(win, 300, 200, "TestMenus");
  NEW(bar); FlMenus.OpenMenuBar(bar, 0, 0, 300, 25, "");
  bar.action := BarCallback;
  Check.Check(bar.Length() = 0, "a menu starts empty");
  open := bar.Add("&File/&Open", ORD("o"), Fl.Ctrl, Open, {});
  save := bar.Add("File/_Save", 0, {}, NIL, {});
  quit := bar.Add("File/Quit", ORD("q"), Fl.Ctrl, Quit, {});
  copy := bar.Add("Edit/Copy", 0, {}, NIL, {});
  grid := bar.Add("View/Grid", 0, {}, NIL, FlMenus.MenuToggle);
  small := bar.Add("View/Small", 0, {}, NIL, FlMenus.MenuRadio);
  large := bar.Add("View/Large", 0, {}, NIL, FlMenus.MenuRadio);
  file := 0; edit := quit + 2;
  Check.Check((open = 1) & (save = 2) & (quit = 3) & (copy = 6) & (grid = 9) & (large = 11)
    & (bar.Length() = 14), "items, their submenus and the ends, in FLTK's array");
  Check.Check(bar.IsItem(file) & bar.IsItem(edit) & ~bar.IsItem(quit + 1) & ~bar.IsItem(13)
    & ~bar.IsItem(-1) & ~bar.IsItem(14), "titles are items, the ends aren't");
  Check.Check(Is(bar, file, "&File") & Is(bar, open, "&Open") & Is(bar, save, "Save"),
    "ItemLabel, without the path or a leading _");
  Check.Check((FlMenus.Submenu * bar.ItemFlags(file) # {}) & (FlMenus.MenuDivider * bar.ItemFlags(save) # {}),
    "a title is a submenu; _ is a divider");
  Check.Check((bar.FindIndex("&File/&Open") = open) & (bar.FindIndex("File/Open") = -1)
    & (bar.FindIndex("View/Large") = large), "FindIndex takes the path as written, with &");
  Check.Check(bar.ItemPath(open, s) & (s = "&File/&Open"), "ItemPath");
  n := bar.Add("File/Quit", ORD("x"), Fl.Ctrl, Quit, {});
  bar.ItemShortcut(quit, key, state);
  Check.Check((n = quit) & (bar.Length() = 14) & (key = ORD("x")) & (state = Fl.Ctrl),
    "adding a path that is there changes that item");
  Check.Check(bar.Value() = -1, "no item is chosen to start with");

  (* picking *)
  bar.Pick(open);
  Check.Check((opened = 1) & (last = bar) & (bar.Value() = open), "Pick calls the item's action with the menu");
  bar.Pick(copy);
  Check.Check((barCalls = 1) & (opened = 1) & (bar.Value() = copy), "an item without one calls the menu's");
  ok := Probe.Shortcut(win, ORD("o"), Fl.Ctrl, "o");
  Check.Check(ok & (opened = 2), "an item's shortcut picks it");
  ok := Probe.Shortcut(win, ORD("x"), Fl.Ctrl, "x");
  Check.Check(ok & (quitted = 1), "a shortcut changed by Add");
  bar.Pick(grid);
  Check.Check(FlMenus.MenuValue * bar.ItemFlags(grid) # {}, "picking a toggle item turns it on");
  bar.Pick(grid);
  Check.Check(FlMenus.MenuValue * bar.ItemFlags(grid) = {}, "and off");
  bar.Pick(large);
  Check.Check((FlMenus.MenuValue * bar.ItemFlags(large) # {}) & (FlMenus.MenuValue * bar.ItemFlags(small) = {}),
    "picking a radio item turns it on");
  bar.Pick(small);
  Check.Check((FlMenus.MenuValue * bar.ItemFlags(small) # {}) & (FlMenus.MenuValue * bar.ItemFlags(large) = {}),
    "and the others of its group off");
  bar.SetOnly(large);
  Check.Check((FlMenus.MenuValue * bar.ItemFlags(large) # {}) & (FlMenus.MenuValue * bar.ItemFlags(small) = {})
    & (barCalls = 5), "SetOnly, without calling back");

  (* changing items *)
  bar.SetItemLabel(save, "Save/As");
  Check.Check(Is(bar, save, "Save/As") & (bar.Length() = 14), "SetItemLabel takes a slash as it is");
  bar.SetItemFlags(file, FlMenus.MenuInactive);
  Check.Check(bar.ItemFlags(file) = FlMenus.MenuInactive + FlMenus.Submenu, "SetItemFlags keeps Submenu");
  bar.SetItemFlags(open, FlMenus.Submenu);
  Check.Check(bar.ItemFlags(open) = {}, "and can't set it");
  bar.SetItemFlags(file, {});
  bar.SetItemShortcut(save, ORD("s"), Fl.Ctrl + Fl.Shift);
  bar.ItemShortcut(save, key, state);
  Check.Check((key = ORD("s")) & (state = Fl.Ctrl + Fl.Shift), "SetItemShortcut");
  action := Open;
  Check.Check((bar.ItemAction(open) = action) & (bar.ItemAction(save) = NIL), "ItemAction");
  bar.SetItemAction(save, Quit); bar.Pick(save);
  Check.Check(quitted = 2, "SetItemAction");
  bar.SetItemAction(save, NIL); bar.Pick(save);
  Check.Check((quitted = 2) & (barCalls = 6), "and to none");

  (* removing *)
  bar.ClearSubmenu(file);
  Check.Check((bar.Length() = 11) & Is(bar, file, "&File") & (bar.FindIndex("&File/&Open") = -1)
    & (bar.Value() = -1), "ClearSubmenu keeps the title, and the value if it isn't one of them");
  large := bar.FindIndex("View/Large");
  bar.Pick(large); bar.Remove(file);
  Check.Check((large = 8) & (bar.Length() = 9) & (bar.Value() = 6) & Is(bar, 6, "Large"),
    "Remove of a submenu's title removes it all; the value follows its item");
  danger := bar.Add("Danger", 0, {}, ClearMenu, {});
  bar.Pick(danger);
  Check.Check((cleared = 1) & (bar.Length() = 0) & (bar.Value() = -1), "a menu cleared in its own Callback");

  (* a choice *)
  NEW(choice); FlMenus.OpenChoice(choice, 50, 50, 100, 25, "Size");
  i := choice.Add("A", 0, {}, NIL, {}); i := choice.Add("B", 0, {}, NIL, {}); i := choice.Add("C", 0, {}, NIL, {});
  choice.ClearDamage;
  Check.Check(choice.SetValue(2) & (choice.Value() = 2) & (choice.Damage() # {}),
    "a choice's SetValue chooses, and redraws it");
  Check.Check(~choice.SetValue(2), "FALSE if it was chosen");
  i := choice.Insert(0, "Z", 0, {}, NIL, {});
  Check.Check((i = 0) & (choice.Value() = 3) & Is(choice, 3, "C"), "inserting before the value keeps it");
  choice.Remove(0);
  Check.Check(choice.Value() = 2, "so does removing");
  choice.Remove(2);
  Check.Check(choice.Value() = -1, "removing it leaves none");
  Check.Check(choice.SetValue(1) & choice.SetValue(-1) & (choice.Value() = -1), "SetValue(-1)");
  choice.SetTextSize(20); choice.SetTextColor(Fl.Red); choice.SetDownBox(Fl.FlatBox);
  Check.Check((choice.TextSize() = 20) & (choice.TextColor() = Fl.Red) & (choice.DownBox() = Fl.FlatBox),
    "the items' look");

  (* a menu button, popped up *)
  NEW(button); FlMenus.OpenMenuButton(button, 50, 100, 100, 25, "Pop");
  i := button.Add("One", 0, {}, Open, {}); i := button.Add("Two", 0, {}, NIL, {});
  Check.Check(button.Kind() = 0, "a menu button is a button to start with");
  win.End;

  (* a global menu, in no window *)
  NEW(other); FlMenus.OpenMenuBar(other, 0, 0, 10, 10, "");
  i := other.Add("Go", ORD("g"), Fl.Ctrl, Quit, {});
  ok := Probe.HandleKey(win, Fl.EvShortcut, ORD("g"), Fl.Ctrl, "g");
  Check.Check(~ok & (quitted = 2), "another menu's shortcut doesn't work in this window");
  other.Global;
  ok := Probe.HandleKey(win, Fl.EvShortcut, ORD("g"), Fl.Ctrl, "g");
  Check.Check(ok & (quitted = 3), "until it is global");
  other.Delete;
  ok := Probe.HandleKey(win, Fl.EvShortcut, ORD("g"), Fl.Ctrl, "g");
  Check.Check(~ok & (quitted = 3), "a global menu deleted is forgotten");

  (* Under Wayland the compositor closes a pop-up menu of a window that
     doesn't have the focus, as a window no user clicked doesn't
     (doc/fltk-issues.md, 29), so this is checked on X11 alone. *)
  IF ~Probe.Wayland() THEN
    win.Show; win.WaitForExpose;
    NEW(answer); answer.pick := TRUE; Fl.AddTimeout(answer, 0.2D0);
    i := button.Popup();
    Check.Check((i = 0) & (opened = 3) & (button.Value() = 0), "Popup returns the item picked, after its action");
    NEW(answer); answer.pick := FALSE; Fl.AddTimeout(answer, 0.2D0);
    i := button.Popup();
    Check.Check((i = -1) & (opened = 3), "or -1, closed")
  END;

  (* A choice of schemes, FLTK's names in FLTK's order *)
  ok := Fl.SetScheme("plastic");
  NEW(schemes); FlMenus.OpenSchemeChoice(schemes, 0, 0, 100, 25, "");
  schemes.ItemLabel(2, s);
  Check.Check((schemes.Value() = 1) & (s = "gtk+"), "a scheme choice: FLTK's schemes, showing the one in use");
  ok := schemes.SetValue(3); schemes.DoCallback;
  Fl.GetScheme(s);
  Check.Check(s = "gleam", "and sets the one chosen");
  schemes.Delete;

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestMenus.
