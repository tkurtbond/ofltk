// The C++ part of FlMenus: menu bars, menu buttons and choices. See
// pofltk.h for the conventions.
//
// A menu item is an index into the menu's Fl_Menu_Item array, as in
// FLTK. Items have no FLTK callback: their user data is the address of
// their Oberon action, a procedure, so FLTK calls the menu's callback for
// every item picked (Fl_Menu_::picked), and the Oberon Menu.Callback runs
// the item's action. A procedure is code, not a heap object, so the
// collector needs to see nothing.

#include "pofltk.h"

#include <FL/Fl_Choice.H>
#include <FL/Fl_Menu_.H>
#include <FL/Fl_Menu_Bar.H>
#include <FL/Fl_Menu_Button.H>
#include <FL/Fl_Menu_Item.H>
#include <FL/Fl_Window.H>
#include <string.h>

#include <vector>

namespace {

// The menu whose shortcuts work in every window (Menu.Global). FLTK's
// own Fl_Menu_::global keeps a pointer that a deleted menu leaves
// dangling (doc/fltk-issues.md, 27), so pofltk keeps its own, and a menu
// forgets it as it is destroyed.
Fl_Menu_ *global_menu;

int global_handler(int event) {
  if (event != FL_SHORTCUT || global_menu == 0 || Fl::modal()) return 0;
  Fl::first_window(global_menu->window());
  return global_menu->handle(event);
}

template <class B> class M : public ofl::W<B> {
public:
  using ofl::W<B>::W;
  ~M() {
    if (global_menu == this) global_menu = 0;
  }
};

template <class T>
intptr_t make(int32_t x, int32_t y, int32_t w, int32_t h, const char *label,
              intptr_t self) {
  M<T> *m = new M<T>(x, y, w, h);
  m->copy_label(ofl::label_text(label));
  return ofl::open(m, self);
}

Fl_Menu_ *menu(intptr_t m) { return ofl::as<Fl_Menu_>(m); }

Fl_Menu_Item *item(intptr_t m, int32_t i) {
  return const_cast<Fl_Menu_Item *>(menu(m)->menu()) + i;
}

// Fl_Choice::value(int) hides Fl_Menu_'s, and adds a redraw.
int set_value(Fl_Menu_ *m, int32_t i) {
  if (Fl_Choice *c = dynamic_cast<Fl_Choice *>(m)) return c->value(i);
  return i < 0 ? m->value(static_cast<const Fl_Menu_Item *>(0))
               : m->value(i);
}

// FLTK keeps the item chosen as a pointer into the array, so inserting or
// removing items before it leaves it naming another item
// (doc/fltk-issues.md, 26). Each item's text is its own copy, which
// neither moves nor is reused while an item is inserted or removed, so it
// finds the chosen item again afterwards, or none if it was removed.
class KeepValue {
public:
  explicit KeepValue(Fl_Menu_ *m)
      : m_(m), text_(m->mvalue() ? m->mvalue()->text : 0) {}
  ~KeepValue() {
    if (text_ == 0) return;
    const Fl_Menu_Item *items = m_->menu();
    for (int i = 0; items && i < m_->size(); i++) {
      if (items[i].text == text_) {
        if (m_->mvalue() != items + i) set_value(m_, i);
        return;
      }
    }
    set_value(m_, -1);
  }

private:
  Fl_Menu_ *m_;
  const char *text_;
};

// FLTK reads an item's label as its text whatever its type
// (doc/fltk-issues.md, 54): Fl_Menu_::insert finds a path's submenus by
// it, and find_index and item_pathname make paths of it. So while one of
// them runs, each item showing an image or a multi-label has its name as
// its text.
class Names {
public:
  explicit Names(Fl_Menu_ *m) : m_(m) {
    Fl_Menu_Item *items = const_cast<Fl_Menu_Item *>(m->menu());
    for (int i = 0; items && i < m->size(); i++) {
      if (ofl::ItemLabel *l = ofl::item_label(m, items + i)) {
        labels_.push_back(l);
        items[i].text = l->name;
      }
    }
  }
  ~Names() {
    if (labels_.empty()) return;
    Fl_Menu_Item *items = const_cast<Fl_Menu_Item *>(m_->menu());
    for (int i = 0; items && i < m_->size(); i++) {
      for (ofl::ItemLabel *l : labels_) {
        if (items[i].text == l->name) {
          items[i].text = reinterpret_cast<const char *>(&l->ml);
        }
      }
    }
  }

private:
  Fl_Menu_ *m_;
  std::vector<ofl::ItemLabel *> labels_;
};

// Makes items from to to - 1 of m text again, each its own copy of its
// name. Fl_Menu_::remove and replace free() an item's text whatever its
// type (doc/fltk-issues.md, 54), and would free an ItemLabel's ml.
void plain(Fl_Menu_ *m, int from, int to) {
  Fl_Menu_Item *items = const_cast<Fl_Menu_Item *>(m->menu());
  for (int i = from; i < to; i++) {
    if (ofl::ItemLabel *l = ofl::item_label(m, items + i)) {
      items[i].text = strdup(l->name);
      items[i].labeltype_ = FL_NORMAL_LABEL;
    }
  }
}

// The index after item i and its submenu, if it has one.
int after(Fl_Menu_ *m, int i) {
  const Fl_Menu_Item *items = m->menu();
  return static_cast<int>(items[i].next() - items);
}

}  // namespace

