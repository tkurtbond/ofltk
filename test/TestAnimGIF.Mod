MODULE TestAnimGIF; (* FlImages.AnimGIF: animated GIFs, their frames, canvases and timers *)

(* images/anim.gif has three 4 by 2 frames, 0.1 s each: red left and blue
   right, then green, then blue. *)

IMPORT GC := GarbageCollectedHeap, Files, Fl, FlImages, Check, Probe;

VAR
  win: Fl.Window;
  box, box2, box3: Fl.Box;
  a, b, c: FlImages.AnimGIF;
  i, t: FlImages.Image;
  name: ARRAY 64 OF CHAR;
  data: ARRAY 1024 OF CHAR;
  x, y, w, h, n, k, red, green, blue: INTEGER;
  ok: BOOLEAN;

(* The bytes of file name into data; their number. *)
PROCEDURE Read(name: ARRAY OF CHAR): INTEGER;
  VAR f: Files.File; r: Files.Rider; n: INTEGER;
BEGIN
  f := Files.Old(name); ASSERT(f # NIL);
  n := SHORT(Files.Length(f)); ASSERT(n <= LEN(data));
  Files.Set(r, f, 0); Files.ReadBytes(r, data, n); Files.Close(f);
  RETURN n
END Read;

(* Pixel x, y of widget w as drawn. *)
PROCEDURE Pixel(w: Fl.Widget; x, y: INTEGER): INTEGER;
  VAR p: INTEGER;
BEGIN ok := Probe.Capture(w); p := Probe.Pixel(x, y); Probe.Release; RETURN p
END Pixel;

(* Waits until a's frame isn't f, up to a generous limit, for valgrind. *)
PROCEDURE WaitFrame(a: FlImages.AnimGIF; f: INTEGER);
  VAR k: INTEGER;
BEGIN k := 0; WHILE (a.Frame() = f) & (k < 500) DO Fl.Wait(0.01D0); INC(k) END
END WaitFrame;

(* Lets FLTK's timers run for about s seconds. *)
PROCEDURE Run(s: LONGREAL);
  VAR k: INTEGER;
BEGIN FOR k := 1 TO SHORT(ENTIER(s * 100)) DO Fl.Wait(0.01D0) END
END Run;

(* Opens an animation playing in box3, and loses it. *)
PROCEDURE Lose;
  VAR a: FlImages.AnimGIF;
BEGIN NEW(a); ASSERT(FlImages.OpenAnimGIF(a, "images/anim.gif", box3, {}))
END Lose;

BEGIN
  red := Fl.RGB(255, 0, 0); green := Fl.RGB(0, 255, 0); blue := Fl.RGB(0, 0, 255);
  NEW(win); Fl.OpenWindow(win, 100, 100, "TestAnimGIF");
  NEW(box); Fl.OpenBox(box, 0, 0, 50, 50, "");
  NEW(box2); Fl.OpenBox(box2, 50, 0, 50, 50, "");
  NEW(box3); Fl.OpenBox(box3, 0, 50, 50, 50, "");
  win.End;

  (* Opening *)
  NEW(a);
  Check.Check(FlImages.OpenAnimGIF(a, "images/anim.gif", box, FlImages.DontStart), "OpenAnimGIF");
  a.GetName(name);
  Check.Check((a.Kind() = FlImages.Animation) & (a.Frames() = 3) & (a.Frame() = 0) & a.IsAnimated()
    & ~a.Playing() & (a.CanvasW() = 4) & (a.CanvasH() = 2) & (a.W() = 4) & (name = "images/anim.gif"),
    "its frames, size and name");
  Check.Check((ABS(a.Delay(1) - 0.1D0) < 1.0D-6) & (a.Speed() = 1.0D0) & ~a.FrameUncache(), "its delays and speed");
  Check.Check((box.W() = 4) & (box.H() = 2), "the canvas sized to it");
  Check.Check((Pixel(box, 0, 0) = red) & (Pixel(box, 3, 1) = blue), "and showing it, at frame 0");
  Check.Check((a.Pixel(0, 0) = red) & (a.Pixel(3, 0) = blue), "its pixels, the frame's");
  NEW(b);
  Check.Check(~FlImages.OpenAnimGIF(b, "images/rb.png", box2, {}) & ~b.IsOpen(), "a PNG isn't one");
  Check.Check(~FlImages.OpenAnimGIF(b, "images/none.gif", box2, {}) & ~b.IsOpen(), "nor a file that isn't there");
  Check.Check(box2.W() = 50, "and the canvas is left alone");
  n := Read("images/anim.gif");
  Check.Check(FlImages.OpenAnimGIFData(b, data, n, NIL, FlImages.DontStart), "OpenAnimGIFData");
  b.GetName(name);
  Check.Check((b.Frames() = 3) & (name = "") & (b.Canvas() = NIL), "with no name, and no canvas");
  b.Close;

  (* Frames *)
  a.SetFrame(1);
  Check.Check((a.Frame() = 1) & (Pixel(box, 0, 0) = green), "SetFrame");
  a.Next; a.Next;
  Check.Check((a.Frame() = 0) & (Pixel(box, 0, 0) = red), "Next, the first after the last");
  a.FrameXYWH(2, x, y, w, h);
  Check.Check((x = 0) & (y = 0) & (w = 4) & (h = 2), "FrameXYWH");
  NEW(i); a.FrameImage(1, i);
  Check.Check((i.Kind() = FlImages.RGB) & (i.Pixel(3, 1) = green), "FrameImage");
  i.Close;
  a.SetDelay(1, 0.05D0);
  Check.Check(ABS(a.Delay(1) - 0.05D0) < 1.0D-6, "SetDelay");

  (* Playing *)
  a.Start;
  Check.Check(a.Playing() & (a.Frame() = 1), "Start, from the next frame");
  WaitFrame(a, 1);
  Check.Check(a.Frame() = 2, "it plays, from FLTK's timers");
  a.Stop; n := a.Frame(); Run(0.3D0);
  Check.Check(~a.Playing() & (a.Frame() = n), "Stop");
  a.SetSpeed(2.0D0); FlImages.SetAnimMinDelay(0.02D0);
  Check.Check((a.Speed() = 2.0D0) & (FlImages.AnimMinDelay() = 0.02D0), "SetSpeed, SetAnimMinDelay");
  FlImages.SetAnimMinDelay(0.0D0);
  Check.Check(FlImages.ScalingAlgorithm() = FlImages.ScalingBilinear, "scaling is bilinear to start with");
  FlImages.SetScalingAlgorithm(FlImages.ScalingNearest);
  Check.Check(FlImages.ScalingAlgorithm() = FlImages.ScalingNearest, "SetScalingAlgorithm");
  a.SetFrameUncache(TRUE);
  Check.Check(a.FrameUncache(), "SetFrameUncache");
  a.SetFrameUncache(FALSE);

  (* Sizes *)
  a.SetFrame(0); a.Resize(8, 4);
  Check.Check((a.W() = 8) & (a.CanvasW() = 8) & (box.W() = 8) & (box.H() = 4), "Resize, the canvas too");
  Check.Check((Pixel(box, 1, 1) = red) & (Pixel(box, 7, 3) = blue), "the frames scaled");
  a.ResizeBy(0.5D0);
  Check.Check((a.W() = 4) & (box.W() = 4), "ResizeBy");

  (* Canvases *)
  a.SetCanvas(box2, FlImages.DontResizeCanvas);
  Check.Check((a.Canvas() = box2) & (box2.W() = 50) & (Pixel(box, 0, 0) # red), "SetCanvas: the old one shows nothing");
  a.SetCanvas(box, {});

  (* Copies *)
  NEW(c); a.Copy(c, 8, 4);
  Check.Check((c.Frames() = 3) & (c.W() = 8) & (c.Canvas() = NIL), "Copy: an AnimGIF, with no canvas");
  Check.Check(~a.Playing() & c.Playing(), "playing, although the original isn't (FLTK's copy)");
  c.SetCanvas(box3, {});
  Check.Check((box3.W() = 8) & (Pixel(box3, 7, 3) = blue), "given one");
  NEW(t); FlImages.OpenTiled(t, c, 16, 4); c.Close;
  Check.Check(~c.IsOpen() & (box3.W() = 8), "a canvas keeps its animation");
  t.Close;

  (* A canvas deleted first: its animation, playing, forgets it, and
     doesn't redraw it from its timer (valgrind) *)
  c := NIL; NEW(c); a.Copy(c, 4, 2); c.SetCanvas(box3, FlImages.DontSetAsImage); c.Start;
  box3.Delete;
  Check.Check(c.Playing() & (c.Canvas() = NIL), "a canvas deleted is forgotten");
  Run(0.3D0);
  (* An animation closed while its timer is pending: deleted, the timer
     with it (valgrind) *)
  c.Close; Run(0.3D0);

  (* One the collector would take, shown in a canvas *)
  NEW(box3); win.Begin; Fl.OpenBox(box3, 0, 50, 50, 50, ""); win.End;
  Lose; GC.Collect; Run(0.2D0);
  Check.Check(box3.W() = 4, "an animation lost while a canvas shows it plays on");
  box3.Delete; Run(0.2D0);

  (* The canvas deleted, still showing it: deleted with it *)
  a.Start; a.Close; Run(0.2D0);
  win.Delete; Run(0.3D0);

  Check.Check((FlImages.openImages = 0) & (Fl.OpenWidgets() = 0), "every image and widget closed");
  Check.Summary
END TestAnimGIF.
