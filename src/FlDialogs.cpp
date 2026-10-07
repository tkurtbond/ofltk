// The C++ part of FlDialogs: FLTK's common dialogs. See pofltk.h for the
// conventions.
//
// fl_message and the rest take a printf format, so the text is always an
// argument of "%s", never the format: an Oberon string may hold a "%".

#include "pofltk.h"

#include <FL/Fl_Color_Chooser.H>
#include <FL/Fl_File_Chooser.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/fl_ask.H>
#include <FL/fl_show_colormap.H>
#include <FL/filename.H>
#include <stdlib.h>
#include <string.h>

#include <new>

namespace {

// "" is no button.
const char *button(const char *s) { return s && *s ? s : 0; }

// fl_file_chooser and fl_dir_chooser keep one chooser window for the
// program, and set its title with Fl_File_Chooser::label, which keeps the
// pointer (doc/fltk-issues.md, 30). So the title is copied here, where it
// outlives the call; a longer one is cut short.
char chooser_title[1024];

const char *keep_title(const char *s) {
  strncpy(chooser_title, s, sizeof chooser_title - 1);
  chooser_title[sizeof chooser_title - 1] = 0;
  return chooser_title;
}


// Fl_Native_File_Chooser. FLTK's own driver, used when zenity, kdialog
// and GTK are off or missing, keeps the title pointer (it is
// Fl_File_Chooser::label, doc/fltk-issues.md, 30), so the title is copied
// here, beside the chooser; the other drivers copy it themselves, as
// every driver copies the filter, directory and preset file.
struct Chooser {
  Fl_Native_File_Chooser chooser;
  char *title;
  explicit Chooser(int kind) : chooser(kind), title(0) {}
  ~Chooser() { free(title); }
};

Chooser *chooser(intptr_t c) { return reinterpret_cast<Chooser *>(c); }

// A directory's names, as fl_filename_list gives them, until freed.
struct Listing {
  dirent **list;
  int n;
};

Listing *listing(intptr_t l) { return reinterpret_cast<Listing *>(l); }

}  // namespace

