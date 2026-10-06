MODULE TestTree; (* FlBrowsers.Tree: items, paths, removal, selection by program and by mouse *)

IMPORT Fl, FlBrowsers, Check, Probe;

VAR
  win: Fl.Window;
  t: FlBrowsers.Tree;
  calls, reason, n: INTEGER;
  removeInCallback: BOOLEAN;
  root, a, b, c, d, e, i, j, last: FlBrowsers.TreeItem;
  s: ARRAY 64 OF CHAR;
  ok: BOOLEAN;

(* Counts the calls, and keeps the last item and reason; removes the item
   if removeInCallback. *)
PROCEDURE Called(w: Fl.Widget);
BEGIN
  INC(calls); last := t.CallbackItem(); reason := t.CallbackReason();
  IF removeInCallback & (reason = FlBrowsers.ReasonSelected) THEN
    last.Remove;
    Check.Check(t.CallbackItem() = NIL, "an item removed in the callback is no longer CallbackItem")
  END
END Called;

(* Clicks in the tree, which is at win's top left: the item in row is
   drawn from y = 5 + 20 * row, row 0 the first one shown. *)
PROCEDURE Click(row: INTEGER; state: SET);
  VAR ok: BOOLEAN; y: INTEGER;
BEGIN
  y := 15 + 20 * row;
  ok := Probe.Mouse(win, Fl.EvPush, 60, y, Fl.LeftMouse, Fl.Button1 + state, 0);
  ok := Probe.Mouse(win, Fl.EvRelease, 60, y, Fl.LeftMouse, state, 0)
END Click;

PROCEDURE Is(i: FlBrowsers.TreeItem; label: ARRAY OF CHAR): BOOLEAN;
  VAR s: ARRAY 64 OF CHAR;
BEGIN
  IF i = NIL THEN RETURN FALSE END;
  i.GetLabel(s); RETURN s = label
END Is;

PROCEDURE PathIs(i: FlBrowsers.TreeItem; path: ARRAY OF CHAR): BOOLEAN;
  VAR s: ARRAY 64 OF CHAR;
BEGIN RETURN i.Path(s) & (s = path)
END PathIs;

