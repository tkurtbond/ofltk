// The C++ part of Fl, ofltk's core module: widgets, groups, windows,
// boxes, timeouts and the event loop. See ofltk.h for the conventions.

#include "ofltk.h"

#include <FL/Fl_Box.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Window.H>
#include <FL/platform.H>

namespace ofl {

SelfFn on_callback, on_draw, on_deleted;
HandleFn on_handle;
ResizeFn on_resize;
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
                  ofl::HandleFn handle, ofl::ResizeFn resize,
                  ofl::SelfFn deleted, ofl::SelfFn timeout) {
  ofl::on_callback = callback;
  ofl::on_draw = draw;
  ofl::on_handle = handle;
  ofl::on_resize = resize;
  ofl::on_deleted = deleted;
  on_timeout = timeout;
  // The box and label types FLTK's headers name by macros that define
  // them on first use (FL_ROUND_UP_BOX is fl_define_FL_ROUND_UP_BOX()).
  // Fl's constants are their plain values, so every one is defined here.
  fl_define_FL_ROUND_UP_BOX();
  fl_define_FL_SHADOW_BOX();
  fl_define_FL_ROUNDED_BOX();
  fl_define_FL_RFLAT_BOX();
  fl_define_FL_RSHADOW_BOX();
  fl_define_FL_DIAMOND_BOX();
  fl_define_FL_OVAL_BOX();
  fl_define_FL_PLASTIC_UP_BOX();
  fl_define_FL_GTK_UP_BOX();
  fl_define_FL_GLEAM_UP_BOX();
  fl_define_FL_OXY_UP_BOX();
  fl_define_FL_SHADOW_LABEL();
  fl_define_FL_ENGRAVED_LABEL();
  fl_define_FL_EMBOSSED_LABEL();
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

// Fl_Window::copy_label also sets a shown window's title, but it hides
// Fl_Widget's rather than overriding it, so a window must be called as one.
void ofl_widget_copy_label(intptr_t w, const char *label) {
  Fl_Window *win = ofl::widget(w)->as_window();
  if (win) {
    win->copy_label(label);
  } else {
    ofl::widget(w)->copy_label(label);
  }
}

// The label, a const char *, or 0 for none.
intptr_t ofl_widget_label(intptr_t w) {
  return reinterpret_cast<intptr_t>(ofl::widget(w)->label());
}

int32_t ofl_widget_x(intptr_t w) { return ofl::widget(w)->x(); }
int32_t ofl_widget_y(intptr_t w) { return ofl::widget(w)->y(); }
int32_t ofl_widget_w(intptr_t w) { return ofl::widget(w)->w(); }
int32_t ofl_widget_h(intptr_t w) { return ofl::widget(w)->h(); }

// FLTK's own resize(), not the virtual one, which reaches Oberon's
// Resize: this is that method's default.
void ofl_widget_base_resize(intptr_t w, int32_t x, int32_t y, int32_t width,
                            int32_t height) {
  dynamic_cast<ofl::Hooks *>(ofl::widget(w))->base_resize(x, y, width, height);
}

void ofl_widget_draw_box(intptr_t w) {
  dynamic_cast<ofl::Hooks *>(ofl::widget(w))->hook_draw_box();
}

void ofl_widget_draw_label(intptr_t w) {
  dynamic_cast<ofl::Hooks *>(ofl::widget(w))->hook_draw_label();
}

void ofl_widget_draw_focus(intptr_t w) {
  dynamic_cast<ofl::Hooks *>(ofl::widget(w))->hook_draw_focus();
}

int32_t ofl_widget_changed(intptr_t w) {
  return ofl::widget(w)->changed() ? 1 : 0;
}

void ofl_widget_set_changed(intptr_t w, int32_t c) {
  if (c) {
    ofl::widget(w)->set_changed();
  } else {
    ofl::widget(w)->clear_changed();
  }
}

int32_t ofl_widget_damage(intptr_t w) { return ofl::widget(w)->damage(); }

void ofl_widget_set_damage(intptr_t w, int32_t d) {
  ofl::widget(w)->damage(static_cast<uchar>(d));
}

void ofl_widget_clear_damage(intptr_t w) { ofl::widget(w)->clear_damage(); }

// The display is opened first: under Wayland, FLTK 1.4.5 crashes when a
// text input takes the focus before it is open (doc/fltk-issues.md).
// fl_open_display does nothing if it is open already.
int32_t ofl_widget_take_focus(intptr_t w) {
  fl_open_display();
  return ofl::widget(w)->take_focus();
}

int32_t ofl_widget_visible_focus(intptr_t w) {
  return ofl::widget(w)->visible_focus() ? 1 : 0;
}

void ofl_widget_set_visible_focus(intptr_t w, int32_t v) {
  ofl::widget(w)->visible_focus(v);
}

// 1 if the event's position is inside w.
int32_t ofl_widget_event_inside(intptr_t w) {
  return Fl::event_inside(ofl::widget(w));
}

void ofl_widget_position(intptr_t w, int32_t x, int32_t y) {
  ofl::widget(w)->position(x, y);
}

void ofl_widget_size(intptr_t w, int32_t width, int32_t height) {
  ofl::widget(w)->size(width, height);
}

// The parent's Oberon object, or 0 (ofl::object_of).
intptr_t ofl_widget_parent(intptr_t w) {
  return ofl::object_of(ofl::widget(w)->parent());
}

int32_t ofl_widget_visible_r(intptr_t w) {
  return ofl::widget(w)->visible_r() ? 1 : 0;
}

void ofl_widget_activate(intptr_t w) { ofl::widget(w)->activate(); }
void ofl_widget_deactivate(intptr_t w) { ofl::widget(w)->deactivate(); }

int32_t ofl_widget_active(intptr_t w) {
  return ofl::widget(w)->active() ? 1 : 0;
}

int32_t ofl_widget_active_r(intptr_t w) {
  return ofl::widget(w)->active_r() ? 1 : 0;
}

// An Fl_Color is unsigned; it crosses as its bits, an int32_t.
int32_t ofl_widget_color(intptr_t w) {
  return static_cast<int32_t>(ofl::widget(w)->color());
}

void ofl_widget_set_color(intptr_t w, int32_t c) {
  ofl::widget(w)->color(static_cast<Fl_Color>(c));
}

int32_t ofl_widget_selection_color(intptr_t w) {
  return static_cast<int32_t>(ofl::widget(w)->selection_color());
}

void ofl_widget_set_selection_color(intptr_t w, int32_t c) {
  ofl::widget(w)->selection_color(static_cast<Fl_Color>(c));
}

int32_t ofl_widget_box(intptr_t w) { return ofl::widget(w)->box(); }

void ofl_widget_set_box(intptr_t w, int32_t b) {
  ofl::widget(w)->box(static_cast<Fl_Boxtype>(b));
}

int32_t ofl_widget_labelfont(intptr_t w) {
  return ofl::widget(w)->labelfont();
}

void ofl_widget_set_labelfont(intptr_t w, int32_t f) {
  ofl::widget(w)->labelfont(f);
}

int32_t ofl_widget_labelsize(intptr_t w) {
  return ofl::widget(w)->labelsize();
}

void ofl_widget_set_labelsize(intptr_t w, int32_t s) {
  ofl::widget(w)->labelsize(s);
}

int32_t ofl_widget_labelcolor(intptr_t w) {
  return static_cast<int32_t>(ofl::widget(w)->labelcolor());
}

void ofl_widget_set_labelcolor(intptr_t w, int32_t c) {
  ofl::widget(w)->labelcolor(static_cast<Fl_Color>(c));
}

int32_t ofl_widget_labeltype(intptr_t w) {
  return ofl::widget(w)->labeltype();
}

void ofl_widget_set_labeltype(intptr_t w, int32_t t) {
  ofl::widget(w)->labeltype(static_cast<Fl_Labeltype>(t));
}

int32_t ofl_widget_align(intptr_t w) {
  return static_cast<int32_t>(ofl::widget(w)->align());
}

void ofl_widget_set_align(intptr_t w, int32_t a) {
  ofl::widget(w)->align(static_cast<Fl_Align>(a));
}

int32_t ofl_widget_when(intptr_t w) { return ofl::widget(w)->when(); }

void ofl_widget_set_when(intptr_t w, int32_t when) {
  ofl::widget(w)->when(static_cast<uchar>(when));
}

void ofl_widget_copy_tooltip(intptr_t w, const char *text) {
  ofl::widget(w)->copy_tooltip(text);
}

// The tooltip, a const char *, or 0 for none.
intptr_t ofl_widget_tooltip(intptr_t w) {
  return reinterpret_cast<intptr_t>(ofl::widget(w)->tooltip());
}

// Windows

int32_t ofl_window_shown(intptr_t w) {
  return ofl::as<Fl_Window>(w)->shown() ? 1 : 0;
}

void ofl_window_size_range(intptr_t w, int32_t minw, int32_t minh,
                           int32_t maxw, int32_t maxh) {
  ofl::as<Fl_Window>(w)->size_range(minw, minh, maxw, maxh);
}

void ofl_window_set_modal(intptr_t w) { ofl::as<Fl_Window>(w)->set_modal(); }

void ofl_window_set_non_modal(intptr_t w) {
  ofl::as<Fl_Window>(w)->set_non_modal();
}

int32_t ofl_window_modal(intptr_t w) {
  return ofl::as<Fl_Window>(w)->modal() ? 1 : 0;
}

void ofl_window_fullscreen(intptr_t w) { ofl::as<Fl_Window>(w)->fullscreen(); }

void ofl_window_fullscreen_off(intptr_t w) {
  ofl::as<Fl_Window>(w)->fullscreen_off();
}

int32_t ofl_window_fullscreen_active(intptr_t w) {
  return ofl::as<Fl_Window>(w)->fullscreen_active() ? 1 : 0;
}

void ofl_window_cursor(intptr_t w, int32_t c) {
  ofl::as<Fl_Window>(w)->cursor(static_cast<Fl_Cursor>(c));
}

// Colors, fonts and schemes

void ofl_set_color(int32_t i, int32_t c) {
  Fl::set_color(static_cast<Fl_Color>(i), static_cast<Fl_Color>(c));
}

void ofl_get_rgb(int32_t c, int32_t *r, int32_t *g, int32_t *b) {
  uchar cr, cg, cb;
  Fl::get_color(static_cast<Fl_Color>(c), cr, cg, cb);
  *r = cr;
  *g = cg;
  *b = cb;
}

void ofl_background(int32_t r, int32_t g, int32_t b) {
  Fl::background(static_cast<uchar>(r), static_cast<uchar>(g), static_cast<uchar>(b));
}

void ofl_background2(int32_t r, int32_t g, int32_t b) {
  Fl::background2(static_cast<uchar>(r), static_cast<uchar>(g), static_cast<uchar>(b));
}

void ofl_foreground(int32_t r, int32_t g, int32_t b) {
  Fl::foreground(static_cast<uchar>(r), static_cast<uchar>(g), static_cast<uchar>(b));
}

int32_t ofl_color_average(int32_t c1, int32_t c2, double weight) {
  return static_cast<int32_t>(fl_color_average(
      static_cast<Fl_Color>(c1), static_cast<Fl_Color>(c2), static_cast<float>(weight)));
}

int32_t ofl_contrast(int32_t fg, int32_t bg) {
  return static_cast<int32_t>(
      fl_contrast(static_cast<Fl_Color>(fg), static_cast<Fl_Color>(bg)));
}

int32_t ofl_inactive(int32_t c) {
  return static_cast<int32_t>(fl_inactive(static_cast<Fl_Color>(c)));
}

int32_t ofl_normal_size(void) { return FL_NORMAL_SIZE; }
void ofl_set_normal_size(int32_t s) { FL_NORMAL_SIZE = s; }

// name is "none", "base", "plastic", "gtk+", "gleam" or "oxy"; 1 if FLTK
// knows it.
int32_t ofl_set_scheme(const char *name) { return Fl::scheme(name); }

// The scheme's name, a const char *, or 0 for none.
intptr_t ofl_scheme(void) { return reinterpret_cast<intptr_t>(Fl::scheme()); }

void ofl_group_begin(intptr_t g) { ofl::as<Fl_Group>(g)->begin(); }
void ofl_group_end(intptr_t g) { ofl::as<Fl_Group>(g)->end(); }

int32_t ofl_group_children(intptr_t g) {
  return ofl::as<Fl_Group>(g)->children();
}

// The Oberon object of child i, or 0 (ofl::object_of).
intptr_t ofl_group_child(intptr_t g, int32_t i) {
  return ofl::object_of(ofl::as<Fl_Group>(g)->child(i));
}

void ofl_group_add(intptr_t g, intptr_t w) {
  ofl::as<Fl_Group>(g)->add(ofl::widget(w));
}

void ofl_group_insert(intptr_t g, intptr_t w, int32_t i) {
  ofl::as<Fl_Group>(g)->insert(*ofl::widget(w), i);
}

void ofl_group_remove(intptr_t g, intptr_t w) {
  ofl::as<Fl_Group>(g)->remove(ofl::widget(w));
}

// The index of w among g's children, or children() if it isn't one.
int32_t ofl_group_find(intptr_t g, intptr_t w) {
  return ofl::as<Fl_Group>(g)->find(ofl::widget(w));
}

// Deletes every child, later inside a dispatch, as ofl_widget_delete does.
void ofl_group_clear(intptr_t g) {
  Fl_Group *group = ofl::as<Fl_Group>(g);
  if (ofl::depth > 0) {
    for (int i = 0; i < group->children(); i++) {
      Fl::delete_widget(group->child(i));
    }
  } else {
    group->clear();
  }
}

// w is 0 for none.
void ofl_group_set_resizable(intptr_t g, intptr_t w) {
  ofl::as<Fl_Group>(g)->resizable(ofl::widget(w));
}

intptr_t ofl_group_resizable(intptr_t g) {
  return ofl::object_of(ofl::as<Fl_Group>(g)->resizable());
}

// Events: the one being handled (Fl::event_x and friends), and the
// widgets that have the focus, the mouse, and the button held.

int32_t ofl_event(void) { return Fl::event(); }
int32_t ofl_event_x(void) { return Fl::event_x(); }
int32_t ofl_event_y(void) { return Fl::event_y(); }
int32_t ofl_event_x_root(void) { return Fl::event_x_root(); }
int32_t ofl_event_y_root(void) { return Fl::event_y_root(); }
int32_t ofl_event_dx(void) { return Fl::event_dx(); }
int32_t ofl_event_dy(void) { return Fl::event_dy(); }
int32_t ofl_event_button(void) { return Fl::event_button(); }
int32_t ofl_event_clicks(void) { return Fl::event_clicks(); }
void ofl_set_event_clicks(int32_t n) { Fl::event_clicks(n); }
int32_t ofl_event_is_click(void) { return Fl::event_is_click(); }
void ofl_event_is_click_off(void) { Fl::event_is_click(0); }
int32_t ofl_event_key(void) { return Fl::event_key(); }
int32_t ofl_event_original_key(void) { return Fl::event_original_key(); }
int32_t ofl_event_key_down(int32_t k) { return Fl::event_key(k); }
int32_t ofl_get_key(int32_t k) { return Fl::get_key(k); }
int32_t ofl_event_state(void) { return Fl::event_state(); }

// The text of a key or paste event, a const char * (never 0), of
// ofl_event_length() bytes.
intptr_t ofl_event_text(void) {
  return reinterpret_cast<intptr_t>(Fl::event_text());
}

int32_t ofl_event_length(void) { return Fl::event_length(); }

int32_t ofl_event_inside(int32_t x, int32_t y, int32_t w, int32_t h) {
  return Fl::event_inside(x, y, w, h);
}

// Each the Oberon object, or 0 (ofl::object_of).
intptr_t ofl_focus(void) { return ofl::object_of(Fl::focus()); }
intptr_t ofl_belowmouse(void) { return ofl::object_of(Fl::belowmouse()); }
intptr_t ofl_pushed(void) { return ofl::object_of(Fl::pushed()); }

// w is 0 for none. The display is opened first, as for take_focus.
void ofl_set_focus(intptr_t w) {
  fl_open_display();
  Fl::focus(ofl::widget(w));
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
