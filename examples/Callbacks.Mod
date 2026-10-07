MODULE Callbacks; (* FLTK's examples/callbacks.cxx: callbacks with arguments of their own *)

(* FLTK's example uses the macros of fl_callback_macros.H to give a
   callback arguments beyond its widget. An Oberon widget is a record, so
   its arguments are its fields: a button type carries what its callback
   needs, and the callback is a procedure (the action field) or a method
   (Callback). The macros' inline callbacks, C++ blocks run as callbacks,
   are procedures here too, since a nested procedure can't be a
   procedure value. *)

IMPORT OutStr, Fl, FlButtons, FlDialogs;

TYPE
  (* Function callbacks: a procedure, given the button, reads its arguments. *)
  TextButton = POINTER TO RECORD (FlButtons.ButtonDesc)
    text: ARRAY 16 OF CHAR;
    number: INTEGER
  END;
  FourButton = POINTER TO RECORD (FlButtons.ButtonDesc)
    a: ARRAY 4 OF INTEGER
  END;

  (* Method callbacks: the button's own Callback, with its id and three
     arguments. *)
  MyButton = POINTER TO RECORD (FlButtons.ButtonDesc)
    id, a, b, c: INTEGER
  END;

  (* The inline callback with four arguments: the window's place and
     size when the callback was made. *)
  PlaceButton = POINTER TO RECORD (FlButtons.ButtonDesc)
    wx, wy, ww, wh: INTEGER
  END;

VAR
  window: Fl.Window;

PROCEDURE Hello0(w: Fl.Widget);
BEGIN FlDialogs.Message("Hello with 0 arguments")
END Hello0;

PROCEDURE Hello2(w: Fl.Widget);
  VAR s: ARRAY 100 OF CHAR;
BEGIN
  s := "Hello with 2 arguments,"; OutStr.Ln(s);
  OutStr.Char(22X, s); OutStr.String(w(TextButton).text, s); OutStr.Char(22X, s); OutStr.String(" and '", s);
  OutStr.Int(w(TextButton).number, 0, s); OutStr.Char("'", s);
  FlDialogs.Message(s)
END Hello2;

PROCEDURE Hello4(w: Fl.Widget);
  VAR s: ARRAY 100 OF CHAR; i: INTEGER;
BEGIN
  s := "Hello with 4 arguments:"; OutStr.Ln(s);
  FOR i := 0 TO 3 DO
    IF i > 0 THEN OutStr.Char(" ", s) END;
    OutStr.Int(w(FourButton).a[i], 0, s)
  END;
  FlDialogs.Message(s)
END Hello4;

PROCEDURE (b: MyButton) Callback*;
  VAR s: ARRAY 120 OF CHAR;
BEGIN
  s := "MyButton has the id "; OutStr.Int(b.id, 0, s); OutStr.Ln(s);
  OutStr.String("and was called with the custom parameters", s); OutStr.Ln(s);
  OutStr.Int(b.a, 0, s); OutStr.String(", ", s); OutStr.Int(b.b, 0, s);
  OutStr.String(", and ", s); OutStr.Int(b.c, 0, s); OutStr.Char(".", s);
  FlDialogs.Message(s)
END Callback;

(* Each button made here has its own arguments, as each made by FLTK's
   macro has its own copy of them. *)
PROCEDURE MakeButton(set: INTEGER);
  VAR b: MyButton;
BEGIN
  NEW(b);
  IF set = 0 THEN FlButtons.OpenButton(b, 200, 60, 180, 25, "id 2 (5, 6, 7)")
  ELSE FlButtons.OpenButton(b, 200, 90, 180, 25, "id 3 (6, 7, 8)")
  END;
  b.id := set + 2; b.a := set + 5; b.b := set + 6; b.c := set + 7
END MakeButton;

PROCEDURE Inline0(w: Fl.Widget);
BEGIN FlDialogs.Message("Inline callback with 0 args.")
END Inline0;

PROCEDURE Inline2(w: Fl.Widget);
  VAR s: ARRAY 80 OF CHAR;
BEGIN
  s := "We received the message "; OutStr.String(w(TextButton).text, s);
  OutStr.String(" with ", s); OutStr.Int(w(TextButton).number, 0, s); OutStr.Char("!", s);
  FlDialogs.Message(s)
END Inline2;

PROCEDURE Inline4(w: Fl.Widget);
  VAR s: ARRAY 160 OF CHAR; p: PlaceButton;
BEGIN
  p := w(PlaceButton);
  s := "The main window was at"; OutStr.Ln(s);
  OutStr.String("x:", s); OutStr.Int(p.wx, 0, s); OutStr.String(", y:", s); OutStr.Int(p.wy, 0, s);
  OutStr.String(", w:", s); OutStr.Int(p.ww, 0, s); OutStr.String(", h:", s); OutStr.Int(p.wh, 0, s);
  OutStr.Ln(s); OutStr.String("when the callback was created", s); OutStr.Ln(s);
  OutStr.String("and is now at x:", s); OutStr.Int(window.X(), 0, s);
  OutStr.String(", y:", s); OutStr.Int(window.Y(), 0, s);
  FlDialogs.Message(s)
END Inline4;

PROCEDURE Build;
  VAR box: Fl.Box; b: FlButtons.Button; t: TextButton; f: FourButton; m: MyButton; p: PlaceButton;
BEGIN
  NEW(window); Fl.OpenWindow(window, 580, 120, "");

  (* Procedures as callbacks, with their arguments in the button *)
  NEW(box); Fl.OpenBox(box, 10, 5, 180, 25, "Function Callbacks:");
  NEW(b); FlButtons.OpenButton(b, 10, 30, 180, 25, "0 args"); b.action := Hello0;
  NEW(t); FlButtons.OpenButton(t, 10, 60, 180, 25, "2 args");
  t.text := "FLTK"; t.number := 2; t.action := Hello2;
  NEW(f); FlButtons.OpenButton(f, 10, 90, 180, 25, "4 args");
  f.a[0] := 1; f.a[1] := 2; f.a[2] := 3; f.a[3] := 4; f.action := Hello4;

  (* Methods as callbacks *)
  NEW(box); Fl.OpenBox(box, 200, 5, 180, 25, "Method Callbacks:");
  NEW(m); FlButtons.OpenButton(m, 200, 30, 180, 25, "id 1 (1, 2, 3)");
  m.id := 1; m.a := 1; m.b := 2; m.c := 3;
  MakeButton(0);
  MakeButton(1);

  (* FLTK's inline callbacks *)
  NEW(box); Fl.OpenBox(box, 390, 5, 180, 25, "Inline Callbacks:");
  NEW(b); FlButtons.OpenButton(b, 390, 30, 180, 25, "0 args"); b.action := Inline0;
  NEW(t); FlButtons.OpenButton(t, 390, 60, 180, 25, "2 args");
  t.text := "FLTK"; t.number := 2; t.action := Inline2;
  NEW(p); FlButtons.OpenButton(p, 390, 90, 180, 25, "4 args");
  p.wx := window.X(); p.wy := window.Y(); p.ww := window.W(); p.wh := window.H();
  p.action := Inline4;

  window.End
END Build;

BEGIN
  Build;
  window.Show;
  Fl.Run
END Callbacks.
