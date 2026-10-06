MODULE FlexSimple; (* FLTK's examples/howto-flex-simple.cxx: a row of buttons laid out by a flex *)

IMPORT Fl, FlButtons, FlLayout, FlDialogs;

VAR
  window: Fl.DoubleWindow;
  flex: FlLayout.Flex;
  space: Fl.Box;
  exit: FlButtons.Button;

PROCEDURE Append(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE (t[j] # 0X) & (i < LEN(s) - 1) DO s[i] := t[j]; INC(i); INC(j) END;
  s[i] := 0X
END Append;

PROCEDURE Message(w: Fl.Widget; what: ARRAY OF CHAR);
  VAR label, s: ARRAY 256 OF CHAR; i: INTEGER;
BEGIN
  w.GetLabel(label);
  s := "The '"; Append(s, label); Append(s, "' button "); Append(s, what);
  i := 0; WHILE s[i] # 0X DO IF s[i] = "?" THEN s[i] := 0AX END; INC(i) END;
  FlDialogs.Message(s)
END Message;

PROCEDURE ButtonCB(w: Fl.Widget);
BEGIN Message(w, "does nothing.")
END ButtonCB;

PROCEDURE ExitCB(w: Fl.Widget);
BEGIN
  Message(w, "closes the window?and terminates the program.");
  window.Hide
END ExitCB;

PROCEDURE Button(label: ARRAY OF CHAR; action: PROCEDURE (w: Fl.Widget)): FlButtons.Button;
  VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, 0, 0, 0, 0, label); b.action := action;
  RETURN b
END Button;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 410, 40, "Simple Fl_Flex Demo");
  NEW(flex); FlLayout.OpenFlex(flex, 5, 5, 400, 30, "");
  flex.SetKind(FlLayout.Row);
  exit := Button("File", ButtonCB); exit := Button("New", ButtonCB); exit := Button("Save", ButtonCB);
  NEW(space); Fl.OpenBox(space, 0, 0, 0, 0, "");  (* empty space *)
  exit := Button("Exit", ExitCB);
  flex.SetGap(10);
  flex.SetFixed(space, 30);  (* in all 50: two gaps and 30 *)
  flex.End;
  window.End;
  window.SetResizable(flex);
  window.SizeRange(300, 30, 0, 0);
  window.Show;
  Fl.Run
END FlexSimple.
