MODULE TestDialogs; (* FlDialogs: each dialog answered by keys, as a user would *)

IMPORT Fl, FlDialogs, Check, Probe;

CONST tries = 400;  (* of 0.05 s, waiting for a dialog; generous, for valgrind *)

TYPE
  (* Waits for a dialog, notes its title, types text into it, a key per
     character, and then sends key. Then it fires once more: FLTK runs
     timers and then waits for an event, so without one a dialog's loop
     ends only when an event comes, and none comes under Xvfb. *)
  Answer = POINTER TO RECORD (Fl.TimerDesc)
    text, keyText, title: ARRAY 64 OF CHAR;
    key, tries, seen: INTEGER;
    sent: BOOLEAN
  END;

VAR
  answer: Answer;
  s: ARRAY 256 OF CHAR;
  i, r, g, b, font, size, c: INTEGER;
  ok: BOOLEAN;

PROCEDURE (a: Answer) Fire*;
  VAR i: INTEGER; c: ARRAY 2 OF CHAR; ok: BOOLEAN;
BEGIN
  IF a.sent THEN (* only to wake the loop *)
  ELSIF ~Probe.Modal(a.title) THEN
    INC(a.tries); IF a.tries < tries THEN Fl.RepeatTimeout(a, 0.05D0) END
  ELSIF a.seen < 2 THEN  (* let it settle *)
    INC(a.seen); Fl.RepeatTimeout(a, 0.05D0)
  ELSE
    i := 0; c[1] := 0X;
    WHILE a.text[i] # 0X DO c[0] := a.text[i]; ok := Probe.ModalKey(ORD(c[0]), {}, c); INC(i) END;
    ok := Probe.ModalKey(a.key, {}, a.keyText);
    a.sent := TRUE; Fl.RepeatTimeout(a, 0.01D0)
  END
END Fire;

(* Answers the next dialog by typing text and then key. *)
PROCEDURE Reply(text: ARRAY OF CHAR; key: INTEGER; keyText: ARRAY OF CHAR);
BEGIN
  NEW(answer); COPY(text, answer.text); answer.key := key; COPY(keyText, answer.keyText);
  Fl.AddTimeout(answer, 0.05D0)
END Reply;

PROCEDURE Enter;
BEGIN Reply("", Fl.KeyEnter, 0DX)
END Enter;

PROCEDURE Escape;
BEGIN Reply("", Fl.KeyEscape, 1BX)
END Escape;

PROCEDURE Ends(s, end: ARRAY OF CHAR): BOOLEAN;
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE end[j] # 0X DO INC(j) END;
  IF j > i THEN RETURN FALSE END;
  WHILE (j > 0) & (s[i - 1] = end[j - 1]) DO DEC(i); DEC(j) END;
  RETURN j = 0
END Ends;

BEGIN
  Check.Check(FlDialogs.Hotspot(), "dialogs are shown under the mouse to start with");
  FlDialogs.SetHotspot(FALSE);
  Check.Check(~FlDialogs.Hotspot(), "SetHotspot");
  FlDialogs.Font(font, size);
  FlDialogs.SetFont(Fl.Courier, 16); FlDialogs.Font(font, size);
  Check.Check((font = Fl.Courier) & (size = 16), "SetFont");
  FlDialogs.SetFont(Fl.Helvetica, 0);

  Enter; FlDialogs.Message("100% done");
  Check.Check(answer.tries < tries, "Message waits for the user; Enter closes it");
  Escape; FlDialogs.Alert("Careful");
  Check.Check(answer.tries < tries, "Alert; Escape closes it");

  Enter; i := FlDialogs.Choice("Save?", "No", "Yes", "Cancel");
  Check.Check(i = 1, "Enter pushes Choice's b1");
  Escape; i := FlDialogs.Choice("Save?", "No", "Yes", "Cancel");
  Check.Check(i = FlDialogs.Escaped, "Escape is Escaped");
  Reply("", ORD("n"), "n"); i := FlDialogs.Choice("Save?", "&No", "&Yes", "&Cancel");
  Check.Check(i = 0, "b0, by its shortcut");
  Reply("", ORD("c"), "c"); i := FlDialogs.Choice("Save?", "&No", "&Yes", "&Cancel");
  Check.Check(i = 2, "b2");
  Enter; i := FlDialogs.Choice("Go on?", "", "Go", "");
  Check.Check(i = 1, "an empty label is no button");

  s := "abc";
  Reply("xy", Fl.KeyEnter, 0DX); ok := FlDialogs.Input("Name:", s);
  Check.Check(ok & (s = "abcxy"), "Input starts with the text, the cursor after it");
  Escape; ok := FlDialogs.Input("Name:", s);
  Check.Check(~ok & (s = "abcxy"), "cancelled, the text is unchanged");
  s := "";
  Reply("secret", Fl.KeyEnter, 0DX); ok := FlDialogs.Password("Password:", s);
  Check.Check(ok & (s = "secret"), "Password");

  FlDialogs.SetTitle("Once");
  Enter; FlDialogs.Message("titled");
  Check.Check(answer.title = "Once", "SetTitle titles the next dialog");
  Enter; FlDialogs.Message("untitled");
  Check.Check(answer.title = "", "and that one only");
  FlDialogs.SetDefaultTitle("Always");
  Enter; FlDialogs.Message("titled");
  Enter; FlDialogs.Message("titled");
  Check.Check(answer.title = "Always", "SetDefaultTitle titles every one");
  FlDialogs.SetDefaultTitle("");

  r := 10; g := 300; b := -5;
  Enter; ok := FlDialogs.ChooseColor("Color", r, g, b, FlDialogs.ColorByte);
  Check.Check(ok & (answer.title = "Color") & (r = 10) & (g = 255) & (b = 0),
    "ChooseColor: OK gives the color, brought into range");
  r := 1; g := 2; b := 3;
  Escape; ok := FlDialogs.ChooseColor("Color", r, g, b, FlDialogs.ColorDefault);
  Check.Check(~ok & (r = 1) & (g = 2) & (b = 3), "cancelled, unchanged");

  s := "TestDialogs.Mod";
  Enter; ok := FlDialogs.ChooseFile("Open", "*.Mod", s, TRUE);
  Check.Check(ok & (answer.title = "Open") & (s = "TestDialogs.Mod"), "ChooseFile, relative");
  Enter; ok := FlDialogs.ChooseFile("Open", "*.Mod", s, FALSE);
  Check.Check(ok & (s[0] = "/") & Ends(s, "/test/TestDialogs.Mod"), "and absolute");
  s := "New.txt";
  Enter; ok := FlDialogs.ChooseFile("Save", "", s, TRUE);
  Check.Check(ok & (s = "New.txt"), "a file that doesn't exist");
  Escape; ok := FlDialogs.ChooseFile("Save", "", s, TRUE);
  Check.Check(~ok & (s = "New.txt"), "cancelled, unchanged");
  s := "..";
  Enter; ok := FlDialogs.ChooseDirectory("Folder", s, FALSE);
  Check.Check(ok & (s[0] = "/") & ~Ends(s, "/test"), "ChooseDirectory");

  Escape; c := FlDialogs.ChooseFromColormap(Fl.Red);
  Check.Check(c = Fl.Red, "ChooseFromColormap gives back old if none is picked");

  Check.Check(Fl.OpenWidgets() = 0, "no widget left open");
  Check.Summary
END TestDialogs.
