MODULE AnimGifImagePlay; (* FLTK's examples/animgifimage-play.cxx: animated GIFs played frame by frame by the program *)

(* AnimGifImagePlay file... [-r] [-s speed_factor]

   Keys: '+', '-' and Enter change the speed, ' ' pauses, and the right
   arrow shows the next frame while paused; 'n' goes on to the next file,
   'r' plays backwards, 'i' shows the frame in the title, 'z' zooms in
   and 'Z' out.

   FLTK's example loads each file into the same Fl_Anim_GIF_Image; this
   one opens an AnimGIF for each, as FlImages opens an image once. *)

IMPORT Args, Out, Strings, Fl, FlImages, RealDigits, OutStr;

TYPE
  (* Shows the next frame, and waits for the one after. *)
  FrameTimer = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  speedFactor: LONGREAL;  (* slows playback down, or speeds it up *)
  reverse, paused, frameInfo: BOOLEAN;  (* frameInfo: the frame shown in the title *)
  animgif: FlImages.AnimGIF;  (* the animation; not open if its file wasn't a GIF *)
  argument: ARRAY 64 OF ARRAY 1024 OF CHAR;  (* the command line, "" for an argument used up *)
  argc, currentArg: INTEGER;  (* argument[currentArg] is the file shown *)
  win: Fl.DoubleWindow;
  canvas, help: Fl.Box;
  timer: FrameTimer;

(* v, positive, as "%.2f" writes it, from RealDigits' exact digits,
   rounded as printf rounds them. *)
PROCEDURE Fixed2(v: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 40 OF CHAR; count, e, p: INTEGER;

  PROCEDURE Digit(p: INTEGER);   (* the digit of 10^p *)
  BEGIN
    IF (e - p >= 0) & (e - p < count) THEN OutStr.Char(d[e - p], s) ELSE OutStr.Char("0", s) END
  END Digit;

BEGIN
  s[0] := 0X;
  RealDigits.Fixed(v, 2, 30, d, count, e);
  p := e; IF p < 0 THEN p := 0 END;
  WHILE p >= 0 DO Digit(p); DEC(p) END;
  OutStr.Char(".", s); Digit(-1); Digit(-2)
END Fixed2;

PROCEDURE Frames(): INTEGER;
BEGIN IF animgif.IsOpen() THEN RETURN animgif.Frames() ELSE RETURN 0 END
END Frames;

PROCEDURE NextArg(): INTEGER;
BEGIN
  REPEAT
    INC(currentArg);
    IF currentArg >= argc THEN currentArg := 1 END
  UNTIL argument[currentArg] # "";
  RETURN currentArg
END NextArg;

PROCEDURE NextFile;
BEGIN WHILE argument[NextArg()][0] = "-" DO END
END NextFile;

PROCEDURE SetTitle;
  VAR buf, n: ARRAY 1200 OF CHAR;
BEGIN
  buf := ""; OutStr.String(argument[currentArg], buf); OutStr.String(" (", buf);
  IF frameInfo THEN
    OutStr.String("frame ", buf); OutStr.Int(animgif.Frame() + 1, 0, buf);
    OutStr.String("/", buf); OutStr.Int(Frames(), 0, buf)
  ELSE
    OutStr.Int(Frames(), 0, buf); OutStr.String(" frames", buf)
  END;
  Fixed2(speedFactor, n);
  OutStr.String(") x ", buf);
  OutStr.String(n, buf); OutStr.Char(" ", buf);
  IF reverse THEN OutStr.String("reverse", buf) END;
  IF paused THEN OutStr.String(" PAUSED", buf) END;
  win.SetLabel(buf)
END SetTitle;

PROCEDURE (t: FrameTimer) Fire*;
  VAR frame: INTEGER;
BEGIN
  IF Frames() = 0 THEN RETURN END;
  frame := animgif.Frame();
  (* to the next frame, or the one before *)
  IF reverse THEN
    win.Redraw;
    DEC(frame);
    IF frame < 0 THEN frame := animgif.Frames() - 1 END
  ELSE
    INC(frame);
    IF frame >= animgif.Frames() THEN frame := 0 END
  END;
  animgif.SetFrame(frame);  (* which redraws the canvas *)

  (* wait for the next frame *)
  IF ~paused & (animgif.Delay(frame) # 0.0D0) THEN
    Fl.RepeatTimeout(timer, animgif.Delay(frame) / speedFactor)
  END;
  IF frameInfo THEN SetTitle END
END Fire;

PROCEDURE NextFrame;
BEGIN timer.Fire
END NextFrame;

PROCEDURE TogglePause;
BEGIN
  paused := ~paused;
  SetTitle;
  IF paused THEN Fl.RemoveTimeout(timer) ELSE NextFrame END;
  SetTitle
END TogglePause;

PROCEDURE ToggleInfo;
BEGIN frameInfo := ~frameInfo; SetTitle
END ToggleInfo;

PROCEDURE ToggleReverse;
BEGIN reverse := ~reverse; SetTitle
END ToggleReverse;

PROCEDURE Zoom(out: BOOLEAN);
  CONST f = 1.05D0;
  VAR w, h: INTEGER;
BEGIN
  IF ~animgif.IsOpen() THEN RETURN END;
  w := animgif.W(); h := animgif.H();
  (* deliberately no range check ('n' resets it) *)
  IF out THEN animgif.Resize(SHORT(ENTIER(w / f)), SHORT(ENTIER(h / f)))
  ELSE animgif.Resize(SHORT(ENTIER(f * w)), SHORT(ENTIER(f * h)))
  END
END Zoom;

PROCEDURE ChangeSpeed(dir: INTEGER);
BEGIN
  IF dir > 0 THEN
    IF speedFactor < 1.0D0 THEN speedFactor := speedFactor + 0.01D0 ELSE speedFactor := speedFactor + 0.1D0 END;
    IF speedFactor > 100.0D0 THEN speedFactor := 100.0D0 END
  ELSIF dir < 0 THEN
    IF speedFactor > 1.0D0 THEN speedFactor := speedFactor - 0.1D0 ELSE speedFactor := speedFactor - 0.01D0 END;
    IF speedFactor < 0.01D0 THEN speedFactor := 0.01D0 END
  ELSE
    speedFactor := 1.0D0
  END;
  SetTitle
END ChangeSpeed;

PROCEDURE LoadNext;
  VAR f: SET; speed: ARRAY 40 OF CHAR;
BEGIN
  Fl.RemoveTimeout(timer);
  paused := FALSE;
  NextFile;
  (* The canvas keeps its size, and the program plays the animation, not
     FLTK's timer. *)
  animgif.Close; NEW(animgif);
  f := FlImages.DontResizeCanvas + FlImages.DontStart;
  IF ~FlImages.OpenAnimGIF(animgif, argument[currentArg], canvas, f) THEN
    FlImages.SetImage(canvas, NIL)  (* as FLTK's failed load() leaves nothing to show *)
  END;
  win.Redraw;
  Out.String("valid: "); IF animgif.IsOpen() THEN Out.Int(1, 0) ELSE Out.Int(0, 0) END;
  Out.String(" frames: "); Out.Int(Frames(), 0); Out.Ln;
  IF animgif.IsOpen() THEN
    Out.String("play '"); Out.String(argument[currentArg]); Out.String("'");
    IF reverse THEN Out.String(" reverse") END;
    Fixed2(speedFactor, speed); Out.String(" with "); Out.String(speed); Out.String(" x speed"); Out.Ln;
    IF reverse THEN animgif.SetFrame(animgif.Frames() - 1) ELSE animgif.SetFrame(0) END;
    (* the first wait, unless the delay is 0: a GIF that isn't animated *)
    IF animgif.Delay(animgif.Frame()) # 0.0D0 THEN
      Fl.AddTimeout(timer, animgif.Delay(animgif.Frame()) / speedFactor)
    END
  END;
  SetTitle
END LoadNext;

PROCEDURE Events(event: INTEGER): BOOLEAN;
  VAR k: INTEGER;
BEGIN
  IF (event = Fl.EvShortcut) & win.Shown() THEN
    k := Fl.EventKey();
    IF k = ORD("+") THEN ChangeSpeed(1)
    ELSIF k = ORD("-") THEN ChangeSpeed(-1)
    ELSIF k = Fl.KeyEnter THEN ChangeSpeed(0)
    ELSIF k = ORD("n") THEN LoadNext
    ELSIF k = ORD("z") THEN Zoom(Fl.Shift * Fl.EventState() # {})
    ELSIF k = ORD("i") THEN ToggleInfo  (* which can raise the CPU's load considerably *)
    ELSIF k = ORD("r") THEN ToggleReverse
    ELSIF k = ORD(" ") THEN TogglePause
    ELSIF k = Fl.KeyRight THEN
      IF paused & Fl.GetKey(Fl.KeyRight) THEN NextFrame END
    ELSE
      RETURN FALSE
    END;
    win.Redraw;
    RETURN TRUE
  END;
  RETURN FALSE
END Events;

PROCEDURE Main;
  VAR i, n: INTEGER;
BEGIN
  (* the play parameters, from the command line *)
  argc := Args.argc; ASSERT(argc <= LEN(argument));
  FOR i := 0 TO argc - 1 DO Args.Get(i, argument[i]) END;
  n := 0; i := 1;
  WHILE i < argc DO
    IF argument[i] = "-r" THEN reverse := ~reverse
    ELSIF (argument[i] = "-s") & (i + 1 < argc) THEN
      INC(i);
      Strings.StrToLongReal(argument[i], speedFactor);
      argument[i] := ""
    ELSIF argument[i][0] # "-" THEN INC(n)
    ELSE
      Out.String("Invalid argument: '"); Out.String(argument[i]); Out.String("'"); Out.Ln;
      HALT(1)
    END;
    INC(i)
  END;
  IF n = 0 THEN
    Out.String("Test program for application controlled GIF animation."); Out.Ln;
    Out.String("Please specify one or more image files!"); Out.Ln;
    RETURN
  END;
  IF (speedFactor < 0.01D0) OR (speedFactor > 100.0D0) THEN speedFactor := 1.0D0 END;

  NEW(win); Fl.OpenDoubleWindow(win, 800, 600, "");

  (* a canvas for the animation, which shows it in its middle *)
  NEW(canvas); Fl.OpenBox(canvas, 0, 0, win.W(), win.H(), "");
  NEW(help); Fl.OpenBox(help, 0, win.H() - 20, win.W(), 20, "Keys: N=next file, I=toggle info, R=play reverse, +/-/Enter/Space=change speed, Z=Zoom");
  win.SetResizable(win);

  win.End;
  win.Show;
  Fl.AddHandler(Events);

  LoadNext;
  Fl.Run
END Main;

BEGIN
  speedFactor := 1.0D0;
  NEW(animgif); NEW(timer);
  Main
END AnimGifImagePlay.
