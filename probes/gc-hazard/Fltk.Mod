MODULE Fltk;
  IMPORT SYSTEM;
  TYPE
    Widget* = SYSTEM.ADDRESS;
    Callback* = PROCEDURE (w: Widget; data: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_window_new"] WindowNew*(w, h: SYSTEM.INT32; label: ARRAY OF CHAR): Widget;
  PROCEDURE ["C", "ofl_button_new"] ButtonNew*(x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR): Widget;
  PROCEDURE ["C", "ofl_group_end"] End*(g: Widget);
  PROCEDURE ["C", "ofl_window_show"] Show*(w: Widget);
  PROCEDURE ["C", "ofl_widget_callback"] SetCallback*(w: Widget; cb: Callback; data: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_widget_copy_label"] CopyLabel*(w: Widget; label: ARRAY OF CHAR);
  PROCEDURE ["C", "ofl_run"] Run*(): SYSTEM.INT32;
  PROCEDURE ["C", "ofl_hide"] Hide*(w: Widget);
  PROCEDURE ["C", "ofl_add_timeout"] AddTimeout*(t: LONGREAL; cb: PROCEDURE (d: SYSTEM.ADDRESS); d: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_do_callback"] DoCallback*(w: Widget);
END Fltk.
