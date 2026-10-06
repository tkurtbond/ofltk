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

  (* FL_GRAY_RAMP and FL_COLOR_CUBE: where the gray ramp and color cube
     start in FLTK's colormap (GrayRamp, ColorCube; TestConstants checks) *)
  grayRamp = 32; colorCube = 56;

(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* events (Fl_Event), the argument of Handle *)
  EvNone* = 0;
  EvPush* = 1;
  EvRelease* = 2;
  EvEnter* = 3;
  EvLeave* = 4;
  EvDrag* = 5;
  EvFocus* = 6;
  EvUnfocus* = 7;
  EvKeyDown* = 8;
  EvKeyUp* = 9;
  EvClose* = 10;
  EvMove* = 11;
  EvShortcut* = 12;
  EvDeactivate* = 13;
  EvActivate* = 14;
  EvHide* = 15;
  EvShow* = 16;
  EvPaste* = 17;
  EvSelectionClear* = 18;
  EvMouseWheel* = 19;
  EvDndEnter* = 20;
  EvDndDrag* = 21;
  EvDndLeave* = 22;
  EvDndRelease* = 23;
  EvScreenConfigurationChanged* = 24;
  EvFullscreen* = 25;
  EvZoomGesture* = 26;
  EvZoomEvent* = 27;

  (* when a widget calls its Callback (Fl_When) *)
  WhenNever* = {};
  WhenChanged* = {0};
  WhenNotChanged* = {1};
  WhenRelease* = {2};
  WhenReleaseAlways* = {1, 2};
  WhenEnterKey* = {3};
  WhenEnterKeyAlways* = {1, 3};
  WhenEnterKeyChanged* = {0, 1, 3};
  WhenClosed* = {4};

  (* box types (Fl_Boxtype); Fl.cpp defines every one at start-up *)
  NoBox* = 0;
  FlatBox* = 1;
  UpBox* = 2;
  DownBox* = 3;
  UpFrame* = 4;
  DownFrame* = 5;
  ThinUpBox* = 6;
  ThinDownBox* = 7;
  ThinUpFrame* = 8;
  ThinDownFrame* = 9;
  EngravedBox* = 10;
  EmbossedBox* = 11;
  EngravedFrame* = 12;
  EmbossedFrame* = 13;
  BorderBox* = 14;
  ShadowBox* = 15;
  BorderFrame* = 16;
  ShadowFrame* = 17;
  RoundedBox* = 18;
  RShadowBox* = 19;
  RoundedFrame* = 20;
  RFlatBox* = 21;
  RoundUpBox* = 22;
  RoundDownBox* = 23;
  DiamondUpBox* = 24;
  DiamondDownBox* = 25;
  OvalBox* = 26;
  OShadowBox* = 27;
  OvalFrame* = 28;
  OFlatBox* = 29;
  PlasticUpBox* = 30;
  PlasticDownBox* = 31;
  PlasticUpFrame* = 32;
  PlasticDownFrame* = 33;
  PlasticThinUpBox* = 34;
  PlasticThinDownBox* = 35;
  PlasticRoundUpBox* = 36;
  PlasticRoundDownBox* = 37;
  GtkUpBox* = 38;
  GtkDownBox* = 39;
  GtkUpFrame* = 40;
  GtkDownFrame* = 41;
  GtkThinUpBox* = 42;
  GtkThinDownBox* = 43;
  GtkThinUpFrame* = 44;
  GtkThinDownFrame* = 45;
  GtkRoundUpBox* = 46;
  GtkRoundDownBox* = 47;
  GleamUpBox* = 48;
  GleamDownBox* = 49;
  GleamUpFrame* = 50;
  GleamDownFrame* = 51;
  GleamThinUpBox* = 52;
  GleamThinDownBox* = 53;
  GleamRoundUpBox* = 54;
  GleamRoundDownBox* = 55;
  OxyUpBox* = 56;
  OxyDownBox* = 57;
  OxyUpFrame* = 58;
  OxyDownFrame* = 59;
  OxyThinUpBox* = 60;
  OxyThinDownBox* = 61;
  OxyThinUpFrame* = 62;
  OxyThinDownFrame* = 63;
  OxyRoundUpBox* = 64;
  OxyRoundDownBox* = 65;
  OxyButtonUpBox* = 66;
  OxyButtonDownBox* = 67;
  FreeBoxtype* = 68;

  (* label types (Fl_Labeltype); multi, icon and image labels come with images *)
  NormalLabel* = 0;
  NoLabel* = 1;
  ShadowLabel* = 2;
  EngravedLabel* = 3;
  EmbossedLabel* = 4;

  (* label alignment (Fl_Align) *)
  AlignCenter* = {};
  AlignTop* = {0};
  AlignBottom* = {1};
  AlignLeft* = {2};
  AlignRight* = {3};
  AlignInside* = {4};
  AlignTextOverImage* = {5};
  AlignImageOverText* = {};
  AlignClip* = {6};
  AlignWrap* = {7};
  AlignImageNextToText* = {8};
  AlignTextNextToImage* = {5, 8};
  AlignImageBackdrop* = {9};
  AlignTopLeft* = {0, 2};
  AlignTopRight* = {0, 3};
  AlignBottomLeft* = {1, 2};
  AlignBottomRight* = {1, 3};
  AlignLeftTop* = {0, 1, 2};
  AlignRightTop* = {0, 1, 3};
  AlignLeftBottom* = {0, 2, 3};
  AlignRightBottom* = {1, 2, 3};
  AlignNoWrap* = {};
  AlignPositionMask* = {0, 1, 2, 3};
  AlignImageMask* = {5, 8, 9};

  (* fonts (Fl_Font); add Bold, Italic or BoldItalic to Helvetica, Courier or Times *)
  Helvetica* = 0;
  HelveticaBold* = 1;
  HelveticaItalic* = 2;
  HelveticaBoldItalic* = 3;
  Courier* = 4;
  CourierBold* = 5;
  CourierItalic* = 6;
  CourierBoldItalic* = 7;
  Times* = 8;
  TimesBold* = 9;
  TimesItalic* = 10;
  TimesBoldItalic* = 11;
  Symbol* = 12;
  Screen* = 13;
  ScreenBold* = 14;
  ZapfDingbats* = 15;
  FreeFont* = 16;
  Bold* = 1;
  Italic* = 2;
  BoldItalic* = 3;

  (* colors (Fl_Color): an index into FLTK's colormap, or RGB(r, g, b) *)
  ForegroundColor* = 0;
  Background2Color* = 7;
  InactiveColor* = 8;
  SelectionColor* = 15;
  Gray0* = 32;
  Dark3* = 39;
  Dark2* = 45;
  Dark1* = 47;
  BackgroundColor* = 49;
  Light1* = 50;
  Light2* = 52;
  Light3* = 54;
  Gray* = 49;
  Black* = 56;
  Red* = 88;
  Green* = 63;
  Yellow* = 95;
  Blue* = 216;
  Magenta* = 248;
  Cyan* = 223;
  DarkRed* = 72;
  DarkGreen* = 60;
  DarkYellow* = 76;
  DarkBlue* = 136;
  DarkMagenta* = 152;
  DarkCyan* = 140;
  White* = 255;
  FreeColor* = 16;
  NumFreeColor* = 16;
  NumGray* = 24;
  NumRed* = 5;
  NumGreen* = 8;
  NumBlue* = 5;
(* END generated constants *)

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
PROCEDURE ["C", "ofl_widget_position"] CPosition(w: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_size"] CSize(w: SYSTEM.ADDRESS; width, height: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_parent"] CParent(w: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_widget_visible_r"] CVisibleR(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_activate"] CActivate(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_deactivate"] CDeactivate(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_active"] CActive(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_active_r"] CActiveR(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_color"] CColor(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_color"] CSetColor(w: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_selection_color"] CSelectionColor(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_selection_color"] CSetSelectionColor(w: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_box"] CBoxType(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_box"] CSetBoxType(w: SYSTEM.ADDRESS; b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_labelfont"] CLabelFont(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_labelfont"] CSetLabelFont(w: SYSTEM.ADDRESS; f: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_labelsize"] CLabelSize(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_labelsize"] CSetLabelSize(w: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_labelcolor"] CLabelColor(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_labelcolor"] CSetLabelColor(w: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_labeltype"] CLabelType(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_labeltype"] CSetLabelType(w: SYSTEM.ADDRESS; t: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_align"] CAlign(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_align"] CSetAlign(w: SYSTEM.ADDRESS; a: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_when"] CWhen(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_when"] CSetWhen(w: SYSTEM.ADDRESS; when: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_copy_tooltip"] CCopyTooltip(w: SYSTEM.ADDRESS; text: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_widget_tooltip"] CTooltip(w: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_group_add"] CAdd(g, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_insert"] CInsert(g, w: SYSTEM.ADDRESS; i: SYSTEM.INT32);
PROCEDURE ["C", "ofl_group_remove"] CRemove(g, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_find"] CFind(g, w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_group_clear"] CClear(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_set_resizable"] CSetResizable(g, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_resizable"] CResizable(g: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_window_shown"] CShown(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_size_range"] CSizeRange(w: SYSTEM.ADDRESS; minw, minh, maxw, maxh: SYSTEM.INT32);
PROCEDURE ["C", "ofl_window_set_modal"] CSetModal(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_set_non_modal"] CSetNonModal(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_modal"] CModal(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_fullscreen"] CFullscreen(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_fullscreen_off"] CFullscreenOff(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_fullscreen_active"] CFullscreenActive(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_color"] CSetIndexColor(i, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_get_rgb"] CGetRGB(c: SYSTEM.INT32; VAR r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_background"] CBackground(r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_background2"] CBackground2(r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_foreground"] CForeground(r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_color_average"] CColorAverage(c1, c2: SYSTEM.INT32; weight: LONGREAL): SYSTEM.INT32;
PROCEDURE ["C", "ofl_contrast"] CContrast(fg, bg: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_inactive"] CInactive(c: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_normal_size"] CNormalSize(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_normal_size"] CSetNormalSize(s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_set_scheme"] CSetScheme(name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_scheme"] CScheme(): SYSTEM.ADDRESS;

(* s := the C string at a, truncated to fit s; "" if a is 0. *)
PROCEDURE FromC(a: SYSTEM.ADDRESS; VAR s: ARRAY OF CHAR);
  VAR i: LONGINT; c: CHAR;
BEGIN
  i := 0;
  IF a # 0 THEN
    SYSTEM.GET(a, c);
    WHILE (c # 0X) & (i < LEN(s) - 1) DO
      s[i] := c; INC(i); SYSTEM.GET(a + i, c)
    END
  END;
  s[i] := 0X
END FromC;

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
BEGIN FromC(CLabel(Live(w)), label)
END GetLabel;

(* The tooltip is copied too. "" removes it. *)
PROCEDURE (w: Widget) SetTooltip*(text-: ARRAY OF CHAR);
BEGIN CCopyTooltip(Live(w), text)
END SetTooltip;

PROCEDURE (w: Widget) GetTooltip*(VAR text: ARRAY OF CHAR);
BEGIN FromC(CTooltip(Live(w)), text)
END GetTooltip;

(* The label's font, size, color and type: a font such as Helvetica, a
   size in pixels, a color, NormalLabel or another label type. *)
PROCEDURE (w: Widget) LabelFont*(): INTEGER;
BEGIN RETURN CLabelFont(Live(w))
END LabelFont;

PROCEDURE (w: Widget) SetLabelFont*(f: INTEGER);
BEGIN CSetLabelFont(Live(w), f)
END SetLabelFont;

PROCEDURE (w: Widget) LabelSize*(): INTEGER;
BEGIN RETURN CLabelSize(Live(w))
END LabelSize;

PROCEDURE (w: Widget) SetLabelSize*(s: INTEGER);
BEGIN CSetLabelSize(Live(w), s)
END SetLabelSize;

PROCEDURE (w: Widget) LabelColor*(): INTEGER;
BEGIN RETURN CLabelColor(Live(w))
END LabelColor;

PROCEDURE (w: Widget) SetLabelColor*(c: INTEGER);
BEGIN CSetLabelColor(Live(w), c)
END SetLabelColor;

PROCEDURE (w: Widget) LabelType*(): INTEGER;
BEGIN RETURN CLabelType(Live(w))
END LabelType;

PROCEDURE (w: Widget) SetLabelType*(t: INTEGER);
BEGIN CSetLabelType(Live(w), t)
END SetLabelType;

(* Where the label goes: a set of the Align constants. *)
PROCEDURE (w: Widget) Align*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CAlign(Live(w)))
END Align;

PROCEDURE (w: Widget) SetAlign*(a: SET);
BEGIN CSetAlign(Live(w), SYSTEM.VAL(SYSTEM.INT32, a))
END SetAlign;

(* The box drawn around w: NoBox, UpBox or another box type. Named so as
   not to read as the type Box. *)
PROCEDURE (w: Widget) BoxType*(): INTEGER;
BEGIN RETURN CBoxType(Live(w))
END BoxType;

PROCEDURE (w: Widget) SetBoxType*(b: INTEGER);
BEGIN CSetBoxType(Live(w), b)
END SetBoxType;

PROCEDURE (w: Widget) Color*(): INTEGER;
BEGIN RETURN CColor(Live(w))
END Color;

PROCEDURE (w: Widget) SetColor*(c: INTEGER);
BEGIN CSetColor(Live(w), c)
END SetColor;

PROCEDURE (w: Widget) SelectionColor*(): INTEGER;
BEGIN RETURN CSelectionColor(Live(w))
END SelectionColor;

PROCEDURE (w: Widget) SetSelectionColor*(c: INTEGER);
BEGIN CSetSelectionColor(Live(w), c)
END SetSelectionColor;

(* When FLTK calls w's Callback: a set of the When constants. *)
PROCEDURE (w: Widget) When*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CWhen(Live(w)))
END When;

PROCEDURE (w: Widget) SetWhen*(when: SET);
BEGIN CSetWhen(Live(w), SYSTEM.VAL(SYSTEM.INT32, when))
END SetWhen;

PROCEDURE (w: Widget) Activate*;
BEGIN CActivate(Live(w))
END Activate;

PROCEDURE (w: Widget) Deactivate*;
BEGIN CDeactivate(Live(w))
END Deactivate;

(* TRUE unless w itself was deactivated. *)
PROCEDURE (w: Widget) Active*(): BOOLEAN;
BEGIN RETURN CActive(Live(w)) # 0
END Active;

(* TRUE if w and every group it is in are active. *)
PROCEDURE (w: Widget) ActiveR*(): BOOLEAN;
BEGIN RETURN CActiveR(Live(w)) # 0
END ActiveR;

(* TRUE if w and every group it is in are visible. *)
PROCEDURE (w: Widget) VisibleR*(): BOOLEAN;
BEGIN RETURN CVisibleR(Live(w)) # 0
END VisibleR;

(* The group w is in, or NIL: none, or one FLTK made rather than ofltk. *)
PROCEDURE (w: Widget) Parent*(): Group;
  VAR p: Widget;
BEGIN
  p := SYSTEM.VAL(Widget, CParent(Live(w)));
  IF (p # NIL) & (p IS Group) THEN RETURN p(Group) END;
  RETURN NIL
END Parent;

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

PROCEDURE (w: Widget) Position*(x, y: INTEGER);
BEGIN CPosition(Live(w), x, y)
END Position;

PROCEDURE (w: Widget) Size*(width, height: INTEGER);
BEGIN CSize(Live(w), width, height)
END Size;

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

(* Adds w as g's last child, removing it from any group it was in. *)
PROCEDURE (g: Group) Add*(w: Widget);
BEGIN CAdd(Live(g), Live(w))
END Add;

(* Adds w before child i, or last if i is Children() or more. *)
PROCEDURE (g: Group) Insert*(w: Widget; i: INTEGER);
BEGIN CInsert(Live(g), Live(w), i)
END Insert;

(* Takes w out of g without deleting it; nothing if it isn't g's. *)
PROCEDURE (g: Group) Remove*(w: Widget);
BEGIN CRemove(Live(g), Live(w))
END Remove;

(* w's index among g's children, or -1 if it isn't one. *)
PROCEDURE (g: Group) Find*(w: Widget): INTEGER;
  VAR h: SYSTEM.ADDRESS; i: INTEGER;
BEGIN
  h := Live(g); i := CFind(h, Live(w));
  IF i = CChildren(h) THEN i := -1 END;
  RETURN i
END Find;

(* Deletes every child, as Delete does each. *)
PROCEDURE (g: Group) Clear*;
BEGIN CClear(Live(g))
END Clear;

(* The child, or g itself, that grows and shrinks when g is resized; NIL
   for none, so nothing does. *)
PROCEDURE (g: Group) SetResizable*(w: Widget);
BEGIN
  IF w = NIL THEN CSetResizable(Live(g), 0) ELSE CSetResizable(Live(g), Live(w)) END
END SetResizable;

PROCEDURE (g: Group) Resizable*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CResizable(Live(g)))
END Resizable;

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

(* TRUE once the window is on the screen: shown, and not since hidden. *)
PROCEDURE (w: Window) Shown*(): BOOLEAN;
BEGIN RETURN CShown(Live(w)) # 0
END Shown;

(* The sizes the user may give the window; 0 for a maximum is no limit. *)
PROCEDURE (w: Window) SizeRange*(minw, minh, maxw, maxh: INTEGER);
BEGIN CSizeRange(Live(w), minw, minh, maxw, maxh)
END SizeRange;

(* A modal window takes every event while it is shown. *)
PROCEDURE (w: Window) SetModal*;
BEGIN CSetModal(Live(w))
END SetModal;

(* A non-modal window stays above the others, without taking their
   events. *)
PROCEDURE (w: Window) SetNonModal*;
BEGIN CSetNonModal(Live(w))
END SetNonModal;

PROCEDURE (w: Window) Modal*(): BOOLEAN;
BEGIN RETURN CModal(Live(w)) # 0
END Modal;

PROCEDURE (w: Window) Fullscreen*;
BEGIN CFullscreen(Live(w))
END Fullscreen;

PROCEDURE (w: Window) FullscreenOff*;
BEGIN CFullscreenOff(Live(w))
END FullscreenOff;

PROCEDURE (w: Window) FullscreenActive*(): BOOLEAN;
BEGIN RETURN CFullscreenActive(Live(w)) # 0
END FullscreenActive;

(* Colors. A color is an index into FLTK's colormap (the color constants,
   GrayRamp, ColorCube), or an RGB color, which is never one. *)

(* The color r, g, b, each 0 to 255. *)
PROCEDURE RGB*(r, g, b: INTEGER): INTEGER;
BEGIN
  (* r, g, b and 0 in bytes 3..0: an Fl_Color's bits, as an INTEGER *)
  RETURN SYSTEM.VAL(INTEGER, LONG((r * 256 + g) * 256 + b) * 256)
END RGB;

(* Gray i of FLTK's ramp from black, 0, to white, NumGray - 1. *)
PROCEDURE GrayRamp*(i: INTEGER): INTEGER;
BEGIN RETURN i + grayRamp
END GrayRamp;

(* The colormap's color r, g, b, from 0 to NumRed - 1, NumGreen - 1 and
   NumBlue - 1. *)
PROCEDURE ColorCube*(r, g, b: INTEGER): INTEGER;
BEGIN RETURN (b * NumRed + r) * NumGreen + g + colorCube
END ColorCube;

(* Sets colormap entry i to c, an RGB color. *)
PROCEDURE SetIndexColor*(i, c: INTEGER);
BEGIN CSetIndexColor(i, c)
END SetIndexColor;

(* The red, green and blue of c, each 0 to 255. *)
PROCEDURE GetRGB*(c: INTEGER; VAR r, g, b: INTEGER);
  VAR cr, cg, cb: SYSTEM.INT32;
BEGIN CGetRGB(c, cr, cg, cb); r := cr; g := cg; b := cb
END GetRGB;

(* The colors of FLTK's scheme: the background of most widgets, of text
   and list widgets, and the color of labels and text. *)
PROCEDURE SetBackground*(r, g, b: INTEGER);
BEGIN CBackground(r, g, b)
END SetBackground;

PROCEDURE SetBackground2*(r, g, b: INTEGER);
BEGIN CBackground2(r, g, b)
END SetBackground2;

PROCEDURE SetForeground*(r, g, b: INTEGER);
BEGIN CForeground(r, g, b)
END SetForeground;

(* c1 * weight + c2 * (1 - weight), weight from 0 to 1. *)
PROCEDURE ColorAverage*(c1, c2: INTEGER; weight: LONGREAL): INTEGER;
BEGIN RETURN CColorAverage(c1, c2, weight)
END ColorAverage;

PROCEDURE Lighter*(c: INTEGER): INTEGER;
BEGIN RETURN CColorAverage(c, White, 0.67D0)
END Lighter;

PROCEDURE Darker*(c: INTEGER): INTEGER;
BEGIN RETURN CColorAverage(c, Black, 0.67D0)
END Darker;

(* fg, or black or white if fg wouldn't show against bg. *)
PROCEDURE Contrast*(fg, bg: INTEGER): INTEGER;
BEGIN RETURN CContrast(fg, bg)
END Contrast;

(* c as FLTK draws it on an inactive widget. *)
PROCEDURE Inactive*(c: INTEGER): INTEGER;
BEGIN RETURN CInactive(c)
END Inactive;

(* The label size of widgets opened from now on, 14 to start with. *)
PROCEDURE NormalSize*(): INTEGER;
BEGIN RETURN CNormalSize()
END NormalSize;

PROCEDURE SetNormalSize*(s: INTEGER);
BEGIN CSetNormalSize(s)
END SetNormalSize;

(* FLTK's look: "none" (or "base"), "plastic", "gtk+", "gleam" or "oxy".
   FALSE if FLTK doesn't know name; the look is then "none". *)
PROCEDURE SetScheme*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CSetScheme(name) # 0
END SetScheme;

(* The scheme's name, "" for none. *)
PROCEDURE GetScheme*(VAR name: ARRAY OF CHAR);
BEGIN FromC(CScheme(), name)
END GetScheme;

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