BEGIN
  NEW(win); Fl.OpenWindow(win, 300, 300, "TestTree");
  NEW(t); FlBrowsers.OpenTree(t, 0, 0, 300, 300, "");
  t.action := Called;

  (* Items and paths *)
  root := t.Root();
  Check.Check(Is(root, "ROOT") & root.IsRoot() & (root.Depth() = 0) & (root.Parent() = NIL)
    & (root.Children() = 0), "a tree starts with its root");
  b := t.Add("a/b");
  a := t.Find("a");
  Check.Check(Is(a, "a") & (a.Depth() = 1) & FlBrowsers.Same(a.Parent(), root)
    & FlBrowsers.Same(b.Parent(), a) & (b.Depth() = 2), "Add makes the path's items");
  Check.Check(FlBrowsers.Same(t.Find("a/b"), b) & ~FlBrowsers.Same(a, b) & (t.Find("a/x") = NIL)
    & (t.Find("b") = NIL), "Find, and Same");
  Check.Check(PathIs(b, "ROOT/a/b"), "Path, with the root shown");
  t.SetShowRoot(FALSE);
  Check.Check(~t.ShowRoot() & PathIs(b, "a/b"), "and without");
  c := t.Add("c"); d := t.Add("d"); e := t.Add("e");
  Check.Check((root.Children() = 4) & FlBrowsers.Same(root.Child(0), a) & FlBrowsers.Same(root.Child(3), e),
    "Children and Child");
  Check.Check(FlBrowsers.Same(t.First(), root) & FlBrowsers.Same(root.Next(), a) & FlBrowsers.Same(a.Next(), b)
    & FlBrowsers.Same(b.Next(), c) & FlBrowsers.Same(t.Last(), e) & (e.Next() = NIL)
    & FlBrowsers.Same(c.Prev(), b), "Next and Prev go down the tree, children after their parent");
  i := a.Add("x/y");
  Check.Check(Is(i, "x/y") & (a.Children() = 2) & PathIs(i, "a/x\/y") & FlBrowsers.Same(t.Find("a/x\/y"), i),
    "a label with a slash is escaped in paths");
  i.Remove;
  i := a.Insert("first", 0);
  j := b.InsertAbove("above");
  Check.Check(Is(a.Child(0), "first") & Is(a.Child(1), "above") & FlBrowsers.Same(a.Child(2), b),
    "Insert and InsertAbove");
  Check.Check(root.InsertAbove("x") = NIL, "InsertAbove of the root");
  i := a.Child(1); i.Remove; i := a.Child(0); i.Remove;
  b.SetLabel("B");
  Check.Check(Is(b, "B") & FlBrowsers.Same(t.Find("a/B"), b), "SetLabel");
  b.SetLabel("b");

  t.SetSortOrder(FlBrowsers.TreeSortAscending);
  i := t.Add("s/m"); i := t.Add("s/z"); i := t.Add("s/a");
  i := t.Find("s");
  Check.Check(Is(i.Child(0), "a") & Is(i.Child(1), "m") & Is(i.Child(2), "z"), "SetSortOrder sorts items as added");
  i.Remove;
  t.SetSortOrder(FlBrowsers.TreeSortNone);

  (* Removal *)
  i := t.Add("r/s/t"); j := t.Find("r/s");
  n := 0; IF i.IsLive() THEN INC(n) END; IF j.IsLive() THEN INC(n) END;
  last := t.Find("r"); last.Remove;
  Check.Check((n = 2) & ~i.IsLive() & ~j.IsLive() & b.IsLive() & (t.Find("r") = NIL),
    "Remove: the item and its children are no longer live");
  (* The allocator is likely to give the new item the old one's memory,
     so the same pointer: its serial tells them apart. *)
  j := t.Add("r"); j.Remove;
  i := t.Add("r");
  Check.Check(~j.IsLive() & i.IsLive(), "an item added after another's removal: only the new one is live");
  i.Remove;
  i := a.Add("k1"); j := a.Add("k2");
  a.ClearChildren;
  Check.Check((a.Children() = 0) & ~i.IsLive() & ~j.IsLive() & a.IsLive(), "ClearChildren");
  b := a.Add("b");

  (* Open and close *)
  Check.Check(a.IsOpen() & b.IsVisible(), "items start open");
  a.Close;
  Check.Check(~a.IsOpen() & ~b.IsVisible() & a.IsVisible() & FlBrowsers.Same(a.NextVisible(), c),
    "Close hides the children");
  a.Open;
  Check.Check(a.IsOpen() & FlBrowsers.Same(a.NextVisible(), b), "Open");

  (* Selection by the program *)
  calls := 0;
  b.Select(TRUE); d.Select(TRUE);
  Check.Check(b.IsSelected() & d.IsSelected() & FlBrowsers.Same(t.FirstSelected(), b)
    & FlBrowsers.Same(b.NextSelected(), d) & (d.NextSelected() = NIL), "Select, whatever the mode");
  c.SelectOnly;
  Check.Check(c.IsSelected() & ~b.IsSelected() & ~d.IsSelected(), "SelectOnly");
  t.SelectAll;
  Check.Check(a.IsSelected() & e.IsSelected(), "SelectAll");
  t.DeselectAll;
  Check.Check((t.FirstSelected() = NIL) & (calls = 0), "DeselectAll; and nothing called back");
  b.Activate(FALSE);
  Check.Check(~b.IsActive(), "Activate");
  b.Activate(TRUE);
  b.SetLabelColor(Fl.Red); b.SetLabelSize(20);
  Check.Check((b.LabelColor() = Fl.Red) & (b.LabelSize() = 20), "an item's label color and size");
  b.SetLabelSize(t.ItemLabelSize());

  (* Selection by the user: rows are a, b, c, d, e from 0, the root hidden
     taking none. *)
  ok := Probe.Capture(t); Probe.Release;
  Click(1, {});
  Check.Check(b.IsSelected() & (calls = 1) & FlBrowsers.Same(last, b) & (reason = FlBrowsers.ReasonSelected),
    "a click selects an item, and calls back with it");
  Click(2, {});
  Check.Check(c.IsSelected() & ~b.IsSelected() & (calls = 3), "a click deselects the other");
  t.SetSelectMode(FlBrowsers.TreeSelectMulti);
  Click(1, {});
  Click(3, Fl.Shift);
  Check.Check(b.IsSelected() & c.IsSelected() & d.IsSelected() & ~e.IsSelected(), "Shift-click extends the selection");

  (* The last item clicked, b, removed with its parent: FLTK would keep it
     as the start of the next Shift-click (doc/fltk-issues.md, 41). Rows
     are now c, d, e. *)
  Click(1, {});
  a.Remove;
  ok := Probe.Capture(t); Probe.Release;
  t.DeselectAll;
  Click(0, Fl.Shift);
  Check.Check(c.IsSelected() & ~d.IsSelected() & ~e.IsSelected(),
    "a Shift-click after the last item clicked was removed selects one item");

  removeInCallback := TRUE; t.SetSelectMode(FlBrowsers.TreeSelectSingle); t.DeselectAll;
  Click(1, {});
  Check.Check(~d.IsLive() & (root.Children() = 2), "an item removed in its own callback");
  removeInCallback := FALSE;

  t.Clear;
  Check.Check((t.Root() = NIL) & ~root.IsLive() & ~c.IsLive(), "Clear removes every item, the root too");
  i := t.Add("again");
  Check.Check(Is(t.Root(), "ROOT") & Is(i, "again"), "Add after Clear makes a root again");
  root := t.Root();

  win.Delete;
  Check.Check(~root.IsLive() & (Fl.OpenWidgets() = 0), "an item of a deleted tree is not live");
  Check.Summary
END TestTree.
