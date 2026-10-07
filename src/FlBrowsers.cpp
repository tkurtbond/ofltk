// The C++ part of FlBrowsers: lists of lines to choose from. See pofltk.h
// for the conventions. Lines and items are numbered from 1, as in FLTK;
// FlBrowsers checks them.

#include "pofltk.h"

#include <FL/Fl_Browser.H>
#include <FL/Fl_Check_Browser.H>
#include <FL/Fl_File_Browser.H>
#include <FL/Fl_Hold_Browser.H>
#include <FL/Fl_Multi_Browser.H>
#include <FL/Fl_Select_Browser.H>
#include <FL/Fl_Tree.H>
#include <stdlib.h>
#include <string.h>

#include <unordered_map>

namespace {

// Fl_Browser::column_widths, Fl_File_Browser::filter and
// Fl_File_Browser::load keep the pointer they are given
// (doc/fltk-issues.md, 37), so a browser keeps its own copies, which
// outlive their use: FLTK's destructors don't read them.
class Keeps {
public:
  Keeps() : widths(0), pattern(0), dir(0) {}
  virtual ~Keeps() {
    free(widths);
    free(pattern);
    free(dir);
  }
  int *widths;
  char *pattern, *dir;
};

template <class B> class Br : public Keeps, public ofl::W<B> {
public:
  using ofl::W<B>::W;
};

Keeps *keeps(intptr_t b) { return dynamic_cast<Keeps *>(ofl::widget(b)); }

template <class T>
intptr_t make(int32_t x, int32_t y, int32_t w, int32_t h, const char *label,
              intptr_t self) {
  Br<T> *b = new Br<T>(x, y, w, h);
  b->copy_label(ofl::label_text(label));
  return ofl::open(b, self);
}

// Fl_Browser_ finds its top line from its scroll position only when it
// draws, or finds a line under the mouse (the private update_top), so
// before it is first drawn, or after scrolling, topline() and displayed()
// read what it was last time (doc/fltk-issues.md, 38). find_item, which
// is protected, calls update_top first.
struct Top : Fl_Browser_ {
  static void update(Fl_Browser_ *b) { (b->*&Top::find_item)(0); }
};

Fl_Browser_ *base(intptr_t b) { return ofl::as<Fl_Browser_>(b); }
Fl_Browser *browser(intptr_t b) { return ofl::as<Fl_Browser>(b); }
Fl_Check_Browser *check(intptr_t b) { return ofl::as<Fl_Check_Browser>(b); }
Fl_File_Browser *files(intptr_t b) { return ofl::as<Fl_File_Browser>(b); }

// A tree's items are FLTK's, made and deleted by the tree, and some (a
// path's parents) without pofltk seeing. So an Oberon TreeItem holds an
// item's pointer and a serial, and the tree keeps the items it has handed
// out, each with its serial. Every item pofltk removes is dropped from the
// map before FLTK deletes it, and the user can't delete items, so a
// TreeItem is live exactly when its pointer is in the map with its
// serial: a pointer FLTK reused for a new item has a new serial.
class Items {
public:
  Items() : next(0) {}
  virtual ~Items() {}
  std::unordered_map<Fl_Tree_Item *, uint32_t> map;
  uint32_t next;
};

class Tr : public Items, public ofl::W<Fl_Tree> {
public:
  using ofl::W<Fl_Tree>::W;
};

Fl_Tree *tree(intptr_t t) { return ofl::as<Fl_Tree>(t); }
Items *items(intptr_t t) { return dynamic_cast<Items *>(ofl::widget(t)); }

// p, for Oberon: its serial in *serial, a new one if p is new to it.
intptr_t hand(intptr_t t, Fl_Tree_Item *p, int32_t *serial) {
  *serial = 0;
  if (p == 0) return 0;
  Items *k = items(t);
  auto i = k->map.find(p);
  if (i == k->map.end()) i = k->map.emplace(p, ++k->next).first;
  *serial = static_cast<int32_t>(i->second);
  return reinterpret_cast<intptr_t>(p);
}

Fl_Tree_Item *item(intptr_t p) { return reinterpret_cast<Fl_Tree_Item *>(p); }

// Removes item's descendants, and then item, last first. Fl_Tree::remove
// forgets the item it removes as the last one clicked, but not that
// item's descendants (doc/fltk-issues.md, 41), so each goes through it.
void remove(Fl_Tree *t, Items *k, Fl_Tree_Item *it) {
  while (it->children() > 0) remove(t, k, it->child(it->children() - 1));
  k->map.erase(it);
  if (t->callback_item() == it) t->callback_item(0);
  t->remove(it);
}

}  // namespace

