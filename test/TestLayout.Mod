MODULE TestLayout; (* FlLayout: where flex, grid, pack, scroll, tabs, wizard and tile put children *)

(* Layouts are computed by their Layout methods, or by drawing them into
   an image (Probe.Capture), as FLTK does before it shows them; the window
   is never shown. *)

IMPORT Fl, FlLayout, FlValuators, Check, Probe;

VAR
  win: Fl.Window;
  flex, row: FlLayout.Flex;
  grid: FlLayout.Grid;
  pack: FlLayout.Pack;
  scroll: FlLayout.Scroll;
  tabs: FlLayout.Tabs;
  wizard: FlLayout.Wizard;
  tile: FlLayout.Tile;
  spinner: FlValuators.Spinner;
  a, b, c, d, content, p1, p2, left, right: Fl.Box;
  g1, g2: Fl.Group;
  w1, w2, w3: Fl.Box;
  l, t, r, bo, rg, cg: INTEGER;

PROCEDURE NewBox(VAR box: Fl.Box; x, y, w, h: INTEGER);
BEGIN NEW(box); Fl.OpenBox(box, x, y, w, h, "")
END NewBox;

PROCEDURE Is(w: Fl.Widget; x, y, width, height: INTEGER): BOOLEAN;
BEGIN RETURN (w.X() = x) & (w.Y() = y) & (w.W() = width) & (w.H() = height)
END Is;

