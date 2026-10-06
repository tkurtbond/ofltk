MODULE Probe; (* For the tests: a widget's pixels, and events sent as from the user *)

(* Its C++ part is Probe.cpp. *)

IMPORT SYSTEM, Fl;

PROCEDURE ["C", "ofltest_capture"] CCapture(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_pixel"] CPixel(x, y: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_release"] CRelease;
PROCEDURE ["C", "ofltest_mouse"] CMouse(win: SYSTEM.ADDRESS; event, x, y, button, state, clicks: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_wheel"] CWheel(win: SYSTEM.ADDRESS; x, y, dx, dy: SYSTEM.INT32): SYSTEM.INT32;
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
BEGIN RETURN CMouse(win.h, event, x, y, button, SYSTEM.VAL(SYSTEM.INT32, state), clicks) # 0
END Mouse;

PROCEDURE Wheel*(win: Fl.Window; x, y, dx, dy: INTEGER): BOOLEAN;
BEGIN RETURN CWheel(win.h, x, y, dx, dy) # 0
END Wheel;

(* A key event, EvKeyDown or EvKeyUp, sent to the focus widget alone,
   which FLTK offers it first; FALSE if there is none. *)
PROCEDURE Key*(event, key: INTEGER; state: SET; text-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CKey(event, key, SYSTEM.VAL(SYSTEM.INT32, state), text) # 0
END Key;

END Probe.
