MODULE HaltAnimFrame; (* SetFrame of a playing animation halts with Fl.Unsupported, 78 *)
IMPORT FlImages;
VAR a: FlImages.AnimGIF;
BEGIN
  NEW(a); ASSERT(FlImages.OpenAnimGIF(a, "images/anim.gif", NIL, {}));
  a.SetFrame(1)
END HaltAnimFrame.
