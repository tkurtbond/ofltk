MODULE HaltMultiLabel; (* A multi-label put in itself halts with Fl.Unsupported, 78 *)
IMPORT FlImages;
VAR m, n: FlImages.MultiLabel;
BEGIN
  NEW(m); FlImages.OpenMultiLabel(m);
  NEW(n); FlImages.OpenMultiLabel(n);
  m.SetMulti(0, n);
  n.SetMulti(1, m)
END HaltMultiLabel.
