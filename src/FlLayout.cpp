// The C++ part of FlLayout: the groups that place their children. See
// pofltk.h for the conventions.

#include "pofltk.h"

#include <FL/Fl_Flex.H>
#include <FL/Fl_Grid.H>
#include <FL/Fl_Pack.H>
#include <FL/Fl_Scroll.H>
#include <FL/Fl_Tabs.H>
#include <FL/Fl_Tile.H>
#include <FL/Fl_Wizard.H>

namespace {

template <class T>
intptr_t make(int32_t x, int32_t y, int32_t w, int32_t h, const char *label,
              intptr_t self) {
  ofl::W<T> *g = new ofl::W<T>(x, y, w, h);
  g->copy_label(ofl::label_text(label));
  return ofl::open(g, self);
}

Fl_Flex *flex(intptr_t f) { return ofl::as<Fl_Flex>(f); }
Fl_Grid *grid(intptr_t g) { return ofl::as<Fl_Grid>(g); }

}  // namespace

extern "C" {

// kind is 0 Fl_Flex, 1 Fl_Grid, and so on, as FlLayout numbers them.
intptr_t ofl_layout_new(int32_t kind, int32_t x, int32_t y, int32_t w,
                        int32_t h, const char *label, intptr_t self) {
  switch (kind) {
    case 1: return make<Fl_Grid>(x, y, w, h, label, self);
    case 2: return make<Fl_Pack>(x, y, w, h, label, self);
    case 3: return make<Fl_Scroll>(x, y, w, h, label, self);
    case 4: return make<Fl_Tabs>(x, y, w, h, label, self);
    case 5: return make<Fl_Tile>(x, y, w, h, label, self);
    case 6: return make<Fl_Wizard>(x, y, w, h, label, self);
    default: return make<Fl_Flex>(x, y, w, h, label, self);
  }
}

// The group's type(): a flex's, pack's or scroll's kind.
int32_t ofl_layout_type(intptr_t g) { return ofl::widget(g)->type(); }

void ofl_layout_set_type(intptr_t g, int32_t t) {
  ofl::widget(g)->type(static_cast<uchar>(t));
}

// Flex

void ofl_flex_fixed(intptr_t f, intptr_t w, int32_t size) {
  flex(f)->fixed(ofl::widget(w), size);
}

int32_t ofl_flex_is_fixed(intptr_t f, intptr_t w) {
  return flex(f)->fixed(ofl::widget(w));
}

void ofl_flex_margins(intptr_t f, int32_t *l, int32_t *t, int32_t *r,
                      int32_t *b) {
  int L, T, R, B;
  flex(f)->margin(&L, &T, &R, &B);
  *l = L;
  *t = T;
  *r = R;
  *b = B;
}

void ofl_flex_set_margins(intptr_t f, int32_t l, int32_t t, int32_t r,
                          int32_t b) {
  flex(f)->margin(l, t, r, b);
}

int32_t ofl_flex_gap(intptr_t f) { return flex(f)->gap(); }
void ofl_flex_set_gap(intptr_t f, int32_t g) { flex(f)->gap(g); }
void ofl_flex_layout(intptr_t f) { flex(f)->layout(); }

// Grid. Rows and columns are checked by FlLayout.

void ofl_grid_set_layout(intptr_t g, int32_t rows, int32_t cols) {
  grid(g)->layout(rows, cols);
}

void ofl_grid_layout(intptr_t g) { grid(g)->layout(); }
void ofl_grid_clear_layout(intptr_t g) { grid(g)->clear_layout(); }
int32_t ofl_grid_rows(intptr_t g) { return grid(g)->rows(); }
int32_t ofl_grid_cols(intptr_t g) { return grid(g)->cols(); }

// 1 if w was put in the cell; 0 if w isn't g's child.
int32_t ofl_grid_widget(intptr_t g, intptr_t w, int32_t row, int32_t col,
                        int32_t rowspan, int32_t colspan, int32_t align) {
  return grid(g)->widget(ofl::widget(w), row, col, rowspan, colspan,
                         static_cast<Fl_Grid_Align>(align)) != 0;
}

void ofl_grid_margins(intptr_t g, int32_t *l, int32_t *t, int32_t *r,
                      int32_t *b) {
  int L, T, R, B;
  grid(g)->margin(&L, &T, &R, &B);
  *l = L;
  *t = T;
  *r = R;
  *b = B;
}

void ofl_grid_set_margins(intptr_t g, int32_t l, int32_t t, int32_t r,
                          int32_t b) {
  grid(g)->margin(l, t, r, b);
}

void ofl_grid_gap(intptr_t g, int32_t *row_gap, int32_t *col_gap) {
  int r, c;
  grid(g)->gap(&r, &c);
  *row_gap = r;
  *col_gap = c;
}

void ofl_grid_set_gap(intptr_t g, int32_t row_gap, int32_t col_gap) {
  grid(g)->gap(row_gap, col_gap);
}

// what: 0 width or height, 1 weight, 2 gap, 3 computed width or height.
int32_t ofl_grid_col(intptr_t g, int32_t what, int32_t col) {
  switch (what) {
    case 1: return grid(g)->col_weight(col);
    case 2: return grid(g)->col_gap(col);
    case 3: return grid(g)->computed_col_width(col);
    default: return grid(g)->col_width(col);
  }
}

void ofl_grid_set_col(intptr_t g, int32_t what, int32_t col, int32_t v) {
  switch (what) {
    case 1: grid(g)->col_weight(col, v); break;
    case 2: grid(g)->col_gap(col, v); break;
    default: grid(g)->col_width(col, v);
  }
}

int32_t ofl_grid_row(intptr_t g, int32_t what, int32_t row) {
  switch (what) {
    case 1: return grid(g)->row_weight(row);
    case 2: return grid(g)->row_gap(row);
    case 3: return grid(g)->computed_row_height(row);
    default: return grid(g)->row_height(row);
  }
}

void ofl_grid_set_row(intptr_t g, int32_t what, int32_t row, int32_t v) {
  switch (what) {
    case 1: grid(g)->row_weight(row, v); break;
    case 2: grid(g)->row_gap(row, v); break;
    default: grid(g)->row_height(row, v);
  }
}

void ofl_grid_show_grid(intptr_t g, int32_t s) { grid(g)->show_grid(s); }

// Pack

int32_t ofl_pack_spacing(intptr_t p) {
  return ofl::as<Fl_Pack>(p)->spacing();
}

void ofl_pack_set_spacing(intptr_t p, int32_t s) {
  ofl::as<Fl_Pack>(p)->spacing(s);
}

// Scroll

int32_t ofl_scroll_xposition(intptr_t s) {
  return ofl::as<Fl_Scroll>(s)->xposition();
}

int32_t ofl_scroll_yposition(intptr_t s) {
  return ofl::as<Fl_Scroll>(s)->yposition();
}

void ofl_scroll_to(intptr_t s, int32_t x, int32_t y) {
  ofl::as<Fl_Scroll>(s)->scroll_to(x, y);
}

int32_t ofl_scroll_scrollbar_size(intptr_t s) {
  return ofl::as<Fl_Scroll>(s)->scrollbar_size();
}

void ofl_scroll_set_scrollbar_size(intptr_t s, int32_t n) {
  ofl::as<Fl_Scroll>(s)->scrollbar_size(n);
}

// Tabs and wizards: value is the child shown, as its Oberon object (0 if
// none, or FLTK made it).

intptr_t ofl_tabs_value(intptr_t t) {
  return ofl::object_of(ofl::as<Fl_Tabs>(t)->value());
}

void ofl_tabs_set_value(intptr_t t, intptr_t w) {
  ofl::as<Fl_Tabs>(t)->value(ofl::widget(w));
}

int32_t ofl_tabs_tab_align(intptr_t t) {
  return static_cast<int32_t>(ofl::as<Fl_Tabs>(t)->tab_align());
}

void ofl_tabs_set_tab_align(intptr_t t, int32_t a) {
  ofl::as<Fl_Tabs>(t)->tab_align(static_cast<Fl_Align>(a));
}

void ofl_tabs_handle_overflow(intptr_t t, int32_t ov) {
  ofl::as<Fl_Tabs>(t)->handle_overflow(ov);
}

void ofl_tabs_client_area(intptr_t t, int32_t *x, int32_t *y, int32_t *w,
                          int32_t *h) {
  int X, Y, W, H;
  ofl::as<Fl_Tabs>(t)->client_area(X, Y, W, H);
  *x = X;
  *y = Y;
  *w = W;
  *h = H;
}

intptr_t ofl_wizard_value(intptr_t z) {
  return ofl::object_of(ofl::as<Fl_Wizard>(z)->value());
}

void ofl_wizard_set_value(intptr_t z, intptr_t w) {
  ofl::as<Fl_Wizard>(z)->value(ofl::widget(w));
}

void ofl_wizard_next(intptr_t z) { ofl::as<Fl_Wizard>(z)->next(); }
void ofl_wizard_prev(intptr_t z) { ofl::as<Fl_Wizard>(z)->prev(); }

// Tile. Without size ranges, move_intersection leaves the children's
// saved sizes (init_sizes) as they were, and the first move with ranges
// starts from those, putting the children back (doc/fltk-issues.md,
// 24). With ranges, FLTK keeps them current, so saving them again here
// is harmless.

void ofl_tile_size_range(intptr_t t, intptr_t w, int32_t minw, int32_t minh,
                         int32_t maxw, int32_t maxh) {
  Fl_Tile *tile = ofl::as<Fl_Tile>(t);
  tile->init_sizes();
  tile->size_range(ofl::widget(w), minw, minh, maxw, maxh);
}

void ofl_tile_init_size_range(intptr_t t, int32_t minw, int32_t minh) {
  Fl_Tile *tile = ofl::as<Fl_Tile>(t);
  tile->init_sizes();
  tile->init_size_range(minw, minh);
}

void ofl_tile_move_intersection(intptr_t t, int32_t oldx, int32_t oldy,
                                int32_t newx, int32_t newy) {
  ofl::as<Fl_Tile>(t)->move_intersection(oldx, oldy, newx, newy);
}

}  // extern "C"
