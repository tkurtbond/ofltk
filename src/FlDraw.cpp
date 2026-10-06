// The C++ part of FlDraw: fl_draw.H's drawing, for a widget's Draw. See
// ofltk.h for the conventions.

#include "ofltk.h"

#include <FL/Fl_Graphics_Driver.H>
#include <FL/fl_draw.H>

namespace {

// Text drawn or measured before any fl_font crashes under Wayland/Cairo
// (doc/design.md, "Problems found"), so each text call sets FLTK's
// normal font first if none is set.
void ensure_font() {
  if (fl_graphics_driver->font_descriptor() == 0) {
    fl_font(FL_HELVETICA, FL_NORMAL_SIZE);
  }
}

}  // namespace

extern "C" {

// Colors and lines

void ofl_draw_color(int32_t c) { fl_color(static_cast<Fl_Color>(c)); }

void ofl_draw_rgb(int32_t r, int32_t g, int32_t b) {
  fl_color(static_cast<uchar>(r), static_cast<uchar>(g), static_cast<uchar>(b));
}

int32_t ofl_draw_get_color(void) { return static_cast<int32_t>(fl_color()); }

void ofl_draw_line_style(int32_t style, int32_t width) {
  fl_line_style(style, width);
}

// Shapes, in integer coordinates, untransformed

void ofl_draw_point(int32_t x, int32_t y) { fl_point(x, y); }

void ofl_draw_line(int32_t x, int32_t y, int32_t x1, int32_t y1) {
  fl_line(x, y, x1, y1);
}

void ofl_draw_rect(int32_t x, int32_t y, int32_t w, int32_t h) {
  fl_rect(x, y, w, h);
}

void ofl_draw_rectf(int32_t x, int32_t y, int32_t w, int32_t h) {
  fl_rectf(x, y, w, h);
}

void ofl_draw_loop3(int32_t x0, int32_t y0, int32_t x1, int32_t y1,
                    int32_t x2, int32_t y2) {
  fl_loop(x0, y0, x1, y1, x2, y2);
}

void ofl_draw_loop4(int32_t x0, int32_t y0, int32_t x1, int32_t y1,
                    int32_t x2, int32_t y2, int32_t x3, int32_t y3) {
  fl_loop(x0, y0, x1, y1, x2, y2, x3, y3);
}

void ofl_draw_polygon3(int32_t x0, int32_t y0, int32_t x1, int32_t y1,
                       int32_t x2, int32_t y2) {
  fl_polygon(x0, y0, x1, y1, x2, y2);
}

void ofl_draw_polygon4(int32_t x0, int32_t y0, int32_t x1, int32_t y1,
                       int32_t x2, int32_t y2, int32_t x3, int32_t y3) {
  fl_polygon(x0, y0, x1, y1, x2, y2, x3, y3);
}

void ofl_draw_xyline(int32_t x, int32_t y, int32_t x1) { fl_xyline(x, y, x1); }
void ofl_draw_yxline(int32_t x, int32_t y, int32_t y1) { fl_yxline(x, y, y1); }

void ofl_draw_arc(int32_t x, int32_t y, int32_t w, int32_t h, double a1,
                  double a2) {
  fl_arc(x, y, w, h, a1, a2);
}

void ofl_draw_pie(int32_t x, int32_t y, int32_t w, int32_t h, double a1,
                  double a2) {
  fl_pie(x, y, w, h, a1, a2);
}

// Paths, in transformed coordinates

void ofl_draw_push_matrix(void) { fl_push_matrix(); }
void ofl_draw_pop_matrix(void) { fl_pop_matrix(); }
void ofl_draw_scale(double x, double y) { fl_scale(x, y); }
void ofl_draw_translate(double x, double y) { fl_translate(x, y); }
void ofl_draw_rotate(double d) { fl_rotate(d); }
void ofl_draw_begin_points(void) { fl_begin_points(); }
void ofl_draw_begin_line(void) { fl_begin_line(); }
void ofl_draw_begin_loop(void) { fl_begin_loop(); }
void ofl_draw_begin_polygon(void) { fl_begin_polygon(); }
void ofl_draw_begin_complex_polygon(void) { fl_begin_complex_polygon(); }
void ofl_draw_gap(void) { fl_gap(); }
void ofl_draw_end_points(void) { fl_end_points(); }
void ofl_draw_end_line(void) { fl_end_line(); }
void ofl_draw_end_loop(void) { fl_end_loop(); }
void ofl_draw_end_polygon(void) { fl_end_polygon(); }
void ofl_draw_end_complex_polygon(void) { fl_end_complex_polygon(); }
void ofl_draw_vertex(double x, double y) { fl_vertex(x, y); }

void ofl_draw_curve(double x0, double y0, double x1, double y1, double x2,
                    double y2, double x3, double y3) {
  fl_curve(x0, y0, x1, y1, x2, y2, x3, y3);
}

void ofl_draw_arc_path(double x, double y, double r, double start,
                       double end) {
  fl_arc(x, y, r, start, end);
}

void ofl_draw_circle(double x, double y, double r) { fl_circle(x, y, r); }

// Text

void ofl_draw_font(int32_t face, int32_t size) { fl_font(face, size); }

int32_t ofl_draw_get_font(void) {
  ensure_font();
  return fl_font();
}

int32_t ofl_draw_size(void) {
  ensure_font();
  return fl_size();
}

int32_t ofl_draw_height(void) {
  ensure_font();
  return fl_height();
}

int32_t ofl_draw_descent(void) {
  ensure_font();
  return fl_descent();
}

double ofl_draw_width(const char *s) {
  ensure_font();
  return fl_width(s);
}

void ofl_draw_text(const char *s, int32_t x, int32_t y) {
  ensure_font();
  fl_draw(s, x, y);
}

void ofl_draw_text_aligned(const char *s, int32_t x, int32_t y, int32_t w,
                           int32_t h, int32_t align) {
  ensure_font();
  fl_draw(s, x, y, w, h, static_cast<Fl_Align>(align));
}

// *w is the width to wrap at on entry, 0 for none.
void ofl_draw_measure(const char *s, int32_t *w, int32_t *h) {
  int mw = *w, mh = 0;
  ensure_font();
  fl_measure(s, mw, mh);
  *w = mw;
  *h = mh;
}

// Clipping

void ofl_draw_push_clip(int32_t x, int32_t y, int32_t w, int32_t h) {
  fl_push_clip(x, y, w, h);
}

void ofl_draw_push_no_clip(void) { fl_push_no_clip(); }
void ofl_draw_pop_clip(void) { fl_pop_clip(); }

int32_t ofl_draw_not_clipped(int32_t x, int32_t y, int32_t w, int32_t h) {
  return fl_not_clipped(x, y, w, h);
}

// fl_clip_box's result is dropped: FLTK 1.4.5 returns 0 when the box was
// clipped and 1 when it wasn't, against its documentation. For a box
// wholly clipped it sets W to 0 and may leave the rest unset, hence the
// zeros.
void ofl_draw_clip_box(int32_t x, int32_t y, int32_t w, int32_t h,
                       int32_t *cx, int32_t *cy, int32_t *cw, int32_t *ch) {
  int X = 0, Y = 0, W = 0, H = 0;
  fl_clip_box(x, y, w, h, X, Y, W, H);
  *cx = X;
  *cy = Y;
  *cw = W;
  *ch = H;
}

// Boxes and symbols

void ofl_draw_box(int32_t type, int32_t x, int32_t y, int32_t w, int32_t h,
                  int32_t c) {
  fl_draw_box(static_cast<Fl_Boxtype>(type), x, y, w, h,
              static_cast<Fl_Color>(c));
}

void ofl_draw_focus_rect(int32_t x, int32_t y, int32_t w, int32_t h) {
  fl_focus_rect(x, y, w, h);
}

int32_t ofl_draw_symbol(const char *name, int32_t x, int32_t y, int32_t w,
                        int32_t h, int32_t c) {
  return fl_draw_symbol(name, x, y, w, h, static_cast<Fl_Color>(c));
}

}  // extern "C"
