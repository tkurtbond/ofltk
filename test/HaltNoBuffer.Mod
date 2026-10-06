MODULE HaltNoBuffer; (* A display's text method without a buffer halts with Fl.ClosedResource, 73 *)
IMPORT FlText;
VAR d: FlText.TextDisplay;
BEGIN
  NEW(d); FlText.OpenTextDisplay(d, 0, 0, 10, 10, "");
  d.Insert("nowhere")
END HaltNoBuffer.
