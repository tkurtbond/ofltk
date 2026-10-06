MODULE TestEvents; (* Handle and Resize overrides; the Event queries, focus *)

(* Events are sent to the window as from the window system (Probe), and
   FLTK delivers them to the widgets as it would the user's; the window
   is never shown. *)

IMPORT Fl, Check, Probe;

TYPE
  (* records the last event it had, and what the Event queries said *)
  Pad = POINTER TO RECORD (Fl.BoxDesc)
    events, last, event, x, y, xRoot, button, clicks, key, dy: INTEGER;
    state: SET;
    inside, insideRect: BOOLEAN;
    text: ARRAY 16 OF CHAR;
    length: INTEGER
  END;
  (* counts its Resize calls, and resizes as FLTK would *)
  Sized = POINTER TO RECORD (Fl.BoxDesc) resizes, rw: INTEGER END;
  (* refuses to move or change size *)
  Fixed = POINTER TO RECORD (Fl.BoxDesc) END;

VAR
  win: Fl.Window;
  pad: Pad; other: Fl.Box; sized: Sized; fixed: Fixed;
  used: BOOLEAN;

PROCEDURE (p: Pad) Handle*(event: INTEGER): BOOLEAN;
BEGIN
  INC(p.events); p.last := event; p.event := Fl.Event();
  CASE event OF
    Fl.EvPush, Fl.EvDrag, Fl.EvRelease:
      p.x := Fl.EventX(); p.y := Fl.EventY(); p.xRoot := Fl.EventXRoot();
      p.button := Fl.EventButton(); p.clicks := Fl.EventClicks();
      p.state := Fl.EventState(); p.inside := p.EventInside();
      p.insideRect := Fl.EventInside(p.X(), p.Y(), 5, 5);
      RETURN TRUE
  | Fl.EvEnter, Fl.EvLeave, Fl.EvMove, Fl.EvFocus, Fl.EvUnfocus:
      RETURN TRUE
  | Fl.EvMouseWheel:
      p.dy := Fl.EventDy(); RETURN TRUE
  | Fl.EvKeyDown:
      p.key := Fl.EventKey(); p.state := Fl.EventState();
      Fl.EventText(p.text); p.length := Fl.EventLength();
      RETURN p.key = ORD("a")
  ELSE
    RETURN p.Handle^(event)
  END
END Handle;

PROCEDURE (s: Sized) Resize*(x, y, w, h: INTEGER);
BEGIN INC(s.resizes); s.rw := w; s.Resize^(x, y, w, h)
END Resize;

PROCEDURE (f: Fixed) Resize*(x, y, w, h: INTEGER);
END Resize;

