// The C++ part of FlTable: Fl_Table and Fl_Table_Row, their cells drawn
// by the Oberon object's DrawCell. See ofltk.h for the conventions.
//
// A table is a group: the widgets in its cells are children of an inner
// group, which Fl.cpp's group functions reach by calling the table as an
// Fl_Table (doc/fltk-issues.md, 52).

#include "ofltk.h"

#include <FL/Fl_Table.H>
#include <FL/Fl_Table_Row.H>

namespace {

typedef void (*DrawCellFn)(intptr_t self, int32_t context, int32_t r,
                           int32_t c, int32_t x, int32_t y, int32_t w,
                           int32_t h);

// The Oberon dispatcher, which FlTable's body registers.
DrawCellFn on_draw_cell;

// Table class B, with draw_cell() sent to the Oberon object as well.
// Fl_Table's own draw_cell() draws nothing.
template <class B> class T : public ofl::W<B> {
public:
  T(int x, int y, int w, int h) : ofl::W<B>(x, y, w, h) {}
  void draw_cell(Fl_Table::TableContext context, int r, int c, int x, int y,
                 int w, int h) override {
    if (this->user_data()) {
      ofl::Dispatch d;
      on_draw_cell(ofl::self_of(this), context, r, c, x, y, w, h);
    }
  }
};

Fl_Table *table(intptr_t t) { return ofl::as<Fl_Table>(t); }
Fl_Table_Row *row_table(intptr_t t) { return ofl::as<Fl_Table_Row>(t); }

}  // namespace

