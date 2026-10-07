MODULE MenubarAdd; (* FLTK's examples/menubar-add.cxx: a menu bar's items added one by one *)

(* Each item's action prints the item picked, its path, and its value if
   it is a toggle or a radio item, on standard error. Help/Google opens
   Google's page with the desktop's browser; File/Quit ends the program. *)

IMPORT Err, Fl, FlMenus;

VAR
  win: Fl.Window;
  menu: FlMenus.MenuBar;
  n, item: INTEGER;
  ok: BOOLEAN;

PROCEDURE MyMenuCallback(w: Fl.Widget);
  VAR bar: FlMenus.Menu; item: INTEGER; label, ipath, msg: ARRAY 256 OF CHAR;
BEGIN
  bar := w(FlMenus.Menu);
  item := bar.Value();                         (* the item picked *)
  bar.ItemLabel(item, label);
  IF ~bar.ItemPath(item, ipath) THEN END;      (* its full path *)
  Err.String("callback: You picked '"); Err.String(label); Err.String("'");
  Err.String(", item_pathname() is '"); Err.String(ipath); Err.String("'");
  IF bar.ItemFlags(item) * (FlMenus.MenuRadio + FlMenus.MenuToggle) # {} THEN   (* a toggle or radio item *)
    Err.String(", value is ");
    IF bar.ItemFlags(item) * FlMenus.MenuValue # {} THEN Err.String("on") ELSE Err.String("off") END
  END;
  Err.Ln;
  IF label = "Google" THEN ok := Fl.OpenURI("http://google.com/", msg) END;
  IF label = "&Quit" THEN HALT(0) END
END MyMenuCallback;

BEGIN
  ok := Fl.SetScheme("gtk+");
  NEW(win); Fl.OpenWindow(win, 400, 200, "menubar-simple");
  NEW(menu); FlMenus.OpenMenuBar(menu, 0, 0, 400, 25, "");
  n := menu.Add("&File/&Open", ORD("o"), Fl.Ctrl, MyMenuCallback, {});
  n := menu.Add("&File/&Save", ORD("s"), Fl.Ctrl, MyMenuCallback, FlMenus.MenuDivider);
  n := menu.Add("&File/&Quit", ORD("q"), Fl.Ctrl, MyMenuCallback, {});
  n := menu.Add("&Edit/&Copy", ORD("c"), Fl.Ctrl, MyMenuCallback, {});
  n := menu.Add("&Edit/&Paste", ORD("v"), Fl.Ctrl, MyMenuCallback, FlMenus.MenuDivider);
  n := menu.Add("&Edit/Radio 1", 0, {}, MyMenuCallback, FlMenus.MenuRadio);
  n := menu.Add("&Edit/Radio 2", 0, {}, MyMenuCallback, FlMenus.MenuRadio + FlMenus.MenuDivider);
  n := menu.Add("&Edit/Toggle 1", 0, {}, MyMenuCallback, FlMenus.MenuToggle);                       (* off *)
  n := menu.Add("&Edit/Toggle 2", 0, {}, MyMenuCallback, FlMenus.MenuToggle);                       (* off *)
  n := menu.Add("&Edit/Toggle 3", 0, {}, MyMenuCallback, FlMenus.MenuToggle + FlMenus.MenuValue);   (* on *)
  n := menu.Add("&Help/Google", 0, {}, MyMenuCallback, {});

  (* Toggle 2 turned on as the program runs *)
  item := menu.FindIndex("&Edit/Toggle 2");
  IF item >= 0 THEN menu.SetItemFlags(item, menu.ItemFlags(item) + FlMenus.MenuValue)
  ELSE Err.String("'Toggle 2' item not found?!"); Err.Ln
  END;

  win.End;
  win.Show;
  Fl.Run
END MenubarAdd.
