MODULE DragAndDrop; (* FLTK's examples/howto-drag-and-drop.cxx: text dragged from one window to another *)

(* Drag from the red box in the Sender window to the green box in the
   Receiver window: the receiver shows each drag and drop event in its
   label, and on standard error, and then shows the text dropped. *)

IMPORT Err, OutStr, Fl, FlDialogs;

TYPE
  Sender = POINTER TO RECORD (Fl.BoxDesc) END;

  Receiver = POINTER TO RECORD (Fl.BoxDesc)
    dndInside: BOOLEAN;      (* inside the widget: accept a drop *)
    dndText: ARRAY 256 OF CHAR;
    message: Fl.Timer        (* shows dndText, after the paste *)
  END;

  Message = POINTER TO RECORD (Fl.TimerDesc) r: Receiver END;

VAR
  winA, winB: Fl.Window;
  a: Sender;
  b: Receiver;

(* The label of w: its lines, a and b and c, with c "" for two lines. *)
PROCEDURE SetLines(w: Fl.Widget; a, b, c: ARRAY OF CHAR);
  VAR s: ARRAY 32 OF CHAR;
BEGIN
  s := a; OutStr.Ln(s); OutStr.String(b, s);
  IF c # "" THEN OutStr.Ln(s); OutStr.String(c, s) END;
  w.SetLabel(s)
END SetLines;

PROCEDURE OpenSender(s: Sender; x, y, w, h: INTEGER);
BEGIN
  Fl.OpenBox(s, x, y, w, h, ""); SetLines(s, "Drag", "from", "here..");
  s.SetBoxType(Fl.FlatBox); s.SetColor(9)
END OpenSender;

(* A click copies the text and starts dragging it. *)
PROCEDURE (s: Sender) Handle*(event: INTEGER): BOOLEAN;
  VAR ret: BOOLEAN;
BEGIN
  ret := s.Handle^(event);
  IF event = Fl.EvPush THEN
    Fl.Copy("It works!", Fl.Selection);
    Fl.Dnd;
    ret := TRUE
  END;
  RETURN ret
END Handle;

PROCEDURE OpenReceiver(r: Receiver; x, y, w, h: INTEGER);
  VAR m: Message;
BEGIN
  Fl.OpenBox(r, x, y, w, h, ""); SetLines(r, "..to", "here", "");
  r.SetBoxType(Fl.FlatBox); r.SetColor(10);
  r.dndInside := FALSE; r.dndText := "";
  NEW(m); m.r := r; r.message := m
END OpenReceiver;

PROCEDURE Trace(s: ARRAY OF CHAR);
BEGIN Err.String(s); Err.Ln
END Trace;

PROCEDURE (r: Receiver) Handle*(event: INTEGER): BOOLEAN;
  VAR ret: BOOLEAN;
BEGIN
  ret := r.Handle^(event);
  IF event = Fl.EvDndEnter THEN           (* TRUE to accept the drag *)
    r.SetLabel("ENTER");                   (* seen only if the mouse stops at the border *)
    Trace("FL_DND_ENTER");
    r.dndInside := TRUE;
    ret := TRUE
  ELSIF event = Fl.EvDndDrag THEN         (* TRUE to accept the drag *)
    SetLines(r, "drop", "here", "");
    Trace("FL_DND_DRAG");
    ret := TRUE
  ELSIF event = Fl.EvDndRelease THEN      (* TRUE to accept the drop *)
    Trace("FL_DND_RELEASE");
    IF r.dndInside THEN
      ret := TRUE;                         (* an EvPaste follows *)
      r.SetLabel("RELEASE")
    ELSE
      ret := FALSE;                        (* the drop is rejected *)
      SetLines(r, "DND", "REJECTED!", "")
    END
  ELSIF event = Fl.EvPaste THEN           (* the drop itself *)
    Trace("FL_PASTE");
    Fl.EventText(r.dndText);
    r.SetLabel(r.dndText);
    Err.String("Pasted '"); Err.String(r.dndText); Err.Char("'"); Err.Ln;
    IF r.dndText # "" THEN Fl.AddTimeout(r.message, 0.001D0) END;  (* the message after the paste *)
    ret := TRUE
  ELSIF event = Fl.EvDndLeave THEN        (* TRUE isn't needed here *)
    SetLines(r, "..to", "here", "");
    Trace("FL_DND_LEAVE");
    r.dndInside := FALSE;                  (* outside: don't accept a drop *)
    ret := TRUE
  END;
  RETURN ret
END Handle;

PROCEDURE (m: Message) Fire*;
BEGIN
  IF m.r.dndText # "" THEN FlDialogs.Message(m.r.dndText); m.r.dndText := "" END
END Fire;

BEGIN
  NEW(winA); Fl.OpenWindowAt(winA, 0, 0, 200, 100, "Sender");
  NEW(a); OpenSender(a, 0, 0, 100, 100);
  winA.End;
  winA.Show;
  NEW(winB); Fl.OpenWindowAt(winB, 400, 0, 200, 100, "Receiver");
  NEW(b); OpenReceiver(b, 100, 0, 100, 100);
  winB.End;
  winB.Show;
  Fl.Run
END DragAndDrop.
