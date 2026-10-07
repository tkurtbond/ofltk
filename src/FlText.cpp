// The C++ part of FlText: text buffers, displays and editors. See pofltk.h
// for the conventions.
//
// A buffer belongs to Oberon until its TextBuffer is closed, and to the
// displays showing it, as their text or their styles; it is deleted when
// none of them holds it. FLTK's ~Fl_Text_Display still uses its buffer, and
// ~Fl_Text_Buffer doesn't detach its displays (doc/fltk-issues.md, 34), so
// a display's hold is released only after the display is destroyed: by
// Holds, a base class destroyed after Fl_Text_Display.

#include "pofltk.h"

#include <FL/Fl_Text_Buffer.H>
#include <FL/Fl_Text_Display.H>
#include <FL/Fl_Text_Editor.H>
#include <stdlib.h>
#include <string.h>

namespace {

typedef void (*ModifiedFn)(intptr_t self, int32_t pos, int32_t inserted,
                           int32_t deleted, int32_t restyled);
ModifiedFn on_modified;

class Buffer : public Fl_Text_Buffer {
public:
  explicit Buffer(intptr_t self) : self_(self), users_(0) {
    add_modify_callback(modified, this);
  }
  // Oberon closes it: deleted now, or by the last display to let it go.
  void close() {
    self_ = 0;
    if (users_ == 0) delete this;
  }
  void hold() { ++users_; }
  void release() {
    if (--users_ == 0 && self_ == 0) delete this;
  }
  intptr_t self() const { return self_; }

private:
  // Every change, to the Oberon TextBuffer's Modified, while it is open.
  static void modified(int pos, int inserted, int deleted, int restyled,
                       const char *, void *arg) {
    Buffer *b = static_cast<Buffer *>(arg);
    if (b->self_ != 0 && on_modified != 0) {
      ofl::Dispatch d;
      on_modified(b->self_, pos, inserted, deleted, restyled);
    }
  }
  intptr_t self_;  // the Oberon TextBuffer, 0 once closed
  int users_;      // displays holding it
};

Buffer *buffer(intptr_t b) { return reinterpret_cast<Buffer *>(b); }

void release(Buffer *b) {
  if (b) b->release();
}

// What a display holds: its buffer, its style buffer, and its style table,
// which Fl_Text_Display::highlight_data keeps the pointer to.
class Holds {
public:
  Holds() : text(0), style(0), styles(0), nstyles(0), capacity(0) {}
  virtual ~Holds() {
    release(text);
    release(style);
    free(styles);
  }
  Buffer *text, *style;
  Fl_Text_Display::Style_Table_Entry *styles;
  int nstyles, capacity;
};

// Holds first, so it is destroyed after the display.
template <class B> class D : public Holds, public ofl::W<B> {
public:
  using ofl::W<B>::W;
};

template <class T>
intptr_t make(int32_t x, int32_t y, int32_t w, int32_t h, const char *label,
              intptr_t self) {
  D<T> *d = new D<T>(x, y, w, h);
  d->copy_label(ofl::label_text(label));
  return ofl::open(d, self);
}

Fl_Text_Display *display(intptr_t d) { return ofl::as<Fl_Text_Display>(d); }
Holds *holds(intptr_t d) { return dynamic_cast<Holds *>(ofl::widget(d)); }

// The style table to FLTK, if there is a style buffer and a style: with
// none, FLTK would read the entry before the table (doc/fltk-issues.md,
// 35).
void set_highlight(intptr_t d) {
  Holds *h = holds(d);
  if (h->style && h->nstyles > 0) {
    display(d)->highlight_data(h->style, h->styles, h->nstyles, 'A', 0, 0);
  } else {
    display(d)->highlight_data(0, 0, 0, 'A', 0, 0);
  }
  display(d)->redraw();
}

// FLTK's malloc'd text into buf, an Oberon ARRAY OF CHAR of n, and freed.
void give(char *s, char *buf, int32_t n) {
  ofl::copy_out(s, buf, n);
  free(s);
}

}  // namespace

