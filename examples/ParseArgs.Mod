MODULE ParseArgs; (* FLTK's examples/howto-parse-args.cxx: a program's own command-line options beside FLTK's *)

(* Try it with -o text, or -h, or with FLTK's options, such as -g 400x100
   or -s plastic, or with an option it doesn't know. *)

IMPORT Args, Err, Fl;

VAR
  helpFlag: BOOLEAN;
  optionString: ARRAY 256 OF CHAR;
  i: INTEGER;
  name: ARRAY 256 OF CHAR;
  help: ARRAY 1024 OF CHAR;
  mainWin: Fl.Window;
  textBox: Fl.Box;

(* The program's own options, offered each argument before FLTK is:
   returns 2 if argument i is an option and its value, 1 if it is one
   alone, and 0 if it isn't one of them. *)
PROCEDURE Arg(i: INTEGER): INTEGER;
  VAR a: ARRAY 256 OF CHAR;
BEGIN
  Args.Get(i, a);
  IF (a = "-h") OR (a = "--help") THEN
    helpFlag := TRUE;
    RETURN 1
  END;
  IF (a = "-o") OR (a = "--option") THEN
    IF i < Args.argc - 1 THEN
      Args.Get(i + 1, optionString);
      RETURN 2
    END
  END;
  RETURN 0
END Arg;

PROCEDURE Usage;
BEGIN
  Err.String("usage: "); Err.String(name); Err.String(" [options]"); Err.Ln;
  Err.String(" -h | --help     : print extended help message"); Err.Ln;
  Err.String(" -o | --option # : example option with parameter"); Err.Ln
END Usage;

BEGIN
  helpFlag := FALSE; optionString := "";
  Args.Get(0, name);
  IF ~Fl.ParseArgs(Arg, i) OR (i < Args.argc) THEN
    Args.Get(i, optionString);
    Err.String("error: unknown option: "); Err.String(optionString); Err.Ln;
    Usage;
    Err.String(" plus standard fltk options"); Err.Ln; Err.Ln;   (* as Fl::fatal ends a line already ended *)
    HALT(1)
  END;
  IF helpFlag THEN
    Usage;
    Err.String(" plus standard fltk options:"); Err.Ln;
    Fl.ArgsHelp(help); Err.String(help); Err.Ln; Err.Ln;
    HALT(1)
  END;

  NEW(mainWin); Fl.OpenWindow(mainWin, 300, 200, "");
  NEW(textBox); Fl.OpenBox(textBox, 0, 0, 300, 200, "");
  IF optionString # "" THEN
    textBox.SetLabel(optionString)
  ELSE
    textBox.SetLabel("re-run with [-o|--option] text")
  END;
  mainWin.End;
  mainWin.SetResizable(mainWin);
  mainWin.ShowArgs;
  Fl.Run
END ParseArgs.