extern "C" {

// kind is 0 Fl_Browser, 1 Fl_Hold_Browser, 2 Fl_Multi_Browser, 3
// Fl_Select_Browser, 4 Fl_File_Browser, 5 Fl_Check_Browser, as FlBrowsers
// numbers them.
intptr_t ofl_browser_new(int32_t kind, int32_t x, int32_t y, int32_t w,
                         int32_t h, const char *label, intptr_t self) {
  switch (kind) {
    case 1: return make<Fl_Hold_Browser>(x, y, w, h, label, self);
    case 2: return make<Fl_Multi_Browser>(x, y, w, h, label, self);
    case 3: return make<Fl_Select_Browser>(x, y, w, h, label, self);
    case 4: return make<Fl_File_Browser>(x, y, w, h, label, self);
    case 5: return make<Fl_Check_Browser>(x, y, w, h, label, self);
    default: return make<Fl_Browser>(x, y, w, h, label, self);
  }
}

// Every browser (Fl_Browser_). what: 0 text font, 1 text size, 2 text
// color, 3 has_scrollbar, 4 scrollbar size, 5 hposition, 6 vposition.
int32_t ofl_browser_get(intptr_t b, int32_t what) {
  Fl_Browser_ *br = base(b);
  switch (what) {
    case 1: return br->textsize();
    case 2: return static_cast<int32_t>(br->textcolor());
    case 3: return br->has_scrollbar();
    case 4: return br->scrollbar_size();
    case 5: return br->hposition();
    case 6: return br->vposition();
    default: return br->textfont();
  }
}

void ofl_browser_set(intptr_t b, int32_t what, int32_t v) {
  Fl_Browser_ *br = base(b);
  switch (what) {
    case 1:
      // Fl_Browser::textsize hides Fl_Browser_'s, to measure its lines
      // again, and Fl_File_Browser's hides it, to size its icons.
      if (Fl_File_Browser *f = dynamic_cast<Fl_File_Browser *>(br)) {
        f->textsize(v);
      } else if (Fl_Browser *l = dynamic_cast<Fl_Browser *>(br)) {
        l->textsize(v);
      } else {
        br->textsize(v);
      }
      break;
    case 2: br->textcolor(static_cast<Fl_Color>(v)); break;
    case 3: br->has_scrollbar(static_cast<uchar>(v)); break;
    case 4: br->scrollbar_size(v); break;
    case 5: br->hposition(v); break;
    case 6: br->vposition(v); break;
    default: br->textfont(v);
  }
  br->redraw();
}

// 1 if any line was selected.
int32_t ofl_browser_deselect(intptr_t b) { return base(b)->deselect(); }

void ofl_browser_sort(intptr_t b, int32_t flags) { base(b)->sort(flags); }

// Fl_Browser

int32_t ofl_browser_size(intptr_t b) { return browser(b)->size(); }

void ofl_browser_add(intptr_t b, const char *s) { browser(b)->add(s); }

void ofl_browser_insert(intptr_t b, int32_t line, const char *s) {
  browser(b)->insert(line, s);
}

void ofl_browser_remove(intptr_t b, int32_t line) {
  browser(b)->remove(line);
}

void ofl_browser_move(intptr_t b, int32_t to, int32_t from) {
  browser(b)->move(to, from);
}

void ofl_browser_swap(intptr_t b, int32_t a, int32_t c) {
  browser(b)->swap(a, c);
}

void ofl_browser_clear(intptr_t b) { browser(b)->clear(); }

// 1 if the file was read. Fl_Browser::load returns 1 for "", having
// read nothing.
int32_t ofl_browser_load(intptr_t b, const char *name) {
  return browser(b)->load(name) != 0 && name[0] != 0;
}

void ofl_browser_text(intptr_t b, int32_t line, char *buf, int32_t n) {
  ofl::copy_out(browser(b)->text(line), buf, n);
}

// Fl_Browser::text copies.
void ofl_browser_set_text(intptr_t b, int32_t line, const char *s) {
  browser(b)->text(line, s);
}

// 1 if that changed the line.
int32_t ofl_browser_select(intptr_t b, int32_t line, int32_t on) {
  return browser(b)->select(line, on);
}

int32_t ofl_browser_selected(intptr_t b, int32_t line) {
  return browser(b)->selected(line);
}

int32_t ofl_browser_value(intptr_t b) { return browser(b)->value(); }

// what: 0 top, 1 bottom, 2 middle, as Fl_Line_Position.
void ofl_browser_lineposition(intptr_t b, int32_t line, int32_t what) {
  browser(b)->lineposition(line,
                           static_cast<Fl_Browser::Fl_Line_Position>(what));
}

int32_t ofl_browser_topline(intptr_t b) {
  Top::update(browser(b));
  return browser(b)->topline();
}

// what: 0 hide, 1 show, 2 visible, 3 displayed, 4 make_visible.
int32_t ofl_browser_line(intptr_t b, int32_t what, int32_t line) {
  Fl_Browser *br = browser(b);
  switch (what) {
    case 1: br->show(line); return 1;
    case 2: return br->visible(line);
    case 3: Top::update(br); return br->displayed(line);
    case 4: br->make_visible(line); return 1;
    default: br->hide(line); return 1;
  }
}

// what: 0 format char, 1 column char.
int32_t ofl_browser_char(intptr_t b, int32_t what) {
  Fl_Browser *br = browser(b);
  return static_cast<unsigned char>(what ? br->column_char()
                                         : br->format_char());
}

void ofl_browser_set_char(intptr_t b, int32_t what, int32_t c) {
  Fl_Browser *br = browser(b);
  if (what) {
    br->column_char(static_cast<char>(c));
  } else {
    br->format_char(static_cast<char>(c));
  }
  br->redraw();
}

// n widths, ended with 0 for FLTK; 1 if they were stored.
int32_t ofl_browser_column_widths(intptr_t b, const int32_t *widths,
                                  int32_t n) {
  Keeps *k = keeps(b);
  int *w = static_cast<int *>(malloc((n + 1) * sizeof(int)));
  if (w == 0) return 0;
  for (int i = 0; i < n; i++) w[i] = widths[i];
  w[n] = 0;
  browser(b)->column_widths(w);
  free(k->widths);
  k->widths = w;
  browser(b)->redraw();
  return 1;
}

// Fl_File_Browser

// 1 if the directory was read. Fl_File_Browser::load returns the number
// of the directory's entries, not of the lines it lists, and 0 if it
// couldn't read it.
int32_t ofl_file_browser_load(intptr_t b, const char *dir) {
  Keeps *k = keeps(b);
  char *d = strdup(dir);
  if (d == 0) return 0;
  int n = files(b)->load(d);
  free(k->dir);
  k->dir = d;
  return n > 0;
}

// 1 if the pattern was stored.
int32_t ofl_file_browser_filter(intptr_t b, const char *pattern) {
  Keeps *k = keeps(b);
  char *p = strdup(pattern);
  if (p == 0) return 0;
  files(b)->filter(p);
  free(k->pattern);
  k->pattern = p;
  return 1;
}

void ofl_file_browser_get_filter(intptr_t b, char *buf, int32_t n) {
  ofl::copy_out(files(b)->filter(), buf, n);
}

int32_t ofl_file_browser_type(intptr_t b) { return files(b)->filetype(); }

void ofl_file_browser_set_type(intptr_t b, int32_t t) {
  files(b)->filetype(t);
}

int32_t ofl_file_browser_iconsize(intptr_t b) { return files(b)->iconsize(); }

void ofl_file_browser_set_iconsize(intptr_t b, int32_t s) {
  files(b)->iconsize(static_cast<uchar>(s));
}

// Fl_Check_Browser

// The new item's number. Fl_Check_Browser::add copies.
int32_t ofl_check_browser_add(intptr_t b, const char *s, int32_t on) {
  return check(b)->add(s, on);
}

void ofl_check_browser_remove(intptr_t b, int32_t item) {
  check(b)->remove(item);
}

void ofl_check_browser_clear(intptr_t b) { check(b)->clear(); }

// what: 0 nitems, 1 nchecked, 2 value.
int32_t ofl_check_browser_count(intptr_t b, int32_t what) {
  Fl_Check_Browser *c = check(b);
  switch (what) {
    case 1: return c->nchecked();
    case 2: return c->value();
    default: return c->nitems();
  }
}

int32_t ofl_check_browser_checked(intptr_t b, int32_t item) {
  return check(b)->checked(item);
}

void ofl_check_browser_set_checked(intptr_t b, int32_t item, int32_t on) {
  check(b)->checked(item, on);
}

// on: 1 check_all, 0 check_none.
void ofl_check_browser_check_all(intptr_t b, int32_t on) {
  if (on) {
    check(b)->check_all();
  } else {
    check(b)->check_none();
  }
}

void ofl_check_browser_text(intptr_t b, int32_t item, char *buf, int32_t n) {
  ofl::copy_out(check(b)->text(item), buf, n);
}

// Fl_Tree. An item is its pointer, and its serial (hand); the Oberon
// side checks an item with ofl_tree_live before passing it. Nothing calls
// back for what the program does: every docallback is 0.

intptr_t ofl_tree_new(int32_t x, int32_t y, int32_t w, int32_t h,
                      const char *label, intptr_t self) {
  Tr *t = new Tr(x, y, w, h);
  t->copy_label(ofl::label_text(label));
  return ofl::open(t, self);
}

// 1 if item p, of that serial, is still in the tree.
int32_t ofl_tree_live(intptr_t t, intptr_t p, int32_t serial) {
  Items *k = items(t);
  auto i = k->map.find(item(p));
  return i != k->map.end() && i->second == static_cast<uint32_t>(serial);
}

// what: 0 root, 1 first, 2 last, 3 first selected, 4 callback item, 5
// focus item.
intptr_t ofl_tree_item(intptr_t t, int32_t what, int32_t *serial) {
  Fl_Tree *tr = tree(t);
  Fl_Tree_Item *p;
  switch (what) {
    case 1: p = tr->first(); break;
    case 2: p = tr->last(); break;
    case 3: p = tr->first_selected_item(); break;
    case 4: p = tr->callback_item(); break;
    case 5: p = tr->get_item_focus(); break;
    default: p = tr->root();
  }
  return hand(t, p, serial);
}

// Fl_Tree::add makes the path's missing parents, and the root.
intptr_t ofl_tree_add(intptr_t t, const char *path, int32_t *serial) {
  return hand(t, tree(t)->add(path), serial);
}

intptr_t ofl_tree_find(intptr_t t, const char *path, int32_t *serial) {
  return hand(t, tree(t)->find_item(path), serial);
}

// Fl_Tree::clear deletes the root too.
void ofl_tree_clear(intptr_t t) {
  tree(t)->clear();
  items(t)->map.clear();
  tree(t)->callback_item(0);
  tree(t)->redraw();
}

// what: 0 callback reason, 1 showroot, 2 selectmode, 3 sortorder, 4
// connectorstyle, 5 item_reselect_mode, 6 item label font, 7 size, 8
// foreground, 9 background, 10 connector color, 11 scrollbar size, 12
// vposition, 13 hposition, 14 showcollapse, 15 marginleft, 16 margintop,
// 17 linespacing, 18 connectorwidth, 19 selectbox.
int32_t ofl_tree_get(intptr_t t, int32_t what) {
  Fl_Tree *tr = tree(t);
  switch (what) {
    case 1: return tr->showroot();
    case 2: return tr->selectmode();
    case 3: return tr->sortorder();
    case 4: return tr->connectorstyle();
    case 5: return tr->item_reselect_mode();
    case 6: return tr->item_labelfont();
    case 7: return tr->item_labelsize();
    case 8: return static_cast<int32_t>(tr->item_labelfgcolor());
    case 9: return static_cast<int32_t>(tr->item_labelbgcolor());
    case 10: return static_cast<int32_t>(tr->connectorcolor());
    case 11: return tr->scrollbar_size();
    case 12: return tr->vposition();
    case 13: return tr->hposition();
    case 14: return tr->showcollapse();
    case 15: return tr->marginleft();
    case 16: return tr->margintop();
    case 17: return tr->linespacing();
    case 18: return tr->connectorwidth();
    case 19: return tr->selectbox();
    default: return tr->callback_reason();
  }
}

void ofl_tree_set(intptr_t t, int32_t what, int32_t v) {
  Fl_Tree *tr = tree(t);
  switch (what) {
    case 1: tr->showroot(v); break;
    case 2: tr->selectmode(static_cast<Fl_Tree_Select>(v)); break;
    case 3: tr->sortorder(static_cast<Fl_Tree_Sort>(v)); break;
    case 4: tr->connectorstyle(static_cast<Fl_Tree_Connector>(v)); break;
    case 5:
      tr->item_reselect_mode(static_cast<Fl_Tree_Item_Reselect_Mode>(v));
      break;
    case 6: tr->item_labelfont(v); break;
    case 7: tr->item_labelsize(v); break;
    case 8: tr->item_labelfgcolor(static_cast<Fl_Color>(v)); break;
    case 9: tr->item_labelbgcolor(static_cast<Fl_Color>(v)); break;
    case 10: tr->connectorcolor(static_cast<Fl_Color>(v)); break;
    case 11: tr->scrollbar_size(v); break;
    case 12: tr->vposition(v); break;
    case 13: tr->hposition(v); break;
    case 14: tr->showcollapse(v); break;
    case 15: tr->marginleft(v); break;
    case 16: tr->margintop(v); break;
    case 17: tr->linespacing(v); break;
    case 18: tr->connectorwidth(v); break;
    case 19: tr->selectbox(static_cast<Fl_Boxtype>(v)); break;
    default: break;
  }
  tr->redraw();
}

// Fl_Tree_Item::label copies.
void ofl_tree_set_root_label(intptr_t t, const char *s) {
  tree(t)->root_label(s);
  tree(t)->redraw();
}

// 1 if every selected item was deselected, or every item selected.
int32_t ofl_tree_select_all(intptr_t t, int32_t on) {
  return on ? tree(t)->select_all(0, 0) : tree(t)->deselect_all(0, 0);
}

// Items

// what: 0 parent, 1 next, 2 prev, 3 next selected, 4 next visible
// (below), 5 previous visible (above).
intptr_t ofl_tree_item_item(intptr_t t, intptr_t p, int32_t what,
                            int32_t *serial) {
  Fl_Tree *tr = tree(t);
  Fl_Tree_Item *it = item(p), *r;
  switch (what) {
    case 1: r = tr->next(it); break;
    case 2: r = tr->prev(it); break;
    case 3: r = tr->next_selected_item(it); break;
    case 4: r = tr->next_visible_item(it, FL_Down); break;
    case 5: r = tr->next_visible_item(it, FL_Up); break;
    default: r = it->parent();
  }
  return hand(t, r, serial);
}

intptr_t ofl_tree_item_child(intptr_t t, intptr_t p, int32_t i,
                             int32_t *serial) {
  return hand(t, item(p)->child(i), serial);
}

// what: 0 add a child, 1 insert a child at pos, 2 insert above (0 for the
// root).
intptr_t ofl_tree_item_add(intptr_t t, intptr_t p, int32_t what,
                           const char *name, int32_t pos, int32_t *serial) {
  Fl_Tree *tr = tree(t);
  Fl_Tree_Item *r;
  switch (what) {
    case 1: r = tr->insert(item(p), name, pos); break;
    case 2: r = tr->insert_above(item(p), name); break;
    default: r = tr->add(item(p), name);
  }
  tr->redraw();
  return hand(t, r, serial);
}

void ofl_tree_item_remove(intptr_t t, intptr_t p) {
  remove(tree(t), items(t), item(p));
  tree(t)->redraw();
}

void ofl_tree_item_clear_children(intptr_t t, intptr_t p) {
  Fl_Tree_Item *it = item(p);
  while (it->children() > 0) {
    remove(tree(t), items(t), it->child(it->children() - 1));
  }
  tree(t)->redraw();
}

void ofl_tree_item_label(intptr_t p, char *buf, int32_t n) {
  ofl::copy_out(item(p)->label(), buf, n);
}

void ofl_tree_item_set_label(intptr_t t, intptr_t p, const char *s) {
  item(p)->label(s);
  tree(t)->redraw();
}

// 1 if the path fitted.
int32_t ofl_tree_item_path(intptr_t t, intptr_t p, char *buf, int32_t n) {
  if (tree(t)->item_pathname(buf, n, item(p)) == 0) return 1;
  buf[0] = 0;
  return 0;
}

// what: 0 children, 1 depth, 2 is_root, 3 is_open, 4 is_selected, 5
// is_active, 6 is_visible_r, 7 label font, 8 size, 9 foreground, 10
// background, 11 displayed.
int32_t ofl_tree_item_get(intptr_t t, intptr_t p, int32_t what) {
  Fl_Tree_Item *it = item(p);
  switch (what) {
    case 1: return it->depth();
    case 2: return it->is_root();
    case 3: return it->is_open();
    case 4: return it->is_selected();
    case 5: return it->is_active();
    case 6: return it->is_visible_r();
    case 7: return it->labelfont();
    case 8: return it->labelsize();
    case 9: return static_cast<int32_t>(it->labelfgcolor());
    case 10: return static_cast<int32_t>(it->labelbgcolor());
    case 11: return tree(t)->displayed(it);
    default: return it->children();
  }
}

// what: 0 open (or close), 1 select (or deselect), 2 select only, 3
// activate, 4 label font, 5 size, 6 foreground, 7 background, 8 focus, 9
// show (scroll to), 10 show at the top.
void ofl_tree_item_set(intptr_t t, intptr_t p, int32_t what, int32_t v) {
  Fl_Tree *tr = tree(t);
  Fl_Tree_Item *it = item(p);
  switch (what) {
    case 1:
      if (v) {
        tr->select(it, 0);
      } else {
        tr->deselect(it, 0);
      }
      break;
    case 2: tr->select_only(it, 0); break;
    case 3: it->activate(v); break;
    case 4: it->labelfont(v); tr->recalc_tree(); break;
    case 5: it->labelsize(v); tr->recalc_tree(); break;
    case 6: it->labelfgcolor(static_cast<Fl_Color>(v)); break;
    case 7: it->labelbgcolor(static_cast<Fl_Color>(v)); break;
    case 8: tr->set_item_focus(it); break;
    case 9: tr->show_item(it); break;
    case 10: tr->show_item_top(it); break;
    default:
      if (v) {
        tr->open(it, 0);
      } else {
        tr->close(it, 0);
      }
  }
  tr->redraw();
}

}  // extern "C"
