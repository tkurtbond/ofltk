MODULE HaltClosedImage; (* An image used after Close halts with Fl.ClosedResource, 73 *)
IMPORT FlImages;
VAR i: FlImages.Image; bits: ARRAY 3 OF CHAR; n: INTEGER;
BEGIN
  NEW(i); FlImages.OpenRGB(i, bits, 1, 1, 3, 0);
  i.Close;
  n := i.W()
END HaltClosedImage.
