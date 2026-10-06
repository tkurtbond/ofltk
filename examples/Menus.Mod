MODULE Menus; (* A menu bar, a choice and FLTK's dialogs *)

(* File/Open asks for a file and names it on the box; Edit/Color asks for
   the box's color; the choice sets the size of its label. The items'
   actions are procedures, given to Add with their shortcuts. *)

IMPORT Fl, FlMenus, FlDialogs;

VAR
  window: Fl.Window;
  box: Fl.Box;
  r, g, b: INTEGER;

PROCEDURE Open(w: Fl.Widget);
  VAR path: ARRAY 1024 OF CHAR;
BEGIN
  path := "";
  IF FlDialogs.ChooseFile("Open", "*.Mod", path, TRUE) THEN box.SetLabel(path) END
END Open;

PROCEDURE Color(w: Fl.Widget);
BEGIN
  IF FlDialogs.ChooseColor("Box color", r, g, b, FlDialogs.ColorByte) THEN
    box.SetColor(Fl.RGB(r, g, b)); box.Redraw
  END
END Color;

PROCEDURE Quit(w: Fl.Widget);
BEGIN
  IF FlDialogs.Choice("Quit?", "No", "Yes", "") = 1 THEN window.Hide END
END Quit;

PROCEDURE About(w: Fl.Widget);
BEGIN FlDialogs.Message("Menus: an ofltk example.")
END About;

(* The choice's own action, since its items have none. *)
PROCEDURE Size(w: Fl.Widget);
BEGIN box.SetLabelSize(12 + 6 * w(FlMenus.Choice).Value()); box.Redraw
END Size;

PROCEDURE Build;
  VAR bar: FlMenus.MenuBar; size: FlMenus.Choice; i: INTEGER;
BEGIN
  NEW(window); Fl.OpenWindow(window, 400, 250, "Menus");
  NEW(bar); FlMenus.OpenMenuBar(bar, 0, 0, 400, 25, "");
  i := bar.Add("&File/&Open...", ORD("o"), Fl.Command, Open, FlMenus.MenuDivider);
  i := bar.Add("&File/&Quit", ORD("q"), Fl.Command, Quit, {});
  i := bar.Add("&Edit/&Color...", 0, {}, Color, {});
  i := bar.Add("&Help/&About", 0, {}, About, {});
  NEW(size); FlMenus.OpenChoice(size, 60, 40, 100, 25, "Size");
  i := size.Add("Small", 0, {}, NIL, {}); i := size.Add("Medium", 0, {}, NIL, {});
  i := size.Add("Large", 0, {}, NIL, {});
  IF size.SetValue(0) THEN END;
  size.action := Size;
  NEW(box); Fl.OpenBox(box, 20, 80, 360, 150, "Pick a file");
  box.SetBoxType(Fl.DownBox); box.SetColor(Fl.White);
  window.End; window.SetResizable(box)
END Build;

BEGIN
  r := 255; g := 255; b := 255;
  Build; window.Show; Fl.Run
END Menus.
