MODULE TestPreferences; (* FlPreferences: entries, groups, deletion, and a file read back *)

IMPORT FlPreferences, Check;

CONST dir = "../build/prefs";

VAR
  p, q, a, bc, b: FlPreferences.Preferences;
  s: ARRAY 256 OF CHAR;
  short: ARRAY 4 OF CHAR;
  odd: ARRAY 32 OF CHAR;  (* text FLTK escapes in its file: a newline, a backslash, quotes *)
  n: INTEGER;

BEGIN
  odd := 'one?two \ "three"'; odd[3] := 0AX;

  (* Entries, in memory *)
  NEW(p); FlPreferences.Open(p, FlPreferences.Memory, "org.example", "pofltk-test");
  Check.Check(p.IsOpen() & (FlPreferences.openDatabases = 1), "Open");
  p.FileName(s);
  Check.Check(s = "", "a database in memory has no file");
  Check.Check((p.Entries() = 0) & (p.Groups() = 0), "empty to start with");
  p.SetInt("n", -42); p.SetReal("x", 0.5D0); p.SetText("s", "hello");
  Check.Check((p.Int("n", 0) = -42) & (p.Real("x", 0.0D0) = 0.5D0), "SetInt, SetReal");
  p.GetText("s", "", s);
  Check.Check((s = "hello") & (p.TextLength("s") = 5), "SetText");
  Check.Check((p.Int("missing", 7) = 7) & (p.Real("missing", 1.5D0) = 1.5D0), "a missing entry gives the default");
  p.GetText("missing", "dflt", s);
  Check.Check((s = "dflt") & (p.TextLength("missing") = 0), "text too");
  p.GetText("s", "", short);
  Check.Check(short = "hel", "text truncated to fit");
  p.SetInt("n", 3);
  Check.Check((p.Int("n", 0) = 3) & (p.Entries() = 3), "SetInt replaces");
  p.EntryName(0, s);
  Check.Check(s = "n", "EntryName");
  Check.Check(p.HasEntry("x") & ~p.HasEntry("y"), "HasEntry");
  Check.Check(p.DeleteEntry("x") & ~p.DeleteEntry("x") & (p.Entries() = 2), "DeleteEntry");

  (* Groups *)
  NEW(a); p.Group(a, "a");
  NEW(bc); p.Group(bc, "b/c");
  a.Path(s);
  Check.Check(s = "a", "a group's path");
  bc.Path(s);
  Check.Check(s = "b/c", "a path makes the groups along it");
  Check.Check((p.Groups() = 2) & p.HasGroup("b") & p.HasGroup("b/c") & ~p.HasGroup("c"), "HasGroup");
  p.GroupName(1, s);
  Check.Check(s = "b", "GroupName");
  NEW(b); p.Group(b, "b");
  Check.Check((b.Groups() = 1) & b.HasGroup("c"), "an existing group, opened again");
  NEW(q); b.Group(q, "c");
  q.Path(s);
  Check.Check(s = "b/c", "a group's group");
  q.SetInt("k", 9);
  Check.Check((bc.Int("k", 0) = 9) & (p.Int("k", 0) = 0) & (a.Entries() = 0), "two objects, one group, apart from the rest");
  a.SetText("t", "in a");

  (* Deletion closes what it deletes. *)
  Check.Check(b.DeleteGroup("c") & ~bc.IsOpen() & ~q.IsOpen() & b.IsOpen(), "DeleteGroup closes the group's objects");
  Check.Check(~b.DeleteGroup("c"), "DeleteGroup of none");
  NEW(bc); b.Group(bc, "c");
  Check.Check(bc.IsOpen() & (bc.Int("k", 0) = 0), "a group made again is new");
  p.DeleteGroups;
  Check.Check((p.Groups() = 0) & ~a.IsOpen() & ~b.IsOpen() & ~bc.IsOpen() & (p.Entries() = 2), "DeleteGroups");
  NEW(a); p.Group(a, "a");
  p.Clear;
  Check.Check((p.Groups() = 0) & (p.Entries() = 0) & ~a.IsOpen(), "Clear");
  NEW(a); p.Group(a, "a");
  a.Close; a.Close;
  Check.Check(~a.IsOpen() & p.HasGroup("a"), "closing a group keeps it");
  NEW(a); p.Group(a, "a");
  p.Close; p.Close;
  Check.Check(~p.IsOpen() & ~a.IsOpen() & (FlPreferences.openDatabases = 0), "closing a database closes its groups");

  (* A file, written and read back *)
  NEW(p); FlPreferences.OpenFile(p, dir, "org.example", "pofltk-test");
  p.Clear;
  p.FileName(s);
  n := 0; WHILE s[n] # 0X DO INC(n) END;
  Check.Check((n > 18) & (s[n - 18] = "/") & (s[n - 17] = "p") & (s[n - 6] = "."), "FileName: dir/pofltk-test.prefs");
  p.SetInt("n", 12); p.SetReal("x", 0.25D0); p.SetText("odd", odd);
  NEW(a); p.Group(a, "a/b"); a.SetText("t", "deep");
  Check.Check(p.Flush(), "Flush");
  p.Close;
  NEW(p); FlPreferences.OpenFile(p, dir, "org.example", "pofltk-test");
  p.GetText("odd", "", s);
  Check.Check((p.Int("n", 0) = 12) & (p.Real("x", 0.0D0) = 0.25D0) & (s = odd), "read back from the file");
  Check.Check(p.TextLength("odd") >= 17, "TextLength holds the text");
  NEW(a); p.Group(a, "a/b"); a.GetText("t", "", s);
  Check.Check(s = "deep", "a group read back");
  p.Clear; p.Close;

  Check.Check(FlPreferences.openDatabases = 0, "every database closed");
  Check.Summary
END TestPreferences.
