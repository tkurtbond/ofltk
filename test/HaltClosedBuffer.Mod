MODULE HaltClosedBuffer; (* A closed buffer used halts with Fl.ClosedResource, 73 *)
IMPORT FlText;
VAR b: FlText.TextBuffer;
BEGIN
  NEW(b); FlText.OpenBuffer(b); b.Close;
  b.SetText("too late")
END HaltClosedBuffer.