extern "C" {

void ofl_text_register(ModifiedFn modified) { on_modified = modified; }

// Buffers

intptr_t ofl_buffer_new(intptr_t self) {
  return reinterpret_cast<intptr_t>(new Buffer(self));
}

void ofl_buffer_close(intptr_t b) { buffer(b)->close(); }

int32_t ofl_buffer_length(intptr_t b) { return buffer(b)->length(); }

void ofl_buffer_set_text(intptr_t b, const char *s) { buffer(b)->text(s); }

void ofl_buffer_text(intptr_t b, char *buf, int32_t n) {
  give(buffer(b)->text(), buf, n);
}

void ofl_buffer_text_range(intptr_t b, int32_t start, int32_t end, char *buf,
                           int32_t n) {
  give(buffer(b)->text_range(start, end), buf, n);
}

int32_t ofl_buffer_char_at(intptr_t b, int32_t pos) {
  return static_cast<int32_t>(buffer(b)->char_at(pos));
}

int32_t ofl_buffer_byte_at(intptr_t b, int32_t pos) {
  return static_cast<unsigned char>(buffer(b)->byte_at(pos));
}

void ofl_buffer_insert(intptr_t b, int32_t pos, const char *s) {
  buffer(b)->insert(pos, s);
}

void ofl_buffer_remove(intptr_t b, int32_t start, int32_t end) {
  buffer(b)->remove(start, end);
}

void ofl_buffer_replace(intptr_t b, int32_t start, int32_t end,
                        const char *s) {
  buffer(b)->replace(start, end, s);
}

// 1 and the cursor position the change leaves in *pos, if there was one.
int32_t ofl_buffer_undo(intptr_t b, int32_t redo, int32_t *pos) {
  int p = 0;
  int r = redo ? buffer(b)->redo(&p) : buffer(b)->undo(&p);
  *pos = p;
  return r != 0;
}

int32_t ofl_buffer_can_undo(intptr_t b, int32_t redo) {
  return redo ? buffer(b)->can_redo() : buffer(b)->can_undo();
}

void ofl_buffer_set_can_undo(intptr_t b, int32_t on) {
  buffer(b)->canUndo(static_cast<char>(on));
}

// 0 or an errno. what: 0 load, 1 append, 2 insert at pos, 3 save, 4 save
// start to end.
int32_t ofl_buffer_file(intptr_t b, int32_t what, const char *name,
                        int32_t pos, int32_t end) {
  switch (what) {
    case 1: return buffer(b)->appendfile(name);
    case 2: return buffer(b)->insertfile(name, pos);
    case 3: return buffer(b)->savefile(name);
    case 4: return buffer(b)->outputfile(name, pos, end);
    default: return buffer(b)->loadfile(name);
  }
}

int32_t ofl_buffer_tab_distance(intptr_t b) {
  return buffer(b)->tab_distance();
}

void ofl_buffer_set_tab_distance(intptr_t b, int32_t n) {
  buffer(b)->tab_distance(n);
}

void ofl_buffer_select(intptr_t b, int32_t start, int32_t end) {
  buffer(b)->select(start, end);
}

void ofl_buffer_unselect(intptr_t b) { buffer(b)->unselect(); }

int32_t ofl_buffer_selection(intptr_t b, int32_t *start, int32_t *end) {
  int s = 0, e = 0;
  int r = buffer(b)->selection_position(&s, &e);
  *start = s;
  *end = e;
  return r != 0;
}

void ofl_buffer_selection_text(intptr_t b, char *buf, int32_t n) {
  give(buffer(b)->selection_text(), buf, n);
}

void ofl_buffer_remove_selection(intptr_t b) {
  buffer(b)->remove_selection();
}

void ofl_buffer_replace_selection(intptr_t b, const char *s) {
  buffer(b)->replace_selection(s);
}

// what: 0 line_start, 1 line_end, 2 word_start, 3 word_end, 4 next_char,
// 5 prev_char, 6 utf8_align.
int32_t ofl_buffer_pos(intptr_t b, int32_t what, int32_t pos) {
  Buffer *buf = buffer(b);
  switch (what) {
    case 1: return buf->line_end(pos);
    case 2: return buf->word_start(pos);
    case 3: return buf->word_end(pos);
    case 4: return buf->next_char(pos);
    case 5: return buf->prev_char(pos);
    case 6: return buf->utf8_align(pos);
    default: return buf->line_start(pos);
  }
}

void ofl_buffer_line_text(intptr_t b, int32_t pos, char *buf, int32_t n) {
  give(buffer(b)->line_text(pos), buf, n);
}

int32_t ofl_buffer_count_lines(intptr_t b, int32_t start, int32_t end) {
  return buffer(b)->count_lines(start, end);
}

int32_t ofl_buffer_skip_lines(intptr_t b, int32_t start, int32_t n) {
  return buffer(b)->skip_lines(start, n);
}

int32_t ofl_buffer_rewind_lines(intptr_t b, int32_t start, int32_t n) {
  return buffer(b)->rewind_lines(start, n);
}

// 1 and the position in *found if s is found from start. FLTK's search
// matching case reads past the end of the text (doc/fltk-issues.md, 36),
// so that one is done here, a byte at a time with byte_at, which checks
// its position. A UTF-8 string matches only at the start of a character,
// so this finds what FLTK's would. Without matching case FLTK reads
// through char_at, which checks too.
int32_t ofl_buffer_search(intptr_t b, int32_t backward, int32_t start,
                          const char *s, int32_t *found, int32_t match_case) {
  Buffer *buf = buffer(b);
  if (!match_case) {
    int f = 0;
    int r = backward ? buf->search_backward(start, s, &f, 0)
                     : buf->search_forward(start, s, &f, 0);
    *found = f;
    return r != 0;
  }
  int n = static_cast<int>(strlen(s)), len = buf->length();
  int last = len - n;  // the last position s fits at
  int p = start < 0 ? 0 : start;
  if (backward && p > last) p = last;
  for (; p >= 0 && p <= last; p += backward ? -1 : 1) {
    int i = 0;
    while (i < n && buf->byte_at(p + i) == s[i]) ++i;
    if (i == n) {
      *found = p;
      return 1;
    }
  }
  return 0;
}

// Displays and editors

// kind is 0 Fl_Text_Display, 1 Fl_Text_Editor.
intptr_t ofl_text_new(int32_t kind, int32_t x, int32_t y, int32_t w,
                      int32_t h, const char *label, intptr_t self) {
  if (kind == 1) return make<Fl_Text_Editor>(x, y, w, h, label, self);
  return make<Fl_Text_Display>(x, y, w, h, label, self);
}

// b may be 0, for none.
void ofl_text_set_buffer(intptr_t d, intptr_t b) {
  Holds *h = holds(d);
  Buffer *old = h->text;
  if (buffer(b) == old) return;
  if (b) buffer(b)->hold();
  display(d)->buffer(buffer(b));
  h->text = buffer(b);
  release(old);
}

void ofl_text_set_style_buffer(intptr_t d, intptr_t b) {
  Holds *h = holds(d);
  Buffer *old = h->style;
  if (buffer(b) == old) return;
  if (b) buffer(b)->hold();
  h->style = buffer(b);
  set_highlight(d);
  release(old);
}

// Adds a style, 'A' + its index in the table, and returns the index.
int32_t ofl_text_add_style(intptr_t d, int32_t color, int32_t font,
                           int32_t size, int32_t attr, int32_t bgcolor) {
  Holds *h = holds(d);
  if (h->nstyles == h->capacity) {
    int capacity = h->capacity ? 2 * h->capacity : 8;
    void *p = realloc(h->styles, capacity * sizeof *h->styles);
    if (p == 0) return -1;
    h->styles = static_cast<Fl_Text_Display::Style_Table_Entry *>(p);
    h->capacity = capacity;
  }
  Fl_Text_Display::Style_Table_Entry &e = h->styles[h->nstyles];
  e.color = static_cast<Fl_Color>(color);
  e.font = font;
  e.size = size;
  e.attr = static_cast<unsigned>(attr);
  e.bgcolor = static_cast<Fl_Color>(bgcolor);
  ++h->nstyles;
  set_highlight(d);
  return h->nstyles - 1;
}

void ofl_text_clear_styles(intptr_t d) {
  holds(d)->nstyles = 0;
  set_highlight(d);
}

int32_t ofl_text_insert_position(intptr_t d) {
  return display(d)->insert_position();
}

void ofl_text_set_insert_position(intptr_t d, int32_t pos) {
  display(d)->insert_position(pos);
}

void ofl_text_show_insert_position(intptr_t d) {
  display(d)->show_insert_position();
}

// Typed at the cursor, as the user would: over the selection if any.
void ofl_text_insert(intptr_t d, const char *s, int32_t overstrike) {
  if (overstrike) {
    display(d)->overstrike(s);
  } else {
    display(d)->insert(s);
  }
}

// what: 0 right, 1 left, 2 up, 3 down, 4 next word, 5 previous word. 1
// if the cursor moved (always, for the words).
int32_t ofl_text_move(intptr_t d, int32_t what) {
  Fl_Text_Display *t = display(d);
  switch (what) {
    case 1: return t->move_left();
    case 2: return t->move_up();
    case 3: return t->move_down();
    case 4: t->next_word(); return 1;
    case 5: t->previous_word(); return 1;
    default: return t->move_right();
  }
}

void ofl_text_scroll(intptr_t d, int32_t line, int32_t offset) {
  display(d)->scroll(line, offset);
}

// 1 and the position's x, y if it is shown.
int32_t ofl_text_position_to_xy(intptr_t d, int32_t pos, int32_t *x,
                                int32_t *y) {
  int X = 0, Y = 0;
  int r = display(d)->position_to_xy(pos, &X, &Y);
  *x = X;
  *y = Y;
  return r != 0;
}

int32_t ofl_text_in_selection(intptr_t d, int32_t x, int32_t y) {
  return display(d)->in_selection(x, y) != 0;
}

// Lines as shown, wrapped. what: 0 line_start, 1 line_end (from a line's
// start if wrapped), 2 count_lines to end, 3 skip_lines n, 4 rewind_lines
// n.
int32_t ofl_text_line(intptr_t d, int32_t what, int32_t pos, int32_t n) {
  Fl_Text_Display *t = display(d);
  switch (what) {
    case 1: return t->line_end(pos, n != 0);
    case 2: return t->count_lines(pos, n, false);
    case 3: return t->skip_lines(pos, n, false);
    case 4: return t->rewind_lines(pos, n);
    default: return t->line_start(pos);
  }
}

void ofl_text_wrap_mode(intptr_t d, int32_t mode, int32_t margin) {
  display(d)->wrap_mode(mode, margin);
}

void ofl_text_show_cursor(intptr_t d, int32_t on) {
  display(d)->show_cursor(on);
}

// what: 0 text font, 1 text size, 2 text color, 3 cursor style, 4 cursor
// color, 5 line number width, 6 line number font, 7 line number size, 8
// line number fg color, 9 line number bg color, 10 scrollbar size, 11
// shortcut, 12 insert mode (editors), 13 tab navigation (editors).
int32_t ofl_text_get(intptr_t d, int32_t what) {
  Fl_Text_Display *t = display(d);
  Fl_Text_Editor *e = dynamic_cast<Fl_Text_Editor *>(t);
  switch (what) {
    case 1: return t->textsize();
    case 2: return static_cast<int32_t>(t->textcolor());
    case 3: return t->cursor_style();
    case 4: return static_cast<int32_t>(t->cursor_color());
    case 5: return t->linenumber_width();
    case 6: return t->linenumber_font();
    case 7: return t->linenumber_size();
    case 8: return static_cast<int32_t>(t->linenumber_fgcolor());
    case 9: return static_cast<int32_t>(t->linenumber_bgcolor());
    case 10: return t->scrollbar_size();
    case 11: return t->shortcut();
    case 12: return e ? e->insert_mode() : 0;
    case 13: return e ? e->tab_nav() : 0;
    default: return t->textfont();
  }
}

void ofl_text_set(intptr_t d, int32_t what, int32_t v) {
  Fl_Text_Display *t = display(d);
  Fl_Text_Editor *e = dynamic_cast<Fl_Text_Editor *>(t);
  switch (what) {
    case 1: t->textsize(v); break;
    case 2: t->textcolor(static_cast<Fl_Color>(v)); break;
    case 3: t->cursor_style(v); break;
    case 4: t->cursor_color(static_cast<Fl_Color>(v)); break;
    case 5: t->linenumber_width(v); break;
    case 6: t->linenumber_font(v); break;
    case 7: t->linenumber_size(v); break;
    case 8: t->linenumber_fgcolor(static_cast<Fl_Color>(v)); break;
    case 9: t->linenumber_bgcolor(static_cast<Fl_Color>(v)); break;
    case 10: t->scrollbar_size(v); break;
    case 11: t->shortcut(v); break;
    case 12: if (e) e->insert_mode(v); break;
    case 13: if (e) e->tab_nav(v); break;
    default: t->textfont(v);
  }
  t->redraw();
}

}  // extern "C"
