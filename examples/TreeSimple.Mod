MODULE TreeSimple; (* FLTK's examples/tree-simple.cxx: a tree, its selections written to standard error *)

IMPORT Err, Fl, FlBrowsers;

TYPE
  Tree = POINTER TO RECORD (FlBrowsers.TreeDesc) END;

VAR
  win: Fl.DoubleWindow;
  tree: Tree;
  item: FlBrowsers.TreeItem;
  ok: BOOLEAN;

PROCEDURE (t: Tree) Callback*;
  VAR item: FlBrowsers.TreeItem; label, path: ARRAY 256 OF CHAR;
BEGIN
  item := t.CallbackItem();
  IF (item # NIL) & (t.CallbackReason() = FlBrowsers.ReasonSelected) THEN
    item.GetLabel(label);
    IF ~item.Path(path) THEN path := "" END;
    Err.String("TreeCallback: Item selected='"); Err.String(label);
    Err.String("', Full pathname='"); Err.String(path); Err.String("'"); Err.Ln
  END
END Callback;

PROCEDURE Add(path: ARRAY OF CHAR);
BEGIN item := tree.Add(path)
END Add;

BEGIN
  ok := Fl.SetScheme("gtk+");
  NEW(win); Fl.OpenDoubleWindow(win, 250, 400, "Simple Tree");
  NEW(tree); FlBrowsers.OpenTree(tree, 10, 10, 230, 380, "");
  tree.SetShowRoot(FALSE);
  Add("Flintstones/Fred"); Add("Flintstones/Wilma"); Add("Flintstones/Pebbles");
  Add("Simpsons/Homer"); Add("Simpsons/Marge"); Add("Simpsons/Bart"); Add("Simpsons/Lisa");
  (* a backslash keeps the slash after it in the name *)
  Add("Pathnames/\/bin"); Add("Pathnames/\/usr\/sbin");
  Add("Pathnames/C:\\Program Files"); Add("Pathnames/C:\\Documents and Settings");
  item := tree.Find("Simpsons"); item.Close;
  item := tree.Find("Pathnames"); item.Close;
  win.End;
  win.SetResizable(win);
  win.Show;
  Fl.Run
END TreeSimple.
