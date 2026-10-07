// The C++ part of Fl, pofltk's core module: widgets, groups, windows,
// boxes, timeouts and the event loop. See pofltk.h for the conventions.

#include "pofltk.h"

#include <FL/Fl_Box.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Flex.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Pack.H>
#include <FL/Fl_Table.H>
#include <FL/Fl_Window.H>
#include <FL/filename.H>
#include <FL/platform.H>
#include <string.h>

#include <vector>

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

// Idle callbacks and watched file descriptors: the data is the Oberon
// Idle's or FdWatch's address, which Fl keeps reachable while FLTK has it.
ofl::SelfFn on_idle, on_fd;

void idle_trampoline(void *self) {
  ofl::Dispatch d;
  on_idle(reinterpret_cast<intptr_t>(self));
}

void fd_trampoline(FL_SOCKET, void *self) {
  ofl::Dispatch d;
  on_fd(reinterpret_cast<intptr_t>(self));
}

// The event dispatch: Fl's, given each event and its window's Oberon
// object (0 for a window FLTK made, or none), with the window kept for
// ofl_handle_default. A dispatch, so a widget deleted in it is deleted
// later, not under Fl::handle_.
int32_t (*on_dispatch)(int32_t, intptr_t);
Fl_Window *dispatch_window;

int dispatch_trampoline(int event, Fl_Window *w) {
  ofl::Dispatch d;
  Fl_Window *outer = dispatch_window;
  dispatch_window = w;
  int r = on_dispatch(event, ofl::object_of(w));
  dispatch_window = outer;
  return r;
}

// The text an event is given (ofl_set_event_text): FLTK keeps the
// pointer until the next event.
std::vector<char> event_text;

}  // namespace

