MODULE AnimGifImageSimple; (* FLTK's examples/animgifimage-simple.cxx: an animated GIF, played in a box *)

(* FLTK's example shows its own test/images/fltk_animated.gif unless given
   a file; this one shows pofltk's test/images/anim.gif, from examples/. *)

IMPORT Args, Out, Fl, FlImages;

VAR
  win: Fl.DoubleWindow;
  canvas: Fl.Box;
  animgif: FlImages.AnimGIF;
  name: ARRAY 1024 OF CHAR;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 400, 300, "Fl_Anim_GIF_Image demo");

  (* prepare a canvas (widget) for the animation *)
  NEW(canvas); Fl.OpenBox(canvas, 20, 40, win.W() - 40, win.H() - 80, "Hello from FLTK GIF-animation!");
  canvas.SetAlign(Fl.AlignTop + Fl.AlignImageBackdrop);
  canvas.SetLabelSize(20);

  win.SetResizable(win);
  win.End;
  win.Show;  (* FLTK's show(1, argv): no options, which the file name isn't *)

  (* Load the animated GIF as the canvas's image, and start it at once.
     DontResizeCanvas tells the animation not to size the canvas to
     itself, as it would by default. *)
  IF Args.argc > 1 THEN Args.Get(1, name) ELSE name := "../test/images/anim.gif" END;
  NEW(animgif);
  IF FlImages.OpenAnimGIF(animgif, name, canvas, FlImages.DontResizeCanvas) THEN
    (* scale the animation to the canvas *)
    animgif.Scale(canvas.W(), canvas.H(), TRUE, TRUE);
    Out.String(name); Out.String(": frames="); Out.Int(animgif.Frames(), 0);
    Out.String(", size="); Out.Int(animgif.CanvasW(), 0); Out.String("x");
    Out.Int(animgif.CanvasH(), 0); Out.Ln;
    Fl.Run
  ELSE
    Out.String(name); Out.String(": not a GIF FLTK can read"); Out.Ln
  END
END AnimGifImageSimple.
