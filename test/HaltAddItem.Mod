MODULE HaltAddItem; (* An item the program made, added twice: halts with Fl.OpenedTwice *)

IMPORT Fl, FlBrowsers;

VAR
  win: Fl.Window;
  t: FlBrowsers.Tree;
  i: FlBrowsers.TreeItem;
  ok: BOOLEAN;

BEGIN
  NEW(win); Fl.OpenWindow(win, 100, 100, "HaltAddItem");
  NEW(t); FlBrowsers.OpenTree(t, 0, 0, 100, 100, "");
  win.End;
  NEW(i);
  ok := t.AddItem("a", i, "a");
  ok := t.AddItem("b", i, "b")
END HaltAddItem.