extern "C" {

void ofl_register_loop(ofl::SelfFn idle, ofl::SelfFn fd,
                       int32_t (*dispatch)(int32_t, intptr_t)) {
  on_idle = idle;
  on_fd = fd;
  on_dispatch = dispatch;
}

void ofl_add_idle(intptr_t self) {
  Fl::add_idle(idle_trampoline, reinterpret_cast<void *>(self));
}

void ofl_remove_idle(intptr_t self) {
  Fl::remove_idle(idle_trampoline, reinterpret_cast<void *>(self));
}

void ofl_add_fd(int32_t fd, int32_t when, intptr_t self) {
  Fl::add_fd(fd, when, fd_trampoline, reinterpret_cast<void *>(self));
}

void ofl_remove_fd(int32_t fd, int32_t when) { Fl::remove_fd(fd, when); }

void ofl_event_dispatch(int32_t on) {
  Fl::event_dispatch(on ? dispatch_trampoline : 0);
}

// FLTK's own handling of the dispatch's event, for its window.
int32_t ofl_handle_default(int32_t event) {
  return Fl::handle_(event, dispatch_window);
}

void ofl_set_event_key(int32_t key) { Fl::e_keysym = key; }

void ofl_set_event_text(const char *s) {
  size_t n = strlen(s);
  event_text.assign(s, s + n + 1);
  Fl::e_text = event_text.data();
  Fl::e_length = static_cast<int>(n);
}

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

// Deleted now, unless an Oberon dispatch is running (pofltk.h).
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
// Text replaces a multi-label (FlImages), which the widget then lets go;
// copy_label keeps the label type, so it is set back to text first
// (doc/fltk-issues.md, 55).
void ofl_widget_copy_label(intptr_t w, const char *label) {
  Fl_Widget *wd = ofl::widget(w);
  bool was_multi = wd->labeltype() == _FL_MULTI_LABEL;
  if (was_multi) wd->label(FL_NORMAL_LABEL, 0);
  Fl_Window *win = wd->as_window();
  if (win) {
    win->copy_label(ofl::label_text(label));
  } else {
    wd->copy_label(ofl::label_text(label));
  }
  if (was_multi) ofl::ref_of(wd)->hold(ofl::Ref::label, 0);
}

// The label, a const char *, or 0 for none: a multi-label, an image or an
// icon label isn't text.
intptr_t ofl_widget_label(intptr_t w) {
  Fl_Widget *wd = ofl::widget(w);
  if (wd->labeltype() >= _FL_MULTI_LABEL && wd->labeltype() <= _FL_IMAGE_LABEL) {
    return 0;
  }
  return reinterpret_cast<intptr_t>(wd->label());
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

// A multi-label's parts have their own types, so a widget showing one
// keeps it. FlImages sets the types that make the label something else.
void ofl_widget_set_labeltype(intptr_t w, int32_t t) {
  if (ofl::widget(w)->labeltype() == _FL_MULTI_LABEL) return;
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

void ofl_window_wait_for_expose(intptr_t w) {
  ofl::as<Fl_Window>(w)->wait_for_expose();
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

// The box type b's border: what 0 dx, 1 dy, 2 dw, 3 dh. b is checked by
// the caller, since FLTK indexes its table of box types with it.
int32_t ofl_box_d(int32_t b, int32_t what) {
  Fl_Boxtype t = static_cast<Fl_Boxtype>(b);
  switch (what) {
    case 0: return Fl::box_dx(t);
    case 1: return Fl::box_dy(t);
    case 2: return Fl::box_dw(t);
    default: return Fl::box_dh(t);
  }
}

// name is "none", "base", "plastic", "gtk+", "gleam" or "oxy"; 1 if FLTK
// knows it.
// Screens. what: 0 x, 1 y, 2 w, 3 h of the main screen's work area.
int32_t ofl_screen(int32_t what) {
  switch (what) {
    case 1: return Fl::y();
    case 2: return Fl::w();
    case 3: return Fl::h();
    default: return Fl::x();
  }
}

int32_t ofl_screen_count() { return Fl::screen_count(); }

int32_t ofl_scrollbar_size() { return Fl::scrollbar_size(); }

void ofl_set_scrollbar_size(int32_t n) { Fl::scrollbar_size(n); }

// Screen n's place and size, or its work area if work is 1.
void ofl_screen_xywh(int32_t n, int32_t work, int32_t *x, int32_t *y,
                     int32_t *w, int32_t *h) {
  int X, Y, W, H;
  if (work) {
    Fl::screen_work_area(X, Y, W, H, n);
  } else {
    Fl::screen_xywh(X, Y, W, H, n);
  }
  *x = X;
  *y = Y;
  *w = W;
  *h = H;
}

int32_t ofl_screen_num(int32_t x, int32_t y) { return Fl::screen_num(x, y); }

// Command-line options. FLTK keeps pointers into argv (the title, the
// geometry, the class name) until a window is shown with them, and C's
// own argv, which poc's Args.argv is, lasts the program's life.

namespace {
int32_t (*arg_handler)(int32_t);

// FLTK's Fl_Args_Handler, giving the program's handler the argument's
// number; the handler's result, checked by Fl.Mod, is the words it used.
int handle_arg(int, char **, int &i) {
  int n = arg_handler(i);
  i += n;
  return n;
}

char **argv_of(intptr_t argv) { return reinterpret_cast<char **>(argv); }
}  // namespace

// Fl::args with handler (0 for none), *i the first argument not parsed:
// 1 unless that is an option no one knows, or lacks its value. Fl::args
// says so by returning 0, but only until it has once stopped at a word
// that isn't an option (doc/fltk-issues.md, 57), so this decides it from
// the word, as Fl::arg does.
int32_t ofl_args(int32_t argc, intptr_t argv, int32_t *i,
                 int32_t (*handler)(int32_t)) {
  arg_handler = handler;
  int n = 1;
  Fl::args(argc, argv_of(argv), n, handler ? handle_arg : 0);
  *i = n;
  const char *s = n < argc ? argv_of(argv)[n] : 0;
  return !(s && s[0] == '-' && s[1] != 0 && s[1] != '-');
}

int32_t ofl_arg(int32_t argc, intptr_t argv, int32_t i) {
  int n = i;
  return Fl::arg(argc, argv_of(argv), n);
}

intptr_t ofl_args_help() { return reinterpret_cast<intptr_t>(Fl::help); }

void ofl_window_show_args(intptr_t w, int32_t argc, intptr_t argv) {
  ofl::as<Fl_Window>(w)->show(argc, argv_of(argv));
}

// 1 if a program was started to open uri; msg, n bytes, gets its command,
// or why not.
int32_t ofl_open_uri(const char *uri, char *msg, int32_t n) {
  if (n > 0) msg[0] = 0;
  return fl_open_uri(uri, msg, n) != 0;
}

int32_t ofl_set_scheme(const char *name) { return Fl::scheme(name); }

// The scheme's name, a const char *, or 0 for none.
intptr_t ofl_scheme(void) { return reinterpret_cast<intptr_t>(Fl::scheme()); }

// A table's children are its cells' widgets, in an inner Fl_Scroll;
// Fl_Table's begin(), end(), children() and the rest reach them, but
// hide Fl_Group's rather than overriding them, so a table must be called
// as one (doc/fltk-issues.md, 52). Fl_Group's own would reach the
// table's scrollbars and the inner group.
static Fl_Table *table(intptr_t g) {
  return dynamic_cast<Fl_Table *>(ofl::widget(g));
}

void ofl_group_begin(intptr_t g) {
  if (Fl_Table *t = table(g)) {
    t->begin();
  } else {
    ofl::as<Fl_Group>(g)->begin();
  }
}

// Fl_Flex::end also asks for a layout, and Fl_Table::end shows the inner
// group if it has children, but each hides Fl_Group's rather than
// overriding it, so each must be called as itself.
void ofl_group_end(intptr_t g) {
  Fl_Flex *flex = dynamic_cast<Fl_Flex *>(ofl::widget(g));
  if (flex) {
    flex->end();
  } else if (Fl_Table *t = table(g)) {
    t->end();
  } else {
    ofl::as<Fl_Group>(g)->end();
  }
}

int32_t ofl_group_children(intptr_t g) {
  if (Fl_Table *t = table(g)) return t->children();
  return ofl::as<Fl_Group>(g)->children();
}

static Fl_Widget *child(intptr_t g, int i) {
  if (Fl_Table *t = table(g)) return t->child(i);
  return ofl::as<Fl_Group>(g)->child(i);
}

// The Oberon object of child i, or 0 (ofl::object_of).
intptr_t ofl_group_child(intptr_t g, int32_t i) {
  return ofl::object_of(child(g, i));
}

void ofl_group_add(intptr_t g, intptr_t w) {
  if (Fl_Table *t = table(g)) {
    t->add(ofl::widget(w));
  } else {
    ofl::as<Fl_Group>(g)->add(ofl::widget(w));
  }
}

void ofl_group_insert(intptr_t g, intptr_t w, int32_t i) {
  if (Fl_Table *t = table(g)) {
    t->insert(*ofl::widget(w), i);
  } else {
    ofl::as<Fl_Group>(g)->insert(*ofl::widget(w), i);
  }
}

void ofl_group_remove(intptr_t g, intptr_t w) {
  if (Fl_Table *t = table(g)) {
    t->remove(*ofl::widget(w));
  } else {
    ofl::as<Fl_Group>(g)->remove(ofl::widget(w));
  }
}

// The index of w among g's children, or children() if it isn't one.
int32_t ofl_group_find(intptr_t g, intptr_t w) {
  if (Fl_Table *t = table(g)) return t->find(ofl::widget(w));
  return ofl::as<Fl_Group>(g)->find(ofl::widget(w));
}

// Deletes every child pofltk opened, later inside a dispatch, as
// ofl_widget_delete does. Not Fl_Group::clear: some groups' children
// are FLTK's own members, not on the heap (a scroll's scrollbars, a
// spinner's field and buttons), which it would delete. Fl_Scroll::clear
// and Fl_Pack::clear allow for that, but hide Fl_Group's rather than
// overriding it. A pack's resizable goes back to none, as
// Fl_Pack::clear leaves it. A table keeps its rows and columns.
void ofl_group_clear(intptr_t g) {
  for (int i = ofl_group_children(g); i-- > 0;) {
    Fl_Widget *c = child(g, i);
    if (ofl::object_of(c) == 0) continue;
    if (ofl::depth > 0) {
      Fl::delete_widget(c);
    } else {
      delete c;
    }
  }
  Fl_Group *group = ofl::as<Fl_Group>(g);
  if (dynamic_cast<Fl_Pack *>(group)) group->resizable(0);
}

// Forgets the sizes g saved of itself and its children, so that the next
// resize starts from where they are now. Fl_Table::init_sizes reaches
// its inner group, but hides Fl_Group's.
void ofl_group_init_sizes(intptr_t g) {
  if (Fl_Table *t = table(g)) {
    t->init_sizes();
  } else {
    ofl::as<Fl_Group>(g)->init_sizes();
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

// The clipboard and drag and drop. destination and source: 0 the
// selection buffer, 1 the clipboard, 2 (copy) both.

// Each opens the display first: FLTK 1.4.5's X11 driver uses it without
// opening it, and crashes when no window has yet been shown
// (doc/fltk-issues.md, 49).

// Fl::copy copies the n bytes at text.
void ofl_copy(const char *text, int32_t n, int32_t destination) {
  fl_open_display();
  Fl::copy(text, n, destination, Fl::clipboard_plain_text);
}

// FLTK's own record of the sources the program owns, in both drivers.
// It is in no header, but exported.
extern char fl_i_own_selection[2];

// image: 0 text, 1 an image. Under X11, another program's data is asked
// for through Fl::first_window. With no window shown, FLTK asks with
// window 0 anyway, and the X server's BadWindow error is printed, so
// pofltk doesn't ask: the paste does nothing, as it would have.
void ofl_paste(intptr_t receiver, int32_t source, int32_t image) {
  fl_open_display();
  if (!fl_wl_display() && !Fl::first_window() &&
      !fl_i_own_selection[source ? 1 : 0])
    return;
  Fl::paste(*ofl::widget(receiver), source,
            image ? Fl::clipboard_image : Fl::clipboard_plain_text);
}

int32_t ofl_clipboard_contains(int32_t image) {
  fl_open_display();
  return Fl::clipboard_contains(image ? Fl::clipboard_image
                                      : Fl::clipboard_plain_text);
}

// 1 if the EvPaste being handled carries an image (Fl::event_clipboard).
int32_t ofl_event_is_image(void) {
  return Fl::event_clipboard_type() == Fl::clipboard_image &&
         Fl::event_clipboard() != 0;
}

int32_t ofl_dnd(void) { return Fl::dnd(); }

// what: 0 get, 1 set off, 2 set on.
int32_t ofl_dnd_text_ops(int32_t what) {
  if (what) Fl::dnd_text_ops(what == 2);
  return Fl::dnd_text_ops();
}

// Fl::option: what 0 get, 1 set off, 2 set on. FLTK reads the saved
// options first, so one set here stays set.
int32_t ofl_option(int32_t o, int32_t what) {
  Fl::Fl_Option opt = static_cast<Fl::Fl_Option>(o);
  if (what) Fl::option(opt, what == 2);
  return Fl::option(opt);
}

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