BEGIN
  NEW(win); Fl.OpenWindow(win, 600, 600, "TestLayout");

  (* a flex column: 300 high, one child fixed at 50 *)
  NEW(flex); FlLayout.OpenFlex(flex, 0, 0, 100, 300, "");
  NewBox(a, 0, 0, 0, 0); NewBox(b, 0, 0, 0, 0); NewBox(c, 0, 0, 0, 0);
  flex.End;
  flex.Margins(l, t, r, bo);
  Check.Check((flex.Gap() = 0) & (l = 0) & (t = 0) & (r = 0) & (bo = 0),
    "a flex has no gap or margins to start with");
  flex.SetFixed(b, 50);
  flex.Layout;
  Check.Check((flex.Kind() = FlLayout.Column) & flex.Fixed(b) & ~flex.Fixed(a),
    "a flex is a column to start with; Fixed");
  Check.Check(Is(a, 0, 0, 100, 125) & Is(b, 0, 125, 100, 50) & Is(c, 0, 175, 100, 125),
    "its children share the height left by the fixed one");
  flex.SetGap(10); flex.SetMargins(5, 5, 5, 5); flex.Layout;
  flex.Margins(l, t, r, bo);
  Check.Check((flex.Gap() = 10) & (l = 5) & (bo = 5) & Is(a, 5, 5, 90, 110) & Is(b, 5, 125, 90, 50),
    "gap and margins");

  (* a flex row, laid out by drawing it *)
  NEW(row); FlLayout.OpenFlex(row, 100, 0, 300, 50, "");
  row.SetKind(FlLayout.Row);
  NewBox(d, 0, 0, 0, 0); NewBox(content, 0, 0, 0, 0);
  row.End;
  Check.Check(Probe.Capture(row) & (row.Kind() = FlLayout.Row)
    & Is(d, 100, 0, 150, 50) & Is(content, 250, 0, 150, 50),
    "a flex row, laid out when drawn after End");
  row.Delete;

  (* a grid, 2 by 2 *)
  NEW(grid); FlLayout.OpenGrid(grid, 0, 300, 200, 100, "");
  NewBox(w1, 0, 0, 0, 0); NewBox(w2, 0, 0, 0, 0); NewBox(w3, 0, 0, 0, 0);
  grid.End;
  grid.SetLayout(2, 2);
  grid.Place(w1, 0, 0, FlLayout.GridFill);
  grid.Place(w2, 0, 1, FlLayout.GridFill);
  grid.PlaceSpan(w3, 1, 0, 1, 2, FlLayout.GridFill);
  grid.Layout;
  Check.Check((grid.Rows() = 2) & (grid.Cols() = 2), "SetLayout gives rows and columns");
  Check.Check(Is(w1, 0, 300, 100, 50) & Is(w2, 100, 300, 100, 50) & Is(w3, 0, 350, 200, 50),
    "each child fills its cell; one spans the second row");
  Check.Check((grid.ColWeight(0) = 50) & (grid.ColGap(0) = -1) & (grid.ColWidth(0) = 0),
    "a column's weight starts at 50, its gap at the grid's (-1), its width at 0");
  grid.SetColWeight(0, 0); grid.SetColWidth(0, 40); grid.SetGap(0, 10); grid.Layout;
  grid.Gap(rg, cg);
  Check.Check((cg = 10) & (grid.ComputedColWidth(0) = 40) & (grid.ComputedColWidth(1) = 150)
    & Is(w2, 50, 300, 150, 50), "a column of fixed width, with a gap, leaves the rest to the other");
  grid.SetMargins(1, 2, 3, 4); grid.Margins(l, t, r, bo);
  Check.Check((l = 1) & (t = 2) & (r = 3) & (bo = 4), "a grid's margins");
  grid.SetRowHeight(1, 30); grid.SetRowWeight(1, 0);
  Check.Check((grid.RowHeight(1) = 30) & (grid.RowWeight(1) = 0), "a row's height and weight");
  grid.Place(w1, 1, 1, FlLayout.GridCenter);
  Check.Check(grid.Children() = 3, "placing a child again moves it, keeping it a child");

  (* a pack: children at their own heights, spaced *)
  NEW(pack); FlLayout.OpenPack(pack, 200, 300, 100, 200, "");
  NewBox(p1, 0, 0, 100, 20); NewBox(p2, 0, 0, 100, 30);
  pack.End;
  pack.SetSpacing(5);
  (* Fl_Pack sets its own size as it draws, so the capture is the size
     the pack was, not the size it is. *)
  IF Probe.Capture(pack) THEN END;
  Check.Check((pack.Kind() = FlLayout.PackVertical) & (pack.Spacing() = 5)
    & (p1.Y() = 300) & (p2.Y() = 325) & (p2.H() = 30) & (pack.H() = 55),
    "a pack stacks its children, spaced, when drawn, and fits itself to them");
  pack.SetResizable(p2); pack.Clear;
  Check.Check((pack.Children() = 0) & (pack.Resizable() = NIL) & ~p1.IsOpen(),
    "Clear deletes a pack's children and leaves it no resizable, as Fl_Pack::clear does");

  (* a scroll: its scrollbars are children FLTK made *)
  NEW(scroll); FlLayout.OpenScroll(scroll, 300, 0, 100, 100, "");
  NewBox(content, 300, 0, 300, 300);
  scroll.End;
  Check.Check((scroll.Children() = 3) & (scroll.Kind() = FlLayout.ScrollBoth),
    "a scroll has its content and two scrollbars, both shown when needed");
  Check.Check(scroll.ScrollbarSize() = 0, "a scroll's scrollbar size is 0, Fl::scrollbar_size(), to start with");
  scroll.ScrollTo(20, 50);
  Check.Check((scroll.XPosition() = 20) & (scroll.YPosition() = 50) & (content.Y() = -50),
    "ScrollTo moves the content");
  scroll.Clear;
  Check.Check((scroll.Children() = 2) & ~content.IsOpen(), "Clear deletes the content, not the scrollbars");
  Check.Check(Probe.Capture(scroll), "and the scroll still draws");

  (* tabs *)
  NEW(tabs); FlLayout.OpenTabs(tabs, 300, 100, 200, 150, "");
  NEW(g1); Fl.OpenGroup(g1, 300, 125, 200, 125, "One"); g1.End;
  NEW(g2); Fl.OpenGroup(g2, 300, 125, 200, 125, "Two"); g2.End;
  tabs.End;
  Check.Check(tabs.Value() = g1, "the first tab is shown to start with");
  tabs.SetValue(g2);
  Check.Check((tabs.Value() = g2) & g2.Visible() & ~g1.Visible(), "SetValue shows another, hiding the first");
  tabs.ClientArea(l, t, r, bo);
  Check.Check((l = 300) & (t > 100) & (r = 200) & (t + bo = 250), "ClientArea is below the tabs");
  tabs.SetTabAlign(Fl.AlignLeft);
  Check.Check(tabs.TabAlign() = Fl.AlignLeft, "TabAlign");

  (* a wizard *)
  NEW(wizard); FlLayout.OpenWizard(wizard, 300, 300, 100, 100, "");
  NewBox(w1, 300, 300, 100, 100); NewBox(w2, 300, 300, 100, 100); NewBox(w3, 300, 300, 100, 100);
  wizard.End;
  Check.Check(wizard.Value() = w1, "a wizard shows its first page");
  wizard.Next; wizard.Next; wizard.Next;
  Check.Check(wizard.Value() = w3, "Next goes on to the last, and stays there");
  wizard.Prev;
  Check.Check(wizard.Value() = w2, "Prev goes back");
  wizard.SetValue(w1);
  Check.Check((wizard.Value() = w1) & w1.Visible() & ~w2.Visible(), "SetValue");

  (* a tile *)
  NEW(tile); FlLayout.OpenTile(tile, 0, 450, 300, 100, "");
  NewBox(left, 0, 450, 150, 100); NewBox(right, 150, 450, 150, 100);
  tile.End;
  tile.MoveIntersection(150, 450, 100, 450);
  Check.Check(Is(left, 0, 450, 100, 100) & Is(right, 100, 450, 200, 100),
    "MoveIntersection moves the border, resizing both sides");
  tile.SizeRange(left, 80, 50, MAX(INTEGER), MAX(INTEGER));
  tile.MoveIntersection(100, 450, 20, 450);
  Check.Check(left.W() = 80, "a size range set after a move stops the next one");

  (* a group with members FLTK made: a spinner *)
  NEW(spinner); FlValuators.OpenSpinner(spinner, 450, 450, 100, 25, "");
  spinner.End;
  spinner.Clear;
  Check.Check((spinner.Children() = 3) & Probe.Capture(spinner), "Clear leaves a spinner's own parts");

  win.End;
  Probe.Release;
  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestLayout.
