// The C++ part of FlInputs: the text input and output classes. See
// ofltk.h for the conventions.

#include "ofltk.h"

#include <FL/Fl_Float_Input.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Int_Input.H>
#include <FL/Fl_Multiline_Input.H>
#include <FL/Fl_Multiline_Output.H>
#include <FL/Fl_Output.H>
#include <FL/Fl_Secret_Input.H>

namespace {

template <class T>
intptr_t make(int32_t x, int32_t y, int32_t w, int32_t h, const char *label,
              intptr_t self) {
  ofl::W<T> *i = new ofl::W<T>(x, y, w, h);
  i->copy_label(ofl::label_text(label));
  return ofl::open(i, self);
}

Fl_Input_ *input(intptr_t i) { return ofl::as<Fl_Input_>(i); }

}  // namespace

extern "C" {

// kind is 0 Fl_Input, 1 Fl_Int_Input, and so on, as FlInputs numbers them.
intptr_t ofl_input_new(int32_t kind, int32_t x, int32_t y, int32_t w,
                       int32_t h, const char *label, intptr_t self) {
  switch (kind) {
    case 1: return make<Fl_Int_Input>(x, y, w, h, label, self);
    case 2: return make<Fl_Float_Input>(x, y, w, h, label, self);
    case 3: return make<Fl_Multiline_Input>(x, y, w, h, label, self);
    case 4: return make<Fl_Secret_Input>(x, y, w, h, label, self);
    case 5: return make<Fl_Output>(x, y, w, h, label, self);
    case 6: return make<Fl_Multiline_Output>(x, y, w, h, label, self);
    default: return make<Fl_Input>(x, y, w, h, label, self);
  }
}

// The text, into buf of n characters, truncated (ofl::copy_out).
void ofl_input_value(intptr_t i, char *buf, int32_t n) {
  ofl::copy_out(input(i)->value(), buf, n);
}

// Copied by FLTK (Fl_Input_::value calls put_in_buffer).
void ofl_input_set_value(intptr_t i, const char *s) { input(i)->value(s); }

int32_t ofl_input_ivalue(intptr_t i) { return input(i)->ivalue(); }
double ofl_input_dvalue(intptr_t i) { return input(i)->dvalue(); }
void ofl_input_set_ivalue(intptr_t i, int32_t v) { input(i)->value(static_cast<int>(v)); }
void ofl_input_set_dvalue(intptr_t i, double v) { input(i)->value(v); }

// The text's length in bytes.
int32_t ofl_input_size(intptr_t i) { return input(i)->size(); }

int32_t ofl_input_maximum_size(intptr_t i) { return input(i)->maximum_size(); }

void ofl_input_set_maximum_size(intptr_t i, int32_t m) {
  input(i)->maximum_size(m);
}

int32_t ofl_input_insert_position(intptr_t i) {
  return input(i)->insert_position();
}

int32_t ofl_input_mark(intptr_t i) { return input(i)->mark(); }

void ofl_input_set_position(intptr_t i, int32_t p, int32_t m) {
  input(i)->insert_position(p, m);
}

// The edits return 0 if nothing changed, or a maximum_size stopped them.
int32_t ofl_input_replace(intptr_t i, int32_t b, int32_t e, const char *s) {
  return input(i)->replace(b, e, s);
}

int32_t ofl_input_cut(intptr_t i) { return input(i)->cut(); }

int32_t ofl_input_cut_range(intptr_t i, int32_t a, int32_t b) {
  return input(i)->cut(a, b);
}

int32_t ofl_input_insert(intptr_t i, const char *s) {
  return input(i)->insert(s);
}

int32_t ofl_input_undo(intptr_t i) { return input(i)->undo(); }
int32_t ofl_input_redo(intptr_t i) { return input(i)->redo(); }

int32_t ofl_input_readonly(intptr_t i) { return input(i)->readonly(); }

void ofl_input_set_readonly(intptr_t i, int32_t r) {
  input(i)->readonly(r);
}

int32_t ofl_input_wrap(intptr_t i) { return input(i)->wrap(); }
void ofl_input_set_wrap(intptr_t i, int32_t w) { input(i)->wrap(w); }

int32_t ofl_input_tab_nav(intptr_t i) { return input(i)->tab_nav(); }
void ofl_input_set_tab_nav(intptr_t i, int32_t t) { input(i)->tab_nav(t); }

int32_t ofl_input_shortcut(intptr_t i) { return input(i)->shortcut(); }
void ofl_input_set_shortcut(intptr_t i, int32_t s) { input(i)->shortcut(s); }

int32_t ofl_input_textfont(intptr_t i) { return input(i)->textfont(); }
void ofl_input_set_textfont(intptr_t i, int32_t f) { input(i)->textfont(f); }
int32_t ofl_input_textsize(intptr_t i) { return input(i)->textsize(); }
void ofl_input_set_textsize(intptr_t i, int32_t s) { input(i)->textsize(s); }

int32_t ofl_input_textcolor(intptr_t i) {
  return static_cast<int32_t>(input(i)->textcolor());
}

void ofl_input_set_textcolor(intptr_t i, int32_t c) {
  input(i)->textcolor(static_cast<Fl_Color>(c));
}

int32_t ofl_input_cursor_color(intptr_t i) {
  return static_cast<int32_t>(input(i)->cursor_color());
}

void ofl_input_set_cursor_color(intptr_t i, int32_t c) {
  input(i)->cursor_color(static_cast<Fl_Color>(c));
}

}  // extern "C"
