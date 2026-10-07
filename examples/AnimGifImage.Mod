MODULE AnimGifImage; (* FLTK's examples/animgifimage.cxx: animated GIFs, each in a window, with FLTK's tests of them *)

(* AnimGifImage -t [directory] [-flags]: every GIF in directory
                                        ("testsuite")
   AnimGifImage file... [-flags]: each file
   AnimGifImage: a file chosen, again and again, each window deleted as
                 the next is chosen

   flags: d debug (dd more, ddd a window for each frame), u uncached,
   D desaturated, A color averaged, T tiled, m minimal update (memory
   optimized), f a second canvas the program redraws, r[factor] resized
   by factor. '+', '-' and '0' change the speed of the animation under
   the mouse.

   FLTK's example keeps each window's animation in its user data; this
   one keeps it in the window's record, and the canvas's, which also
   find it for the keys. *)

IMPORT Args, Out, Strings, Fl, FlImages, FlDialogs, RealDigits, OutStr;

CONST
  backGroundColor = Fl.Gray;  (* Fl.Red, say, shows transparent parts better *)
  redrawDelay = 1.0D0 / 20;  (* seconds between forced redraws *)
  testsuite = "testsuite";

TYPE
  (* A window, and the animation it shows *)
  AnimWindow = POINTER TO RECORD (Fl.DoubleWindowDesc)
    anim: FlImages.AnimGIF
  END;

  (* A box showing an animation *)
  Canvas = POINTER TO RECORD (Fl.BoxDesc)
    anim: FlImages.AnimGIF;
    win: AnimWindow
  END;

  (* A group tiled with an animation *)
  TileGroup = POINTER TO RECORD (Fl.GroupDesc)
    anim: FlImages.AnimGIF;
    win: AnimWindow
  END;

  Flags = ARRAY 1024 OF CHAR;

VAR
  goodCount, badCount, frameCount: INTEGER;
  forcedRedraw: Fl.Timer;

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

(* Whether c is in s. *)
PROCEDURE Has(s-: ARRAY OF CHAR; c: CHAR): BOOLEAN;
  VAR i: INTEGER;
