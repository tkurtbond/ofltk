MODULE Fl; (* ofltk's core: widgets, groups, windows, boxes, timers, the event loop *)

(* Each widget type extends Widget, and a program extends those in turn:
   NEW(b); Fl.OpenBox(b, ...) makes the FLTK widget for b, whatever
   extension of Box b is. FLTK then calls b's Draw, Handle and Callback.

   FLTK owns its widgets: one lives until it is deleted, by Delete or
   with its parent group, and its Oberon object lives at least as long,
   kept reachable here (the registry) because the collector never sees
   pointers held only by FLTK. When FLTK destroys a widget it tells this
   module (ofltk.h, Ref), which forgets the object and marks it closed.
   A method of a widget that isn't open - never opened, or deleted -
   halts with NotOpen. PLAN.md, "Object model" and "Lifetime and the
   collector", has the reasons.

   Timers work the same way: a pending timer is kept reachable here until
   it fires or is removed.

   The C++ part is Fl.cpp, with ofltk.h. *)

IMPORT SYSTEM;

CONST
  (* ASSERT codes of programmer errors (PLAN.md, "Halt codes") *)
  NotOpen* = 70;        (* a method of a widget never opened, or deleted *)
  OpenedTwice* = 71;    (* an Open of a widget opened before *)
  NilArgument* = 72;    (* NIL where a widget or timer is required *)
  IndexOutOfRange* = 74; (* a child index outside the group *)
  NotFiring* = 75;      (* RepeatTimeout outside its timer's Fire *)

  (* Widget.state *)
  new = 0; open = 1; closed = 2;

TYPE
  Widget* = POINTER TO WidgetDesc;
  WidgetDesc* = RECORD
    h-: SYSTEM.ADDRESS;  (* the Fl_Widget *; 0 unless open *)
    state: SHORTINT;
    prev, next: Widget;  (* the registry, while open *)
    (* called by the default Callback, when set *)
    action*: PROCEDURE (w: Widget)
  END;

  Group* = POINTER TO GroupDesc;
  GroupDesc* = RECORD (WidgetDesc) END;

  Window* = POINTER TO WindowDesc;
  WindowDesc* = RECORD (GroupDesc) END;

  DoubleWindow* = POINTER TO DoubleWindowDesc;
  DoubleWindowDesc* = RECORD (WindowDesc) END;

  Box* = POINTER TO BoxDesc;
  BoxDesc* = RECORD (WidgetDesc) END;

  Timer* = POINTER TO TimerDesc;
  TimerDesc* = RECORD
    pending: BOOLEAN;
    prev, next: Timer;   (* the pending timers *)
    (* called by the default Fire, when set *)
    action*: PROCEDURE (t: Timer)
  END;

  SelfProc = PROCEDURE (self: SYSTEM.ADDRESS);
  HandleProc = PROCEDURE (self: SYSTEM.ADDRESS; event: SYSTEM.INT32): SYSTEM.INT32;

VAR
  widgets: Widget;  (* every open widget: the registry *)
  timers: Timer;    (* every pending timer *)
  openCount, pendingCount: LONGINT;
  firing: Timer;    (* the timer whose Fire is running, or NIL *)

PROCEDURE ["C", "ofl_register"] CRegister(callback, draw: SelfProc; handle: HandleProc; deleted, timeout: SelfProc);
PROCEDURE ["C", "ofl_group_new"] CGroupNew(x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_window_new"] CWindowNew(placed, x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_double_window_new"] CDoubleWindowNew(placed, x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_box_new"] CBoxNew(x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_widget_delete"] CDelete(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_show"] CShow(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_hide"] CHide(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_redraw"] CRedraw(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_do_callback"] CDoCallback(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_visible"] CVisible(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_default_callback"] CDefaultCallback(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_default_callback"] CWindowDefaultCallback(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_base_draw"] CBaseDraw(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_base_handle"] CBaseHandle(w: SYSTEM.ADDRESS; event: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_copy_label"] CCopyLabel(w: SYSTEM.ADDRESS; label: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_widget_label"] CLabel(w: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_widget_x"] CX(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_y"] CY(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_w"] CW(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_h"] CH(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_resize"] CResize(w: SYSTEM.ADDRESS; x, y, width, height: SYSTEM.INT32);
PROCEDURE ["C", "ofl_group_begin"] CBegin(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_end"] CEnd(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_children"] CChildren(g: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_group_child"] CChild(g: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_run"] CRun(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_check"] CCheck(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_wait"] CWait(seconds: LONGREAL);
PROCEDURE ["C", "ofl_add_timeout"] CAddTimeout(seconds: LONGREAL; self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_repeat_timeout"] CRepeatTimeout(seconds: LONGREAL; self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_remove_timeout"] CRemoveTimeout(self: SYSTEM.ADDRESS);

(* The registry *)

PROCEDURE Register(w: Widget);
BEGIN
  w.prev := NIL; w.next := widgets;
  IF widgets # NIL THEN widgets.prev := w END;
  widgets := w; INC(openCount)
END Register;

PROCEDURE Unregister(w: Widget);
BEGIN
  IF w.prev = NIL THEN widgets := w.next ELSE w.prev.next := w.next END;
  IF w.next # NIL THEN w.next.prev := w.prev END;
  w.prev := NIL; w.next := NIL; DEC(openCount)
END Unregister;

(* The handle of w, which must be open. *)
PROCEDURE Live(w: Widget): SYSTEM.ADDRESS;
BEGIN
  ASSERT(w # NIL, NilArgument); ASSERT(w.state = open, NotOpen);
  RETURN w.h
END Live;

(* For ofltk's modules only: makes w the Oberon object of h, the widget
   their C++ part has just made with ofl::open(..., self) - self being
   SelfOf(w), which must have come from BeginOpen(w) first. *)
PROCEDURE BeginOpen*(w: Widget): SYSTEM.ADDRESS;
BEGIN
  ASSERT(w # NIL, NilArgument); ASSERT(w.state = new, OpenedTwice);
  RETURN SYSTEM.VAL(SYSTEM.ADDRESS, w)
END BeginOpen;

PROCEDURE EndOpen*(w: Widget; h: SYSTEM.ADDRESS);
BEGIN
  w.h := h; w.state := open; Register(w)
END EndOpen;

(* The number of open widgets: those the registry holds. *)
PROCEDURE OpenWidgets*(): LONGINT;
BEGIN RETURN openCount
END OpenWidgets;

(* Opening the widget types of this module. x, y are relative to the
   window, as FLTK's are; the label is copied. *)

PROCEDURE OpenGroup*(g: Group; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN
  EndOpen(g, CGroupNew(x, y, w, h, BeginOpen(g))); CCopyLabel(g.h, label)
END OpenGroup;

(* A window the window manager places. *)
PROCEDURE OpenWindow*(win: Window; w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CWindowNew(0, 0, 0, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenWindow;

(* A window at x, y on the screen. *)
PROCEDURE OpenWindowAt*(win: Window; x, y, w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CWindowNew(1, x, y, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenWindowAt;

PROCEDURE OpenDoubleWindow*(win: DoubleWindow; w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CDoubleWindowNew(0, 0, 0, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenDoubleWindow;

PROCEDURE OpenDoubleWindowAt*(win: DoubleWindow; x, y, w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CDoubleWindowNew(1, x, y, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenDoubleWindowAt;

PROCEDURE OpenBox*(b: Box; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN
  EndOpen(b, CBoxNew(x, y, w, h, BeginOpen(b))); CCopyLabel(b.h, label)
END OpenBox;

(* Widget *)

(* TRUE while w is open: opened, and not yet deleted. *)
PROCEDURE (w: Widget) IsOpen*(): BOOLEAN;
BEGIN RETURN w.state = open
END IsOpen;

(* Deletes w's FLTK widget, and its children if it is a group. Inside a
   Callback, Draw, Handle or Fire, FLTK deletes it after that returns, so
   w stays open until then. *)
PROCEDURE (w: Widget) Delete*;
BEGIN CDelete(Live(w))
END Delete;

PROCEDURE (w: Widget) Show*;
BEGIN CShow(Live(w))
END Show;

PROCEDURE (w: Widget) Hide*;
BEGIN CHide(Live(w))
END Hide;

PROCEDURE (w: Widget) Visible*(): BOOLEAN;
BEGIN RETURN CVisible(Live(w)) # 0
END Visible;

PROCEDURE (w: Widget) Redraw*;
BEGIN CRedraw(Live(w))
END Redraw;

(* Calls w's Callback, as FLTK does. *)
PROCEDURE (w: Widget) DoCallback*;
BEGIN CDoCallback(Live(w))
END DoCallback;

(* What FLTK calls when w is used: its action, if set, else FLTK's
   default (for a widget, queueing it for Fl::readqueue). *)
PROCEDURE (w: Widget) Callback*;
BEGIN
  IF w.action # NIL THEN w.action(w) ELSE CDefaultCallback(Live(w)) END
END Callback;

(* FLTK's drawing of w, which an extension's Draw may call. *)
PROCEDURE (w: Widget) Draw*;
BEGIN CBaseDraw(Live(w))
END Draw;

(* FLTK's handling of event, TRUE if w used it. *)
PROCEDURE (w: Widget) Handle*(event: INTEGER): BOOLEAN;
BEGIN RETURN CBaseHandle(Live(w), event) # 0
END Handle;

PROCEDURE (w: Widget) SetLabel*(label-: ARRAY OF CHAR);
BEGIN CCopyLabel(Live(w), label)
END SetLabel;

(* The label, truncated to fit label, "" for none. *)
PROCEDURE (w: Widget) GetLabel*(VAR label: ARRAY OF CHAR);
  VAR a: SYSTEM.ADDRESS; i: LONGINT; c: CHAR;
BEGIN
  a := CLabel(Live(w)); i := 0;
  IF a # 0 THEN
    SYSTEM.GET(a, c);
    WHILE (c # 0X) & (i < LEN(label) - 1) DO
      label[i] := c; INC(i); SYSTEM.GET(a + i, c)
    END
  END;
  label[i] := 0X
END GetLabel;

PROCEDURE (w: Widget) X*(): INTEGER;
BEGIN RETURN CX(Live(w))
END X;

PROCEDURE (w: Widget) Y*(): INTEGER;
BEGIN RETURN CY(Live(w))
END Y;

PROCEDURE (w: Widget) W*(): INTEGER;
BEGIN RETURN CW(Live(w))
END W;

PROCEDURE (w: Widget) H*(): INTEGER;
BEGIN RETURN CH(Live(w))
END H;

PROCEDURE (w: Widget) Resize*(x, y, width, height: INTEGER);
BEGIN CResize(Live(w), x, y, width, height)
END Resize;

(* Group *)

(* Widgets opened after Begin are added to g, until End. Opening a group
   or window begins it. *)
PROCEDURE (g: Group) Begin*;
BEGIN CBegin(Live(g))
END Begin;

PROCEDURE (g: Group) End*;
BEGIN CEnd(Live(g))
END End;

PROCEDURE (g: Group) Children*(): INTEGER;
BEGIN RETURN CChildren(Live(g))
END Children;

(* Child i, from 0, or NIL if FLTK made it rather than ofltk. *)
PROCEDURE (g: Group) Child*(i: INTEGER): Widget;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Live(g); ASSERT((i >= 0) & (i < CChildren(h)), IndexOutOfRange);
  RETURN SYSTEM.VAL(Widget, CChild(h, i))
END Child;

(* Window *)

(* With no action, FLTK's default: hide the window (Fl::atclose). *)
PROCEDURE (w: Window) Callback*;
BEGIN
  IF w.action # NIL THEN w.action(w) ELSE CWindowDefaultCallback(Live(w)) END
END Callback;

(* Timer *)

(* What a timer does when it fires: its action, if set. *)
PROCEDURE (t: Timer) Fire*;
BEGIN
  IF t.action # NIL THEN t.action(t) END
END Fire;

PROCEDURE (t: Timer) Pending*(): BOOLEAN;
BEGIN RETURN t.pending
END Pending;

PROCEDURE Link(t: Timer);
BEGIN
  t.prev := NIL; t.next := timers;
  IF timers # NIL THEN timers.prev := t END;
  timers := t; t.pending := TRUE; INC(pendingCount)
END Link;

PROCEDURE Unlink(t: Timer);
BEGIN
  IF t.prev = NIL THEN timers := t.next ELSE t.prev.next := t.next END;
  IF t.next # NIL THEN t.next.prev := t.prev END;
  t.prev := NIL; t.next := NIL; t.pending := FALSE; DEC(pendingCount)
END Unlink;

(* Has t fire once, seconds from now. A timer is pending at most once:
   adding a pending one moves it. *)
PROCEDURE AddTimeout*(t: Timer; seconds: LONGREAL);
  VAR self: SYSTEM.ADDRESS;
BEGIN
  ASSERT(t # NIL, NilArgument); self := SYSTEM.VAL(SYSTEM.ADDRESS, t);
  IF t.pending THEN CRemoveTimeout(self); Unlink(t) END;
  Link(t); CAddTimeout(seconds, self)
END AddTimeout;

(* From t's own Fire only: has t fire again, seconds after it was due,
   so a repeating timer doesn't drift. *)
PROCEDURE RepeatTimeout*(t: Timer; seconds: LONGREAL);
BEGIN
  ASSERT(t # NIL, NilArgument); ASSERT((t = firing) & ~t.pending, NotFiring);
  Link(t); CRepeatTimeout(seconds, SYSTEM.VAL(SYSTEM.ADDRESS, t))
END RepeatTimeout;

(* t won't fire; nothing if it isn't pending. *)
PROCEDURE RemoveTimeout*(t: Timer);
BEGIN
  ASSERT(t # NIL, NilArgument);
  IF t.pending THEN CRemoveTimeout(SYSTEM.VAL(SYSTEM.ADDRESS, t)); Unlink(t) END
END RemoveTimeout;

PROCEDURE PendingTimers*(): LONGINT;
BEGIN RETURN pendingCount
END PendingTimers;

(* The event loop *)

(* Handles events until no window is shown. *)
PROCEDURE Run*;
  VAR r: SYSTEM.INT32;
BEGIN r := CRun()
END Run;

(* Handles the events waiting now, without waiting; TRUE if a window is
   shown. *)
PROCEDURE Check*(): BOOLEAN;
BEGIN RETURN CCheck() # 0
END Check;

(* Waits up to seconds for events, and handles them. *)
PROCEDURE Wait*(seconds: LONGREAL);
BEGIN CWait(seconds)
END Wait;

(* The dispatchers the C++ part calls (ofltk.h), registered below. *)

PROCEDURE CallbackD(self: SYSTEM.ADDRESS);
  VAR w: Widget;
BEGIN w := SYSTEM.VAL(Widget, self); w.Callback
END CallbackD;

PROCEDURE DrawD(self: SYSTEM.ADDRESS);
  VAR w: Widget;
BEGIN w := SYSTEM.VAL(Widget, self); w.Draw
END DrawD;

PROCEDURE HandleD(self: SYSTEM.ADDRESS; event: SYSTEM.INT32): SYSTEM.INT32;
  VAR w: Widget;
BEGIN
  w := SYSTEM.VAL(Widget, self);
  IF w.Handle(event) THEN RETURN 1 ELSE RETURN 0 END
END HandleD;

(* FLTK is destroying the widget: forget it. *)
PROCEDURE DeletedD(self: SYSTEM.ADDRESS);
  VAR w: Widget;
BEGIN
  w := SYSTEM.VAL(Widget, self); Unregister(w); w.h := 0; w.state := closed
END DeletedD;

(* Unlinked before Fire runs, so Fire may add or repeat it. *)
PROCEDURE TimeoutD(self: SYSTEM.ADDRESS);
  VAR t, outer: Timer;
BEGIN
  t := SYSTEM.VAL(Timer, self); Unlink(t);
  outer := firing; firing := t; t.Fire; firing := outer
END TimeoutD;

BEGIN
  CRegister(CallbackD, DrawD, HandleD, DeletedD, TimeoutD)
END Fl.
