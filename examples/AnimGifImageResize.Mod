MODULE AnimGifImageResize; (* FLTK's examples/animgifimage-resize.cxx: an animated GIF copied to its canvas's size as the window is resized *)

IMPORT Args, Out, Fl, FlDraw, FlImages;

TYPE
  (* Shows a copy of the animation at its own size, made a moment after
     each resize, over a transparency grid. *)
  Canvas = POINTER TO RECORD (Fl.BoxDesc)
    shown: FlImages.AnimGIF  (* its image: orig, or a copy *)
  END;

  (* Copies the animation to its canvas's size: resizing is put off to a
     timer, so a window being dragged to a new size doesn't lock up. *)
  ResizeTimer = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  orig: FlImages.AnimGIF;
  drawGrid: BOOLEAN;
  win: Fl.DoubleWindow;
  canvas: Canvas;
  resizer: ResizeTimer;

PROCEDURE Events(event: INTEGER): BOOLEAN;
BEGIN
  IF event = Fl.EvShortcut THEN
    IF Fl.EventKey() = ORD("g") THEN
      drawGrid := ~drawGrid;
      Out.String("grid: "); IF drawGrid THEN Out.String("ON") ELSE Out.String("OFF") END; Out.Ln
    ELSIF Fl.EventKey() = ORD("b") THEN
      IF FlImages.ScalingAlgorithm() # FlImages.ScalingBilinear THEN
        FlImages.SetScalingAlgorithm(FlImages.ScalingBilinear)
      ELSE
        FlImages.SetScalingAlgorithm(FlImages.ScalingNearest)
      END;
      Out.String("bilenear: ");
      IF FlImages.ScalingAlgorithm() # FlImages.ScalingBilinear THEN Out.String("OFF") ELSE Out.String("ON") END;
      Out.Ln
    ELSE
      RETURN FALSE
    END;
    win.Redraw
  END;
  RETURN TRUE  (* as FLTK's example: every event but an unused shortcut *)
END Events;

PROCEDURE (c: Canvas) Draw*;
  CONST sz = 8;
  VAR x, y, c1, c2: INTEGER;
BEGIN
  IF drawGrid THEN
    (* a transparency grid as background *)
    c1 := Fl.RGB(0CCH, 0CCH, 0CCH); c2 := Fl.RGB(88H, 88H, 88H);
    y := 0;
    WHILE y < c.H() DO
      x := 0;
      WHILE x < c.W() DO
        IF (x MOD (sz * 2) # 0) = (y MOD (sz * 2) # 0) THEN FlDraw.SetColor(c1) ELSE FlDraw.SetColor(c2) END;
        FlDraw.RectF(x, y, 32, 32);
        INC(x, sz)
      END;
      INC(y, sz)
    END
  END;
  (* the frame shown, over the grid *)
  c.Draw^
END Draw;

PROCEDURE (c: Canvas) DoResize(w, h: INTEGER);
  VAR copied: FlImages.AnimGIF;
BEGIN
  IF (c.shown # NIL) & ((c.shown.W() # w) OR (c.shown.H() # h)) THEN
    c.shown.Stop;
    FlImages.SetImage(c, NIL);
    (* let go of a copy already made *)
    IF c.shown # orig THEN c.shown.Close END;
    NEW(copied); orig.Copy(copied, w, h);
    Out.String("resized to "); Out.Int(copied.W(), 0); Out.String(" x "); Out.Int(copied.H(), 0); Out.Ln;
    copied.SetCanvas(c, FlImages.DontResizeCanvas);
    c.shown := copied
  END;
  win.SetCursor(Fl.CursorDefault)
END DoResize;

PROCEDURE (t: ResizeTimer) Fire*;
BEGIN canvas.DoResize(canvas.W(), canvas.H())
END Fire;

PROCEDURE (c: Canvas) Resize*(x, y, w, h: INTEGER);
BEGIN
  c.Resize^(x, y, w, h);
  Fl.RemoveTimeout(resizer);
  Fl.AddTimeout(resizer, 0.1D0);
  win.SetCursor(Fl.CursorWait)
END Resize;

PROCEDURE Main;
  VAR
    fileName, a: ARRAY 1024 OF CHAR;
    haveFile, bilinear, optimize, uncache, debug: BOOLEAN;
    i, n, x, y, w, h, wW, wH: INTEGER;
    flags: SET;
    ratio: LONGREAL;
BEGIN
  (* the play parameters, from the command line *)
  haveFile := FALSE; bilinear := FALSE; optimize := FALSE; uncache := FALSE; debug := FALSE;
  FOR i := 1 TO Args.argc - 1 DO
    Args.Get(i, a);
    IF a = "-b" THEN bilinear := TRUE  (* bilinear scaling on *)
    ELSIF a = "-o" THEN optimize := TRUE
    ELSIF a = "-g" THEN drawGrid := FALSE
    ELSIF a = "-u" THEN uncache := TRUE
    ELSIF a = "-d" THEN debug := TRUE
    ELSIF (a[0] # "-") & ~haveFile THEN fileName := a; haveFile := TRUE
    ELSIF a[0] = "-" THEN
      Out.String("Invalid argument: '"); Out.String(a); Out.String("'"); Out.Ln;
      HALT(1)
    END
  END;
  IF ~haveFile THEN
    Args.Get(0, a);
    Out.String("Test program for animated copy."); Out.Ln;
    Out.String("Usage: "); Out.String(a); Out.String(" fileName [-b]ilinear [-o]ptimize [-g]rid [-u]ncache"); Out.Ln;
    RETURN
  END;
  FlImages.SetAnimMinDelay(0.1D0);  (* a minimum delay for playback *)

  NEW(win); Fl.OpenDoubleWindow(win, 640, 480, "");

  (* a canvas for the animation *)
  NEW(canvas); Fl.OpenBox(canvas, 0, 0, win.W(), win.H(), "");
  win.SetResizable(win);
  win.SizeRange(1, 1, 0, 0);

  win.End;
  win.Show;

  (* Load the animated GIF and start it at once. DontResizeCanvas tells
     the animation not to size the canvas to itself, as it would by
     default. *)
  flags := FlImages.DontResizeCanvas;
  IF optimize THEN
    flags := flags + FlImages.OptimizeMemory;
    Out.String("Using memory optimization (if image supports)"); Out.Ln
  END;
  IF debug THEN flags := flags + FlImages.AnimDebug END;
  NEW(orig);
  IF FlImages.OpenAnimGIF(orig, fileName, canvas, flags) THEN
    canvas.shown := orig;
    Out.String(fileName); Out.String(": frames: "); Out.Int(orig.Frames(), 0);
    Out.String(" uncache: "); IF orig.FrameUncache() THEN Out.Int(1, 0) ELSE Out.Int(0, 0) END; Out.Ln;
    win.SetLabel(fileName);

    (* how many frames are optimized: drawn in part of the canvas *)
    n := 0;
    FOR i := 0 TO orig.Frames() - 1 DO
      orig.FrameXYWH(i, x, y, w, h);
      IF (x # 0) OR (y # 0) THEN INC(n) END
    END;
    Out.String("image has "); Out.Int(n, 0); Out.String(" optimized frames"); Out.Ln;

    FlImages.SetScalingAlgorithm(FlImages.ScalingNearest);
    IF bilinear THEN
      FlImages.SetScalingAlgorithm(FlImages.ScalingBilinear);
      (* this can be very slow at large sizes, where FLTK scales without
         the hardware *)
      Out.String("Using bilinear scaling - can be slow!"); Out.Ln
    END;
    orig.SetFrameUncache(uncache);
    IF uncache THEN Out.String("Caching disabled - watch cpu load!"); Out.Ln END;

    (* an initial size to fit the window *)
    ratio := orig.W() / orig.H();
    wW := win.W() - 40;
    wH := SHORT(ENTIER(wW / ratio));
    Out.String("original size: "); Out.Int(orig.W(), 0); Out.String(" x "); Out.Int(orig.H(), 0); Out.Ln;
    win.Size(wW, wH);
    Fl.AddHandler(Events);

    Fl.Run
  ELSE
    Out.String(fileName); Out.String(": not a GIF FLTK can read"); Out.Ln
  END
END Main;

BEGIN
  drawGrid := TRUE;
  NEW(resizer);
  Main
END AnimGifImageResize.
