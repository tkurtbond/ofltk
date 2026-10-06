// The C++ part of FlValuators: sliders, scrollbars, counters, dials,
// rollers, adjusters, value inputs and outputs, spinners and progress
// bars. See ofltk.h for the conventions.

#include "ofltk.h"

#include <FL/Fl_Adjuster.H>
#include <FL/Fl_Counter.H>
#include <FL/Fl_Dial.H>
#include <FL/Fl_Progress.H>
#include <FL/Fl_Roller.H>
#include <FL/Fl_Scrollbar.H>
#include <FL/Fl_Slider.H>
#include <FL/Fl_Spinner.H>
#include <FL/Fl_Value_Input.H>
#include <FL/Fl_Value_Output.H>
#include <FL/Fl_Value_Slider.H>

namespace {

template <class T>
intptr_t make(int32_t x, int32_t y, int32_t w, int32_t h, const char *label,
              intptr_t self) {
  ofl::W<T> *v = new ofl::W<T>(x, y, w, h);
  v->copy_label(ofl::label_text(label));
  return ofl::open(v, self);
}

Fl_Valuator *valuator(intptr_t v) { return ofl::as<Fl_Valuator>(v); }
Fl_Spinner *spinner(intptr_t s) { return ofl::as<Fl_Spinner>(s); }
Fl_Progress *progress(intptr_t p) { return ofl::as<Fl_Progress>(p); }

// *t := w as a T; TRUE if it is one.
template <class T> bool as_a(Fl_Widget *w, T **t) {
  *t = dynamic_cast<T *>(w);
  return *t != 0;
}

// The text font, size and color of a value slider, counter, value input
// or value output: each class has its own, unrelated to the others'.

#define OFL_TEXT_GET(what)                                               \
  {                                                                      \
    Fl_Widget *w = ofl::widget(v);                                       \
    Fl_Value_Slider *vs;                                                 \
    Fl_Counter *c;                                                       \
    Fl_Value_Input *vi;                                                  \
    Fl_Value_Output *vo;                                                 \
    if (as_a(w, &vs)) return static_cast<int32_t>(vs->what());        \
    if (as_a(w, &c)) return static_cast<int32_t>(c->what());          \
    if (as_a(w, &vi)) return static_cast<int32_t>(vi->what());        \
    if (as_a(w, &vo)) return static_cast<int32_t>(vo->what());        \
    return 0;                                                            \
  }

#define OFL_TEXT_SET(what, type)                                         \
  {                                                                      \
    Fl_Widget *w = ofl::widget(v);                                       \
    Fl_Value_Slider *vs;                                                 \
    Fl_Counter *c;                                                       \
    Fl_Value_Input *vi;                                                  \
    Fl_Value_Output *vo;                                                 \
    if (as_a(w, &vs)) vs->what(static_cast<type>(x));                 \
    else if (as_a(w, &c)) c->what(static_cast<type>(x));              \
    else if (as_a(w, &vi)) vi->what(static_cast<type>(x));            \
    else if (as_a(w, &vo)) vo->what(static_cast<type>(x));            \
  }

}  // namespace

