MODULE BrowserSimple; (* FLTK's examples/browser-simple.cxx: a hold browser and a multi browser, their picks written out *)

IMPORT Out, Fl, FlBrowsers;

TYPE
  Hold = POINTER TO RECORD (FlBrowsers.HoldBrowserDesc) END;
  Multi = POINTER TO RECORD (FlBrowsers.MultiBrowserDesc) END;

VAR
  win: Fl.DoubleWindow;
  hold: Hold;
  multi: Multi;
  ok: BOOLEAN;

PROCEDURE (b: Hold) Callback*;
  VAR line: INTEGER; text: ARRAY 256 OF CHAR;
BEGIN
  line := b.Value();
  IF line > 0 THEN b.GetText(line, text) ELSE text := "" END;
  Out.String("[hold browser] item "); Out.Int(line, 0); Out.String(" picked: ");
  Out.String(text); Out.Ln
END Callback;

PROCEDURE (b: Multi) Callback*;
  VAR t: INTEGER; text: ARRAY 256 OF CHAR;
BEGIN
  FOR t := 1 TO b.Count() DO
    IF b.Selected(t) THEN
      b.GetText(t, text);
      Out.String("[multi browser] item "); Out.Int(t, 0); Out.String(" selected: ");
      Out.String(text); Out.Ln
    END
  END;
  Out.Ln
END Callback;

BEGIN
  ok := Fl.SetScheme("gtk+");
  NEW(win); Fl.OpenDoubleWindow(win, 250, 220, "Simple Browser");
  NEW(hold); FlBrowsers.OpenHoldBrowser(hold, 10, 10, 250 - 20, 80, "Hold");
  hold.Add("One"); hold.Add("Two"); hold.Add("Three"); hold.Add("Four");
  ok := hold.Select(1, TRUE);
  NEW(multi); FlBrowsers.OpenMultiBrowser(multi, 10, 120, 250 - 20, 80, "Multi");
  multi.Add("Aaa"); multi.Add("Bbb"); multi.Add("Ccc"); multi.Add("Ddd");
  ok := multi.Select(1, TRUE); ok := multi.Select(2, TRUE);
  win.End;
  win.SetResizable(win);
  win.Show;
  Fl.Run
END BrowserSimple.
