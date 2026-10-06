MODULE Scribble; (* Drawing with the mouse: a custom widget's Handle and Draw *)

(* Drag with the left button to draw; the right button clears, and the
   Escape key quits. Each stroke is kept in Oberon, and Draw redraws
   them all, so the drawing survives the window being covered. *)

IMPORT Fl, FlDraw;

TYPE
  Point = POINTER TO RECORD x, y: INTEGER; next: Point END;
  Stroke = POINTER TO RECORD first, last: Point; next: Stroke END;

  Canvas = POINTER TO RECORD (Fl.BoxDesc)
    strokes, current: Stroke
  END;

VAR
  window: Fl.DoubleWindow;
  canvas: Canvas;

PROCEDURE (c: Canvas) AddPoint(x, y: INTEGER);
  VAR p: Point;
BEGIN
  NEW(p); p.x := x; p.y := y;
  IF c.current.last = NIL THEN c.current.first := p ELSE c.current.last.next := p END;
  c.current.last := p
END AddPoint;

PROCEDURE (c: Canvas) Handle*(event: INTEGER): BOOLEAN;
  VAR s: Stroke;
BEGIN
  IF (event = Fl.EvPush) & (Fl.EventButton() = Fl.RightMouse) THEN
    c.strokes := NIL; c.current := NIL; c.Redraw; RETURN TRUE
  ELSIF event = Fl.EvPush THEN
    NEW(s); s.next := c.strokes; c.strokes := s; c.current := s;
    c.AddPoint(Fl.EventX(), Fl.EventY()); c.Redraw; RETURN TRUE
  ELSIF (event = Fl.EvDrag) & (c.current # NIL) THEN
    c.AddPoint(Fl.EventX(), Fl.EventY()); c.Redraw; RETURN TRUE
  ELSIF event = Fl.EvRelease THEN
    c.current := NIL; RETURN TRUE
  END;
  RETURN c.Handle^(event)
END Handle;

PROCEDURE (c: Canvas) Draw*;
  VAR s: Stroke; p: Point;
BEGIN
  c.DrawBox;
  FlDraw.PushClip(c.X(), c.Y(), c.W(), c.H());
  FlDraw.SetColor(Fl.DarkBlue); FlDraw.LineStyle(FlDraw.Solid + FlDraw.CapRound + FlDraw.JoinRound, 3);
  s := c.strokes;
  WHILE s # NIL DO
    FlDraw.BeginLine;
    p := s.first;
    WHILE p # NIL DO FlDraw.Vertex(p.x, p.y); p := p.next END;
    FlDraw.EndLine;
    s := s.next
  END;
  FlDraw.LineStyle(FlDraw.Solid, 0);
  IF c.strokes = NIL THEN c.DrawLabel END;
  FlDraw.PopClip
END Draw;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 400, 300, "Scribble");
  NEW(canvas); Fl.OpenBox(canvas, 0, 0, 400, 300, "Drag to draw; right-click clears");
  canvas.SetBoxType(Fl.FlatBox); canvas.SetColor(Fl.White);
  canvas.SetLabelColor(Fl.GrayRamp(12));
  window.SetResizable(canvas);
  window.End;
  window.Show;
  Fl.Run
END Scribble.
