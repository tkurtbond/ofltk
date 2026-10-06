MODULE TabsSimple; (* FLTK's examples/tabs-simple.cxx: two tabs of colored buttons *)

IMPORT Fl, FlButtons, FlLayout;

VAR
  win: Fl.Window;
  tabs: FlLayout.Tabs;
  aaa, bbb: Fl.Group;
  ok: BOOLEAN;

PROCEDURE Button(x, y: INTEGER; label: ARRAY OF CHAR; color: INTEGER);
  VAR b: FlButtons.Button;
BEGIN NEW(b); FlButtons.OpenButton(b, x, y, 90, 25, label); b.SetColor(color)
END Button;

BEGIN
  ok := Fl.SetScheme("gtk+");
  NEW(win); Fl.OpenWindow(win, 500, 200, "Tabs Example");
  NEW(tabs); FlLayout.OpenTabs(tabs, 10, 10, 500 - 20, 200 - 20, "");
  NEW(aaa); Fl.OpenGroup(aaa, 10, 35, 500 - 20, 200 - 45, "Aaa");
  Button(50, 60, "Button A1", 88 + 1); Button(50, 90, "Button A2", 88 + 2);
  Button(50, 120, "Button A3", 88 + 3);
  aaa.End;
  NEW(bbb); Fl.OpenGroup(bbb, 10, 35, 500 - 10, 200 - 35, "Bbb");
  Button(50, 60, "Button B1", 88 + 1); Button(150, 60, "Button B2", 88 + 3);
  Button(250, 60, "Button B3", 88 + 5); Button(50, 90, "Button B4", 88 + 2);
  Button(150, 90, "Button B5", 88 + 4); Button(250, 90, "Button B6", 88 + 6);
  bbb.End;
  tabs.End;
  win.End;
  win.Show;
  Fl.Run
END TabsSimple.
