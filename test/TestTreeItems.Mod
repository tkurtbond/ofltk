MODULE TestTreeItems; (* FlBrowsers.Tree: items the program makes, and widgets in items *)

IMPORT GC := GarbageCollectedHeap, Fl, FlDraw, FlButtons, FlBrowsers, Check, Probe;

TYPE
  (* An item that fills its label's place with red, and counts its draws. *)
  Red = POINTER TO RECORD (FlBrowsers.TreeItemDesc) tag, draws: INTEGER END;

VAR
  win: Fl.Window;
  t: FlBrowsers.Tree;
  r, r2, r3: Red;
  i, j, m, last: FlBrowsers.TreeItem;
  b, b2: FlButtons.Button;
  pressed, x, y, w, h: INTEGER;
  removeOwn: BOOLEAN;
  s: ARRAY 64 OF CHAR;
  ok: BOOLEAN;

PROCEDURE (r: Red) DrawContent*(render: BOOLEAN): INTEGER;
  VAR x, y, w, h: INTEGER;
BEGIN
  r.LabelXYWH(x, y, w, h);
  IF render THEN
    INC(r.draws);
    FlDraw.SetColor(Fl.Red); FlDraw.RectF(x, y, w, h)
  END;
  RETURN x + w
END DrawContent;

PROCEDURE Called(w: Fl.Widget);
BEGIN last := t.CallbackItem()
END Called;

(* The button's action; removes its item if removeOwn. *)
PROCEDURE Press(w: Fl.Widget);
BEGIN
  INC(pressed);
  IF removeOwn THEN i.Remove END
END Press;

(* Adds an item that only the tree holds. *)
PROCEDURE AddLost;
  VAR r: Red;
BEGIN NEW(r); r.tag := 42; ok := t.AddItem("lost", r, "lost")
END AddLost;

PROCEDURE Click(x, y: INTEGER);
  VAR ok: BOOLEAN;
BEGIN
  ok := Probe.Mouse(win, Fl.EvPush, x, y, Fl.LeftMouse, Fl.Button1, 0);
  ok := Probe.Mouse(win, Fl.EvRelease, x, y, Fl.LeftMouse, {}, 0)
END Click;

PROCEDURE NewButton(): FlButtons.Button;
  VAR b: FlButtons.Button;
BEGIN NEW(b); FlButtons.OpenButton(b, 0, 0, 60, 20, "b"); b.action := Press; RETURN b
END NewButton;

BEGIN
  NEW(win); Fl.OpenWindow(win, 300, 300, "TestTreeItems");
  NEW(t); FlBrowsers.OpenTree(t, 0, 0, 300, 300, "");
  t.SetShowRoot(FALSE); t.action := Called;
  win.End;

  (* Items the program makes *)
  NEW(r); r.tag := 1;
  Check.Check(t.AddItem("m/red", r, "red") & r.IsLive(), "AddItem");
  i := t.Find("m/red");
  m := r.Parent();
  Check.Check((i = r) & (m.Children() = 1), "the tree's reference to the item is the object itself");
  r.GetLabel(s);
  Check.Check(s = "red", "labelled as given");
  NEW(r2);
  Check.Check(~t.AddItem("", r2, "x") & ~r2.IsLive(), "AddItem of an empty path adds nothing");
  Check.Check(t.AddItem("m/red", r2, "r2") & (r2.Parent() = r) & (r.Children() = 1),
    "AddItem of a whole path there already adds under its item, as FLTK does");
  r2.Remove;
  Check.Check(~r2.IsLive() & (r.Children() = 0), "Remove of the program's item");

  AddLost; GC.Collect;
  i := t.Find("lost");
  Check.Check((i # NIL) & (i IS Red) & (i(Red).tag = 42), "an item only the tree holds is kept from the collector");
  i.Remove;

  i := t.Add("m/two"); j := t.Add("m/three");
  NEW(r3); i.Replace(r3, "new");
  Check.Check(~i.IsLive() & r3.IsLive() & (t.Find("m/new") = r3) & (m.Child(1) = r3)
    & FlBrowsers.Same(r3.Next(), j), "Replace puts the item in the old one's place");

  r.draws := 0;
  ok := Probe.Capture(t);
  r.LabelXYWH(x, y, w, h);
  Check.Check((r.draws > 0) & (w > 0) & (h > 0) & (Probe.Pixel(x + w DIV 2, y + h DIV 2) = Fl.RGB(255, 0, 0)),
    "DrawContent draws the item, in its label's place");
  i := t.Find("m/three"); i.LabelXYWH(x, y, w, h);
  Check.Check((w > 0) & (Probe.Pixel(x + w DIV 2, y + h DIV 2) # Fl.RGB(255, 0, 0)), "and FLTK's items as FLTK does");
  Probe.Release;
  Check.Check((r.DrawFgColor() = t.ItemLabelColor()) & (r.DrawBgColor() = t.Color()),
    "DrawFgColor and DrawBgColor: the label's, and the tree's, unselected");

  r.LabelXYWH(x, y, w, h);
  Click(x + 2, y + 2);
  Check.Check((last = r) & (last IS Red) & r.IsSelected(), "a click calls back with the object itself");
  Check.Check(r.DrawBgColor() = t.SelectionColor(), "DrawBgColor, selected: the tree's selection color");

  (* Widgets in items *)
  t.SetItemDrawMode(FlBrowsers.ItemDrawLabelAndWidget + FlBrowsers.ItemHeightFromWidget);
  t.SetWidgetMarginLeft(12);
  Check.Check((t.ItemDrawMode() = FlBrowsers.ItemDrawLabelAndWidget + FlBrowsers.ItemHeightFromWidget)
    & (t.WidgetMarginLeft() = 12), "ItemDrawMode and WidgetMarginLeft");
  i := t.Add("w/one");
  b := NewButton(); i.SetWidget(b);
  Check.Check((i.Widget() = b) & (b.Parent() = NIL) & (win.Find(b) = -1), "SetWidget: the tree's child, no group");
  ok := Probe.Capture(t); Probe.Release;
  (* The label's place runs to the tree's right edge; the widget is in
     it, after the label's text and the margin. *)
  i.LabelXYWH(x, y, w, h);
  Check.Check((b.X() > x + 12) & (b.X() + b.W() < x + w) & (b.Y() = y), "the tree puts the widget beside the label");
  pressed := 0;
  Click(b.X() + 5, b.Y() + 5);
  Check.Check(pressed = 1, "and it takes clicks");
  i.SetWidget(NIL);
  Check.Check((i.Widget() = NIL) & b.IsOpen() & (b.Parent() = NIL), "SetWidget NIL: the widget leaves, still open");
  b.Delete;

  b := NewButton(); i.SetWidget(b);
  j := t.Add("w/two"); j.SetWidget(b);
  Check.Check((i.Widget() = NIL) & (j.Widget() = b), "a widget given to another item leaves the first");
  b.Delete;
  Check.Check(j.Widget() = NIL, "a widget deleted leaves its item");
  ok := Probe.Capture(t); Probe.Release;
  b := NewButton(); j.SetWidget(b); win.Add(b);
  Check.Check((j.Widget() = NIL) & (b.Parent() = win), "and one added to another group");
  b.Delete;

  b := NewButton(); j.SetWidget(b); b2 := NewButton(); i.SetWidget(b2);
  ok := Probe.Capture(t); Probe.Release;
  x := b.X(); y := b.Y();
  j.Remove;
  Check.Check(~b.IsOpen(), "a widget is deleted with its item");
  pressed := 0;
  Click(x + 5, y + 5);
  Check.Check(pressed = 0, "and takes no more clicks where it was");

  (* i, with b2, removed by b2's own action *)
  removeOwn := TRUE; pressed := 0;
  ok := Probe.Capture(t); Probe.Release;
  Click(b2.X() + 5, b2.Y() + 5);
  Check.Check((pressed = 1) & ~i.IsLive() & b2.IsOpen(), "an item removed in its widget's callback");
  ok := Fl.Check();
  Check.Check(~b2.IsOpen(), "the widget deleted at the next Check");
  removeOwn := FALSE;

  i := t.Add("w/three"); b := NewButton(); i.SetWidget(b);
  t.Clear;
  Check.Check(~b.IsOpen() & ~r.IsLive() & ~r3.IsLive(), "Clear deletes the items' widgets, and the program's items");

  NEW(r); ok := t.AddItem("again", r, "again"); b := NewButton(); r.SetWidget(b);
  win.Delete;
  Check.Check(~r.IsLive() & ~b.IsOpen() & (Fl.OpenWidgets() = 0), "all deleted with the tree");
  Check.Summary
END TestTreeItems.