extern "C" {

void ofl_dialog_message(int32_t alert, const char *text) {
  if (alert) {
    fl_alert("%s", text);
  } else {
    fl_message("%s", text);
  }
}

// The button pushed, 0 to 2; -1 if Escape closed the dialog, -2 its
// window's close button.
int32_t ofl_dialog_choice(const char *text, const char *b0, const char *b1,
                          const char *b2) {
  return fl_choice_n("%s", button(b0), button(b1), button(b2), text);
}

// 1 and the text typed in buf, which also holds the text to start with; 0
// if the dialog was cancelled. FLTK returns its own copy, and copies buf
// before the dialog starts.
int32_t ofl_dialog_input(int32_t password, const char *label, char *buf,
                         int32_t n) {
  const char *r = password ? fl_password("%s", buf, label)
                           : fl_input("%s", buf, label);
  if (r == 0) return 0;
  ofl::copy_out(r, buf, n);
  return 1;
}

// fl_message_title copies; the title is for the next dialog only, or with
// dflt for every dialog given none.
void ofl_dialog_title(int32_t dflt, const char *title) {
  if (dflt) {
    fl_message_title_default(title);
  } else {
    fl_message_title(title);
  }
}

int32_t ofl_dialog_hotspot(void) { return fl_message_hotspot(); }
void ofl_dialog_set_hotspot(int32_t on) { fl_message_hotspot(on); }

void ofl_dialog_font(int32_t *font, int32_t *size) {
  *font = fl_message_font_;
  *size = fl_message_size_;
}

void ofl_dialog_set_font(int32_t font, int32_t size) {
  fl_message_font(font, size);
}

void ofl_beep(int32_t kind) { fl_beep(kind); }

// 1, and the color chosen in r, g, b (0 to 255), if the user chose one.
int32_t ofl_color_chooser(const char *title, int32_t *r, int32_t *g,
                          int32_t *b, int32_t mode) {
  uchar R = static_cast<uchar>(*r), G = static_cast<uchar>(*g),
        B = static_cast<uchar>(*b);
  if (!fl_color_chooser(title, R, G, B, mode)) return 0;
  *r = R;
  *g = G;
  *b = B;
  return 1;
}

int32_t ofl_show_colormap(int32_t old) {
  return static_cast<int32_t>(fl_show_colormap(static_cast<Fl_Color>(old)));
}

// 1 and the path chosen in buf, which also holds the one to start with; 0
// if cancelled. FLTK returns its own copy.
int32_t ofl_file_chooser(int32_t dir, const char *title, const char *pattern,
                         char *buf, int32_t n, int32_t relative) {
  Fl_File_Chooser::sort = ofl::numericsort;  // doc/fltk-issues.md, 63
  const char *r = dir ? fl_dir_chooser(keep_title(title), buf, relative)
                      : fl_file_chooser(keep_title(title), pattern, buf,
                                        relative);
  if (r == 0) return 0;
  ofl::copy_out(r, buf, n);
  return 1;
}

// A native file chooser of kind (Fl_Native_File_Chooser::Type); 0 if out
// of memory. It opens the display, and looks for zenity and kdialog.
intptr_t ofl_fnfc_new(int32_t kind) {
  return reinterpret_cast<intptr_t>(new (std::nothrow) Chooser(kind));
}

void ofl_fnfc_close(intptr_t c) { delete chooser(c); }

// what: 0 the title, 1 the filter, 2 the directory, 3 the preset file.
// 0 if out of memory.
int32_t ofl_fnfc_set_text(intptr_t c, int32_t what, const char *s) {
  Fl_Native_File_Chooser &f = chooser(c)->chooser;
  switch (what) {
    case 0: {
      char *t = strdup(s);
      if (!t) return 0;
      f.title(t);
      free(chooser(c)->title);
      chooser(c)->title = t;
      break;
    }
    case 1: f.filter(s); break;
    case 2: f.directory(s); break;
    default: f.preset_file(s);
  }
  return 1;
}

// what: 0 the kind, 1 the options, 2 the filter chosen.
void ofl_fnfc_set_int(intptr_t c, int32_t what, int32_t v) {
  Fl_Native_File_Chooser &f = chooser(c)->chooser;
  switch (what) {
    case 0: f.type(v); break;
    case 1: f.options(v); break;
    default: f.filter_value(v);
  }
}

// what: 0 the kind, 1 the options, 2 the filter chosen, 3 the number of
// filters, 4 the number of files chosen.
int32_t ofl_fnfc_get_int(intptr_t c, int32_t what) {
  Fl_Native_File_Chooser &f = chooser(c)->chooser;
  switch (what) {
    case 0: return f.type();
    case 1: return f.options();
    case 2: return f.filter_value();
    case 3: return f.filters();
    default: return f.count();
  }
}

// 0 a file chosen, 1 cancelled, -1 an error (ofl_fnfc_errmsg).
// FLTK's own chooser lists a directory sorted by Fl_File_Chooser::sort,
// which is fl_numericsort until it is set (doc/fltk-issues.md, 63).
int32_t ofl_fnfc_show(intptr_t c) {
  Fl_File_Chooser::sort = ofl::numericsort;
  return chooser(c)->chooser.show();
}

// File i chosen, of ofl_fnfc_get_int(c, 4).
intptr_t ofl_fnfc_filename(intptr_t c, int32_t i) {
  return reinterpret_cast<intptr_t>(chooser(c)->chooser.filename(i));
}

intptr_t ofl_fnfc_errmsg(intptr_t c) {
  return reinterpret_cast<intptr_t>(chooser(c)->chooser.errmsg());
}

// Directories

// Directory dir's names, sorted by sort (0 fl_alphasort, 1
// fl_casealphasort, 2 fl_numericsort, 3 fl_casenumericsort, the last two
// corrected: doc/fltk-issues.md, 63), their number in *n; 0 if it can't
// be read.
intptr_t ofl_filename_list(const char *dir, int32_t sort, int32_t *n) {
  Fl_File_Sort_F *f = sort == 1   ? fl_casealphasort
                      : sort == 2 ? ofl::numericsort
                      : sort == 3 ? ofl::casenumericsort
                                  : fl_alphasort;
  dirent **list = 0;
  int k = fl_filename_list(dir, &list, f);
  if (k < 0) return 0;
  *n = k;
  return reinterpret_cast<intptr_t>(new Listing{list, k});
}

int32_t ofl_filename_length(intptr_t l, int32_t i) {
  return static_cast<int32_t>(strlen(listing(l)->list[i]->d_name));
}

void ofl_filename_get(intptr_t l, int32_t i, char *buf, int32_t n) {
  ofl::copy_out(listing(l)->list[i]->d_name, buf, n);
}

void ofl_filename_free(intptr_t l) {
  fl_filename_free_list(&listing(l)->list, listing(l)->n);
  delete listing(l);
}

}  // extern "C"
