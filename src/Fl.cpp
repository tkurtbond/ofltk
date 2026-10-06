// The C++ part of Fl, ofltk's core module: widgets, groups, windows,
// boxes, timeouts and the event loop. See ofltk.h for the conventions.

#include "ofltk.h"

#include <FL/Fl_Box.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Window.H>

namespace ofl {

SelfFn on_callback, on_draw, on_deleted;
HandleFn on_handle;
int depth;

void callback_trampoline(Fl_Widget *, void *data) {
  Dispatch d;
  on_callback(static_cast<Ref *>(data)->self);
}

}  // namespace ofl

namespace {

ofl::SelfFn on_timeout;

// A timeout's data is its Oberon Timer's address, which Fl keeps
// reachable while the timeout is pending.
void timeout_trampoline(void *self) {
  ofl::Dispatch d;
  on_timeout(reinterpret_cast<intptr_t>(self));
}

}  // namespace

extern "C" {

void ofl_register(ofl::SelfFn callback, ofl::SelfFn draw,
                  ofl::HandleFn handle, ofl::SelfFn deleted,
                  ofl::SelfFn timeout) {
  ofl::on_callback = callback;
  ofl::on_draw = draw;
  ofl::on_handle = handle;
  ofl::on_deleted = deleted;
  on_timeout = timeout;
}

// Widgets

intptr_t ofl_group_new(int32_t x, int32_t y, int32_t w, int32_t h,
                       intptr_t self) {
  return ofl::open(new ofl::W<Fl_Group>(x, y, w, h), self);
}

// A window placed by the window manager unless placed is 1.
intptr_t ofl_window_new(int32_t placed, int32_t x, int32_t y, int32_t w,
                        int32_t h, intptr_t self) {
  if (placed) return ofl::open(new ofl::W<Fl_Window>(x, y, w, h), self);
  return ofl::open(new ofl::W<Fl_Window>(w, h), self);
}

intptr_t ofl_double_window_new(int32_t placed, int32_t x, int32_t y,
                               int32_t w, int32_t h, intptr_t self) {
  if (placed) return ofl::open(new ofl::W<Fl_Double_Window>(x, y, w, h), self);
  return ofl::open(new ofl::W<Fl_Double_Window>(w, h), self);
}

intptr_t ofl_box_new(int32_t x, int32_t y, int32_t w, int32_t h,
                     intptr_t self) {
  return ofl::open(new ofl::W<Fl_Box>(x, y, w, h), self);
}

// Deleted now, unless an Oberon dispatch is running (ofltk.h).
void ofl_widget_delete(intptr_t w) {
  if (ofl::depth > 0) {
    Fl::delete_widget(ofl::widget(w));
  } else {
    delete ofl::widget(w);
  }
}

void ofl_widget_show(intptr_t w) { ofl::widget(w)->show(); }
void ofl_widget_hide(intptr_t w) { ofl::widget(w)->hide(); }
void ofl_widget_redraw(intptr_t w) { ofl::widget(w)->redraw(); }
void ofl_widget_do_callback(intptr_t w) { ofl::widget(w)->do_callback(); }

int32_t ofl_widget_visible(intptr_t w) {
  return ofl::widget(w)->visible() ? 1 : 0;
}

// What FLTK does with no callback of the program's: queue the widget
// for Fl::readqueue, or for a window, Fl::atclose, which hides it.
void ofl_widget_default_callback(intptr_t w) {
  Fl_Widget::default_callback(ofl::widget(w), 0);
}

void ofl_window_default_callback(intptr_t w) {
  Fl_Window::default_callback(ofl::as<Fl_Window>(w), 0);
}

void ofl_widget_base_draw(intptr_t w) {
  dynamic_cast<ofl::Hooks *>(ofl::widget(w))->base_draw();
}

int32_t ofl_widget_base_handle(intptr_t w, int32_t event) {
  return dynamic_cast<ofl::Hooks *>(ofl::widget(w))->base_handle(event);
}

void ofl_widget_copy_label(intptr_t w, const char *label) {
  ofl::widget(w)->copy_label(label);
}

// The label, a const char *, or 0 for none.
intptr_t ofl_widget_label(intptr_t w) {
  return reinterpret_cast<intptr_t>(ofl::widget(w)->label());
}

int32_t ofl_widget_x(intptr_t w) { return ofl::widget(w)->x(); }
int32_t ofl_widget_y(intptr_t w) { return ofl::widget(w)->y(); }
int32_t ofl_widget_w(intptr_t w) { return ofl::widget(w)->w(); }
int32_t ofl_widget_h(intptr_t w) { return ofl::widget(w)->h(); }

void ofl_widget_resize(intptr_t w, int32_t x, int32_t y, int32_t width,
                       int32_t height) {
  ofl::widget(w)->resize(x, y, width, height);
}

void ofl_group_begin(intptr_t g) { ofl::as<Fl_Group>(g)->begin(); }
void ofl_group_end(intptr_t g) { ofl::as<Fl_Group>(g)->end(); }

int32_t ofl_group_children(intptr_t g) {
  return ofl::as<Fl_Group>(g)->children();
}

// The Oberon object of child i, or 0 if ofltk didn't open it (FLTK makes
// some children itself, such as a scroll group's scrollbars).
intptr_t ofl_group_child(intptr_t g, int32_t i) {
  Fl_Widget *c = ofl::as<Fl_Group>(g)->child(i);
  if (c->callback() != ofl::callback_trampoline) return 0;
  return ofl::self_of(c);
}

// The event loop

int32_t ofl_run(void) { return Fl::run(); }
int32_t ofl_check(void) { return Fl::check(); }
void ofl_wait(double seconds) { Fl::wait(seconds); }

void ofl_add_timeout(double seconds, intptr_t self) {
  Fl::add_timeout(seconds, timeout_trampoline, reinterpret_cast<void *>(self));
}

void ofl_repeat_timeout(double seconds, intptr_t self) {
  Fl::repeat_timeout(seconds, timeout_trampoline,
                     reinterpret_cast<void *>(self));
}

void ofl_remove_timeout(intptr_t self) {
  Fl::remove_timeout(timeout_trampoline, reinterpret_cast<void *>(self));
}

}  // extern "C"
