MODULE TestBrowsers; (* FlBrowsers: lines, selection by program and by mouse, files and check boxes *)

IMPORT Fl, FlBrowsers, Check, Probe;

VAR
  win: Fl.Window;
  b: FlBrowsers.Browser;
  hold: FlBrowsers.HoldBrowser;
  multi: FlBrowsers.MultiBrowser;
  files: FlBrowsers.FileBrowser;
  checks: FlBrowsers.CheckBrowser;
  calls, i, sink: INTEGER;
  s: ARRAY 64 OF CHAR;
  ok: BOOLEAN;

(* The first x, from 3, at which line 1 of b, drawn, isn't white; -1 if
   none is. *)
PROCEDURE Ink(b: FlBrowsers.Browser): INTEGER;
  VAR x, y, white: INTEGER;
BEGIN
  white := Fl.RGB(255, 255, 255);
  ASSERT(Probe.Capture(b));
  FOR x := 3 TO 150 DO
    FOR y := 4 TO 16 DO
      IF Probe.Pixel(x, y) # white THEN Probe.Release; RETURN x END
    END
  END;
  Probe.Release; RETURN -1
END Ink;

(* Sets f's filter from an array that dies with this frame. *)
PROCEDURE SetFilter(f: FlBrowsers.FileBrowser);
  VAR p: ARRAY 16 OF CHAR;
BEGIN p := "*.cpp"; f.SetFilter(p)
END SetFilter;

(* Sets b's first column width from an array that dies with this frame. *)
PROCEDURE SetWidths(b: FlBrowsers.Browser);
  VAR w: ARRAY 2 OF INTEGER;
BEGIN w[0] := 40; w[1] := 40; b.SetColumnWidths(w, 1)
END SetWidths;

(* Writes over the stack that SetFilter used. *)
PROCEDURE Clobber;
  VAR a: ARRAY 256 OF CHAR; i: INTEGER;
BEGIN
  FOR i := 0 TO 255 DO a[i] := "x" END;
  FOR i := 0 TO 255 DO sink := sink + ORD(a[i]) END
END Clobber;

PROCEDURE Count(w: Fl.Widget);
BEGIN INC(calls)
END Count;

PROCEDURE Is(b: FlBrowsers.Browser; line: INTEGER; text: ARRAY OF CHAR): BOOLEAN;
  VAR s: ARRAY 128 OF CHAR;
BEGIN b.GetText(line, s); RETURN s = text
END Is;

(* Clicks in win at x, y. *)
PROCEDURE Click(x, y: INTEGER);
  VAR ok: BOOLEAN;
BEGIN
  ok := Probe.Mouse(win, Fl.EvPush, x, y, Fl.LeftMouse, Fl.Button1, 0);
  ok := Probe.Mouse(win, Fl.EvRelease, x, y, Fl.LeftMouse, {}, 0)
END Click;

BEGIN
  NEW(win); Fl.OpenWindow(win, 400, 300, "TestBrowsers");

  NEW(b); FlBrowsers.OpenBrowser(b, 0, 0, 100, 100, "");
  Check.Check(b.Count() = 0, "a browser starts empty");
  b.Add("one"); b.Add("two"); b.Add("three");
  b.Insert(1, "zero"); b.Insert(5, "four");
  Check.Check((b.Count() = 5) & Is(b, 1, "zero") & Is(b, 3, "two") & Is(b, 5, "four"),
    "Add, and Insert before a line or after the last");
  b.Remove(1);
  Check.Check((b.Count() = 4) & Is(b, 1, "one"), "Remove");
  b.Move(4, 1);
  Check.Check(Is(b, 1, "two") & Is(b, 4, "one"), "Move");
  b.Swap(1, 4);
  Check.Check(Is(b, 1, "one") & Is(b, 4, "two"), "Swap");
  b.SetText(2, "THREE");
  Check.Check(Is(b, 2, "THREE"), "SetText");
  b.Sort(FlBrowsers.SortAscending);
  Check.Check(Is(b, 1, "THREE") & Is(b, 2, "four") & Is(b, 4, "two"), "Sort, by bytes");
  b.Sort(FlBrowsers.SortAscending + FlBrowsers.SortCaseInsensitive);
  Check.Check(Is(b, 1, "four") & Is(b, 3, "THREE"), "Sort, ignoring case");
  b.Sort(FlBrowsers.SortDescending);
  Check.Check(Is(b, 1, "two") & Is(b, 4, "THREE"), "Sort, descending");

  Check.Check(b.Value() = 0, "no line selected");
  Check.Check(b.Select(2, TRUE) & b.Selected(2) & (b.Value() = 2), "Select");
  Check.Check(~b.Select(2, TRUE), "Select returns FALSE when nothing changed");
  Check.Check(b.Deselect() & ~b.Selected(2) & ~b.Deselect(), "Deselect");

  b.HideLine(2);
  Check.Check(~b.LineVisible(2) & b.LineVisible(1) & (b.Count() = 4), "HideLine");
  b.ShowLine(2);
  Check.Check(b.LineVisible(2), "ShowLine");

  Check.Check((b.FormatChar() = "@") & (b.ColumnChar() = 9X), "the format and column characters");
  b.SetColumnChar("|");
  Check.Check(b.ColumnChar() = "|", "SetColumnChar");
  b.Clear; b.Add("|W");
  i := Ink(b);
  Check.Check((i > 0) & (i < 10), "with no column widths, the column character is drawn");
  SetWidths(b); Clobber;
  i := Ink(b);
  Check.Check((i >= 40) & (i < 50), "the column widths, copied: the second column at 40");

  b.SetTextSize(20);
  Check.Check(b.TextSize() = 20, "SetTextSize");
  b.SetScrollbars(FlBrowsers.ScrollbarVertical);
  Check.Check(b.Scrollbars() = FlBrowsers.ScrollbarVertical, "SetScrollbars");

  b.Clear;
  FOR i := 1 TO 50 DO b.Add("line") END;
  b.SetTopLine(20);
  Check.Check((b.TopLine() = 20) & b.Displayed(20) & ~b.Displayed(1), "SetTopLine");
  b.MakeVisible(1);
  Check.Check(b.Displayed(1), "MakeVisible");
  Check.Check(b.Load("Check.Mod") & (b.Count() = 36) & Is(b, 1, "MODULE Check; (* Shared ok/FAIL reporting for the test programs *)")
    & Is(b, 2, "") & Is(b, 36, ""), "Load: a line per newline, and one after the last");
  Check.Check(~b.Load("no such file") & (b.Count() = 0), "Load of a missing file");

  (* A hold browser, clicked *)
  NEW(hold); FlBrowsers.OpenHoldBrowser(hold, 100, 0, 150, 200, "");
  hold.action := Count;
  hold.Add("a"); hold.Add("b"); hold.Add("c");
  Click(110, 10);
  Check.Check(hold.Value() = 0, "a browser never drawn selects nothing when clicked (FLTK)");
  ok := Probe.Capture(hold);
  calls := 0;
  Click(110, 32);
  Check.Check((hold.Value() = 2) & hold.Selected(2) & (calls = 1), "a click selects a line and calls back");
  Click(110, 52);
  Check.Check((hold.Value() = 3) & ~hold.Selected(2) & (calls = 2), "and deselects the last");
  Click(110, 52);
  Check.Check((hold.Value() = 3) & (calls = 3), "WhenReleaseAlways: called back with no change");
  Click(110, 150);
  Check.Check((hold.Value() = 0) & ~hold.Selected(3), "a click below the lines deselects");

  (* A multi browser *)
  NEW(multi); FlBrowsers.OpenMultiBrowser(multi, 250, 0, 150, 100, "");
  multi.Add("a"); multi.Add("b"); multi.Add("c");
  ok := Probe.Capture(multi); Probe.Release;
  Click(260, 12);
  ok := Probe.Mouse(win, Fl.EvPush, 260, 52, Fl.LeftMouse, Fl.Button1 + Fl.Ctrl, 0);
  ok := Probe.Mouse(win, Fl.EvRelease, 260, 52, Fl.LeftMouse, Fl.Ctrl, 0);
  Check.Check(multi.Selected(1) & ~multi.Selected(2) & multi.Selected(3) & (multi.Value() = 3),
    "a multi browser: Ctrl-click adds a line");
  Click(260, 32);
  Check.Check(~multi.Selected(1) & multi.Selected(2) & ~multi.Selected(3), "a click selects one line");
  Check.Check(multi.Select(1, TRUE) & multi.Selected(2), "Select keeps the others in a multi browser");
  Check.Check(hold.Select(1, TRUE) & ~hold.Selected(3) & (hold.Value() = 1), "not in a hold browser");
  multi.Delete;

  (* A file browser *)
  NEW(files); FlBrowsers.OpenFileBrowser(files, 250, 0, 150, 100, "");
  Check.Check(files.FileType() = FlBrowsers.Files, "a file browser lists files");
  files.Filter(s);
  Check.Check(s = "*", "with the filter *");
  SetFilter(files); Clobber;
  files.Filter(s);
  Check.Check(s = "*.cpp", "SetFilter, copied");
  Check.Check(files.LoadDirectory(".") & (files.Count() = 3) & Is(files, 1, "../")
    & Is(files, 2, "CConstants.cpp") & Is(files, 3, "Probe.cpp"),
    "LoadDirectory: the directories, then the files matching");
  files.SetFileType(FlBrowsers.Directories);
  Check.Check(files.LoadDirectory(".") & (files.Count() = 1), "or the directories alone");
  Check.Check(~files.LoadDirectory("no such directory") & (files.Count() = 0), "a missing directory");
  files.SetTextSize(20);
  Check.Check((files.TextSize() = 20) & (files.IconSize() = 30), "SetTextSize sizes the icons too");
  files.SetIconSize(16);
  Check.Check(files.IconSize() = 16, "SetIconSize");

  (* A check browser *)
  NEW(checks); FlBrowsers.OpenCheckBrowser(checks, 0, 200, 150, 100, "");
  checks.action := Count;
  Check.Check((checks.Add("a", FALSE) = 1) & (checks.Add("b", TRUE) = 2) & (checks.Add("c", FALSE) = 3),
    "a check browser: Add returns the item's number");
  checks.GetText(2, s);
  Check.Check((checks.Count() = 3) & (checks.CheckedCount() = 1) & checks.Checked(2) & (s = "b"),
    "items, checked or not");
  checks.SetChecked(1, TRUE);
  Check.Check(checks.Checked(1) & (checks.CheckedCount() = 2), "SetChecked");
  checks.CheckNone;
  Check.Check(checks.CheckedCount() = 0, "CheckNone");
  checks.CheckAll;
  Check.Check(checks.CheckedCount() = 3, "CheckAll");
  checks.Remove(1);
  checks.GetText(1, s);
  Check.Check((checks.Count() = 2) & (s = "b"), "Remove");
  checks.CheckNone;
  ok := Probe.Capture(checks); Probe.Release;
  calls := 0;
  Click(10, 226);
  Check.Check(checks.Checked(2) & ~checks.Checked(1) & (checks.Value() = 2) & (calls = 0),
    "a click checks an item, not calling back (FLTK's WhenNever)");
  checks.SetWhen(Fl.WhenChanged);
  Click(10, 226);
  Check.Check(~checks.Checked(2) & (calls = 1), "a second unchecks it; WhenChanged calls back");
  Click(10, 210);
  Check.Check(checks.Checked(1) & (checks.Value() = 1) & (calls = 2), "another item");
  checks.Clear;
  Check.Check(checks.Count() = 0, "Clear");

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestBrowsers.
