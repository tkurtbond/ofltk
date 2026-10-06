MODULE HaltClosedGroup; (* A preferences group used after it is deleted halts with Fl.ClosedResource, 73 *)
IMPORT FlPreferences;
VAR p, g: FlPreferences.Preferences; n: INTEGER;
BEGIN
  NEW(p); FlPreferences.Open(p, FlPreferences.Memory, "org.example", "ofltk-test");
  NEW(g); p.Group(g, "g");
  p.Clear;
  n := g.Entries()
END HaltClosedGroup.