BEGIN
  i := 0; WHILE (s[i] # 0X) & (s[i] # c) DO INC(i) END;
  RETURN s[i] = c
END Has;

PROCEDURE QuitCB(w: Fl.Widget);
BEGIN HALT(0)
END QuitCB;

PROCEDURE SetTitle(win: Fl.Window; animgif: FlImages.AnimGIF);
  VAR name, buf: ARRAY 1024 OF CHAR; speed: ARRAY 40 OF CHAR; i, j: INTEGER;
BEGIN
  animgif.GetName(name);
  (* fl_filename_name: the name after the last "/" *)
  i := 0; j := 0;
  WHILE name[i] # 0X DO IF name[i] = "/" THEN j := i + 1 END; INC(i) END;
  buf := ""; i := j;
  WHILE name[i] # 0X DO OutStr.Char(name[i], buf); INC(i) END;
  OutStr.String(" (", buf); OutStr.Int(animgif.Frames(), 0, buf); OutStr.String(" frames)  ", buf);
  Fixed2(animgif.Speed(), speed); OutStr.String(speed, buf); OutStr.Char("x", buf);
  IF animgif.FrameUncache() THEN OutStr.String(" U", buf) END;
  win.SetLabel(buf);
  win.SetTooltip(buf)
END SetTitle;

(* Redraws every window while any is shown. *)
PROCEDURE ForcedRedraw(t: Fl.Timer);
BEGIN
  Fl.Redraw;
  IF Fl.WindowShown() THEN Fl.RepeatTimeout(t, redrawDelay) END
END ForcedRedraw;

(* The real number at s[from], as atof reads it; 0 for none. *)
PROCEDURE Atof(s-: ARRAY OF CHAR; from: INTEGER): LONGREAL;
  VAR n: ARRAY 64 OF CHAR; i: INTEGER; r: LONGREAL;
BEGIN
  i := 0;
  WHILE (i < LEN(n) - 1) & ((s[from + i] >= "0") & (s[from + i] <= "9") OR (s[from + i] = ".")) DO
    n[i] := s[from + i]; INC(i)
  END;
  n[i] := 0X;
  IF i = 0 THEN RETURN 0.0D0 END;
  Strings.StrToLongReal(n, r);
  RETURN r
END Atof;

PROCEDURE OpenFile(name-: ARRAY OF CHAR; flags-: ARRAY OF CHAR; close: BOOLEAN): AnimWindow;
  VAR
    uncache, optimizeMem, desaturate, average, testTiles, testForcedRedraw, resizable, good: BOOLEAN;
    debug, i, w, h, x, y, fw, fh, bigW, bigH: INTEGER;
    scale: LONGREAL;
    win, fwin: AnimWindow;
    canvas, canvas2: Canvas;
    group: TileGroup;
    b: Fl.Box;
    tiled, frame: FlImages.Image;
    animgif: FlImages.AnimGIF;
    gifFlags: SET;
    buf: ARRAY 200 OF CHAR;
BEGIN
  (* the test's options, from flags *)
  uncache := Has(flags, "u");
  debug := 0; i := 0;
  WHILE flags[i] # 0X DO IF flags[i] = "d" THEN INC(debug) END; INC(i) END;
  optimizeMem := Has(flags, "m");
  desaturate := Has(flags, "D");
  average := Has(flags, "A");
  testTiles := Has(flags, "T");
  testForcedRedraw := Has(flags, "f");
  resizable := Has(flags, "r") & ~testTiles;
  scale := 1.0D0;
  IF resizable THEN
    i := 0; WHILE flags[i] # "r" DO INC(i) END;
    scale := Atof(flags, i + 1)
  END;
  IF (scale <= 0.1D0) OR (scale > 5.0D0) THEN
    IF resizable THEN scale := 0.7D0 ELSE scale := 1.0D0 END
  END;

  (* the window *)
  Fl.RemoveTimeout(forcedRedraw);
  NEW(win); Fl.OpenDoubleWindow(win, 300, 300, "");
  win.SetColor(backGroundColor);
  IF close THEN win.action := QuitCB END;
  Out.String("Loading '"); Out.String(name); Out.String("'");
  IF uncache THEN Out.String(" (uncached)") END;
  IF optimizeMem THEN Out.String(" (optimized)") END;
  Out.String(" ... ");

  (* a canvas for the animation, which sizes it *)
  canvas := NIL; canvas2 := NIL;
  IF ~testTiles THEN NEW(canvas); Fl.OpenBox(canvas, 0, 0, 0, 0, ""); canvas.win := win END;
  gifFlags := {};
  IF debug > 0 THEN gifFlags := FlImages.AnimLog END;
  IF debug > 1 THEN gifFlags := gifFlags + FlImages.AnimDebug END;
  IF optimizeMem THEN gifFlags := gifFlags + FlImages.OptimizeMemory END;

  (* the animation, shown by the canvas *)
  NEW(animgif);
  good := FlImages.OpenAnimGIF(animgif, name, canvas, gifFlags);
  Out.String(name); Out.String(": ");
  IF good THEN
    Out.Int(animgif.W(), 0); Out.String(" x "); Out.Int(animgif.H(), 0);
    Out.String(" ("); Out.Int(animgif.Frames(), 0); Out.String(" frames) OK")
  ELSE
    Out.String("0 x 0 (0 frames) ERROR")
  END;
  Out.Ln;
  (* the statistics, for a directory *)
  IF good THEN INC(goodCount); INC(frameCount, animgif.Frames()) ELSE INC(badCount) END;

  IF ~good THEN win.Delete; RETURN NIL END;  (* FLTK's: no frames *)
  win.anim := animgif;
  IF canvas # NIL THEN canvas.anim := animgif END;

  (* the optional tests of the animation *)
  animgif.SetFrameUncache(uncache);
  IF scale # 1.0D0 THEN
    animgif.ResizeBy(scale);
    Out.String("TEST: resized "); Out.String(name); Out.String(" by "); Fixed2(scale, buf); Out.String(buf);
    Out.String(" to "); Out.Int(animgif.W(), 0); Out.String(" x "); Out.Int(animgif.H(), 0); Out.Ln
  END;
  IF average THEN
    Out.String("TEST: color_average "); Out.String(name); Out.Ln;
    animgif.ColorAverage(Fl.Green, 0.5)  (* fixed, as FLTK's *)
  END;
  IF desaturate THEN
    Out.String("TEST: desaturate "); Out.String(name); Out.Ln;
    animgif.Desaturate
  END;
  bigW := animgif.W(); bigH := animgif.H();
  IF testTiles THEN
    (* the animation as the tile of a tiled image *)
    Out.String("TEST: use "); Out.String(name); Out.String(" as tiles"); Out.Ln;
    bigW := bigW * 2; bigH := bigH * 2;
    NEW(tiled); FlImages.OpenTiled(tiled, animgif, 0, 0);
    NEW(group); Fl.OpenGroup(group, 0, 0, win.W(), win.H(), "");
    group.anim := animgif; group.win := win;
    FlImages.SetImage(group, tiled);
    group.SetAlign(Fl.AlignInside);
    animgif.SetCanvas(group, FlImages.DontResizeCanvas + FlImages.DontSetAsImage);
    win.SetResizable(group)
  ELSIF testForcedRedraw & (bigW < 400) THEN
    (* the same animation in a second canvas: FLTK redraws only one, so
       the program redraws them all *)
    Out.String("TEST: open "); Out.String(name); Out.String(" in another animation with application redraw"); Out.Ln;
    NEW(canvas2); Fl.OpenBox(canvas2, bigW, 0, animgif.W(), animgif.H(), "");
    canvas2.anim := animgif; canvas2.win := win;
    FlImages.SetImage(canvas2, animgif);
    bigW := bigW * 2;
    Fl.AddTimeout(forcedRedraw, redrawDelay)
  END;
  (* resizable before Show *)
  IF resizable & (canvas # NIL) THEN win.SetResizable(win) END;
  win.Size(bigW, bigH);  (* the canvas's size *)
  win.End;
  win.Show;
  win.WaitForExpose;
  SetTitle(win, animgif);
  IF resizable THEN
    (* SetResizable moved the widgets *)
    IF canvas2 # NIL THEN
      canvas.Resize(0, 0, bigW DIV 2, canvas.H());
      canvas2.Resize(bigW DIV 2, 0, bigW DIV 2, canvas2.H())
    ELSE
      canvas.Resize(0, 0, animgif.CanvasW(), animgif.CanvasH())
    END
  END;
  win.InitSizes;  (* or scaling with Ctrl and + or - goes wrong *)

  IF debug >= 3 THEN
    (* each frame in a window of its own *)
    FOR i := 0 TO animgif.Frames() - 1 DO
      buf := "Frame #"; OutStr.Int(i + 1, 0, buf);
      NEW(fwin); Fl.OpenDoubleWindow(fwin, animgif.W(), animgif.H(), buf);
      fwin.SetTooltip(buf);
      fwin.SetColor(backGroundColor);
      NEW(frame); animgif.FrameImage(i, frame);
      w := frame.W(); h := frame.H();
      (* optimized frames are drawn at their place in the canvas *)
      animgif.FrameXYWH(i, x, y, fw, fh);
      IF (w = animgif.W()) & (h = animgif.H()) THEN x := 0; y := 0 END;
      NEW(b); Fl.OpenBox(b, x, y, w, h, "");
      FlImages.SetImage(b, frame); frame.Close;
      fwin.End;
      fwin.Show
    END
  END;
  RETURN win
END OpenFile;

PROCEDURE OpenDirectory(dir-: ARRAY OF CHAR; VAR flags: Flags): BOOLEAN;
  VAR names: FlDialogs.Names; name, buf: ARRAY 512 OF CHAR; i, cnt, p: INTEGER;
BEGIN
  IF ~FlDialogs.ListDirectory(dir, FlDialogs.AlphaSort, names) OR (LEN(names^) = 0) THEN RETURN FALSE END;
  cnt := 0;
  FOR i := 0 TO SHORT(LEN(names^)) - 1 DO
    COPY(names[i]^, name);
    p := Strings.Pos(".gif", name, 0);
    IF p < 0 THEN p := Strings.Pos(".GIF", name, 0) END;
    (* a name ending .gif or .GIF, where it first has either *)
    IF (name # ".") & (name # "..") & (p >= 0) & (name[p + 4] = 0X) THEN
      buf := ""; OutStr.String(dir, buf); OutStr.Char("/", buf); OutStr.String(name, buf);
      (* a name with "debug" in it opens each frame too, as do those after it *)
      IF Strings.Pos("debug", name, 0) >= 0 THEN Strings.Append("d", flags) END;
      IF OpenFile(buf, flags, cnt = 0) # NIL THEN INC(cnt) END
    END
  END;
  RETURN cnt # 0
END OpenDirectory;

(* Changes the speed of the animation under the mouse, by delta; back to
   1 for 0. *)
PROCEDURE ChangeSpeed(delta: LONGREAL);
  VAR below: Fl.Widget; animgif: FlImages.AnimGIF; win: AnimWindow; speed: LONGREAL;
BEGIN
  below := Fl.BelowMouse(); animgif := NIL;
  IF below = NIL THEN
  ELSIF below IS Canvas THEN animgif := below(Canvas).anim; win := below(Canvas).win
  ELSIF below IS TileGroup THEN animgif := below(TileGroup).anim; win := below(TileGroup).win
  END;
  IF (animgif # NIL) & animgif.Playing() THEN
    speed := animgif.Speed();
    IF delta = 0.0D0 THEN speed := 1.0D0 ELSE speed := speed + delta END;
    IF speed < 0.1D0 THEN speed := 0.1D0 END;
    IF speed > 10.0D0 THEN speed := 10.0D0 END;
    animgif.SetSpeed(speed);
    SetTitle(win, animgif)
  END
END ChangeSpeed;

PROCEDURE Events(event: INTEGER): BOOLEAN;
BEGIN
  IF event = Fl.EvShortcut THEN
    IF Fl.EventKey() = ORD("+") THEN ChangeSpeed(0.1D0)
    ELSIF Fl.EventKey() = ORD("-") THEN ChangeSpeed(-0.1D0)
    ELSIF Fl.EventKey() = ORD("0") THEN ChangeSpeed(0.0D0)
    ELSE RETURN FALSE
    END;
    RETURN TRUE
  END;
  RETURN FALSE
END Events;

PROCEDURE Main;
  VAR
    openFlags: Flags;
    arg, dir: ARRAY 1024 OF CHAR;
    filename: ARRAY 1024 OF CHAR;
    i, j, k: INTEGER;
    win: AnimWindow;
    ok: BOOLEAN;
BEGIN
  Fl.AddHandler(Events);
  openFlags := "";
  IF Args.argc > 1 THEN
    (* with arguments *)
    Args.Get(1, arg);
    IF Strings.Pos("-h", arg, 0) >= 0 THEN
      Out.String("Usage:"); Out.Ln;
      Out.String("   -t [directory] [-{flags}] open all files in directory (default name: ");
      Out.String(testsuite); Out.String(") [with options]"); Out.Ln;
      Out.String("   filename [-{flags}] open single file [with options] "); Out.Ln;
      Out.String("   No arguments open a fileselector"); Out.Ln;
      Out.String("   {flags} can be: d=debug mode, u=uncached, D=desaturated, A=color averaged, T=tiled"); Out.Ln;
      Out.String("                   m=minimal update, r[scale factor]=resize by 'scale factor'"); Out.Ln;
      Out.String("   Use keys '+'/'-/0' to change speed of the active image (belowmouse)."); Out.Ln;
      HALT(1)
    END;
    FOR i := 1 TO Args.argc - 1 DO
      Args.Get(i, arg);
      IF arg[0] = "-" THEN
        k := Strings.Length(openFlags); j := 1;
        WHILE (arg[j] # 0X) & (k < LEN(openFlags) - 1) DO openFlags[k] := arg[j]; INC(j); INC(k) END;
        openFlags[k] := 0X
      END
    END;
    IF Has(openFlags, "t") THEN
      (* every GIF in a directory *)
      dir := testsuite;
      FOR i := 2 TO Args.argc - 1 DO
        Args.Get(i, arg);
        IF arg[0] # "-" THEN dir := arg END
      END;
      ok := OpenDirectory(dir, openFlags);
      Out.String("Summary: good="); Out.Int(goodCount, 0); Out.String(", bad="); Out.Int(badCount, 0);
      Out.String(", frames="); Out.Int(frameCount, 0); Out.Ln
    ELSE
      (* the files given *)
      FOR i := 1 TO Args.argc - 1 DO
        Args.Get(i, arg);
        IF arg[0] # "-" THEN win := OpenFile(arg, openFlags, Has(openFlags, "d")) END
      END
    END
  ELSE
    (* no arguments: a file chosen, again and again *)
    FlImages.SetAnimateGIFs(TRUE);  (* GIFs FLTK loads (the chooser's preview) animated *)
    LOOP
      Fl.AddTimeout(forcedRedraw, 0.1D0);  (* animates the chooser's images *)
      filename := "";
      ok := FlDialogs.ChooseFile("Select a GIF image file", "*.{gif,GIF}", filename, FALSE);
      Fl.RemoveTimeout(forcedRedraw);
      IF ~ok THEN EXIT END;
      win := OpenFile(filename, openFlags, FALSE);
      Fl.Run;
      (* The last window, now hidden, is deleted, to test the
         destructors. FLTK's example must delete the animation first, or
         its timer redraws a canvas deleted; FlImages makes either order
         safe. *)
      IF win # NIL THEN win.anim.Close; win.Delete END
    END
  END;
  Fl.Run
END Main;

BEGIN
  NEW(forcedRedraw); forcedRedraw.action := ForcedRedraw;
  Main
END AnimGifImage.
