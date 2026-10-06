MODULE FlDraw; (* Drawing: colors, lines, shapes, paths, text, clipping *)

(* FLTK's fl_draw.H, for a widget's Draw. FLTK draws only while a Draw
   runs (or into an image surface), so these belong in Draw methods and
   procedures they call. Coordinates are the window's, as a widget's X
   and Y are: a widget draws in X() .. X() + W() - 1, and so on.

   The shapes (Line, Rect, ...) take integer coordinates and ignore the
   transformation; the paths (BeginLine ... Vertex ... EndLine, Circle,
   Curve, ArcPath) take real ones and apply it (PushMatrix, Translate,
   Scale, Rotate). Angles are in degrees, counterclockwise from three
   o'clock.

   Text is drawn in the font SetFont last set. FLTK's own drawing (labels,
   boxes) sets the font and color too, so a Draw sets them before it uses
   them. Offscreen drawing and images come in a later phase.

   The C++ part is FlDraw.cpp. *)

IMPORT SYSTEM;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* line styles (LineStyle): a dash pattern, plus a cap and a join *)
  Solid* = 0;
  Dash* = 1;
  Dot* = 2;
  DashDot* = 3;
  DashDotDot* = 4;
  CapFlat* = 256;
  CapRound* = 512;
  CapSquare* = 768;
  JoinMiter* = 4096;
  JoinRound* = 8192;
  JoinBevel* = 12288;
(* END generated constants *)

