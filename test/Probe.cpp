// The C++ part of Probe: what the tests need of FLTK that ofltk doesn't
// give programs. Capturing a widget's drawing as pixels, and sending
// events as if from the user (PLAN.md, "Build and test").

#include <FL/Fl.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_RGB_Image.H>
#include <FL/Fl_Widget.H>
#include <FL/Fl_Window.H>
#include <FL/fl_draw.H>
#include <stdint.h>
#include <string.h>

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

}  // extern "C"