extern "C" {

// kind is 0 Fl_Menu_Bar, 1 Fl_Menu_Button, 2 Fl_Choice, as FlMenus
// numbers them.
intptr_t ofl_menu_new(int32_t kind, int32_t x, int32_t y, int32_t w,
                      int32_t h, const char *label, intptr_t self) {
  switch (kind) {
    case 1: return make<Fl_Menu_Button>(x, y, w, h, label, self);
    case 2: return make<Fl_Choice>(x, y, w, h, label, self);
    default: return make<Fl_Menu_Bar>(x, y, w, h, label, self);
  }
}

// The array's length, with the ends of the menu and its submenus.
int32_t ofl_menu_size(intptr_t m) { return menu(m)->size(); }

// 1 if i is an item: in the array, and not the end of a menu.
int32_t ofl_menu_is_item(intptr_t m, int32_t i) {
  return i >= 0 && i < menu(m)->size() - 1 && item(m, i)->text != 0;
}

// The new item's index. index is -1 to add at the end; flags never has
// FL_SUBMENU_POINTER, which would make action a menu array.
int32_t ofl_menu_insert(intptr_t m, int32_t index, const char *label,
                        int32_t shortcut, intptr_t action, int32_t flags) {
  KeepValue keep(menu(m));
  Names names(menu(m));
  return menu(m)->insert(index, label, shortcut, 0,
                         reinterpret_cast<void *>(action),
                         flags & ~FL_SUBMENU_POINTER);
}

void ofl_menu_remove(intptr_t m, int32_t i) {
  KeepValue keep(menu(m));
  plain(menu(m), i, after(menu(m), i));
  menu(m)->remove(i);
  ofl::drop_item_labels(menu(m));
}

void ofl_menu_clear(intptr_t m) {
  menu(m)->clear();
  ofl::drop_item_labels(menu(m));
}

void ofl_menu_clear_submenu(intptr_t m, int32_t i) {
  KeepValue keep(menu(m));
  plain(menu(m), i + 1, after(menu(m), i));
  menu(m)->clear_submenu(i);
  ofl::drop_item_labels(menu(m));
}

int32_t ofl_menu_value(intptr_t m) { return menu(m)->value(); }

int32_t ofl_menu_set_value(intptr_t m, int32_t i) {
  return set_value(menu(m), i);
}

// As if the user picked item i: FLTK's toggling and radio, then the
// callback.
void ofl_menu_pick(intptr_t m, int32_t i) { menu(m)->picked(item(m, i)); }

void ofl_menu_setonly(intptr_t m, int32_t i) { menu(m)->setonly(item(m, i)); }

void ofl_menu_label(intptr_t m, int32_t i, char *buf, int32_t n) {
  ofl::copy_out(ofl::item_name(menu(m), item(m, i)), buf, n);
}

// Fl_Menu_::replace copies the text of a menu made by add().
void ofl_menu_set_label(intptr_t m, int32_t i, const char *s) {
  plain(menu(m), i, i + 1);
  menu(m)->replace(i, s);
  ofl::drop_item_labels(menu(m));
}

// 1 if item i's path ("File/Open") fits in buf.
int32_t ofl_menu_pathname(intptr_t m, int32_t i, char *buf, int32_t n) {
  Names names(menu(m));
  int r = menu(m)->item_pathname(buf, n, item(m, i));
  if (r != 0) buf[0] = 0;
  return r == 0;
}

int32_t ofl_menu_find_index(intptr_t m, const char *path) {
  Names names(menu(m));
  return menu(m)->find_index(path);
}

int32_t ofl_menu_flags(intptr_t m, int32_t i) { return item(m, i)->flags; }

// The submenu bits stay as they are: they describe the array's shape.
void ofl_menu_set_flags(intptr_t m, int32_t i, int32_t flags) {
  const int shape = FL_SUBMENU | FL_SUBMENU_POINTER;
  Fl_Menu_Item *it = item(m, i);
  it->flags = (it->flags & shape) | (flags & ~shape);
  menu(m)->redraw();
}

int32_t ofl_menu_shortcut(intptr_t m, int32_t i) {
  return item(m, i)->shortcut();
}

void ofl_menu_set_shortcut(intptr_t m, int32_t i, int32_t s) {
  item(m, i)->shortcut(s);
}

intptr_t ofl_menu_action(intptr_t m, int32_t i) {
  return reinterpret_cast<intptr_t>(item(m, i)->user_data());
}

void ofl_menu_set_action(intptr_t m, int32_t i, intptr_t a) {
  item(m, i)->user_data(reinterpret_cast<void *>(a));
}

// what: 0 text font, 1 text size, 2 text color, 3 down box, 4 menu box.
int32_t ofl_menu_style(intptr_t m, int32_t what) {
  Fl_Menu_ *mn = menu(m);
  switch (what) {
    case 1: return mn->textsize();
    case 2: return static_cast<int32_t>(mn->textcolor());
    case 3: return mn->down_box();
    case 4: return mn->menu_box();
    default: return mn->textfont();
  }
}

void ofl_menu_set_style(intptr_t m, int32_t what, int32_t v) {
  Fl_Menu_ *mn = menu(m);
  switch (what) {
    case 1: mn->textsize(v); break;
    case 2: mn->textcolor(static_cast<Fl_Color>(v)); break;
    case 3: mn->down_box(static_cast<Fl_Boxtype>(v)); break;
    case 4: mn->menu_box(static_cast<Fl_Boxtype>(v)); break;
    default: mn->textfont(v);
  }
  mn->redraw();
}

void ofl_menu_global(intptr_t m) {
  if (global_menu == 0) {
    Fl::remove_handler(global_handler);
    Fl::add_handler(global_handler);
  }
  global_menu = menu(m);
}

// Menu buttons

// The index of the item picked, after its callback; -1 if none was.
// Under Wayland a menu popped up over a window shown but not yet on the
// screen is a fatal protocol error (doc/fltk-issues.md, 28), so this waits
// for the window first, which takes no time once it is there.
int32_t ofl_menu_popup(intptr_t m) {
  Fl_Menu_Button *b = ofl::as<Fl_Menu_Button>(m);
  Fl_Window *top = b->top_window();
  if (top && top->shown()) top->wait_for_expose();
  if (b->popup() == 0) return -1;
  return b->value();
}

int32_t ofl_menu_type(intptr_t m) { return menu(m)->type(); }

void ofl_menu_set_type(intptr_t m, int32_t t) {
  menu(m)->type(static_cast<uchar>(t));
}

}  // extern "C"
