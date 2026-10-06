MODULE Probe; (* For the tests: a widget's pixels, and events sent as from the user *)

(* Its C++ part is Probe.cpp. *)

IMPORT SYSTEM, Fl;

PROCEDURE ["C", "ofltest_capture"] CCapture(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_pixel"] CPixel(x, y: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_release"] CRelease;
PROCEDURE ["C", "ofltest_mouse"] CMouse(win: SYSTEM.ADDRESS; event, x, y, button, state, clicks: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_wheel"] CWheel(win: SYSTEM.ADDRESS; x, y, dx, dy: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_shortcut"] CShortcut(win: SYSTEM.ADDRESS; key, state: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_handle_key"] CHandleKey(win: SYSTEM.ADDRESS; event, key, state: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_wayland"] CWayland(): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_modal_key"] CModalKey(key, state: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_modal"] CModal(VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_key"] CKey(event, key, state: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;

(* Draws w, as FLTK would in its window, on white, for Pixel; TRUE if
   the image is w's size. *)
PROCEDURE Capture*(w: Fl.Widget): BOOLEAN;
BEGIN RETURN CCapture(w.h) # 0
END Capture;

(* Pixel x, y of the capture, from w's top left, as Fl.RGB gives it: its
   red, green and blue, and 0. *)
PROCEDURE Pixel*(x, y: INTEGER): INTEGER;
  VAR p: INTEGER;
BEGIN
  p := CPixel(x, y);
  IF p < 0 THEN RETURN -1 END;
  RETURN Fl.RGB(p DIV 10000H, p DIV 100H MOD 100H, p MOD 100H)
END Pixel;

(* Frees the capture. *)
PROCEDURE Release*;
BEGIN CRelease
END Release;

(* Each sends an event to win, as from the window system, and returns
   TRUE if a widget used it. x, y are in win's coordinates. An EvPush no
   widget uses shows win, as FLTK raises a window clicked in. *)
PROCEDURE Mouse*(win: Fl.Window; event, x, y, button: INTEGER; state: SET; clicks: INTEGER): BOOLEAN;
BEGIN RETURN CMouse(win.h, event, x, y, button, ORD(state), clicks) # 0
END Mouse;

PROCEDURE Wheel*(win: Fl.Window; x, y, dx, dy: INTEGER): BOOLEAN;
BEGIN RETURN CWheel(win.h, x, y, dx, dy) # 0
END Wheel;

(* A key event, EvKeyDown or EvKeyUp, sent to the focus widget alone,
   which FLTK offers it first; FALSE if there is none. *)
PROCEDURE Key*(event, key: INTEGER; state: SET; text-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CKey(event, key, ORD(state), text) # 0
END Key;

(* A key offered to win's widgets as a shortcut, as FLTK offers one the
   focus doesn't use; TRUE if one used it. *)
PROCEDURE Shortcut*(win: Fl.Window; key: INTEGER; state: SET; text-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CShortcut(win.h, key, ORD(state), text) # 0
END Shortcut;

(* A key event, EvKeyDown or EvShortcut, sent by FLTK's route, as
   from the window system: to a pop-up menu if one is up, else a shortcut
   goes to win's widgets and then to a global menu. Not a key no widget
   uses after mouse events, in a window never shown, which crashes FLTK. *)
PROCEDURE HandleKey*(win: Fl.Window; event, key: INTEGER; state: SET; text-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CHandleKey(win.h, event, key, ORD(state), text) # 0
END HandleKey;

(* TRUE if a modal window, a dialog, is shown, with its title in title. *)
PROCEDURE Modal*(VAR title: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CModal(title, SHORT(LEN(title))) # 0
END Modal;

(* A key sent to the modal window, a dialog, as from the window system;
   FALSE if no modal window is shown. *)
PROCEDURE ModalKey*(key: INTEGER; state: SET; text-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CModalKey(key, ORD(state), text) # 0
END ModalKey;

(* TRUE if FLTK uses Wayland, FALSE if X11. *)
PROCEDURE Wayland*(): BOOLEAN;
BEGIN RETURN CWayland() # 0
END Wayland;

END Probe.
