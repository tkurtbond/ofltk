MODULE TestClipboard; (* Fl's clipboard, and FlImages' images on it *)

IMPORT Fl, FlInputs, FlImages, Check, Probe;

TYPE
  (* Keeps what is pasted into it: the text, or the image if take. *)
  Receiver = POINTER TO RECORD (Fl.BoxDesc)
    pastes: INTEGER;
    text: ARRAY 64 OF CHAR;
    take, isImage, accept: BOOLEAN;
    img: FlImages.Image
  END;

  (* Takes part in drag and drop if accept: keeps the last such event it
     got, and how many. *)
  DndBox = POINTER TO RECORD (Fl.BoxDesc)
    accept: BOOLEAN;
    last, events: INTEGER
  END;

VAR
  win, dwin: Fl.Window;
  r: Receiver;
  d: DndBox;
  in: FlInputs.Input;
  i: FlImages.Image;
  bits: ARRAY 12 OF CHAR;
  s: ARRAY 64 OF CHAR;
  n: INTEGER;
  ok: BOOLEAN;

PROCEDURE (r: Receiver) Handle*(event: INTEGER): BOOLEAN;
  VAR ok: BOOLEAN;
BEGIN
  IF event = Fl.EvPaste THEN
    INC(r.pastes); r.isImage := Fl.EventIsImage();
    IF r.isImage THEN
      IF r.take THEN NEW(r.img); ok := FlImages.TakePastedImage(r.img) END
    ELSE Fl.EventText(r.text)
    END;
    RETURN r.accept
  END;
  RETURN r.Handle^(event)
END Handle;

PROCEDURE (d: DndBox) Handle*(event: INTEGER): BOOLEAN;
BEGIN
  IF (event >= Fl.EvDndEnter) & (event <= Fl.EvDndRelease) THEN
    d.last := event; INC(d.events);
    RETURN d.accept
  END;
  RETURN d.Handle^(event)
END Handle;

