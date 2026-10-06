MODULE HaltIndex; (* A child index outside the group halts with Fl.IndexOutOfRange, 74 *)
IMPORT Fl;
VAR g: Fl.Group; b: Fl.Box; w: Fl.Widget;
BEGIN
  NEW(g); Fl.OpenGroup(g, 0, 0, 10, 10, ""); NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, ""); g.End;
  w := g.Child(1)
END HaltIndex.
