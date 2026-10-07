MODULE TestArgs; (* Fl.ParseArgs, Arg, ArgsHelp and Window.ShowArgs, on the command line make test gives it *)

(* make test runs it as
     TestArgs -o hello --help -g 120x80 -ti Title -s plastic -nokbd rest more
   (TESTARGS in GNUmakefile). *)

IMPORT Args, Fl, Check;

VAR
  option: ARRAY 32 OF CHAR;
  help: BOOLEAN;
  offered, i: INTEGER;
  s: ARRAY 512 OF CHAR;
  win: Fl.Window;

(* The program's own options: -h or --help, and -o or --option with a
   value, as FLTK's example has. *)
PROCEDURE Handler(i: INTEGER): INTEGER;
  VAR a: ARRAY 32 OF CHAR;
BEGIN
  INC(offered); Args.Get(i, a);
  IF (a = "-h") OR (a = "--help") THEN help := TRUE; RETURN 1
  ELSIF ((a = "-o") OR (a = "--option")) & (i < Args.argc - 1) THEN Args.Get(i + 1, option); RETURN 2
  END;
  RETURN 0
END Handler;

BEGIN
  Check.Check(Args.argc = 13, "run with make test's arguments (TESTARGS)");
  IF Args.argc = 13 THEN
    Check.Check(Fl.ParseArgs(Handler, i) & (i = 11), "ParseArgs: TRUE, up to the first argument not an option");
    Check.Check((option = "hello") & help, "the program's options go to its handler");
    Check.Check(offered = 7, "which is offered each first, and the word that ends them");
    Fl.GetScheme(s);
    Check.Check(s = "plastic", "FLTK's options take effect: -s");
    Check.Check(~Fl.Option(Fl.OptionVisibleFocus), "and -nokbd");
    Check.Check((Fl.Arg(8) = 2) & (Fl.Arg(10) = 1) & (Fl.Arg(11) = 0) & (Fl.Arg(1) = 0),
      "Arg: the words of one of FLTK's options; 0 for another");
    Check.Check(~Fl.ParseArgs(NIL, i) & (i = 1),
      "ParseArgs: FALSE at an option no one knows, after once stopping at a word");
    Fl.ArgsHelp(s);
    s[11] := 0X;
    Check.Check(s = " -bg2 color", "ArgsHelp: FLTK's options");

    NEW(win); Fl.OpenWindow(win, 300, 200, "");
    win.End;
    win.ShowArgs;
    win.GetLabel(s);
    Check.Check(win.Shown() & (win.W() = 120) & (win.H() = 80), "ShowArgs: shown, with -g's size");
    Check.Check(s = "Title", "and -ti's title");
    win.Delete
  END;
  Check.Summary
END TestArgs.