BEGIN
  NEW(win); Fl.OpenWindow(win, 100, 100, "TestClipboard");
  NEW(r); Fl.OpenBox(r, 0, 0, 10, 10, ""); r.accept := TRUE;
  NEW(in); FlInputs.OpenInput(in, 0, 20, 100, 20, "");
  win.End;

  (* Before the program owns either, under X11 no window is shown to ask
     for another program's data: nothing is pasted. *)
  Fl.Paste(r, Fl.Selection); Fl.Paste(r, Fl.Clipboard);
  Check.Check(r.pastes = 0, "Paste with nothing to paste");

  (* Text *)
  Fl.Copy("hello", Fl.Clipboard);
  Check.Check(Fl.ClipboardHasText() & ~Fl.ClipboardHasImage(), "Copy: the clipboard holds text");
  Fl.Paste(r, Fl.Clipboard);
  Check.Check((r.pastes = 1) & ~r.isImage & (r.text = "hello"), "Paste of the program's own text: at once");
  in.SetValue("ab"); in.Select(1, 1);
  Fl.Paste(in, Fl.Clipboard);
  in.Value(s);
  Check.Check(s = "ahellob", "an input pastes at its cursor");
  IF ~Probe.Wayland() THEN
    Fl.Copy("sel", Fl.Selection);
    Fl.Paste(r, Fl.Selection);
    Check.Check((r.pastes = 2) & (r.text = "sel"), "the selection buffer (X11)");
    Fl.Paste(r, Fl.Clipboard);
    Check.Check(r.text = "hello", "apart from the clipboard");
    r.pastes := 1
  ELSE
    Fl.Copy("sel", Fl.Selection);
    Fl.Paste(r, Fl.Selection);
    Check.Check(r.pastes = 1, "no selection buffer (Wayland)")
  END;
  Fl.Copy("both", Fl.Both);
  Fl.Paste(r, Fl.Clipboard);
  Check.Check(r.text = "both", "Both");

  (* Images *)
  bits[0] := 0FFX; bits[1] := 0X; bits[2] := 0X; bits[3] := 0X; bits[4] := 0X; bits[5] := 0FFX;
  NEW(i); FlImages.OpenRGB(i, bits, 2, 1, 3, 0);
  i.CopyToClipboard;
  Check.Check(Fl.ClipboardHasImage() & ~Fl.ClipboardHasText(), "CopyToClipboard");
  n := r.pastes;
  Fl.PasteImage(r);
  Check.Check((r.pastes = n + 1) & r.isImage & (r.img = NIL), "PasteImage: an EvPaste with an image");
  r.take := TRUE;
  Fl.PasteImage(r);
  Check.Check((r.img # NIL) & r.img.IsOpen() & (r.img.DataW() = 2) & (r.img.DataH() = 1)
    & (r.img.Pixel(0, 0) = Fl.RGB(255, 0, 0)) & (r.img.Pixel(1, 0) = Fl.RGB(0, 0, 255)),
    "TakePastedImage: the image, as copied");
  r.img.Close; r.img := NIL;
  (* An image not taken is freed, whatever Handle returns: valgrind sees
     no leak and no double free. *)
  r.take := FALSE; r.accept := FALSE;
  Fl.PasteImage(r);
  r.accept := TRUE;
  Fl.PasteImage(r);
  Check.Check(r.pastes = n + 4, "an image not taken, refused or accepted");
  i.Close;

  (* Drag and drop, as the window system sends it while the user drags:
     FLTK's routing, from Fl::handle, decides which widget gets which. In
     a window of its own, with no input: EvDndLeave to a window never
     shown crashes FLTK in an Fl_Input (doc/fltk-issues.md, 53). *)
  NEW(dwin); Fl.OpenWindow(dwin, 100, 100, "TestClipboard: drag and drop");
  NEW(d); Fl.OpenBox(d, 50, 50, 20, 20, "");
  dwin.End;
  d.accept := TRUE;
  Check.Check(Probe.Mouse(dwin, Fl.EvDndEnter, 55, 55, 0, {}, 0) & (d.last = Fl.EvDndEnter)
    & (Fl.BelowMouse() = d), "EvDndEnter: a widget that takes it is below the mouse");
  Check.Check(Probe.Mouse(dwin, Fl.EvDndDrag, 60, 60, 0, {}, 0) & (d.last = Fl.EvDndDrag) & (d.events = 2),
    "EvDndDrag over it");
  Check.Check(Probe.Mouse(dwin, Fl.EvDndRelease, 60, 60, 0, {}, 0) & (d.last = Fl.EvDndRelease),
    "EvDndRelease: TRUE takes the drop");
  ok := Probe.Mouse(dwin, Fl.EvDndDrag, 90, 5, 0, {}, 0);  (* FALSE: the window has no use for it *)
  Check.Check((d.last = Fl.EvDndLeave) & (d.events = 4) & (Fl.BelowMouse() = dwin), "EvDndLeave: dragged off it");
  ok := Probe.Mouse(dwin, Fl.EvDndLeave, 90, 5, 0, {}, 0);
  Check.Check((d.events = 5) & (d.last = Fl.EvDndLeave) & (Fl.BelowMouse() = NIL),
    "EvDndLeave: out of the window, which passes it to each child again");
  d.accept := FALSE; d.events := 0;
  Check.Check(~Probe.Mouse(dwin, Fl.EvDndEnter, 55, 55, 0, {}, 0) & (d.last = Fl.EvDndEnter)
    & (Fl.BelowMouse() # d), "EvDndEnter refused: not below the mouse");
  ok := Probe.Mouse(dwin, Fl.EvDndLeave, 90, 5, 0, {}, 0);
  dwin.Delete;

  win.Delete;
  Check.Check((FlImages.openImages = 0) & (Fl.OpenWidgets() = 0), "every image and widget closed");
  Check.Summary
END TestClipboard.
