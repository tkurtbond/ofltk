MODULE DraggableGroup; (* FLTK's examples/draggable-group.cxx: a group whose children are dragged with the right mouse button *)

(* A DraggableGroup's children can be dragged within its borders, with
   the right mouse button, so as not to clash with clicking a button.
   Groups can be nested, but only a group's own children are dragged.
   The child dragged is raised to the top (made the last child) while it
   is dragged, and put back in its place among the children after: so it
   can end up behind another, but the order the program gave is kept. *)

IMPORT OutStr, Fl, FlButtons;

TYPE
  DraggableGroup = POINTER TO RECORD (Fl.GroupDesc)
    xoff, yoff: INTEGER;    (* where in the child the drag started *)
    dragIndex: INTEGER;     (* the child's index before *)
    dragWidget: Fl.Widget   (* the child dragged, or NIL *)
  END;

  (* Clears the status line, after a button's message. *)
  ClearStatus = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  win: Fl.DoubleWindow;
  status: Fl.Box;
  clearStatus: ClearStatus;

PROCEDURE OpenDraggableGroup(g: DraggableGroup; x, y, w, h: INTEGER; label: ARRAY OF CHAR);
BEGIN
  Fl.OpenGroup(g, x, y, w, h, label);
  g.dragWidget := NIL;
  g.SetBoxType(Fl.UpBox)
END OpenDraggableGroup;

(* Raises q, one of g's children, to the top: makes it the last child,
   saving its index. Add takes it out of g first. *)
PROCEDURE (g: DraggableGroup) TopLevel(q: Fl.Widget);
BEGIN
  g.dragIndex := g.Find(q);
  g.Add(q)
END TopLevel;

(* EvPush, EvDrag and EvRelease drag a child, kept inside g's border;
   FLTK's group handles the rest. *)
PROCEDURE (g: DraggableGroup) Handle*(e: INTEGER): BOOLEAN;
  VAR below: Fl.Widget; nx, ny, bbx, bby: INTEGER; parent: Fl.Group;
BEGIN
  IF (e = Fl.EvPush) & (Fl.EventButton() = Fl.RightMouse) THEN
    below := Fl.BelowMouse();
    IF (below # NIL) & (below.Parent() = g) THEN
      g.dragWidget := below;
      g.xoff := Fl.EventX() - below.X();
      g.yoff := Fl.EventY() - below.Y();
      g.TopLevel(below);                     (* on top, to be seen *)
      g.Redraw;
      RETURN TRUE
    END
  ELSIF (e = Fl.EvDrag) & (g.dragWidget # NIL) THEN
    nx := Fl.EventX() - g.xoff;              (* the new place *)
    ny := Fl.EventY() - g.yoff;
    bbx := Fl.BoxDX(g.BoxType());            (* the border's width, left and right *)
    bby := Fl.BoxDY(g.BoxType());            (* top and bottom *)
    IF nx < g.X() + bbx THEN nx := g.X() + bbx
    ELSIF nx + g.dragWidget.W() > g.X() + g.W() - bbx THEN nx := g.X() + g.W() - g.dragWidget.W() - bbx
    END;
    IF ny < g.Y() + bby THEN ny := g.Y() + bby
    ELSIF ny + g.dragWidget.H() > g.Y() + g.H() - bby THEN ny := g.Y() + g.H() - g.dragWidget.H() - bby
    END;
    g.dragWidget.Position(nx, ny);
    g.Redraw;
    RETURN TRUE
  ELSIF (e = Fl.EvRelease) & (g.dragWidget # NIL) & (Fl.EventButton() = Fl.RightMouse) THEN
    g.Insert(g.dragWidget, g.dragIndex);
    g.InitSizes;                             (* the places, for later resizing *)
    g.dragWidget := NIL;
    g.Redraw;
    parent := g.Parent();
    IF parent # NIL THEN parent.Redraw END;
    RETURN TRUE
  END;
  RETURN g.Handle^(e)
END Handle;

PROCEDURE (c: ClearStatus) Fire*;
BEGIN status.SetLabel(""); status.Redraw
END Fire;

PROCEDURE ButtonCb(w: Fl.Widget);
  VAR s, label: ARRAY 128 OF CHAR;
BEGIN
  w.GetLabel(label);
  s := "button_cb: '"; OutStr.String(label, s); OutStr.String("'.", s); OutStr.Ln(s);
  status.SetLabel(s);
  status.Redraw;
  Fl.AddTimeout(clearStatus, 2.0D0)          (* again, if it was pending *)
END ButtonCb;

PROCEDURE Square(x, y, size, color: INTEGER);
  VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, x, y, size, size, "");
  b.SetColor(color);
  b.SetBoxType(Fl.FlatBox)
END Square;

PROCEDURE Build;
  VAR area, dobj, dobj3, dobj4: DraggableGroup; dobj2: Fl.Group; button1, button2: FlButtons.Button;
    s, ttDrag, ttButton: ARRAY 160 OF CHAR;
BEGIN
  ttDrag := "Drag this DraggableGroup and/or its child groups and squares. ";
  OutStr.String("Use the right mouse button (MB3) to drag objects.", ttDrag);
  ttButton := "You can drag this button with the right mouse button ";
  OutStr.String("and you can click it with the left mouse button.", ttButton);
  NEW(win); Fl.OpenDoubleWindow(win, 500, 500, "Drag children within their parent group");
  s := "Use the right mouse button (MB3)"; OutStr.Ln(s); OutStr.String("to drag objects", s);
  NEW(area); OpenDraggableGroup(area, 0, 0, 500, 400, s);
  area.SetAlign(Fl.AlignInside);
  area.SetTooltip(ttDrag);

  NEW(dobj); OpenDraggableGroup(dobj, 5, 5, 140, 140, "DraggableGroup");
  dobj.SetAlign(Fl.AlignInside);
  Square(25, 25, 20, Fl.Red);
  Square(105, 105, 20, Fl.Green);
  dobj.End;
  dobj.SetTooltip(ttDrag);

  NEW(dobj2); Fl.OpenGroup(dobj2, 5, 280, 110, 110, "Fl_Group");
  dobj2.SetBoxType(Fl.DownBox);
  dobj2.SetAlign(Fl.AlignInside);
  Square(15, 290, 20, Fl.Blue);
  Square(85, 360, 20, Fl.Yellow);
  dobj2.End;
  dobj2.SetTooltip("You can drag this Fl_Group, but not its children (squares).");

  NEW(dobj3); OpenDraggableGroup(dobj3, 245, 5, 150, 150, "DraggableGroup");
  dobj3.SetAlign(Fl.AlignInside);
  dobj3.SetTooltip(ttDrag);
  NEW(dobj4); OpenDraggableGroup(dobj4, 250, 10, 50, 50, "");
  Square(255, 15, 15, Fl.Black);
  Square(275, 30, 15, Fl.White);
  dobj4.End;
  dobj4.SetTooltip(ttDrag);
  dobj3.End;

  NEW(button1); FlButtons.OpenButton(button1, 200, 350, 180, 40, "Fl_Button inside DraggableGroup");
  button1.SetAlign(Fl.AlignInside + Fl.AlignWrap);
  button1.SetTooltip(ttButton);
  area.End;

  NEW(button2); FlButtons.OpenButton(button2, 200, 410, 180, 40, "Fl_Button outside DraggableGroup");
  button2.SetAlign(Fl.AlignInside + Fl.AlignWrap);
  button2.SetTooltip("This is a normal button and can't be dragged.");

  NEW(status); Fl.OpenBox(status, 0, 460, win.W(), 40, "Messages ...");
  status.SetBoxType(Fl.DownBox);
  NEW(clearStatus);
  button1.action := ButtonCb;
  button2.action := ButtonCb;
  win.End;
  win.SetResizable(win)
END Build;

BEGIN
  Build;
  win.Show;
  Fl.Run
END DraggableGroup.
