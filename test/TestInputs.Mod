MODULE TestInputs; (* FlInputs: text in and out, typing, editing, numbers *)

(* Keys are sent as from the window system (Probe) to the focus, in a
   window never shown. *)

IMPORT Fl, FlInputs, Check, Probe;

VAR
  win: Fl.Window;
  in: FlInputs.Input;
  int: FlInputs.IntInput;
  float: FlInputs.FloatInput;
  multi: FlInputs.MultilineInput;
  secret: FlInputs.SecretInput;
  out: FlInputs.Output;
  mout: FlInputs.MultilineOutput;
  s: ARRAY 64 OF CHAR;
  small: ARRAY 4 OF CHAR;
  calls: INTEGER;
  ok: BOOLEAN;

PROCEDURE Count(w: Fl.Widget);
BEGIN INC(calls)
END Count;

(* Types each character of keys into the focus. *)
PROCEDURE Type(keys: ARRAY OF CHAR);
  VAR i: INTEGER; t: ARRAY 2 OF CHAR; used: BOOLEAN;
BEGIN
  i := 0; t[1] := 0X;
  WHILE keys[i] # 0X DO
    t[0] := keys[i]; used := Probe.Key(Fl.EvKeyDown, ORD(keys[i]), {}, t); INC(i)
  END
END Type;

BEGIN
  NEW(win); Fl.OpenWindow(win, 400, 300, "TestInputs");
  NEW(in); FlInputs.OpenInput(in, 60, 10, 300, 25, "in");
  NEW(int); FlInputs.OpenIntInput(int, 60, 40, 100, 25, "int");
  NEW(float); FlInputs.OpenFloatInput(float, 200, 40, 100, 25, "float");
  NEW(multi); FlInputs.OpenMultilineInput(multi, 60, 70, 300, 60, "multi");
  NEW(secret); FlInputs.OpenSecretInput(secret, 60, 140, 100, 25, "secret");
  NEW(out); FlInputs.OpenOutput(out, 200, 140, 100, 25, "out");
  NEW(mout); FlInputs.OpenMultilineOutput(mout, 60, 170, 300, 60, "mout");
  win.End;

  (* the text, from the program *)
  in.Value(s);
  Check.Check((s = "") & (in.Length() = 0), "an input starts empty");
  in.SetValue("hello, world");
  in.Value(s);
  Check.Check((s = "hello, world") & (in.Length() = 12) & (in.InsertPosition() = 12),
    "SetValue sets the text, with the cursor at its end");
  in.Value(small);
  Check.Check(small = "hel", "Value truncates to fit its argument");

  (* typing *)
  in.SetValue(""); in.action := Count; in.SetWhen(Fl.WhenChanged); calls := 0;
  Check.Check(in.TakeFocus() & (Fl.Focus() = in), "an input takes the focus");
  Type("abc");
  in.Value(s);
  Check.Check((s = "abc") & (calls = 3), "typed keys go in, with a Callback each (WhenChanged)");
  (* with the text the window system gives it: under Wayland, FLTK takes
     a key with no text as composed text *)
  ok := Probe.Key(Fl.EvKeyDown, Fl.KeyBackSpace, {}, 08X);
  in.Value(s);
  Check.Check(ok & (s = "ab"), "BackSpace deletes");
  in.SetWhen(Fl.WhenEnterKey); calls := 0;
  ok := Probe.Key(Fl.EvKeyDown, Fl.KeyEnter, {}, 0DX);
  Check.Check(calls = 0, "Enter doesn't call back (WhenEnterKey) if nothing changed");
  Check.Check((in.InsertPosition() = 2) & (in.Mark() = 0), "but selects all the text");
  in.Select(2, 2); Type("c");
  ok := Probe.Key(Fl.EvKeyDown, Fl.KeyEnter, {}, 0DX);
  in.Value(s);
  Check.Check((calls = 1) & (s = "abc"), "Enter calls back once something has changed, typing nothing");
  in.SetMaximumSize(4); in.Select(3, 3);
  Type("xyz");
  in.Value(s);
  Check.Check((s = "abcx") & (in.MaximumSize() = 4), "typing stops at the maximum size");
  in.SetMaximumSize(32767);

  (* editing *)
  in.SetValue("hello, world");
  in.Select(0, 5);
  Check.Check((in.InsertPosition() = 0) & (in.Mark() = 5), "Select sets the cursor and mark");
  Check.Check(in.Insert("goodbye"), "Insert replaces the selection");
  in.Value(s);
  Check.Check(s = "goodbye, world", "with its text");
  Check.Check(in.Replace(9, 14, "moon"), "Replace a range");
  in.Value(s);
  Check.Check(s = "goodbye, moon", "with its text");
  Check.Check(in.CutRange(0, 9), "CutRange");
  in.Value(s);
  Check.Check(s = "moon", "deletes the range");
  Check.Check(in.Undo(), "Undo");
  in.Value(s);
  Check.Check(s = "goodbye, moon", "restores it");
  in.Select(0, 8);
  Check.Check(in.Cut(), "Cut");
  in.Value(s);
  Check.Check(s = " moon", "deletes the selection");

  (* numbers *)
  Check.Check(int.TakeFocus(), "focus to the int input");
  Type("1x2-");
  int.Value(s);
  Check.Check((s = "12") & (int.IntValue() = 12), "an int input takes only digits where they fit");
  int.SetIntValue(-345);
  int.Value(s);
  Check.Check((s = "-345") & (int.IntValue() = -345), "SetIntValue and IntValue");
  Check.Check(float.TakeFocus(), "focus to the float input");
  Type("2.5x");
  float.Value(s);
  Check.Check((s = "2.5") & (float.RealValue() = 2.5D0), "a float input takes a real number");
  float.SetRealValue(0.25D0);
  Check.Check(float.RealValue() = 0.25D0, "SetRealValue and RealValue");

  (* many lines *)
  Check.Check(multi.TakeFocus(), "focus to the multiline input");
  Type("a"); ok := Probe.Key(Fl.EvKeyDown, Fl.KeyEnter, {}, 0DX); Type("b");
  multi.Value(s);
  Check.Check((s[0] = "a") & (s[1] = 0AX) & (s[2] = "b") & (s[3] = 0X),
    "Enter types a new line in a multiline input");
  multi.SetWrap(TRUE); multi.SetTabNav(FALSE);
  Check.Check(multi.Wrap() & ~multi.TabNav(), "Wrap and TabNav read back");

  (* secrets and outputs *)
  Check.Check(secret.TakeFocus(), "focus to the secret input");
  Type("pw");
  secret.Value(s);
  Check.Check(s = "pw", "a secret input's Value is the text typed");
  Check.Check(out.Readonly() & mout.Readonly() & ~in.Readonly(), "outputs are read-only, inputs not");
  out.SetValue("shown");
  Check.Check(out.TakeFocus(), "an output takes the focus, for selecting");
  Type("x");
  out.Value(s);
  Check.Check(s = "shown", "but typing doesn't change it");
  in.SetReadonly(TRUE);
  Check.Check(in.Readonly(), "SetReadonly");

  (* the text's look *)
  in.SetTextFont(Fl.Courier); in.SetTextSize(18); in.SetTextColor(Fl.Blue);
  in.SetCursorColor(Fl.Red);
  Check.Check((in.TextFont() = Fl.Courier) & (in.TextSize() = 18) & (in.TextColor() = Fl.Blue)
    & (in.CursorColor() = Fl.Red), "text font, size and color, and cursor color, read back");

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestInputs.