PROCEDURE ["C", "ofl_draw_color"] CColor(c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_rgb"] CRGB(r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_get_color"] CGetColor(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_line_style"] CLineStyle(style, width: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_point"] CPoint(x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_line"] CLine(x, y, x1, y1: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_rect"] CRect(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_rectf"] CRectF(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_loop3"] CLoop3(x0, y0, x1, y1, x2, y2: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_loop4"] CLoop4(x0, y0, x1, y1, x2, y2, x3, y3: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_polygon3"] CPolygon3(x0, y0, x1, y1, x2, y2: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_polygon4"] CPolygon4(x0, y0, x1, y1, x2, y2, x3, y3: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_xyline"] CXYLine(x, y, x1: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_yxline"] CYXLine(x, y, y1: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_arc"] CArc(x, y, w, h: SYSTEM.INT32; a1, a2: LONGREAL);
PROCEDURE ["C", "ofl_draw_pie"] CPie(x, y, w, h: SYSTEM.INT32; a1, a2: LONGREAL);
PROCEDURE ["C", "ofl_draw_push_matrix"] CPushMatrix;
PROCEDURE ["C", "ofl_draw_pop_matrix"] CPopMatrix;
PROCEDURE ["C", "ofl_draw_scale"] CScale(x, y: LONGREAL);
PROCEDURE ["C", "ofl_draw_translate"] CTranslate(x, y: LONGREAL);
PROCEDURE ["C", "ofl_draw_rotate"] CRotate(d: LONGREAL);
PROCEDURE ["C", "ofl_draw_begin_points"] CBeginPoints;
PROCEDURE ["C", "ofl_draw_begin_line"] CBeginLine;
PROCEDURE ["C", "ofl_draw_begin_loop"] CBeginLoop;
PROCEDURE ["C", "ofl_draw_begin_polygon"] CBeginPolygon;
PROCEDURE ["C", "ofl_draw_begin_complex_polygon"] CBeginComplexPolygon;
PROCEDURE ["C", "ofl_draw_gap"] CGap;
PROCEDURE ["C", "ofl_draw_end_points"] CEndPoints;
PROCEDURE ["C", "ofl_draw_end_line"] CEndLine;
PROCEDURE ["C", "ofl_draw_end_loop"] CEndLoop;
PROCEDURE ["C", "ofl_draw_end_polygon"] CEndPolygon;
PROCEDURE ["C", "ofl_draw_end_complex_polygon"] CEndComplexPolygon;
PROCEDURE ["C", "ofl_draw_vertex"] CVertex(x, y: LONGREAL);
PROCEDURE ["C", "ofl_draw_curve"] CCurve(x0, y0, x1, y1, x2, y2, x3, y3: LONGREAL);
PROCEDURE ["C", "ofl_draw_arc_path"] CArcPath(x, y, r, start, end: LONGREAL);
PROCEDURE ["C", "ofl_draw_circle"] CCircle(x, y, r: LONGREAL);
PROCEDURE ["C", "ofl_draw_font"] CFont(face, size: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_get_font"] CGetFont(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_size"] CSize(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_height"] CHeight(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_descent"] CDescent(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_width"] CWidth(s: ARRAY OF CHAR): LONGREAL;
PROCEDURE ["C", "ofl_draw_text"] CText(s: ARRAY OF CHAR; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_text_aligned"] CTextAligned(s: ARRAY OF CHAR; x, y, w, h, align: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_measure"] CMeasure(s: ARRAY OF CHAR; VAR w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_push_clip"] CPushClip(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_push_no_clip"] CPushNoClip;
PROCEDURE ["C", "ofl_draw_pop_clip"] CPopClip;
PROCEDURE ["C", "ofl_draw_not_clipped"] CNotClipped(x, y, w, h: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_clip_box"] CClipBox(x, y, w, h: SYSTEM.INT32; VAR cx, cy, cw, ch: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_box"] CDrawBox(type, x, y, w, h, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_focus_rect"] CFocusRect(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_symbol"] CDrawSymbol(name: ARRAY OF CHAR; x, y, w, h, c: SYSTEM.INT32): SYSTEM.INT32;

(* Colors and lines *)

(* What draws from now on: c, a color of Fl's (Fl.Red, Fl.RGB(...)). *)
PROCEDURE SetColor*(c: INTEGER);
BEGIN CColor(c)
END SetColor;

PROCEDURE SetRGB*(r, g, b: INTEGER);
BEGIN CRGB(r, g, b)
END SetRGB;

PROCEDURE Color*(): INTEGER;
BEGIN RETURN CGetColor()
END Color;

(* Lines from now on: style is Solid, Dash or another dash pattern, plus
   a cap and a join (Dash + CapRound + JoinRound); width is in pixels, 0
   for the thinnest. LineStyle(Solid, 0) goes back to FLTK's default,
   which a Draw that changes the style must do before it returns. *)
PROCEDURE LineStyle*(style, width: INTEGER);
BEGIN CLineStyle(style, width)
END LineStyle;

(* Shapes *)

PROCEDURE Point*(x, y: INTEGER);
BEGIN CPoint(x, y)
END Point;

PROCEDURE Line*(x, y, x1, y1: INTEGER);
BEGIN CLine(x, y, x1, y1)
END Line;

(* The outline of the rectangle, inside it. *)
PROCEDURE Rect*(x, y, w, h: INTEGER);
BEGIN CRect(x, y, w, h)
END Rect;

(* The rectangle, filled. *)
PROCEDURE RectF*(x, y, w, h: INTEGER);
BEGIN CRectF(x, y, w, h)
END RectF;

(* The outlines of a triangle and a quadrilateral. *)
PROCEDURE Loop3*(x0, y0, x1, y1, x2, y2: INTEGER);
BEGIN CLoop3(x0, y0, x1, y1, x2, y2)
END Loop3;

PROCEDURE Loop4*(x0, y0, x1, y1, x2, y2, x3, y3: INTEGER);
BEGIN CLoop4(x0, y0, x1, y1, x2, y2, x3, y3)
END Loop4;

(* The same, filled. *)
PROCEDURE Polygon3*(x0, y0, x1, y1, x2, y2: INTEGER);
BEGIN CPolygon3(x0, y0, x1, y1, x2, y2)
END Polygon3;

PROCEDURE Polygon4*(x0, y0, x1, y1, x2, y2, x3, y3: INTEGER);
BEGIN CPolygon4(x0, y0, x1, y1, x2, y2, x3, y3)
END Polygon4;

(* A horizontal line from x, y to x1, y; a vertical one to x, y1. *)
PROCEDURE XYLine*(x, y, x1: INTEGER);
BEGIN CXYLine(x, y, x1)
END XYLine;

PROCEDURE YXLine*(x, y, y1: INTEGER);
BEGIN CYXLine(x, y, y1)
END YXLine;

(* The arc of the ellipse inside x, y, w, h from angle a1 to a2, and the
   same, filled as a pie slice. *)
PROCEDURE Arc*(x, y, w, h: INTEGER; a1, a2: LONGREAL);
BEGIN CArc(x, y, w, h, a1, a2)
END Arc;

PROCEDURE Pie*(x, y, w, h: INTEGER; a1, a2: LONGREAL);
BEGIN CPie(x, y, w, h, a1, a2)
END Pie;

(* Paths and the transformation *)

(* Saves the transformation, for PopMatrix to restore; at most 32 deep. *)
PROCEDURE PushMatrix*;
BEGIN CPushMatrix
END PushMatrix;

PROCEDURE PopMatrix*;
BEGIN CPopMatrix
END PopMatrix;

PROCEDURE Scale*(x, y: LONGREAL);
BEGIN CScale(x, y)
END Scale;

PROCEDURE Translate*(x, y: LONGREAL);
BEGIN CTranslate(x, y)
END Translate;

(* By d degrees, counterclockwise. *)
PROCEDURE Rotate*(d: LONGREAL);
BEGIN CRotate(d)
END Rotate;

(* A path is a Begin, its Vertex, Curve, ArcPath and Circle calls, and the
   matching End: points, a line through them, a closed loop, a convex
   polygon, or any polygon, with Gap between its separate outlines. *)
PROCEDURE BeginPoints*;
BEGIN CBeginPoints
END BeginPoints;

PROCEDURE BeginLine*;
BEGIN CBeginLine
END BeginLine;

PROCEDURE BeginLoop*;
BEGIN CBeginLoop
END BeginLoop;

PROCEDURE BeginPolygon*;
BEGIN CBeginPolygon
END BeginPolygon;

PROCEDURE BeginComplexPolygon*;
BEGIN CBeginComplexPolygon
END BeginComplexPolygon;

PROCEDURE Gap*;
BEGIN CGap
END Gap;

PROCEDURE EndPoints*;
BEGIN CEndPoints
END EndPoints;

PROCEDURE EndLine*;
BEGIN CEndLine
END EndLine;

PROCEDURE EndLoop*;
BEGIN CEndLoop
END EndLoop;

PROCEDURE EndPolygon*;
BEGIN CEndPolygon
END EndPolygon;

PROCEDURE EndComplexPolygon*;
BEGIN CEndComplexPolygon
END EndComplexPolygon;

PROCEDURE Vertex*(x, y: LONGREAL);
BEGIN CVertex(x, y)
END Vertex;

(* A Bezier curve from x0, y0 to x3, y3, drawn toward x1, y1 and x2, y2. *)
PROCEDURE Curve*(x0, y0, x1, y1, x2, y2, x3, y3: LONGREAL);
BEGIN CCurve(x0, y0, x1, y1, x2, y2, x3, y3)
END Curve;

(* The arc of the circle at x, y, radius r, from angle start to end. *)
PROCEDURE ArcPath*(x, y, r, start, end: LONGREAL);
BEGIN CArcPath(x, y, r, start, end)
END ArcPath;

(* A circle: the whole path, between one Begin and End. *)
PROCEDURE Circle*(x, y, r: LONGREAL);
BEGIN CCircle(x, y, r)
END Circle;

(* Text *)

(* Text from now on: face is a font of Fl's (Fl.Helvetica, Fl.Courier +
   Fl.Bold), size in pixels. *)
PROCEDURE SetFont*(face, size: INTEGER);
BEGIN CFont(face, size)
END SetFont;

PROCEDURE Font*(): INTEGER;
BEGIN RETURN CGetFont()
END Font;

PROCEDURE Size*(): INTEGER;
BEGIN RETURN CSize()
END Size;

(* The font's line height, and how far below the baseline it reaches. *)
PROCEDURE Height*(): INTEGER;
BEGIN RETURN CHeight()
END Height;

PROCEDURE Descent*(): INTEGER;
BEGIN RETURN CDescent()
END Descent;

(* The width of s, in pixels. *)
PROCEDURE Width*(s-: ARRAY OF CHAR): LONGREAL;
BEGIN RETURN CWidth(s)
END Width;

(* s, from x on the baseline y. *)
PROCEDURE Text*(s-: ARRAY OF CHAR; x, y: INTEGER);
BEGIN CText(s, x, y)
END Text;

(* s in the box x, y, w, h, placed as a label is, by a set of Fl's Align
   constants, its lines split at each 0AX and, with Fl.AlignWrap, wrapped.
   "@" starts a symbol's name, as in a label; "@@" draws "@". *)
PROCEDURE TextAligned*(s-: ARRAY OF CHAR; x, y, w, h: INTEGER; align: SET);
BEGIN CTextAligned(s, x, y, w, h, ORD(align))
END TextAligned;

(* The width and height TextAligned would take for s. On entry w is the
   width to wrap at, 0 for none. *)
PROCEDURE Measure*(s-: ARRAY OF CHAR; VAR w, h: INTEGER);
  VAR cw, ch: SYSTEM.INT32;
BEGIN
  cw := w; ch := 0; CMeasure(s, cw, ch); w := cw; h := ch
END Measure;

(* Clipping *)

(* Draws only inside x, y, w, h, and the clip region before, until the
   matching PopClip. *)
PROCEDURE PushClip*(x, y, w, h: INTEGER);
BEGIN CPushClip(x, y, w, h)
END PushClip;

(* Draws anywhere, until the matching PopClip. *)
PROCEDURE PushNoClip*;
BEGIN CPushNoClip
END PushNoClip;

PROCEDURE PopClip*;
BEGIN CPopClip
END PopClip;

(* FALSE if nothing drawn in x, y, w, h would show, so it may be skipped. *)
PROCEDURE NotClipped*(x, y, w, h: INTEGER): BOOLEAN;
BEGIN RETURN CNotClipped(x, y, w, h) # 0
END NotClipped;

(* The bounding box of the part of x, y, w, h that would show, in cx, cy,
   cw, ch; cw or ch is 0 if none would. (FLTK's fl_clip_box also says
   whether the box is all of x, y, w, h, but says it wrongly:
   doc/fltk-issues.md, 2.) *)
PROCEDURE ClipBox*(x, y, w, h: INTEGER; VAR cx, cy, cw, ch: INTEGER);
  VAR X, Y, W, H: SYSTEM.INT32;
BEGIN
  CClipBox(x, y, w, h, X, Y, W, H);
  cx := X; cy := Y; cw := W; ch := H
END ClipBox;

(* Boxes and symbols *)

(* A box of type (Fl.UpBox or another box type), in color c. *)
PROCEDURE DrawBox*(type, x, y, w, h, c: INTEGER);
BEGIN CDrawBox(type, x, y, w, h, c)
END DrawBox;

(* The dotted box showing a widget has the focus. *)
PROCEDURE FocusRect*(x, y, w, h: INTEGER);
BEGIN CFocusRect(x, y, w, h)
END FocusRect;

(* The symbol name ("->", "circle", "+", ..., without the "@" a label
   uses) in x, y, w, h, in color c; FALSE if FLTK hasn't one by name. *)
PROCEDURE DrawSymbol*(name-: ARRAY OF CHAR; x, y, w, h, c: INTEGER): BOOLEAN;
BEGIN RETURN CDrawSymbol(name, x, y, w, h, c) # 0
END DrawSymbol;

END FlDraw.
