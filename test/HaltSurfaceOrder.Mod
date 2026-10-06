MODULE HaltSurfaceOrder; (* Ending a surface that isn't the one last begun halts with Fl.OutOfOrder, 77 *)
IMPORT FlImages;
VAR s, t: FlImages.Surface;
BEGIN
  NEW(s); FlImages.OpenSurface(s, 2, 2);
  NEW(t); FlImages.OpenSurface(t, 2, 2);
  s.Begin; t.Begin;
  s.End
END HaltSurfaceOrder.
