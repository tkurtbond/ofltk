MODULE HaltBrowserLine; (* A browser line past the last halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlBrowsers;
VAR b: FlBrowsers.Browser;
BEGIN
  NEW(b); FlBrowsers.OpenBrowser(b, 0, 0, 10, 10, "");
  b.Add("one");
  b.Remove(2)
END HaltBrowserLine.
