// The C++ part of Probe: what the tests need of FLTK that pofltk doesn't
// give programs. Capturing a widget's drawing as pixels, and sending
// events as if from the user (PLAN.md, "Build and test").

#include "../src/pofltk.h"

#include <FL/Fl.H>
#include <FL/platform.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_RGB_Image.H>
#include <FL/Fl_Widget.H>
#include <FL/Fl_Window.H>
#include <FL/fl_draw.H>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

namespace {

Fl_RGB_Image *shot;  // the last capture, or 0
char text[64];       // the text of the last key event sent

Fl_Widget *widget(intptr_t h) { return reinterpret_cast<Fl_Widget *>(h); }

// FLTK's handling of event, sent to win, as from the window system.
int32_t send(intptr_t win, int32_t event) {
  return Fl::handle(event, widget(win)->as_window());
}

}  // namespace

extern "C" {


// Draws w as FLTK would in its window, on white, into an image of w's
// size, for ofltest_pixel. The window need not be shown.
// How many resources w keeps beside its label images (ofl::Ref::keep).
int32_t ofltest_kept(intptr_t w) {
  return static_cast<int32_t>(ofl::ref_of(widget(w))->kept_count());
}

int32_t ofltest_capture(intptr_t w) {
  Fl_Widget *wd = widget(w);
  delete shot;
  Fl_Image_Surface surface(wd->w(), wd->h());
  Fl_Surface_Device::push_current(&surface);
  fl_color(FL_WHITE);
  fl_rectf(0, 0, wd->w(), wd->h());
  surface.draw(wd, 0, 0);
  shot = surface.image();
  Fl_Surface_Device::pop_current();
  return shot != 0 && shot->w() == wd->w() && shot->h() == wd->h();
}

// The pixel x, y of the capture, relative to the widget's top left, as
// 0xRRGGBB; -1 outside it.
int32_t ofltest_pixel(int32_t x, int32_t y) {
  if (shot == 0 || x < 0 || y < 0 || x >= shot->w() || y >= shot->h()) {
    return -1;
  }
  int ld = shot->ld() ? shot->ld() : shot->w() * shot->d();
  const uchar *p =
      reinterpret_cast<const uchar *>(shot->data()[0]) + y * ld + x * shot->d();
  if (shot->d() < 3) return p[0] << 16 | p[0] << 8 | p[0];
  return p[0] << 16 | p[1] << 8 | p[2];
}

void ofltest_release(void) {
  delete shot;
  shot = 0;
}

// A mouse event at x, y in win's coordinates: button is 1 to 3 for
// FL_PUSH and FL_RELEASE, state FLTK's event state bits.
int32_t ofltest_mouse(intptr_t win, int32_t event, int32_t x, int32_t y,
                      int32_t button, int32_t state, int32_t clicks) {
  Fl_Widget *w = widget(win);
  Fl::e_x = x;
  Fl::e_y = y;
  Fl::e_x_root = w->x() + x;
  Fl::e_y_root = w->y() + y;
  Fl::e_keysym = FL_Button + button;
  Fl::e_state = state;
  Fl::e_clicks = clicks;
  Fl::e_is_click = 1;
  return send(win, event);
}

// A mouse wheel turned dx across and dy down, the mouse at x, y.
int32_t ofltest_wheel(intptr_t win, int32_t x, int32_t y, int32_t dx,
                      int32_t dy) {
  Fl_Widget *w = widget(win);
  Fl::e_x = x;
  Fl::e_y = y;
  Fl::e_x_root = w->x() + x;
  Fl::e_y_root = w->y() + y;
  Fl::e_dx = dx;
  Fl::e_dy = dy;
  return send(win, FL_MOUSEWHEEL);
}

// A key event (FL_KEYDOWN or FL_KEYUP) of key, typing s, sent to the
// focus widget, as FLTK sends it first. Not by Fl::handle: FLTK 1.4.5
// then offers a key the focus doesn't use as a shortcut, which crashes in
// a window never shown.
int32_t ofltest_key(int32_t event, int32_t key, int32_t state,
                    const char *s) {
  Fl_Widget *focus = Fl::focus();
  if (focus == 0) return 0;
  char *old_text = Fl::e_text;
  int old_length = Fl::e_length;
  strncpy(text, s, sizeof text - 1);
  Fl::e_keysym = Fl::e_original_keysym = key;
  Fl::e_state = state;
  Fl::e_text = text;
  Fl::e_length = static_cast<int>(strlen(text));
  Fl::e_number = event;
  int32_t r = focus->handle(event);
  Fl::e_text = old_text;
  Fl::e_length = old_length;
  return r;
}

// A key, typing s, offered to win and its widgets as a shortcut (as
// FLTK offers a key the focus doesn't use): FL_SHORTCUT sent to win's
// handle(), which an Fl_Group passes to each child.
int32_t ofltest_shortcut(intptr_t win, int32_t key, int32_t state,
                         const char *s) {
  char *old_text = Fl::e_text;
  int old_length = Fl::e_length;
  strncpy(text, s, sizeof text - 1);
  Fl::e_keysym = Fl::e_original_keysym = key;
  Fl::e_state = state;
  Fl::e_text = text;
  Fl::e_length = static_cast<int>(strlen(text));
  Fl::e_number = FL_SHORTCUT;
  int32_t r = widget(win)->handle(FL_SHORTCUT);
  Fl::e_text = old_text;
  Fl::e_length = old_length;
  return r;
}

// A key event (FL_KEYDOWN or FL_SHORTCUT) of key, typing s, sent by
// Fl::handle to win, as from the window system: to the grab (a pop-up
// menu) if there is one, else for a shortcut to win's widgets and then
// the event handlers (a global menu). Never send a key no widget uses
// while the mouse is over a widget of a window never shown
// (doc/fltk-issues.md, 3).
int32_t ofltest_handle_key(intptr_t win, int32_t event, int32_t key,
                           int32_t state, const char *s) {
  char *old_text = Fl::e_text;
  int old_length = Fl::e_length;
  strncpy(text, s, sizeof text - 1);
  Fl::e_keysym = Fl::e_original_keysym = key;
  Fl::e_state = state;
  Fl::e_text = text;
  Fl::e_length = static_cast<int>(strlen(text));
  int32_t r = send(win, event);
  Fl::e_text = old_text;
  Fl::e_length = old_length;
  return r;
}

// A key, typing s, sent by Fl::handle to the modal window (a dialog) as
// from the window system, so to its focus widget first; 0 if no modal
// window is shown.
int32_t ofltest_modal_key(int32_t key, int32_t state, const char *s) {
  Fl_Window *modal = Fl::modal();
  if (modal == 0) return 0;
  return ofltest_handle_key(reinterpret_cast<intptr_t>(modal), FL_KEYDOWN,
                            key, state, s);
}

// 1 if a modal window (a dialog) is shown, with its title in buf; 0 if
// none is.
int32_t ofltest_modal(char *buf, int32_t n) {
  Fl_Window *modal = Fl::modal();
  buf[0] = 0;
  if (modal == 0 || !modal->shown()) return 0;
  const char *t = modal->label() ? modal->label() : "";
  int32_t i = 0;
  for (; i < n - 1 && t[i]; i++) buf[i] = t[i];
  buf[i] = 0;
  return 1;
}

// 1 if FLTK draws with Wayland, 0 with X11; opens the display. An FLTK
// built without Wayland has no fl_wl_display.
int32_t ofltest_wayland(void) {
  fl_open_display();
#if defined(FLTK_USE_WAYLAND)
  return fl_wl_display() != 0;
#else
  return 0;
#endif
}

// A pipe, for FdWatch: its read and write ends in fds[0] and fds[1]; 1
// if it was made.
int32_t ofltest_pipe(int32_t *fds) {
  int p[2];
  if (pipe(p) != 0) return 0;
  fds[0] = p[0];
  fds[1] = p[1];
  return 1;
}

// Writes s to fd; the bytes written, or -1.
int32_t ofltest_write(int32_t fd, const char *s) {
  return static_cast<int32_t>(write(fd, s, strlen(s)));
}

// Reads up to n - 1 bytes from fd into buf, ended with 0X; the bytes
// read, or -1.
int32_t ofltest_read(int32_t fd, char *buf, int32_t n) {
  ssize_t r = read(fd, buf, n - 1);
  buf[r > 0 ? r : 0] = 0;
  return static_cast<int32_t>(r);
}

void ofltest_close(int32_t fd) { close(fd); }

}  // extern "C"
