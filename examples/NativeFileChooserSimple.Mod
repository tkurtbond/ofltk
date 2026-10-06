MODULE NativeFileChooserSimple; (* FLTK's examples/nativefilechooser-simple.cxx: the desktop's file chooser, from a pop-up menu *)

IMPORT Fl, FlMenus, FlDialogs;

VAR
  win: Fl.Window;
  menu: FlMenus.MenuButton;
  chooser: FlDialogs.NativeFileChooser;
  i: INTEGER;
  ok: BOOLEAN;

PROCEDURE Quit(w: Fl.Widget);
BEGIN win.Hide
END Quit;

PROCEDURE Open(w: Fl.Widget);
  VAR name, s: ARRAY 1024 OF CHAR; i, j: INTEGER;
BEGIN
  IF chooser = NIL THEN
    NEW(chooser); FlDialogs.OpenNativeFileChooser(chooser, FlDialogs.BrowseFile);
    chooser.SetDirectory(".");  (* where to start *)
    chooser.SetPresetFile("NativeFileChooserSimple.Mod");
    name := "Oberon?*.Mod"; name[6] := 09X; chooser.SetFilter(name);
    chooser.SetTitle("Pick a file please..")
  END;
  IF chooser.Show() = FlDialogs.Chosen THEN
    chooser.FileName(0, name);
    chooser.SetPresetFile(name);
    s := "You chose: "; i := 11; j := 0;
    WHILE (name[j] # 0X) & (i < LEN(s) - 1) DO s[i] := name[j]; INC(i); INC(j) END;
    s[i] := 0X;
    FlDialogs.Message(s)
  END
END Open;

BEGIN
  ok := Fl.SetScheme("gtk+");
  NEW(win); Fl.OpenWindow(win, 640, 480, "Test Native File Chooser");
  win.SetTooltip("Use right-click for popup menu..");
  NEW(menu); FlMenus.OpenMenuButton(menu, 0, 20, 640, 480, "Popup Menu");
  menu.SetKind(FlMenus.Popup3);
  i := menu.Add("Open File Chooser..", 0, {}, Open, {});
  i := menu.Add("Quit", 0, {}, Quit, {});
  win.End;
  win.Show;
  Fl.Run;
  IF chooser # NIL THEN chooser.Close END
END NativeFileChooserSimple.
