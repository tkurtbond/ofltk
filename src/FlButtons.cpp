// The C++ part of FlButtons: the button classes. See ofltk.h for the
// conventions.

#include "ofltk.h"

#include <FL/Fl_Button.H>
#include <FL/Fl_Check_Button.H>
#include <FL/Fl_Light_Button.H>
#include <FL/Fl_Radio_Button.H>
#include <FL/Fl_Radio_Light_Button.H>
#include <FL/Fl_Radio_Round_Button.H>
#include <FL/Fl_Repeat_Button.H>
#include <FL/Fl_Return_Button.H>
#include <FL/Fl_Round_Button.H>
#include <FL/Fl_Toggle_Button.H>

namespace {

// A new widget of class T, opened for self, with a copy of label.
template <class T>
intptr_t make(int32_t x, int32_t y, int32_t w, int32_t h, const char *label,
              intptr_t self) {
  ofl::W<T> *b = new ofl::W<T>(x, y, w, h);
  b->copy_label(label);
  return ofl::open(b, self);
}

Fl_Button *button(intptr_t b) { return ofl::as<Fl_Button>(b); }

}  // namespace

extern "C" {

// Each class's own: kind is 0 Fl_Button, 1 Fl_Check_Button, and so on,
// as FlButtons numbers them.
intptr_t ofl_button_new(int32_t kind, int32_t x, int32_t y, int32_t w,
                        int32_t h, const char *label, intptr_t self) {
  switch (kind) {
    case 1: return make<Fl_Check_Button>(x, y, w, h, label, self);
    case 2: return make<Fl_Light_Button>(x, y, w, h, label, self);
    case 3: return make<Fl_Round_Button>(x, y, w, h, label, self);
    case 4: return make<Fl_Radio_Button>(x, y, w, h, label, self);
    case 5: return make<Fl_Radio_Light_Button>(x, y, w, h, label, self);
    case 6: return make<Fl_Radio_Round_Button>(x, y, w, h, label, self);
    case 7: return make<Fl_Return_Button>(x, y, w, h, label, self);
    case 8: return make<Fl_Repeat_Button>(x, y, w, h, label, self);
    case 9: return make<Fl_Toggle_Button>(x, y, w, h, label, self);
    default: return make<Fl_Button>(x, y, w, h, label, self);
  }
}

int32_t ofl_button_value(intptr_t b) { return button(b)->value(); }

// 1 if the value changed.
int32_t ofl_button_set_value(intptr_t b, int32_t v) {
  return button(b)->value(v);
}

void ofl_button_setonly(intptr_t b) { button(b)->setonly(); }

int32_t ofl_button_type(intptr_t b) { return button(b)->type(); }

void ofl_button_set_type(intptr_t b, int32_t t) {
  button(b)->type(static_cast<uchar>(t));
}

// A key, plus FLTK's event state bits; 0 for none.
int32_t ofl_button_shortcut(intptr_t b) { return button(b)->shortcut(); }

void ofl_button_set_shortcut(intptr_t b, int32_t s) {
  button(b)->shortcut(s);
}

int32_t ofl_button_down_box(intptr_t b) { return button(b)->down_box(); }

void ofl_button_set_down_box(intptr_t b, int32_t t) {
  button(b)->down_box(static_cast<Fl_Boxtype>(t));
}

}  // extern "C"
