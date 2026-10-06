MODULE FL;  (* sketch of an object-style binding *)
  IMPORT SYSTEM;
  CONST Push* = 1; Release* = 2;
  TYPE
    Widget* = POINTER TO WidgetDesc;
    WidgetDesc* = RECORD
      h-: SYSTEM.ADDRESS;  (* the Fl_Widget* *)
      next: Widget         (* registry link: keeps the object alive while FLTK holds it *)
    END;
    Window* = POINTER TO RECORD (WidgetDesc) END;
    Button* = POINTER TO ButtonDesc;
    ButtonDesc* = RECORD (WidgetDesc) END;
    Box* = POINTER TO BoxDesc;      (* a custom widget: extend it, override Draw/Handle *)
    BoxDesc* = RECORD (WidgetDesc) END;
  VAR live: Widget;

  PROCEDURE ["C", "ofl_init"] Init(d, h, c, g: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_window_new"] WindowNew(w, h: SYSTEM.INT32; l: ARRAY OF CHAR): SYSTEM.ADDRESS;
  PROCEDURE ["C", "ofl_button_new"] ButtonNew(x, y, w, h: SYSTEM.INT32; l: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
  PROCEDURE ["C", "ofl_obox_new"] OBoxNew(x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
  PROCEDURE ["C", "ofl_end"] CEnd(g: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_show"] CShow(w: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_hide"] CHide(w: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_redraw"] CRedraw(w: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_delete"] CDelete(w: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_do_callback"] CDoCallback(w: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_geom"] CGeom(w: SYSTEM.ADDRESS; VAR x, y, ww, hh: SYSTEM.INT32);
  PROCEDURE ["C", "ofl_color"] Color*(c: SYSTEM.INT32);
  PROCEDURE ["C", "ofl_rectf"] RectF*(x, y, w, h: SYSTEM.INT32);
  PROCEDURE ["C", "ofl_text"] Text*(s: ARRAY OF CHAR; x, y: SYSTEM.INT32);
  PROCEDURE ["C", "ofl_add_timeout"] AddTimeout*(t: LONGREAL; cb: PROCEDURE (d: SYSTEM.ADDRESS); d: SYSTEM.ADDRESS);
  PROCEDURE ["C", "ofl_run"] CRun(): SYSTEM.INT32;

  PROCEDURE Register(w: Widget); BEGIN w.next := live; live := w END Register;
  PROCEDURE Unregister(w: Widget);
    VAR p: Widget;
  BEGIN
    IF live = w THEN live := w.next
    ELSE p := live; WHILE (p # NIL) & (p.next # w) DO p := p.next END; IF p # NIL THEN p.next := w.next END
    END; w.h := 0
  END Unregister;

  (* overridable behaviour *)
  PROCEDURE (w: Widget) Clicked*; END Clicked;
  PROCEDURE (b: Box) Draw*; END Draw;
  PROCEDURE (b: Box) Handle*(event: LONGINT): BOOLEAN; BEGIN RETURN FALSE END Handle;

  PROCEDURE (w: Widget) Show*; BEGIN CShow(w.h) END Show;
  PROCEDURE (w: Widget) Hide*; BEGIN CHide(w.h) END Hide;
  PROCEDURE (w: Widget) Redraw*; BEGIN IF w.h # 0 THEN CRedraw(w.h) END END Redraw;
  PROCEDURE (w: Widget) Delete*; BEGIN CDelete(w.h) END Delete;
  PROCEDURE (w: Widget) DoCallback*; BEGIN CDoCallback(w.h) END DoCallback;
  PROCEDURE (w: Widget) Geometry*(VAR x, y, ww, hh: LONGINT);
    VAR a, b, c, d: SYSTEM.INT32;
  BEGIN ASSERT(w.h # 0, 20); CGeom(w.h, a, b, c, d); x := a; y := b; ww := c; hh := d END Geometry;
  PROCEDURE (w: Window) End*; BEGIN CEnd(w.h) END End;

  PROCEDURE OpenWindow*(w: Window; width, height: LONGINT; label: ARRAY OF CHAR);
  BEGIN w.h := WindowNew(SHORT(width), SHORT(height), label); Register(w) END OpenWindow;
  PROCEDURE OpenButton*(b: Button; x, y, w, h: LONGINT; label: ARRAY OF CHAR);
  BEGIN b.h := ButtonNew(SHORT(x), SHORT(y), SHORT(w), SHORT(h), label, SYSTEM.VAL(SYSTEM.ADDRESS, b)); Register(b) END OpenButton;
  PROCEDURE OpenBox*(b: Box; x, y, w, h: LONGINT);
  BEGIN b.h := OBoxNew(SHORT(x), SHORT(y), SHORT(w), SHORT(h), SYSTEM.VAL(SYSTEM.ADDRESS, b)); Register(b) END OpenBox;

  PROCEDURE Run*; VAR r: SYSTEM.INT32; BEGIN r := CRun() END Run;
  PROCEDURE LiveCount*(): LONGINT; VAR n: LONGINT; p: Widget; BEGIN n := 0; p := live; WHILE p # NIL DO INC(n); p := p.next END; RETURN n END LiveCount;

  (* dispatchers called from C++ *)
  PROCEDURE DrawD(self: SYSTEM.ADDRESS); VAR w: Widget; BEGIN w := SYSTEM.VAL(Widget, self); w(Box).Draw END DrawD;
  PROCEDURE HandleD(self: SYSTEM.ADDRESS; ev: SYSTEM.INT32): SYSTEM.INT32;
    VAR w: Widget; BEGIN w := SYSTEM.VAL(Widget, self); IF w(Box).Handle(ev) THEN RETURN 1 ELSE RETURN 0 END END HandleD;
  PROCEDURE ClickD(self: SYSTEM.ADDRESS); VAR w: Widget; BEGIN w := SYSTEM.VAL(Widget, self); w.Clicked END ClickD;
  PROCEDURE GoneD(self: SYSTEM.ADDRESS); BEGIN Unregister(SYSTEM.VAL(Widget, self)) END GoneD;
  PROCEDURE Adr(p: PROCEDURE (s: SYSTEM.ADDRESS)): SYSTEM.ADDRESS; BEGIN RETURN SYSTEM.VAL(SYSTEM.ADDRESS, p) END Adr;
  VAR hp: PROCEDURE (s: SYSTEM.ADDRESS; e: SYSTEM.INT32): SYSTEM.INT32;
BEGIN
  hp := HandleD;
  Init(Adr(DrawD), SYSTEM.VAL(SYSTEM.ADDRESS, hp), Adr(ClickD), Adr(GoneD))
END FL.