extern "C" {

// kind is 0 Fl_Slider, 1 Fl_Value_Slider, and so on, as FlValuators
// numbers them.
intptr_t ofl_valuator_new(int32_t kind, int32_t x, int32_t y, int32_t w,
                          int32_t h, const char *label, intptr_t self) {
  switch (kind) {
    case 1: return make<Fl_Value_Slider>(x, y, w, h, label, self);
    case 2: return make<Fl_Scrollbar>(x, y, w, h, label, self);
    case 3: return make<Fl_Counter>(x, y, w, h, label, self);
    case 4: return make<Fl_Dial>(x, y, w, h, label, self);
    case 5: return make<Fl_Roller>(x, y, w, h, label, self);
    case 6: return make<Fl_Adjuster>(x, y, w, h, label, self);
    case 7: return make<Fl_Value_Input>(x, y, w, h, label, self);
    case 8: return make<Fl_Value_Output>(x, y, w, h, label, self);
    default: return make<Fl_Slider>(x, y, w, h, label, self);
  }
}

intptr_t ofl_spinner_new(int32_t x, int32_t y, int32_t w, int32_t h,
                         const char *label, intptr_t self) {
  return make<Fl_Spinner>(x, y, w, h, label, self);
}

intptr_t ofl_progress_new(int32_t x, int32_t y, int32_t w, int32_t h,
                          const char *label, intptr_t self) {
  return make<Fl_Progress>(x, y, w, h, label, self);
}

// Valuators

double ofl_valuator_value(intptr_t v) { return valuator(v)->value(); }

void ofl_valuator_set_value(intptr_t v, double x) { valuator(v)->value(x); }

double ofl_valuator_minimum(intptr_t v) { return valuator(v)->minimum(); }
double ofl_valuator_maximum(intptr_t v) { return valuator(v)->maximum(); }

// Fl_Slider::bounds also redraws the slider, but it hides
// Fl_Valuator's rather than overriding it, so a slider is called as one.
void ofl_valuator_bounds(intptr_t v, double a, double b) {
  Fl_Slider *s = dynamic_cast<Fl_Slider *>(ofl::widget(v));
  if (s) {
    s->bounds(a, b);
  } else {
    valuator(v)->bounds(a, b);
  }
}

double ofl_valuator_step(intptr_t v) { return valuator(v)->step(); }
void ofl_valuator_set_step(intptr_t v, double s) { valuator(v)->step(s); }

void ofl_valuator_precision(intptr_t v, int32_t digits) {
  valuator(v)->precision(digits);
}

double ofl_valuator_round(intptr_t v, double x) {
  return valuator(v)->round(x);
}

double ofl_valuator_clamp(intptr_t v, double x) {
  return valuator(v)->clamp(x);
}

double ofl_valuator_increment(intptr_t v, double x, int32_t n) {
  return valuator(v)->increment(x, n);
}

// The value as FLTK shows it, into buf of n characters, truncated.
// Fl_Valuator::format writes up to 128 bytes.
void ofl_valuator_format(intptr_t v, char *buf, int32_t n) {
  char s[128];
  valuator(v)->format(s);
  ofl::copy_out(s, buf, n);
}

int32_t ofl_valuator_type(intptr_t v) { return valuator(v)->type(); }

void ofl_valuator_set_type(intptr_t v, int32_t t) {
  valuator(v)->type(static_cast<uchar>(t));
}

// Sliders and scrollbars

double ofl_slider_size(intptr_t s) {
  return ofl::as<Fl_Slider>(s)->slider_size();
}

void ofl_slider_set_size(intptr_t s, double v) {
  ofl::as<Fl_Slider>(s)->slider_size(v);
}

int32_t ofl_slider_box(intptr_t s) { return ofl::as<Fl_Slider>(s)->slider(); }

void ofl_slider_set_box(intptr_t s, int32_t b) {
  ofl::as<Fl_Slider>(s)->slider(static_cast<Fl_Boxtype>(b));
}

int32_t ofl_slider_scrollvalue(intptr_t s, int32_t pos, int32_t size,
                               int32_t first, int32_t total) {
  return ofl::as<Fl_Slider>(s)->scrollvalue(pos, size, first, total);
}

int32_t ofl_scrollbar_linesize(intptr_t s) {
  return ofl::as<Fl_Scrollbar>(s)->linesize();
}

void ofl_scrollbar_set_linesize(intptr_t s, int32_t n) {
  ofl::as<Fl_Scrollbar>(s)->linesize(n);
}

// Counters, dials, adjusters, value inputs and outputs

void ofl_counter_lstep(intptr_t c, double s) {
  ofl::as<Fl_Counter>(c)->lstep(s);
}

int32_t ofl_dial_angle1(intptr_t d) { return ofl::as<Fl_Dial>(d)->angle1(); }
int32_t ofl_dial_angle2(intptr_t d) { return ofl::as<Fl_Dial>(d)->angle2(); }

void ofl_dial_angles(intptr_t d, int32_t a, int32_t b) {
  ofl::as<Fl_Dial>(d)->angles(static_cast<short>(a), static_cast<short>(b));
}

// soft: whether the user may go past the bounds. Each class has its own.
int32_t ofl_valuator_soft(intptr_t v) {
  Fl_Widget *w = ofl::widget(v);
  Fl_Adjuster *a;
  Fl_Value_Input *vi;
  Fl_Value_Output *vo;
  if (as_a(w, &a)) return a->soft();
  if (as_a(w, &vi)) return vi->soft();
  if (as_a(w, &vo)) return vo->soft();
  return 0;
}

void ofl_valuator_set_soft(intptr_t v, int32_t s) {
  Fl_Widget *w = ofl::widget(v);
  Fl_Adjuster *a;
  Fl_Value_Input *vi;
  Fl_Value_Output *vo;
  if (as_a(w, &a)) a->soft(s);
  else if (as_a(w, &vi)) vi->soft(static_cast<char>(s));
  else if (as_a(w, &vo)) vo->soft(static_cast<uchar>(s));
}

int32_t ofl_valuator_textfont(intptr_t v) OFL_TEXT_GET(textfont)
int32_t ofl_valuator_textsize(intptr_t v) OFL_TEXT_GET(textsize)
int32_t ofl_valuator_textcolor(intptr_t v) OFL_TEXT_GET(textcolor)
void ofl_valuator_set_textfont(intptr_t v, int32_t x) OFL_TEXT_SET(textfont, Fl_Font)
void ofl_valuator_set_textsize(intptr_t v, int32_t x) OFL_TEXT_SET(textsize, Fl_Fontsize)
void ofl_valuator_set_textcolor(intptr_t v, int32_t x) OFL_TEXT_SET(textcolor, Fl_Color)

// Spinners. Fl_Spinner's color, selection_color and type are its input
// field's, and hide Fl_Widget's rather than override them, so a spinner
// is called as one. Its format is not bound: FLTK keeps the pointer, and
// hands the string to snprintf as a format.

double ofl_spinner_value(intptr_t s) { return spinner(s)->value(); }
void ofl_spinner_set_value(intptr_t s, double v) { spinner(s)->value(v); }
double ofl_spinner_minimum(intptr_t s) { return spinner(s)->minimum(); }
double ofl_spinner_maximum(intptr_t s) { return spinner(s)->maximum(); }

void ofl_spinner_range(intptr_t s, double a, double b) {
  spinner(s)->range(a, b);
}

double ofl_spinner_step(intptr_t s) { return spinner(s)->step(); }
void ofl_spinner_set_step(intptr_t s, double v) { spinner(s)->step(v); }
int32_t ofl_spinner_wrap(intptr_t s) { return spinner(s)->wrap(); }
void ofl_spinner_set_wrap(intptr_t s, int32_t w) { spinner(s)->wrap(w); }
int32_t ofl_spinner_type(intptr_t s) { return spinner(s)->type(); }

void ofl_spinner_set_type(intptr_t s, int32_t t) {
  spinner(s)->type(static_cast<uchar>(t));
}

int32_t ofl_spinner_color(intptr_t s) {
  return static_cast<int32_t>(spinner(s)->color());
}

void ofl_spinner_set_color(intptr_t s, int32_t c) {
  spinner(s)->color(static_cast<Fl_Color>(c));
}

int32_t ofl_spinner_selection_color(intptr_t s) {
  return static_cast<int32_t>(spinner(s)->selection_color());
}

void ofl_spinner_set_selection_color(intptr_t s, int32_t c) {
  spinner(s)->selection_color(static_cast<Fl_Color>(c));
}

int32_t ofl_spinner_textfont(intptr_t s) { return spinner(s)->textfont(); }
void ofl_spinner_set_textfont(intptr_t s, int32_t f) { spinner(s)->textfont(f); }
int32_t ofl_spinner_textsize(intptr_t s) { return spinner(s)->textsize(); }
void ofl_spinner_set_textsize(intptr_t s, int32_t z) { spinner(s)->textsize(z); }

int32_t ofl_spinner_textcolor(intptr_t s) {
  return static_cast<int32_t>(spinner(s)->textcolor());
}

void ofl_spinner_set_textcolor(intptr_t s, int32_t c) {
  spinner(s)->textcolor(static_cast<Fl_Color>(c));
}

// Progress bars, whose values are floats in FLTK

double ofl_progress_value(intptr_t p) { return progress(p)->value(); }
double ofl_progress_minimum(intptr_t p) { return progress(p)->minimum(); }
double ofl_progress_maximum(intptr_t p) { return progress(p)->maximum(); }

void ofl_progress_set_value(intptr_t p, double v) {
  progress(p)->value(static_cast<float>(v));
}

void ofl_progress_set_minimum(intptr_t p, double v) {
  progress(p)->minimum(static_cast<float>(v));
}

void ofl_progress_set_maximum(intptr_t p, double v) {
  progress(p)->maximum(static_cast<float>(v));
}

}  // extern "C"
