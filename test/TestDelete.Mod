MODULE TestDelete; (* However FLTK destroys a widget, Fl closes its object *)

(* PLAN.md, "Lifetime and the collector": FLTK deletes a widget's user
   data with it (AUTO_DELETE_USER_DATA), and Fl closes the object then:
   explicitly, with its parent group, deleted inside its own callback
   (later, by Fl::delete_widget), and as a shown window. Also: a label is
   copied, so changing the string it came from changes nothing. *)

IMPORT Fl, Check;

TYPE
  SelfDeleting = POINTER TO RECORD (Fl.BoxDesc)
    openInside: BOOLEAN  (* IsOpen right after Delete, inside the callback *)
  END;

VAR
  win: Fl.Window;
  g, inner: Fl.Group;
  a, b, c: Fl.Box;
  s: SelfDeleting;
  label: ARRAY 16 OF CHAR;
  got: ARRAY 32 OF CHAR;
  shown: BOOLEAN;

PROCEDURE (w: SelfDeleting) Callback*;
BEGIN w.Delete; w.openInside := w.IsOpen()
END Callback;

BEGIN
  (* explicitly *)
  NEW(a); Fl.OpenBox(a, 0, 0, 10, 10, "a");
  Check.Check(a.IsOpen() & (Fl.OpenWidgets() = 1), "an opened box is open");
  a.Delete;
  Check.Check(~a.IsOpen() & (a.h = 0) & (Fl.OpenWidgets() = 0), "Delete closes it at once");

  (* with its parent group, to any depth *)
  NEW(g); Fl.OpenGroup(g, 0, 0, 100, 100, "g");
  NEW(a); Fl.OpenBox(a, 0, 0, 10, 10, "child");
  NEW(inner); Fl.OpenGroup(inner, 0, 0, 50, 50, "inner");
  NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, "grandchild");
  inner.End; g.End;
  Check.Check((g.Children() = 2) & (inner.Children() = 1) & (Fl.OpenWidgets() = 4),
    "a group with a box and a group with a box");
  g.Delete;
  Check.Check(~g.IsOpen() & ~a.IsOpen() & ~inner.IsOpen() & ~b.IsOpen()
    & (Fl.OpenWidgets() = 0), "deleting the group closes all four");

  (* inside its own callback: later *)
  NEW(s); Fl.OpenBox(s, 0, 0, 10, 10, "s");
  s.DoCallback;
  Check.Check(s.openInside, "deleted inside its callback, it stays open until that returns");
  Check.Check(s.IsOpen() & (Fl.OpenWidgets() = 1), "and after the callback, until FLTK runs");
  shown := Fl.Check();
  Check.Check(~s.IsOpen() & (Fl.OpenWidgets() = 0), "Fl.Check deletes it");

  (* a shown window *)
  NEW(win); Fl.OpenWindow(win, 120, 80, "TestDelete");
  NEW(c); Fl.OpenBox(c, 10, 10, 100, 20, "");
  win.End; win.Show; shown := Fl.Check();
  Check.Check(win.Visible() & (Fl.OpenWidgets() = 2), "a shown window with a box");

  (* the label is FLTK's copy *)
  label := "first"; c.SetLabel(label); label := "XXXXX";
  c.GetLabel(got);
  Check.Check(got = "first", "a label is copied");
  c.SetLabel("a longer label"); got := ""; c.GetLabel(got);
  Check.Check(got = "a longer label", "SetLabel replaces it");

  win.Delete;
  Check.Check(~win.IsOpen() & ~c.IsOpen() & (Fl.OpenWidgets() = 0),
    "deleting the shown window closes it and its box");
  shown := Fl.Check();
  Check.Check(~shown, "no window is shown");
  Check.Summary
END TestDelete.