extern "C" {

void ofl_table_register(DrawCellFn draw_cell) { on_draw_cell = draw_cell; }

// kind: 0 Fl_Table, 1 Fl_Table_Row. Like every table, it leaves itself
// the current group, for the widgets of its cells.
intptr_t ofl_table_new(int32_t kind, int32_t x, int32_t y, int32_t w,
                       int32_t h, const char *label, intptr_t self) {
  Fl_Table *t;
  if (kind == 1) {
    t = new T<Fl_Table_Row>(x, y, w, h);
  } else {
    t = new T<Fl_Table>(x, y, w, h);
  }
  t->copy_label(ofl::label_text(label));
  return ofl::open(t, self);
}

// The table's numbers, by what: 0 rows, 1 cols, 2 row header shown, 3
// column header shown, 4 row header width, 5 column header height, 6
// row header color, 7 column header color, 8 row resizing allowed, 9
// column resizing allowed, 10 least row height in a resize, 11 least
// column width, 12 row position, 13 column position, 14 table box, 15
// scrollbar size, 16 callback row, 17 callback column, 18 callback
// context, 19 being resized by the user, 20 (Fl_Table_Row) selection
// mode.
int32_t ofl_table_get(intptr_t t, int32_t what) {
  Fl_Table *tb = table(t);
  switch (what) {
    case 0: return tb->rows();
    case 1: return tb->cols();
    case 2: return tb->row_header();
    case 3: return tb->col_header();
    case 4: return tb->row_header_width();
    case 5: return tb->col_header_height();
    case 6: return static_cast<int32_t>(tb->row_header_color());
    case 7: return static_cast<int32_t>(tb->col_header_color());
    case 8: return tb->row_resize();
    case 9: return tb->col_resize();
    case 10: return tb->row_resize_min();
    case 11: return tb->col_resize_min();
    case 12: return tb->row_position();
    case 13: return tb->col_position();
    case 14: return tb->table_box();
    case 15: return tb->scrollbar_size();
    case 16: return tb->callback_row();
    case 17: return tb->callback_col();
    case 18: return tb->callback_context();
    case 19: return tb->is_interactive_resize();
    default: return row_table(t)->type();
  }
}

// The same numbers, set: 0 to 15, and 20.
void ofl_table_set(intptr_t t, int32_t what, int32_t v) {
  Fl_Table *tb = table(t);
  switch (what) {
    case 0: tb->rows(v); break;
    case 1: tb->cols(v); break;
    case 2: tb->row_header(v); break;
    case 3: tb->col_header(v); break;
    case 4: tb->row_header_width(v); break;
    case 5: tb->col_header_height(v); break;
    case 6: tb->row_header_color(static_cast<Fl_Color>(v)); break;
    case 7: tb->col_header_color(static_cast<Fl_Color>(v)); break;
    case 8: tb->row_resize(v); break;
    case 9: tb->col_resize(v); break;
    case 10: tb->row_resize_min(v); break;
    case 11: tb->col_resize_min(v); break;
    case 12: tb->row_position(v); break;
    case 13: tb->col_position(v); break;
    case 14: tb->table_box(static_cast<Fl_Boxtype>(v)); break;
    case 15: tb->scrollbar_size(v); break;
    default:
      row_table(t)->type(static_cast<Fl_Table_Row::TableRowSelectMode>(v));
  }
}

// what: 0 a row's height, 1 a column's width.
int32_t ofl_table_size(intptr_t t, int32_t what, int32_t i) {
  return what ? table(t)->col_width(i) : table(t)->row_height(i);
}

// what as ofl_table_size; i -1 for every row or column.
void ofl_table_set_size(intptr_t t, int32_t what, int32_t i, int32_t v) {
  Fl_Table *tb = table(t);
  if (what) {
    if (i < 0) tb->col_width_all(v); else tb->col_width(i, v);
  } else {
    if (i < 0) tb->row_height_all(v); else tb->row_height(i, v);
  }
}

void ofl_table_visible_cells(intptr_t t, int32_t *r1, int32_t *r2,
                             int32_t *c1, int32_t *c2) {
  int a, b, c, d;
  table(t)->visible_cells(a, b, c, d);
  *r1 = a; *r2 = b; *c1 = c; *c2 = d;
}

int32_t ofl_table_is_selected(intptr_t t, int32_t r, int32_t c) {
  return table(t)->is_selected(r, c);
}

void ofl_table_get_selection(intptr_t t, int32_t *top, int32_t *left,
                             int32_t *bottom, int32_t *right) {
  int a, b, c, d;
  table(t)->get_selection(a, b, c, d);
  *top = a; *left = b; *bottom = c; *right = d;
}

void ofl_table_set_selection(intptr_t t, int32_t top, int32_t left,
                             int32_t bottom, int32_t right) {
  table(t)->set_selection(top, left, bottom, right);
}

// 1 if the cursor moved.
int32_t ofl_table_move_cursor(intptr_t t, int32_t r, int32_t c,
                              int32_t shift) {
  return table(t)->move_cursor(r, c, shift);
}

// Fl_Table::find_cell and redraw_range are protected; the subclass
// reaches them.
struct Protected : Fl_Table {
  using Fl_Table::find_cell;
  using Fl_Table::redraw_range;
};

// 1, and the cell's box, if it is on screen.
int32_t ofl_table_find_cell(intptr_t t, int32_t context, int32_t r,
                            int32_t c, int32_t *x, int32_t *y, int32_t *w,
                            int32_t *h) {
  int X, Y, W, H;
  int (Fl_Table::*find)(Fl_Table::TableContext, int, int, int &, int &,
                        int &, int &) = &Protected::find_cell;
  if ((table(t)->*find)(static_cast<Fl_Table::TableContext>(context), r, c,
                        X, Y, W, H) != 0)
    return 0;
  *x = X; *y = Y; *w = W; *h = H;
  return 1;
}

void ofl_table_redraw_range(intptr_t t, int32_t r1, int32_t r2, int32_t c1,
                            int32_t c2) {
  void (Fl_Table::*redraw)(int, int, int, int) = &Protected::redraw_range;
  (table(t)->*redraw)(r1, r2, c1, c2);
}

int32_t ofl_table_row_selected(intptr_t t, int32_t r) {
  return row_table(t)->row_selected(r);
}

// flag: 0 off, 1 on, 2 toggled. 1 if it changed, 0 if not, -1 if r is
// out of range.
int32_t ofl_table_select_row(intptr_t t, int32_t r, int32_t flag) {
  return row_table(t)->select_row(r, flag);
}

void ofl_table_select_all_rows(intptr_t t, int32_t flag) {
  row_table(t)->select_all_rows(flag);
}

}  // extern "C"
