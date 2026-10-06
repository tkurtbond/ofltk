// ofltk.h: what the C++ part of every ofltk module shares (PLAN.md,
// "Object model" and "Lifetime and the collector").
//
// A module's C++ part makes each widget as ofl::W<its FLTK class> and
// hands it to ofl::open with its Oberon object's address. From then on
// FLTK's draw(), handle(), resize() and callback reach the Oberon object's
// Draw, Handle, Resize and Callback, and FLTK tells Fl when the widget is
// destroyed.
// The Oberon side sees only extern "C" functions taking and returning
// int32_t, intptr_t and double; a widget is its Fl_Widget * as an
// intptr_t.

#ifndef OFLTK_H
#define OFLTK_H

#include <FL/Fl.H>
#include <FL/Fl_Widget.H>
#include <stdint.h>

namespace ofl {

typedef void (*SelfFn)(intptr_t self);
typedef int32_t (*HandleFn)(intptr_t self, int32_t event);
typedef void (*ResizeFn)(intptr_t self, int32_t x, int32_t y, int32_t w,
                         int32_t h);

// The Oberon dispatchers, which Fl's body registers (ofl_register in
// Fl.cpp): each recovers the object from self and calls its method.
extern SelfFn on_callback, on_draw, on_deleted;
extern HandleFn on_handle;
extern ResizeFn on_resize;

// How many Oberon dispatches are running. A widget deleted inside one is
// deleted later, by Fl::delete_widget, since FLTK may still be using it.
extern int depth;

struct Dispatch {
  Dispatch() { ++depth; }
  ~Dispatch() { --depth; }
};

// A widget's user data: its Oberon object's address. Opened with
// AUTO_DELETE_USER_DATA, so FLTK deletes it when the widget is destroyed:
// explicitly, with its parent, or by Fl::delete_widget (confirmed for all
// three, PLAN.md Phase 0), and the destructor tells Fl. FLTK also deletes
// the old user data when it is replaced, which would unregister a live
// widget, so open sets it once and nothing sets it again.
class Ref : public Fl_Callback_User_Data {
public:
  explicit Ref(intptr_t s) : self(s) {}
  ~Ref() {
    Dispatch d;
    on_deleted(self);
  }
  const intptr_t self;
};

// Every opened widget's FLTK callback, defined in Fl.cpp; also how
// Fl.cpp tells an ofltk widget from one FLTK made itself.
void callback_trampoline(Fl_Widget *w, void *data);

inline intptr_t self_of(Fl_Widget *w) {
  return static_cast<Ref *>(w->user_data())->self;
}

// The Oberon object of w, or 0 if w is 0 or a widget ofltk didn't open
// (FLTK makes some itself, such as a scroll group's scrollbars).
inline intptr_t object_of(Fl_Widget *w) {
  if (w == 0 || w->callback() != callback_trampoline) return 0;
  return self_of(w);
}

// The FLTK class's own draw(), handle() and resize(), for the Oberon
// Draw, Handle and Resize defaults to call (FLTKAda's fl_box_draw, for
// every class); and Fl_Widget's protected drawing of the box, label and
// focus box, for an Oberon Draw.
class Hooks {
public:
  virtual ~Hooks() {}
  virtual void base_draw() = 0;
  virtual int base_handle(int event) = 0;
  virtual void base_resize(int x, int y, int w, int h) = 0;
  virtual void hook_draw_box() = 0;
  virtual void hook_draw_label() = 0;
  virtual void hook_draw_focus() = 0;
};

// FLTK class B, with draw(), handle() and resize() sent to the Oberon
// object. Until open has set the user data there is no object, and B's
// own run.
template <class B> class W : public B, public Hooks {
public:
  using B::B;
  void draw() override {
    if (this->user_data()) {
      Dispatch d;
      on_draw(self_of(this));
    } else {
      B::draw();
    }
  }
  int handle(int event) override {
    if (this->user_data()) {
      Dispatch d;
      return on_handle(self_of(this), event);
    }
    return B::handle(event);
  }
  void resize(int x, int y, int w, int h) override {
    if (this->user_data()) {
      Dispatch d;
      on_resize(self_of(this), x, y, w, h);
    } else {
      B::resize(x, y, w, h);
    }
  }
  void base_draw() override { B::draw(); }
  int base_handle(int event) override { return B::handle(event); }
  void base_resize(int x, int y, int w, int h) override {
    B::resize(x, y, w, h);
  }
  void hook_draw_box() override { this->draw_box(); }
  void hook_draw_label() override { this->draw_label(); }
  void hook_draw_focus() override { this->draw_focus(); }
};

// Makes w, just made, the widget of the Oberon object at self.
template <class T> intptr_t open(T *w, intptr_t self) {
  w->callback(callback_trampoline, new Ref(self), true);
  return reinterpret_cast<intptr_t>(static_cast<Fl_Widget *>(w));
}

// s into buf, an Oberon ARRAY OF CHAR of n characters, truncated to fit;
// "" if s is 0.
inline void copy_out(const char *s, char *buf, int32_t n) {
  int32_t i = 0;
  if (s) {
    for (; i < n - 1 && s[i]; i++) buf[i] = s[i];
  }
  buf[i] = 0;
}

inline Fl_Widget *widget(intptr_t h) {
  return reinterpret_cast<Fl_Widget *>(h);
}

template <class T> T *as(intptr_t h) { return static_cast<T *>(widget(h)); }

}  // namespace ofl

#endif
