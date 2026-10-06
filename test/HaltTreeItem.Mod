MODULE HaltTreeItem; (* An item removed from its tree halts with Fl.ClosedResource, 73 *)
IMPORT FlBrowsers;
VAR t: FlBrowsers.Tree; a, b: FlBrowsers.TreeItem; s: ARRAY 16 OF CHAR;
BEGIN
  NEW(t); FlBrowsers.OpenTree(t, 0, 0, 10, 10, "");
  b := t.Add("a/b"); a := t.Find("a");
  a.Remove;
  b.GetLabel(s)
END HaltTreeItem.
