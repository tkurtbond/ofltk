MODULE HaltMenuItem; (* A menu index that names the end of a submenu halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlMenus;
VAR m: FlMenus.MenuBar; i: INTEGER;
BEGIN
  NEW(m); FlMenus.OpenMenuBar(m, 0, 0, 10, 10, "");
  i := m.Add("File/Open", 0, {}, NIL, {});
  m.Remove(2)
END HaltMenuItem.
