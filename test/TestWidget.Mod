MODULE TestWidget; (* Widget, group and window properties; colors and schemes *)

(* Each property set reads back as set, through FLTK. Drawing them is
   tested by pixels in Phase 2. *)

IMPORT Fl, Check;

VAR
  win: Fl.Window;
  g: Fl.Group;
  a, b, c, d: Fl.Box;
  s: ARRAY 64 OF CHAR;
  r, gr, bl: INTEGER;
  shown: BOOLEAN;

BEGIN
  NEW(win); Fl.OpenWindow(win, 300, 200, "TestWidget");
  NEW(g); Fl.OpenGroup(g, 10, 10, 200, 150, "g");
  NEW(a); Fl.OpenBox(a, 20, 20, 50, 20, "a");
  NEW(b); Fl.OpenBox(b, 20, 50, 50, 20, "b");
  g.End;
  NEW(c); Fl.OpenBox(c, 220, 20, 50, 20, "c");
  win.End;

  (* the label's look *)
  a.SetBoxType(Fl.RoundUpBox); a.SetLabelFont(Fl.Times + Fl.BoldItalic);
  a.SetLabelSize(24); a.SetLabelColor(Fl.Blue); a.SetLabelType(Fl.EngravedLabel);
  Check.Check((a.BoxType() = Fl.RoundUpBox) & (a.LabelFont() = Fl.TimesBoldItalic)
    & (a.LabelSize() = 24) & (a.LabelColor() = Fl.Blue) & (a.LabelType() = Fl.EngravedLabel),
    "box type, label font, size, color and type read back");
  Check.Check((b.BoxType() = Fl.NoBox) & (b.LabelFont() = Fl.Helvetica)
    & (b.LabelSize() = Fl.NormalSize()) & (b.LabelType() = Fl.NormalLabel),
    "a box's defaults: no box, Helvetica, the normal size, a normal label");
  a.SetAlign(Fl.AlignTopLeft + Fl.AlignInside + Fl.AlignWrap);
  Check.Check(a.Align() = {0, 2, 4, 7}, "an alignment set reads back");
  a.SetColor(Fl.RGB(10, 20, 30)); a.SetSelectionColor(Fl.DarkRed);
  Check.Check((a.Color() = Fl.RGB(10, 20, 30)) & (a.SelectionColor() = Fl.DarkRed),
    "color and selection color, an RGB color and an index");
  a.SetWhen(Fl.WhenRelease + Fl.WhenChanged);
  Check.Check(a.When() = Fl.WhenRelease + Fl.WhenChanged, "when reads back");

  (* tooltips are copied *)
  s := "tip"; a.SetTooltip(s); s := "XXX"; a.GetTooltip(s);
  Check.Check(s = "tip", "a tooltip is copied");
  a.SetTooltip(""); a.GetTooltip(s);
  Check.Check(s = "", "an empty tooltip removes it");

  (* geometry *)
  a.Position(30, 25); a.Size(60, 22);
  Check.Check((a.X() = 30) & (a.Y() = 25) & (a.W() = 60) & (a.H() = 22),
    "Position and Size");
  a.Resize(20, 20, 50, 20);
  Check.Check((a.X() = 20) & (a.W() = 50), "Resize");

  (* activation and visibility through the group *)
  g.Deactivate;
  Check.Check(~g.Active() & a.Active() & ~a.ActiveR() & c.ActiveR(),
    "a deactivated group's child is active, but not active_r");
  g.Activate;
  Check.Check(a.ActiveR(), "and active_r again once the group is activated");
  win.Show; shown := Fl.Check();
  Check.Check(win.Shown() & a.VisibleR(), "a shown window's box is visible_r");
  g.Hide;
  Check.Check(a.Visible() & ~a.VisibleR(), "a hidden group's child: visible, not visible_r");
  g.Show;

  (* parents and children *)
  Check.Check((a.Parent() = g) & (g.Parent() = win) & (win.Parent() = NIL),
    "Parent finds each object");
  Check.Check((g.Find(b) = 1) & (g.Find(c) = -1) & (win.Find(c) = 1), "Find");
  g.Remove(a);
  Check.Check((g.Children() = 1) & (a.Parent() = NIL) & a.IsOpen(), "Remove keeps the widget");
  g.Insert(a, 0);
  Check.Check((g.Child(0) = a) & (g.Child(1) = b) & (a.Parent() = g), "Insert at 0");
  g.Add(c);
  Check.Check((g.Child(2) = c) & (win.Find(c) = -1) & (c.Parent() = g),
    "Add moves a widget from its group");
  win.SetResizable(g);
  Check.Check(win.Resizable() = g, "Resizable");
  win.SetResizable(NIL);
  Check.Check(win.Resizable() = NIL, "no resizable");

  (* Clear deletes, so closes, the children *)
  NEW(d); Fl.OpenBox(d, 0, 0, 10, 10, ""); g.Add(d);
  Check.Check((g.Children() = 4) & (Fl.OpenWidgets() = 6), "four children");
  g.Clear;
  Check.Check((g.Children() = 0) & ~a.IsOpen() & ~b.IsOpen() & ~c.IsOpen() & ~d.IsOpen()
    & (Fl.OpenWidgets() = 2), "Clear closes them");

  (* window modes *)
  win.SetNonModal;
  Check.Check(~win.Modal(), "non-modal isn't modal");
  win.SetModal;
  Check.Check(win.Modal(), "modal");

  (* a window's title is its label *)
  win.SetLabel("retitled"); win.GetLabel(s);
  Check.Check(s = "retitled", "a shown window's title");

  (* colors *)
  Fl.GetRGB(Fl.RGB(1, 2, 3), r, gr, bl);
  Check.Check((r = 1) & (gr = 2) & (bl = 3), "GetRGB of an RGB color");
  Fl.SetIndexColor(Fl.FreeColor, Fl.RGB(200, 100, 50));
  Fl.GetRGB(Fl.FreeColor, r, gr, bl);
  Check.Check((r = 200) & (gr = 100) & (bl = 50), "SetIndexColor, and GetRGB of an index");
  Check.Check(Fl.Contrast(Fl.Black, Fl.Black) = Fl.White, "black on black contrasts to white");
  Fl.GetRGB(Fl.ColorAverage(Fl.RGB(200, 0, 0), Fl.RGB(0, 0, 100), 0.5D0), r, gr, bl);
  Check.Check((r = 100) & (gr = 0) & (bl = 50), "ColorAverage");

  (* schemes and the normal size *)
  Check.Check(Fl.SetScheme("gtk+"), "a known scheme");
  Fl.GetScheme(s);
  Check.Check(s = "gtk+", "reads back");
  Fl.SetNormalSize(18);
  NEW(d); Fl.OpenBox(d, 0, 0, 10, 10, "");
  Check.Check(d.LabelSize() = 18, "a box opened after SetNormalSize gets the size");
  d.Delete; Fl.SetNormalSize(14);

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "all deleted");
  Check.Summary
END TestWidget.
