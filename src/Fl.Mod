MODULE Fl; (* pofltk's core: widgets, groups, windows, boxes, timers, the event loop *)

(* Each widget type extends Widget, and a program extends those in turn:
   NEW(b); Fl.OpenBox(b, ...) makes the FLTK widget for b, whatever
   extension of Box b is. FLTK then calls b's Draw, Handle, Resize and
   Callback; while Handle runs, the Event procedures below say what the
   event was. Draw draws with FlDraw.

   FLTK owns its widgets: one lives until it is deleted, by Delete or
   with its parent group, and its Oberon object lives at least as long,
   kept reachable here (the registry) because the collector never sees
   pointers held only by FLTK. When FLTK destroys a widget it tells this
   module (pofltk.h, Ref), which forgets the object and marks it closed.
   A method of a widget that isn't open - never opened, or deleted -
   halts with NotOpen. PLAN.md, "Object model" and "Lifetime and the
   collector", has the reasons.

   Timers work the same way: a pending timer is kept reachable here until
   it fires or is removed; so is an idle callback while it is added, and
   a file descriptor's watch while it watches.

   The C++ part is Fl.cpp, with pofltk.h. *)

IMPORT SYSTEM, Args;

CONST
  (* ASSERT codes of programmer errors (PLAN.md, "Halt codes") *)
  NotOpen* = 70;        (* a method of a widget never opened, or deleted *)
  OpenedTwice* = 71;    (* an Open of a widget opened before *)
  NilArgument* = 72;    (* NIL where a widget or timer is required *)
  ClosedResource* = 73; (* a resource used after Close, or missing where needed *)
  IndexOutOfRange* = 74; (* a child index outside the group *)
  NotFiring* = 75;      (* RepeatTimeout outside its timer's Fire *)
  NotAChild* = 76;      (* a widget that must be a group's child isn't *)
  OutOfOrder* = 77;     (* an End that doesn't match the last Begin *)
  Unsupported* = 78;    (* an argument a call can't take: a multi-label for a window, or in itself *)

  (* where Copy puts text, and Paste takes it from: FLTK has no names *)
  Selection* = 0;  (* the selection buffer, pasted with the middle button on X11 *)
  Clipboard* = 1;  (* the clipboard, for cut, copy and paste *)
  Both* = 2;       (* Copy only *)

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

  (* keys (Fl::event_key): a character's code for most; KeyF + n is F<n>, KeyKP + c keypad c *)
  KeyButton* = 65256;
  KeyBackSpace* = 65288;
  KeyTab* = 65289;
  KeyIsoKey* = 65292;
  KeyEnter* = 65293;
  KeyPause* = 65299;
  KeyScrollLock* = 65300;
  KeyEscape* = 65307;
  KeyKana* = 65326;
  KeyEisu* = 65327;
  KeyYen* = 65328;
  KeyJISUnderscore* = 65329;
  KeyHome* = 65360;
  KeyLeft* = 65361;
  KeyUp* = 65362;
  KeyRight* = 65363;
  KeyDown* = 65364;
  KeyPageUp* = 65365;
  KeyPageDown* = 65366;
  KeyEnd* = 65367;
  KeyPrint* = 65377;
  KeyInsert* = 65379;
  KeyMenu* = 65383;
  KeyHelp* = 65384;
  KeyNumLock* = 65407;
  KeyKP* = 65408;
  KeyKPEnter* = 65421;
  KeyKPLast* = 65469;
  KeyF* = 65469;
  KeyFLast* = 65504;
  KeyShiftL* = 65505;
  KeyShiftR* = 65506;
  KeyControlL* = 65507;
  KeyControlR* = 65508;
  KeyCapsLock* = 65509;
  KeyMetaL* = 65511;
  KeyMetaR* = 65512;
  KeyAltL* = 65513;
  KeyAltR* = 65514;
  KeyDelete* = 65535;
  KeyAltGr* = 65027;
  KeyVolumeDown* = 61201;
  KeyVolumeMute* = 61202;
  KeyVolumeUp* = 61203;
  KeyMediaPlay* = 61204;
  KeyMediaStop* = 61205;
  KeyMediaPrev* = 61206;
  KeyMediaNext* = 61207;
  KeyHomePage* = 61208;
  KeyMail* = 61209;
  KeySearch* = 61211;
  KeyBack* = 61222;
  KeyForward* = 61223;
  KeyStop* = 61224;
  KeyRefresh* = 61225;
  KeySleep* = 61231;
  KeyFavorites* = 61232;

  (* mouse buttons (Fl::event_button) *)
  LeftMouse* = 1;
  MiddleMouse* = 2;
  RightMouse* = 3;
  BackMouse* = 4;
  ForwardMouse* = 5;

  (* the shift keys and mouse buttons held (Fl::event_state); Command is Ctrl, but Meta on macOS *)
  Shift* = {16};
  CapsLock* = {17};
  Ctrl* = {18};
  Alt* = {19};
  NumLock* = {20};
  Meta* = {22};
  ScrollLock* = {23};
  Button1* = {24};
  Button2* = {25};
  Button3* = {26};
  Button4* = {27};
  Button5* = {28};
  Buttons* = {24, 25, 26, 27, 28};
  Command* = {18};
  Control* = {22};

  (* what needs redrawing (Fl_Damage), Widget.Damage *)
  DamageChild* = {0};
  DamageExpose* = {1};
  DamageScroll* = {2};
  DamageOverlay* = {3};
  DamageUser1* = {4};
  DamageUser2* = {5};
  DamageAll* = {7};

  (* mouse cursors (Fl_Cursor), Window.SetCursor *)
  CursorDefault* = 0;
  CursorArrow* = 35;
  CursorCross* = 66;
  CursorWait* = 76;
  CursorInsert* = 77;
  CursorHand* = 31;
  CursorHelp* = 47;
  CursorMove* = 27;
  CursorNs* = 78;
  CursorWe* = 79;
  CursorNwse* = 80;
  CursorNesw* = 81;
  CursorN* = 70;
  CursorNe* = 69;
  CursorE* = 49;
  CursorSe* = 8;
  CursorS* = 9;
  CursorSw* = 7;
  CursorW* = 36;
  CursorNw* = 68;
  CursorNone* = 255;

  (* FLTK's options (Fl::Fl_Option), Option and SetOption *)
  OptionArrowFocus* = 0;
  OptionVisibleFocus* = 1;
  OptionDndText* = 2;
  OptionShowTooltips* = 3;
  OptionFnfcUsesGtk* = 4;
  OptionFnfcUsesZenity* = 5;
  OptionFnfcUsesKdialog* = 6;
  OptionPrinterUsesGtk* = 7;
  OptionShowScaling* = 8;
  OptionSimpleZoomShortcut* = 9;

  (* what a watched file descriptor waits for (FdWatch, WatchFd) *)
  FdRead* = {0};
  FdWrite* = {2};
  FdExcept* = {3};
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

  (* Runs whenever the event loop has nothing else to do, while added
     (AddIdle): its Run, whose default calls its action. *)
  Idle* = POINTER TO IdleDesc;
  IdleDesc* = RECORD
    added: BOOLEAN;
    prev, next: Idle;    (* the idles added *)
    action*: PROCEDURE (i: Idle)
  END;

  (* Watches a file descriptor, fd, for what when says (FdRead, FdWrite,
     FdExcept), while it watches (WatchFd): its Ready, whose default
     calls its action, runs when the descriptor is ready for one of them.
     FLTK doesn't say which. *)
  FdWatch* = POINTER TO FdWatchDesc;
  FdWatchDesc* = RECORD
    fd-: INTEGER;
    when-: SET;          (* {} when it isn't watching *)
    prev, next: FdWatch; (* the watches watching *)
    action*: PROCEDURE (w: FdWatch)
  END;

  (* Sees every event first (SetEventDispatch), with its window: NIL for
     one FLTK made itself, such as a menu's or a dialog's, or for an
     event with none. It returns TRUE if the event was used, as
     HandleDefault, which hands the event on, says. *)
  EventDispatch* = PROCEDURE (event: INTEGER; w: Window): BOOLEAN;

  (* Sees an event no widget used (AddHandler), such as an EvShortcut no
     widget took. It returns TRUE if it used the event, which then goes
     to no other handler. *)
  EventHandler* = PROCEDURE (event: INTEGER): BOOLEAN;
  HandlerNode = POINTER TO RECORD
    h: EventHandler;
    next: HandlerNode
  END;

  SelfProc = PROCEDURE (self: SYSTEM.ADDRESS);
  HandleProc = PROCEDURE (self: SYSTEM.ADDRESS; event: SYSTEM.INT32): SYSTEM.INT32;
  ResizeProc = PROCEDURE (self: SYSTEM.ADDRESS; x, y, w, h: SYSTEM.INT32);
  DispatchProc = PROCEDURE (event: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.INT32;
  HandlerProc = PROCEDURE (event: SYSTEM.INT32): SYSTEM.INT32;
  ArgProc = PROCEDURE (i: SYSTEM.INT32): SYSTEM.INT32;

  (* A program's own command-line options (ParseArgs): given argument i
     (Args.Get), the number of words of it the program uses: 0 if it
     isn't one of them, 1 for an option alone, 2 for one with a value. *)
  ArgHandler* = PROCEDURE (i: INTEGER): INTEGER;

VAR
  widgets: Widget;  (* every open widget: the registry *)
  timers: Timer;    (* every pending timer *)
  openCount, pendingCount: LONGINT;
  firing: Timer;    (* the timer whose Fire is running, or NIL *)
  argHandler: ArgHandler;  (* the handler of the ParseArgs running *)
  idles: Idle;               (* every idle added *)
  watches: FdWatch;          (* every watch watching *)
  dispatch: EventDispatch;   (* the event dispatch, or NIL for FLTK's own *)
  dispatching: INTEGER;      (* how many dispatch calls are running *)
  handlers: HandlerNode;     (* the event handlers, newest first *)

PROCEDURE ["C", "ofl_register"] CRegister(callback, draw: SelfProc; handle: HandleProc; resize: ResizeProc; deleted, timeout: SelfProc);
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
PROCEDURE ["C", "ofl_widget_base_resize"] CBaseResize(w: SYSTEM.ADDRESS; x, y, width, height: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_draw_box"] CDrawBox(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_draw_label"] CDrawLabel(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_draw_focus"] CDrawFocus(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_changed"] CChanged(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_changed"] CSetChanged(w: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_damage"] CDamage(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_damage"] CSetDamage(w: SYSTEM.ADDRESS; d: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_clear_damage"] CClearDamage(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_take_focus"] CTakeFocus(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_visible_focus"] CVisibleFocus(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_visible_focus"] CSetVisibleFocus(w: SYSTEM.ADDRESS; v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_event_inside"] CWidgetEventInside(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_cursor"] CCursor(w: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_event"] CEvent(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_x"] CEventX(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_y"] CEventY(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_x_root"] CEventXRoot(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_y_root"] CEventYRoot(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_dx"] CEventDx(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_dy"] CEventDy(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_button"] CEventButton(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_clicks"] CEventClicks(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_event_clicks"] CSetEventClicks(n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_event_is_click"] CEventIsClick(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_is_click_off"] CEventIsClickOff;
PROCEDURE ["C", "ofl_event_key"] CEventKey(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_original_key"] CEventOriginalKey(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_key_down"] CEventKeyDown(k: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_get_key"] CGetKey(k: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_state"] CEventState(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_text"] CEventText(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_event_length"] CEventLength(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_copy"] CCopy(text: ARRAY OF CHAR; n, destination: SYSTEM.INT32);
PROCEDURE ["C", "ofl_paste"] CPaste(receiver: SYSTEM.ADDRESS; source, image: SYSTEM.INT32);
PROCEDURE ["C", "ofl_clipboard_contains"] CClipboardContains(image: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_is_image"] CEventIsImage(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dnd"] CDnd(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dnd_text_ops"] CDndTextOps(what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_option"] COption(o, what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_inside"] CEventInside(x, y, w, h: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_focus"] CFocus(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_belowmouse"] CBelowmouse(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_pushed"] CPushed(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_open_uri"] COpenURI(uri: ARRAY OF CHAR; VAR msg: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_register_loop"] CRegisterLoop(idle, fd: SelfProc; dispatch: DispatchProc; handler: HandlerProc);
PROCEDURE ["C", "ofl_event_handlers"] CEventHandlers(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_redraw_all"] CRedrawAll;
PROCEDURE ["C", "ofl_window_shown_any"] CWindowShownAny(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_add_idle"] CAddIdle(self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_remove_idle"] CRemoveIdle(self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_add_fd"] CAddFd(fd, when: SYSTEM.INT32; self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_remove_fd"] CRemoveFd(fd, when: SYSTEM.INT32);
PROCEDURE ["C", "ofl_event_dispatch"] CEventDispatch(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_handle_default"] CHandleDefault(event: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_event_key"] CSetEventKey(key: SYSTEM.INT32);
PROCEDURE ["C", "ofl_set_event_text"] CSetEventText(s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_screen"] CScreen(what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_screen_count"] CScreenCount(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_scrollbar_size"] CScrollbarSize(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_scrollbar_size"] CSetScrollbarSize(n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_screen_xywh"] CScreenXYWH(n, work: SYSTEM.INT32; VAR x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_screen_num"] CScreenNum(x, y: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_args"] CArgs(argc: SYSTEM.INT32; argv: SYSTEM.ADDRESS; VAR i: SYSTEM.INT32; handler: ArgProc): SYSTEM.INT32;
PROCEDURE ["C", "ofl_arg"] CArg(argc: SYSTEM.INT32; argv: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_args_help"] CArgsHelp(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_window_show_args"] CWindowShowArgs(w: SYSTEM.ADDRESS; argc: SYSTEM.INT32; argv: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_set_focus"] CSetFocus(w: SYSTEM.ADDRESS);
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
PROCEDURE ["C", "ofl_group_init_sizes"] CInitSizes(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_set_resizable"] CSetResizable(g, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_resizable"] CResizable(g: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_window_shown"] CShown(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_wait_for_expose"] CWaitForExpose(w: SYSTEM.ADDRESS);
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
PROCEDURE ["C", "ofl_box_d"] CBoxD(b, what: SYSTEM.INT32): SYSTEM.INT32;
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

(* The handle of w, which must be open: for pofltk's modules, whose
   methods pass it to their C++ part. *)
PROCEDURE Live*(w: Widget): SYSTEM.ADDRESS;
BEGIN
  ASSERT(w # NIL, NilArgument); ASSERT(w.state = open, NotOpen);
  RETURN w.h
END Live;

(* For pofltk's modules only: makes w the Oberon object of h, the widget
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

(* Copied; it replaces a multi-label (FlImages.SetMultiLabel). *)
PROCEDURE (w: Widget) SetLabel*(label-: ARRAY OF CHAR);
BEGIN CCopyLabel(Live(w), label)
END SetLabel;

(* The label, truncated to fit label, "" for none or a multi-label. *)
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

(* NormalLabel to EmbossedLabel. The types of a multi-label, an image or
   an icon (5 to 7) halt (Unsupported): FlImages.SetMultiLabel gives a
   widget a multi-label, which it keeps whatever type is set. *)
PROCEDURE (w: Widget) SetLabelType*(t: INTEGER);
BEGIN ASSERT((t < 5) OR (t > 7), Unsupported); CSetLabelType(Live(w), t)
END SetLabelType;

(* Where the label goes: a set of the Align constants. *)
PROCEDURE (w: Widget) Align*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CAlign(Live(w)))
END Align;

PROCEDURE (w: Widget) SetAlign*(a: SET);
BEGIN CSetAlign(Live(w), ORD(a))
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
BEGIN CSetWhen(Live(w), ORD(when))
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

(* The group w is in, or NIL: none, or one FLTK made rather than pofltk. *)
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

(* Moves and sizes w: FLTK's resizing, which an extension's Resize may
   call. FLTK calls Resize whenever w moves or changes size: by Position
   or Size, or as its group is resized. *)
PROCEDURE (w: Widget) Resize*(x, y, width, height: INTEGER);
BEGIN CBaseResize(Live(w), x, y, width, height)
END Resize;

(* Each calls Resize. *)
PROCEDURE (w: Widget) Position*(x, y: INTEGER);
BEGIN CPosition(Live(w), x, y)
END Position;

PROCEDURE (w: Widget) Size*(width, height: INTEGER);
BEGIN CSize(Live(w), width, height)
END Size;

(* For an extension's Draw: FLTK's drawing of w's box, in its box type
   and color; of its label, as aligned; and of the dotted box showing it
   has the keyboard focus, if it has. *)
PROCEDURE (w: Widget) DrawBox*;
BEGIN CDrawBox(Live(w))
END DrawBox;

PROCEDURE (w: Widget) DrawLabel*;
BEGIN CDrawLabel(Live(w))
END DrawLabel;

PROCEDURE (w: Widget) DrawFocus*;
BEGIN CDrawFocus(Live(w))
END DrawFocus;

(* TRUE if the user has changed w's value: FLTK sets it before running
   the Callback for a change, and clears it when the Callback returns, or
   the program sets the value. So it tells a Callback whether it runs for
   a change. *)
PROCEDURE (w: Widget) Changed*(): BOOLEAN;
BEGIN RETURN CChanged(Live(w)) # 0
END Changed;

PROCEDURE (w: Widget) SetChanged*(c: BOOLEAN);
BEGIN
  IF c THEN CSetChanged(Live(w), 1) ELSE CSetChanged(Live(w), 0) END
END SetChanged;

(* What needs redrawing: a set of the Damage constants, {} for nothing.
   Redraw sets DamageAll. *)
PROCEDURE (w: Widget) Damage*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CDamage(Live(w)))
END Damage;

(* Adds d to what needs redrawing, and has FLTK redraw w soon. *)
PROCEDURE (w: Widget) SetDamage*(d: SET);
BEGIN CSetDamage(Live(w), ORD(d))
END SetDamage;

(* Sets what needs redrawing to {}, without redrawing: FLTK does this
   after a Draw. *)
PROCEDURE (w: Widget) ClearDamage*;
BEGIN CClearDamage(Live(w))
END ClearDamage;

(* Gives w the keyboard focus, if it takes it: TRUE if it did. *)
PROCEDURE (w: Widget) TakeFocus*(): BOOLEAN;
BEGIN RETURN CTakeFocus(Live(w)) # 0
END TakeFocus;

(* Whether w may take the focus by the keyboard and shows it has it;
   TRUE to start with. *)
PROCEDURE (w: Widget) VisibleFocus*(): BOOLEAN;
BEGIN RETURN CVisibleFocus(Live(w)) # 0
END VisibleFocus;

PROCEDURE (w: Widget) SetVisibleFocus*(v: BOOLEAN);
BEGIN
  IF v THEN CSetVisibleFocus(Live(w), 1) ELSE CSetVisibleFocus(Live(w), 0) END
END SetVisibleFocus;

(* TRUE if the event's position is inside w. *)
PROCEDURE (w: Widget) EventInside*(): BOOLEAN;
BEGIN RETURN CWidgetEventInside(Live(w)) # 0
END EventInside;

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

(* Deletes every child pofltk opened, as Delete does each; children FLTK
   made itself, such as a scroll's scrollbars, stay. *)
PROCEDURE (g: Group) Clear*;
BEGIN CClear(Live(g))
END Clear;

(* Makes g forget the sizes it saved of itself and its children, after
   the program moves or resizes them: else the next resize of g puts them
   back where they were. *)
PROCEDURE (g: Group) InitSizes*;
BEGIN CInitSizes(Live(g))
END InitSizes;

(* The child, or g itself, that grows and shrinks when g is resized; NIL
   for none, so nothing does. *)
PROCEDURE (g: Group) SetResizable*(w: Widget);
BEGIN
  IF w = NIL THEN CSetResizable(Live(g), 0) ELSE CSetResizable(Live(g), Live(w)) END
END SetResizable;

PROCEDURE (g: Group) Resizable*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CResizable(Live(g)))
END Resizable;

(* Child i, from 0, or NIL if FLTK made it rather than pofltk. *)
PROCEDURE (g: Group) Child*(i: INTEGER): Widget;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Live(g); ASSERT((i >= 0) & (i < CChildren(h)), IndexOutOfRange);
  RETURN SYSTEM.VAL(Widget, CChild(h, i))
END Child;

(* Window *)

(* Shows w, as Show does, with FLTK's command-line options (ParseArgs,
   which this calls first if no ParseArgs or Arg has): its title, its
   class name, and, for the first window shown this way, its geometry;
   and the colors and scheme. A title or class not given is the
   program's name. *)
PROCEDURE (w: Window) ShowArgs*;
BEGIN CWindowShowArgs(Live(w), Args.argc, Args.argv)
END ShowArgs;

(* With no action, FLTK's default: hide the window (Fl::atclose). *)
PROCEDURE (w: Window) Callback*;
BEGIN
  IF w.action # NIL THEN w.action(w) ELSE CWindowDefaultCallback(Live(w)) END
END Callback;

(* TRUE once the window is on the screen: shown, and not since hidden. *)
PROCEDURE (w: Window) Shown*(): BOOLEAN;
BEGIN RETURN CShown(Live(w)) # 0
END Shown;

(* Waits until a window just shown is on the screen, handling events
   meanwhile; returns at once if it is there, or not shown. Under Wayland
   a menu popped up over a window not yet on the screen kills the program
   (doc/fltk-issues.md, 28), so MenuButton.Popup waits first. *)
PROCEDURE (w: Window) WaitForExpose*;
BEGIN CWaitForExpose(Live(w))
END WaitForExpose;

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

(* The mouse pointer's shape over the window: CursorDefault, or another
   cursor constant. *)
PROCEDURE (w: Window) SetCursor*(c: INTEGER);
BEGIN CCursor(Live(w), c)
END SetCursor;

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

(* The border of box type b, as drawn: how far inside a box's left and
   top edges what it holds starts (BoxDX, BoxDY), and how much narrower
   and shorter it is (BoxDW, BoxDH). b is from 0 to 255. *)
PROCEDURE BoxD(b, what: INTEGER): INTEGER;
BEGIN ASSERT((b >= 0) & (b <= 255), IndexOutOfRange); RETURN CBoxD(b, what)
END BoxD;

PROCEDURE BoxDX*(b: INTEGER): INTEGER;
BEGIN RETURN BoxD(b, 0)
END BoxDX;

PROCEDURE BoxDY*(b: INTEGER): INTEGER;
BEGIN RETURN BoxD(b, 1)
END BoxDY;

PROCEDURE BoxDW*(b: INTEGER): INTEGER;
BEGIN RETURN BoxD(b, 2)
END BoxDW;

PROCEDURE BoxDH*(b: INTEGER): INTEGER;
BEGIN RETURN BoxD(b, 3)
END BoxDH;

(* FLTK's look: "none" (or "base"), "plastic", "gtk+", "gleam" or "oxy".
   FALSE if FLTK doesn't know name; the look is then "none". *)
PROCEDURE SetScheme*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CSetScheme(name) # 0
END SetScheme;

(* The scheme's name, "" for none. *)
PROCEDURE GetScheme*(VAR name: ARRAY OF CHAR);
BEGIN FromC(CScheme(), name)
END GetScheme;

(* Events. While a widget's Handle runs, these say what the event was:
   where, which key or button, what text. A position is in the window's
   coordinates, as a widget's X and Y are, unless it is Root. *)

(* The event being handled: EvPush, or another event constant. *)
PROCEDURE Event*(): INTEGER;
BEGIN RETURN CEvent()
END Event;

PROCEDURE EventX*(): INTEGER;
BEGIN RETURN CEventX()
END EventX;

PROCEDURE EventY*(): INTEGER;
BEGIN RETURN CEventY()
END EventY;

(* The position on the screen. *)
PROCEDURE EventXRoot*(): INTEGER;
BEGIN RETURN CEventXRoot()
END EventXRoot;

PROCEDURE EventYRoot*(): INTEGER;
BEGIN RETURN CEventYRoot()
END EventYRoot;

(* How far an EvMouseWheel turned: across, and down (positive) or up. *)
PROCEDURE EventDx*(): INTEGER;
BEGIN RETURN CEventDx()
END EventDx;

PROCEDURE EventDy*(): INTEGER;
BEGIN RETURN CEventDy()
END EventDy;

(* The button of an EvPush or EvRelease: LeftMouse, MiddleMouse, ... *)
PROCEDURE EventButton*(): INTEGER;
BEGIN RETURN CEventButton()
END EventButton;

(* For an EvPush: 0 for a single click, 1 for a double, and so on. *)
PROCEDURE EventClicks*(): INTEGER;
BEGIN RETURN CEventClicks()
END EventClicks;

(* Sets EventClicks: 0 makes the next click a single one. *)
PROCEDURE SetEventClicks*(n: INTEGER);
BEGIN CSetEventClicks(n)
END SetEventClicks;

(* TRUE if the mouse hasn't moved far, or for long, since the EvPush, so
   that it is still a click. *)
PROCEDURE EventIsClick*(): BOOLEAN;
BEGIN RETURN CEventIsClick() # 0
END EventIsClick;

(* Makes EventIsClick FALSE until the next EvPush. *)
PROCEDURE EventIsClickOff*;
BEGIN CEventIsClickOff
END EventIsClickOff;

(* The key of an EvKeyDown or EvKeyUp: a character's code, unshifted
   ("a" for "A"), or a Key constant; for a mouse button, KeyButton plus
   the button. *)
PROCEDURE EventKey*(): INTEGER;
BEGIN RETURN CEventKey()
END EventKey;

(* EventKey, before FLTK's keypad translation (NumLock off). *)
PROCEDURE EventOriginalKey*(): INTEGER;
BEGIN RETURN CEventOriginalKey()
END EventOriginalKey;

(* TRUE if key was held down when the event happened. *)
PROCEDURE EventKeyDown*(key: INTEGER): BOOLEAN;
BEGIN RETURN CEventKeyDown(key) # 0
END EventKeyDown;

(* TRUE if key is held down now, whatever the event. (FLTK's name: KeyDown
   is the down arrow.) *)
PROCEDURE GetKey*(key: INTEGER): BOOLEAN;
BEGIN RETURN CGetKey(key) # 0
END GetKey;

(* The shift keys and buttons held during the event: a set of Shift,
   Ctrl, Button1 and the other state constants. *)
PROCEDURE EventState*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CEventState())
END EventState;

(* The text of an EvKeyDown (what the key types, UTF-8) or an EvPaste,
   truncated to fit text; "" for none. *)
PROCEDURE EventText*(VAR text: ARRAY OF CHAR);
BEGIN FromC(CEventText(), text)
END EventText;

(* The length of EventText's text, in bytes, untruncated. *)
PROCEDURE EventLength*(): INTEGER;
BEGIN RETURN CEventLength()
END EventLength;

(* The clipboard, and drag and drop *)

(* Puts text, up to its 0X, in the selection buffer, the clipboard, or
   both (Selection, Clipboard, Both). Under Wayland, which has no
   selection buffer, Both is the clipboard alone (doc/fltk-issues.md,
   50). *)
PROCEDURE Copy*(text-: ARRAY OF CHAR; destination: INTEGER);
  VAR n: INTEGER;
BEGIN
  ASSERT((destination >= Selection) & (destination <= Both), IndexOutOfRange);
  n := 0; WHILE (n < LEN(text)) & (text[n] # 0X) DO INC(n) END;
  CCopy(text, n, destination)
END Copy;

(* Asks for the text in source, Selection or Clipboard, to be sent to
   receiver as an EvPaste, its text in EventText: at once, if the program
   copied it itself, else later, as the window system delivers it, or
   never. Under Wayland only the clipboard can be pasted from; under X11
   another program's text needs a window shown. *)
PROCEDURE Paste*(receiver: Widget; source: INTEGER);
BEGIN
  ASSERT((source = Selection) OR (source = Clipboard), IndexOutOfRange);
  CPaste(Live(receiver), source, 0)
END Paste;

(* The same for an image on the clipboard: the receiver's Handle takes it
   with FlImages.TakePastedImage. *)
PROCEDURE PasteImage*(receiver: Widget);
BEGIN CPaste(Live(receiver), Clipboard, 1)
END PasteImage;

(* Whether the clipboard holds text, or an image. *)
PROCEDURE ClipboardHasText*(): BOOLEAN;
BEGIN RETURN CClipboardContains(0) # 0
END ClipboardHasText;

PROCEDURE ClipboardHasImage*(): BOOLEAN;
BEGIN RETURN CClipboardContains(1) # 0
END ClipboardHasImage;

(* In an EvPaste, TRUE if it carries an image, not text. *)
PROCEDURE EventIsImage*(): BOOLEAN;
BEGIN RETURN CEventIsImage() # 0
END EventIsImage;

(* Starts dragging the text last copied to the selection buffer, from a
   Handle's EvPush or EvDrag. A widget it is dragged over gets EvDndEnter,
   EvDndDrag and EvDndLeave, and if it returned TRUE for them,
   EvDndRelease and then the text as an EvPaste where it is dropped. On
   X11 Dnd returns when the text is dropped; under Wayland at once, the
   compositor doing the dragging. *)
PROCEDURE Dnd*;
VAR r: INTEGER;
BEGIN r := CDnd()
END Dnd;

(* Whether text widgets let the user drag text out of them and drop it in;
   TRUE to start with. *)
PROCEDURE DndTextOps*(): BOOLEAN;
BEGIN RETURN CDndTextOps(0) # 0
END DndTextOps;

PROCEDURE SetDndTextOps*(on: BOOLEAN);
VAR r: INTEGER;
BEGIN IF on THEN r := CDndTextOps(2) ELSE r := CDndTextOps(1) END
END SetDndTextOps;

(* FLTK's options, OptionArrowFocus and the rest: the user's and the
   system's (set with FLTK's fltk-options), unless SetOption overrides
   one for the rest of the run. *)
PROCEDURE Option*(o: INTEGER): BOOLEAN;
BEGIN
  ASSERT((o >= OptionArrowFocus) & (o <= OptionSimpleZoomShortcut), IndexOutOfRange);
  RETURN COption(o, 0) # 0
END Option;

PROCEDURE SetOption*(o: INTEGER; on: BOOLEAN);
  VAR r: INTEGER;
BEGIN
  ASSERT((o >= OptionArrowFocus) & (o <= OptionSimpleZoomShortcut), IndexOutOfRange);
  IF on THEN r := COption(o, 2) ELSE r := COption(o, 1) END
END SetOption;

(* TRUE if the event's position is inside the rectangle x, y, w, h. *)
PROCEDURE EventInside*(x, y, w, h: INTEGER): BOOLEAN;
BEGIN RETURN CEventInside(x, y, w, h) # 0
END EventInside;

(* The widget with the keyboard focus, or NIL: none, or one FLTK made. *)
PROCEDURE Focus*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CFocus())
END Focus;

(* Gives w the focus without asking it, as TakeFocus does; NIL for none. *)
PROCEDURE SetFocus*(w: Widget);
BEGIN
  IF w = NIL THEN CSetFocus(0) ELSE CSetFocus(Live(w)) END
END SetFocus;

(* The widget under the mouse, which gets EvMove and EvMouseWheel, and the
   one that took the last EvPush, which gets EvDrag and EvRelease; NIL
   for none, or one FLTK made. *)
PROCEDURE BelowMouse*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CBelowmouse())
END BelowMouse;

PROCEDURE Pushed*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CPushed())
END Pushed;

(* Screens, numbered from 0 *)

(* The work area of the main screen, screen 0: the screen less what the
   desktop keeps, such as panels. *)
PROCEDURE ScreenX*(): INTEGER;
BEGIN RETURN CScreen(0)
END ScreenX;

PROCEDURE ScreenY*(): INTEGER;
BEGIN RETURN CScreen(1)
END ScreenY;

PROCEDURE ScreenW*(): INTEGER;
BEGIN RETURN CScreen(2)
END ScreenW;

PROCEDURE ScreenH*(): INTEGER;
BEGIN RETURN CScreen(3)
END ScreenH;

PROCEDURE ScreenCount*(): INTEGER;
BEGIN RETURN CScreenCount()
END ScreenCount;

(* Screen n's place and size, from 0 to ScreenCount() - 1. *)
PROCEDURE ScreenXYWH*(n: INTEGER; VAR x, y, w, h: INTEGER);
  VAR cx, cy, cw, ch: SYSTEM.INT32;
BEGIN
  ASSERT((n >= 0) & (n < CScreenCount()), IndexOutOfRange);
  CScreenXYWH(n, 0, cx, cy, cw, ch); x := cx; y := cy; w := cw; h := ch
END ScreenXYWH;

(* Screen n's work area. *)
PROCEDURE ScreenWorkArea*(n: INTEGER; VAR x, y, w, h: INTEGER);
  VAR cx, cy, cw, ch: SYSTEM.INT32;
BEGIN
  ASSERT((n >= 0) & (n < CScreenCount()), IndexOutOfRange);
  CScreenXYWH(n, 1, cx, cy, cw, ch); x := cx; y := cy; w := cw; h := ch
END ScreenWorkArea;

(* The width of scrollbars: of every widget's whose own is 0, as it is
   unless set (Browser, Table, Tree and the rest have SetScrollbarSize).
   FLTK's is 16. *)
PROCEDURE ScrollbarSize*(): INTEGER;
BEGIN RETURN CScrollbarSize()
END ScrollbarSize;

(* From 1 up, or it halts (IndexOutOfRange). *)
PROCEDURE SetScrollbarSize*(n: INTEGER);
BEGIN ASSERT(n >= 1, IndexOutOfRange); CSetScrollbarSize(n)
END SetScrollbarSize;

(* The screen the point x, y is on; 0 if it is on none. *)
PROCEDURE ScreenAt*(x, y: INTEGER): INTEGER;
BEGIN RETURN CScreenNum(x, y)
END ScreenAt;

(* Command-line options *)

(* The C++ part's handler: argHandler's, checked. *)
PROCEDURE CallArgHandler(i: SYSTEM.INT32): SYSTEM.INT32;
  VAR n: INTEGER;
BEGIN
  n := argHandler(i);
  ASSERT((n >= 0) & (n <= Args.argc - i), IndexOutOfRange);
  RETURN n
END CallArgHandler;

(* Parses the command line's options (Args), the program's and FLTK's,
   from argument 1: handler, if not NIL, is offered each first, then
   FLTK (Arg). i is the number of the first argument not parsed:
   Args.argc if all were, or the first not an option (not starting with
   "-", or starting with "--", or "-" alone), or the first option
   neither knows, or that lacks its value, when the result is FALSE.
   FLTK's options take effect at once (-scheme, -kbd, -dnd, -tooltips,
   and the rest), or are kept for ShowArgs. ArgsHelp lists them. *)
PROCEDURE ParseArgs*(handler: ArgHandler; VAR i: INTEGER): BOOLEAN;
  VAR r: INTEGER; n: SYSTEM.INT32;
BEGIN
  argHandler := handler;
  IF handler = NIL THEN r := CArgs(Args.argc, Args.argv, n, NIL)
  ELSE r := CArgs(Args.argc, Args.argv, n, CallArgHandler)
  END;
  argHandler := NIL; i := n;
  RETURN r # 0
END ParseArgs;

(* Parses argument i, if it is one of FLTK's options: the number of words
   used, 0 if it isn't one. *)
PROCEDURE Arg*(i: INTEGER): INTEGER;
BEGIN
  ASSERT((i >= 0) & (i < Args.argc), IndexOutOfRange);
  RETURN CArg(Args.argc, Args.argv, i)
END Arg;

(* FLTK's options, a line each, indented a space (" -bg2 color" and the
   rest, without a heading), truncated to fit s. *)
PROCEDURE ArgsHelp*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CArgsHelp(), s)
END ArgsHelp;

(* Opens uri with the desktop's program for it (xdg-open, on Linux),
   which runs on by itself: a file:, ftp:, http:, https:, mailto: or
   news: URI. TRUE if the program was started, with msg its command;
   FALSE, with msg why not, if uri's scheme isn't one of those, or no
   program could be found. msg is truncated to fit. *)
PROCEDURE OpenURI*(uri-: ARRAY OF CHAR; VAR msg: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN COpenURI(uri, msg, SHORT(LEN(msg))) # 0
END OpenURI;

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

(* Idle callbacks *)

(* What an idle callback does: its action, if set. *)
PROCEDURE (i: Idle) Run*;
BEGIN
  IF i.action # NIL THEN i.action(i) END
END Run;

PROCEDURE (i: Idle) Added*(): BOOLEAN;
BEGIN RETURN i.added
END Added;

(* Has i run whenever the event loop is idle, until RemoveIdle. While one
   is added, Wait doesn't wait. Adding one added does nothing. *)
PROCEDURE AddIdle*(i: Idle);
BEGIN
  ASSERT(i # NIL, NilArgument);
  IF ~i.added THEN
    i.prev := NIL; i.next := idles;
    IF idles # NIL THEN idles.prev := i END;
    idles := i; i.added := TRUE;
    CAddIdle(SYSTEM.VAL(SYSTEM.ADDRESS, i))
  END
END AddIdle;

(* i won't run again, even from its own Run; nothing if it isn't added. *)
PROCEDURE RemoveIdle*(i: Idle);
BEGIN
  ASSERT(i # NIL, NilArgument);
  IF i.added THEN
    CRemoveIdle(SYSTEM.VAL(SYSTEM.ADDRESS, i));
    IF i.prev = NIL THEN idles := i.next ELSE i.prev.next := i.next END;
    IF i.next # NIL THEN i.next.prev := i.prev END;
    i.prev := NIL; i.next := NIL; i.added := FALSE
  END
END RemoveIdle;

(* File descriptors *)

(* What a watch does when its descriptor is ready: its action, if set. *)
PROCEDURE (w: FdWatch) Ready*;
BEGIN
  IF w.action # NIL THEN w.action(w) END
END Ready;

PROCEDURE (w: FdWatch) Watching*(): BOOLEAN;
BEGIN RETURN w.when # {}
END Watching;

PROCEDURE Unwatch(w: FdWatch);
BEGIN
  IF w.prev = NIL THEN watches := w.next ELSE w.prev.next := w.next END;
  IF w.next # NIL THEN w.next.prev := w.prev END;
  w.prev := NIL; w.next := NIL; w.when := {}
END Unwatch;

(* w stops watching; nothing if it isn't. Ready may stop its own watch. *)
PROCEDURE UnwatchFd*(w: FdWatch);
BEGIN
  ASSERT(w # NIL, NilArgument);
  IF w.when # {} THEN CRemoveFd(w.fd, ORD(w.when)); Unwatch(w) END
END UnwatchFd;

(* Has w watch fd for when: one or more of FdRead, FdWrite and FdExcept,
   or it halts (Unsupported). A watch watches one descriptor: watching
   another stops the first. As in FLTK, a descriptor has one watch for
   each of them, so another watch of fd stops watching for these. *)
PROCEDURE WatchFd*(w: FdWatch; fd: INTEGER; when: SET);
  VAR v, next: FdWatch;
BEGIN
  ASSERT(w # NIL, NilArgument); ASSERT(fd >= 0, IndexOutOfRange);
  ASSERT((when # {}) & (when - (FdRead + FdWrite + FdExcept) = {}), Unsupported);
  UnwatchFd(w);
  v := watches;
  WHILE v # NIL DO
    next := v.next;
    IF (v.fd = fd) & (v.when * when # {}) THEN
      v.when := v.when - when;           (* FLTK's add_fd took these from it *)
      IF v.when = {} THEN Unwatch(v) END
    END;
    v := next
  END;
  w.fd := fd; w.when := when;
  w.prev := NIL; w.next := watches;
  IF watches # NIL THEN watches.prev := w END;
  watches := w;
  CAddFd(fd, ORD(when), SYSTEM.VAL(SYSTEM.ADDRESS, w))
END WatchFd;

(* The event dispatch *)

(* d sees every event first, and hands it on with HandleDefault; NIL for
   FLTK's own dispatch. *)
PROCEDURE SetEventDispatch*(d: EventDispatch);
BEGIN
  dispatch := d;
  IF d = NIL THEN CEventDispatch(0) ELSE CEventDispatch(1) END
END SetEventDispatch;

(* Event handlers *)

(* Adds h to the handlers, which see the events no widget used, newest
   first; h may be added more than once. *)
PROCEDURE AddHandler*(h: EventHandler);
  VAR n: HandlerNode;
BEGIN
  ASSERT(h # NIL, NilArgument);
  IF handlers = NIL THEN CEventHandlers(1) END;
  NEW(n); n.h := h; n.next := handlers; handlers := n
END AddHandler;

(* Removes h, added last; nothing if it isn't added. *)
PROCEDURE RemoveHandler*(h: EventHandler);
  VAR n, prev: HandlerNode;
BEGIN
  n := handlers; prev := NIL;
  WHILE (n # NIL) & (n.h # h) DO prev := n; n := n.next END;
  IF n # NIL THEN
    IF prev = NIL THEN handlers := n.next ELSE prev.next := n.next END;
    n.h := NIL;  (* removed; n.next stays, for HandlerD *)
    IF handlers = NIL THEN CEventHandlers(0) END
  END
END RemoveHandler;

(* Redraws every window shown. *)
PROCEDURE Redraw*;
BEGIN CRedrawAll
END Redraw;

(* Whether any window is shown, the program's or FLTK's own (a dialog's,
   a menu's). *)
PROCEDURE WindowShown*(): BOOLEAN;
BEGIN RETURN CWindowShownAny() # 0
END WindowShown;

(* In the event dispatch only (NotFiring): FLTK's own handling of the
   event, for the dispatch's window; TRUE if a widget used it. *)
PROCEDURE HandleDefault*(event: INTEGER): BOOLEAN;
BEGIN ASSERT(dispatching > 0, NotFiring); RETURN CHandleDefault(event) # 0
END HandleDefault;

(* The event's key (EventKey) and text (EventText) become these, for
   what handles it next: as the event dispatch remaps a key. EventLength
   is the text's length. *)
PROCEDURE SetEventKey*(key: INTEGER);
BEGIN CSetEventKey(key)
END SetEventKey;

PROCEDURE SetEventText*(text-: ARRAY OF CHAR);
BEGIN CSetEventText(text)
END SetEventText;

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

(* The dispatchers the C++ part calls (pofltk.h), registered below. *)

PROCEDURE CallbackD(self: SYSTEM.ADDRESS);
  VAR w: Widget;
BEGIN w := SYSTEM.VAL(Widget, self); w.Callback
END CallbackD;

PROCEDURE DrawD(self: SYSTEM.ADDRESS);
  VAR w: Widget;
BEGIN w := SYSTEM.VAL(Widget, self); w.Draw
END DrawD;

PROCEDURE ResizeD(self: SYSTEM.ADDRESS; x, y, w, h: SYSTEM.INT32);
  VAR wd: Widget;
BEGIN wd := SYSTEM.VAL(Widget, self); wd.Resize(x, y, w, h)
END ResizeD;

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

PROCEDURE IdleD(self: SYSTEM.ADDRESS);
  VAR i: Idle;
BEGIN i := SYSTEM.VAL(Idle, self); i.Run
END IdleD;

PROCEDURE FdD(self: SYSTEM.ADDRESS);
  VAR w: FdWatch;
BEGIN w := SYSTEM.VAL(FdWatch, self); w.Ready
END FdD;

(* self is the event's window's object, or 0. *)
PROCEDURE DispatchD(event: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.INT32;
  VAR w: Window; used: BOOLEAN;
BEGIN
  IF self = 0 THEN w := NIL ELSE w := SYSTEM.VAL(Window, self) END;
  INC(dispatching);
  IF dispatch # NIL THEN used := dispatch(event, w) ELSE used := CHandleDefault(event) # 0 END;
  DEC(dispatching);
  IF used THEN RETURN 1 ELSE RETURN 0 END
END DispatchD;

(* Each handler in turn, until one uses the event. One may remove itself
   or another: a node removed keeps its next, and its h is NIL, so it is
   passed over. One added meanwhile is first, and not called. *)
PROCEDURE HandlerD(event: SYSTEM.INT32): SYSTEM.INT32;
  VAR n: HandlerNode;
BEGIN
  n := handlers;
  WHILE n # NIL DO
    IF (n.h # NIL) & n.h(event) THEN RETURN 1 END;
    n := n.next
  END;
  RETURN 0
END HandlerD;

BEGIN
  CRegister(CallbackD, DrawD, HandleD, ResizeD, DeletedD, TimeoutD);
  CRegisterLoop(IdleD, FdD, DispatchD, HandlerD)
END Fl.
