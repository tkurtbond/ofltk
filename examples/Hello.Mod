MODULE Hello; (* FLTK's test/hello.cxx in Oberon-2 *)

IMPORT Fl;

VAR
  window: Fl.Window;
  box: Fl.Box;

BEGIN
  NEW(window); Fl.OpenWindow(window, 340, 180, "Hello");
  NEW(box); Fl.OpenBox(box, 20, 40, 300, 100, "Hello, World!");
  box.SetBoxType(Fl.UpBox);
  box.SetLabelFont(Fl.Bold + Fl.Italic);
  box.SetLabelSize(36);
  box.SetLabelType(Fl.ShadowLabel);
  window.End;
  window.Show;
  Fl.Run
END Hello.