BEGIN
  NEW(win); Fl.OpenWindow(win, 300, 200, "TestEvents");
  NEW(pad); Fl.OpenBox(pad, 20, 30, 100, 80, "");
  NEW(other); Fl.OpenBox(other, 150, 30, 100, 80, "");
  NEW(sized); Fl.OpenBox(sized, 10, 150, 50, 20, "");
  NEW(fixed); Fl.OpenBox(fixed, 100, 150, 50, 20, "");
  win.End;

  (* the mouse *)
  used := Probe.Mouse(win, Fl.EvPush, 50, 60, Fl.LeftMouse, Fl.Button1, 0);
  Check.Check(used & (pad.last = Fl.EvPush) & (pad.event = Fl.EvPush),
    "EvPush reaches the Handle of the widget under the mouse, which uses it");
  Check.Check((pad.x = 50) & (pad.y = 60) & (pad.xRoot = win.X() + 50),
    "EventX, EventY in the window's coordinates; EventXRoot the screen's");
  Check.Check((pad.button = Fl.LeftMouse) & (pad.state * Fl.Buttons = Fl.Button1)
    & (pad.clicks = 0), "EventButton, EventState and EventClicks of a single click");
  Check.Check(pad.inside & ~pad.insideRect, "Widget.EventInside and Fl.EventInside");
  Check.Check(Fl.Pushed() = pad, "Pushed is the widget that took the EvPush");
  used := Probe.Mouse(win, Fl.EvDrag, 200, 70, Fl.LeftMouse, Fl.Button1, 0);
  Check.Check(used & (pad.last = Fl.EvDrag) & (pad.x = 200) & ~pad.inside,
    "EvDrag goes to the pushed widget, even outside it");
  used := Probe.Mouse(win, Fl.EvRelease, 200, 70, Fl.LeftMouse, {}, 0);
  Check.Check(used & (pad.last = Fl.EvRelease) & (Fl.Pushed() = NIL),
    "EvRelease goes to it too, and ends the push");
  used := Probe.Mouse(win, Fl.EvPush, 50, 60, Fl.RightMouse, Fl.Button3 + Fl.Shift, 1);
  Check.Check((pad.button = Fl.RightMouse) & (pad.clicks = 1)
    & (pad.state * (Fl.Shift + Fl.Buttons) = Fl.Button3 + Fl.Shift),
    "a shifted right double click");
  used := Probe.Mouse(win, Fl.EvRelease, 50, 60, Fl.RightMouse, {}, 1);

  (* moving and the wheel *)
  used := Probe.Mouse(win, Fl.EvMove, 60, 60, 0, {}, 0);
  Check.Check(Fl.BelowMouse() = pad, "EvMove: the widget under the mouse is BelowMouse");
  used := Probe.Wheel(win, 60, 60, 0, 3);
  Check.Check(used & (pad.last = Fl.EvMouseWheel) & (pad.dy = 3),
    "EvMouseWheel reaches it, with EventDy");

  (* the keyboard *)
  Check.Check(pad.VisibleFocus() & pad.TakeFocus() & (Fl.Focus() = pad),
    "TakeFocus, when Handle uses EvFocus, gives the focus");
  used := Probe.Key(Fl.EvKeyDown, ORD("a"), Fl.Ctrl, "a");
  Check.Check(used & (pad.key = ORD("a")) & (pad.text = "a") & (pad.length = 1)
    & (pad.state * Fl.Ctrl = Fl.Ctrl),
    "EvKeyDown reaches the focus, with EventKey, EventText, EventLength and EventState");
  used := Probe.Key(Fl.EvKeyDown, Fl.KeyF + 2, {}, "");
  Check.Check(~used & (pad.key = Fl.KeyF + 2) & (pad.text = ""),
    "a key the focus doesn't use: F2, with no text");
  Fl.SetFocus(other);
  Check.Check((Fl.Focus() = other) & (pad.last = Fl.EvUnfocus), "SetFocus moves it, unfocusing the pad");
  Fl.SetFocus(NIL);
  Check.Check(Fl.Focus() = NIL, "SetFocus(NIL): no focus");
  pad.SetVisibleFocus(FALSE);
  Check.Check(~pad.VisibleFocus() & ~pad.TakeFocus(), "a widget without visible focus doesn't take it");

  (* resizing *)
  sized.Size(80, 30);
  Check.Check((sized.resizes = 1) & (sized.rw = 80) & (sized.W() = 80) & (sized.H() = 30),
    "Size calls the Resize override, whose Resize^ resizes");
  sized.Position(5, 140);
  Check.Check((sized.resizes = 2) & (sized.X() = 5) & (sized.Y() = 140), "so does Position");
  win.SetResizable(sized);
  win.Size(400, 200);
  Check.Check((sized.resizes = 3) & (sized.W() = 180),
    "resizing the window resizes its resizable child, through the override");
  fixed.Resize(0, 0, 10, 10); fixed.Size(99, 99);
  Check.Check((fixed.X() = 100) & (fixed.W() = 50),
    "a Resize override that doesn't call Resize^ keeps the widget as it was");

  (* Last, since FLTK raises a window clicked in where no widget uses the
     click: it shows it, and makes it the pushed widget. *)
  pad.events := 0;
  used := Probe.Mouse(win, Fl.EvPush, other.X() + 5, other.Y() + 5, Fl.LeftMouse, Fl.Button1, 0);
  Check.Check((pad.last # Fl.EvPush) & (Fl.Pushed() = win),
    "a push on a plain box: the pad doesn't see it, and the window is Pushed");
  Check.Check(used & win.Shown() & (pad.events = 1) & (pad.last = Fl.EvShow),
    "FLTK shows the window, and the pad has EvShow");
  win.Hide;

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestEvents.
