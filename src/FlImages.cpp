// The C++ part of FlImages: images, loaded or made from pixels, drawn, and
// shown as widget labels; animated GIFs; image surfaces, offscreen
// drawing. See pofltk.h for the conventions.

#include "pofltk.h"

#include <FL/Fl_Anim_GIF_Image.H>
#include <FL/Fl_BMP_Image.H>
#include <FL/Fl_Browser.H>
#include <FL/Fl_Copy_Surface.H>
#include <FL/Fl_GIF_Image.H>
#include <FL/Fl_Image.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_JPEG_Image.H>
#include <FL/Fl_Menu_.H>
#include <FL/Fl_Multi_Label.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_PNM_Image.H>
#include <FL/Fl_Pixmap.H>
#include <FL/Fl_SVG_Image.H>
#include <FL/Fl_Tiled_Image.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_XPM_Image.H>
#include <FL/fl_draw.H>
#include <FL/platform.H>
#include <stdio.h>
#include <string.h>

#include <new>
#include <vector>

namespace {

// An image, shared by the program's Image and the widgets showing it
// (ofl::Shared): FLTK keeps a label image's pointer, and doesn't own it.
class Img : public ofl::Shared {
public:
  // under is an image i uses and doesn't own, which it holds: the image a
  // tiled image tiles.
  explicit Img(Fl_Image *i, ofl::Shared *under = 0)
      : image(i), rgb_(0), under_(under) {
    if (under_) under_->hold();
  }
  ~Img() {
    delete rgb_;
    delete image;
    if (under_) under_->release();
  }
  // The image as RGB pixels, for reading: itself, or a copy of a pixmap
  // made once, until the image changes, or an animation's frame shown,
  // unless it is smaller than the animation (OPTIMIZE_MEMORY); 0 for a
  // bitmap or a tiled image.
  Fl_RGB_Image *rgb() {
    if (Fl_Anim_GIF_Image *a = dynamic_cast<Fl_Anim_GIF_Image *>(image)) {
      Fl_RGB_Image *f = dynamic_cast<Fl_RGB_Image *>(a->image());
      if (f && f->data_w() == a->data_w() && f->data_h() == a->data_h()) {
        return f;
      }
      return 0;
    }
    if (Fl_SVG_Image *s = dynamic_cast<Fl_SVG_Image *>(image)) s->normalize();
    if (Fl_RGB_Image *r = dynamic_cast<Fl_RGB_Image *>(image)) return r;
    if (!rgb_) {
      if (Fl_Pixmap *p = dynamic_cast<Fl_Pixmap *>(image)) {
        rgb_ = new Fl_RGB_Image(p);
      }
    }
    return rgb_;
  }
  void changed() {
    delete rgb_;
    rgb_ = 0;
  }
  Fl_Image *const image;

private:
  Fl_RGB_Image *rgb_;
  ofl::Shared *const under_;
};

Img *img(intptr_t i) { return reinterpret_cast<Img *>(i); }

// Fl_Anim_GIF_Image's private canvas_, reached as FlBrowsers.cpp reaches
// Fl_Tree's _lastselect, through an explicit instantiation, which may
// name a private member ([temp.explicit]).
template <class Tag, typename Tag::type M> struct Reach {
  friend typename Tag::type member(Tag) { return M; }
};
struct CanvasOf {
  typedef Fl_Widget *Fl_Anim_GIF_Image::*type;
  friend type member(CanvasOf);
};
template struct Reach<CanvasOf, &Fl_Anim_GIF_Image::canvas_>;

// An animated GIF. FLTK's animation keeps its canvas widget's pointer, and
// redraws it from a timer, so a canvas deleted first would be used after
// it is freed (doc/fltk-issues.md, 62): the animation watches the canvas,
// and forgets it as it dies.
class Anim : public Img, public ofl::Watcher {
public:
  explicit Anim(Fl_Anim_GIF_Image *a) : Img(a), canvas_(0) {}
  ~Anim() {
    if (canvas_) canvas_->unwatch(this);
  }
  Fl_Anim_GIF_Image *gif() const {
    return static_cast<Fl_Anim_GIF_Image *>(image);
  }
  // Watches widget w, the canvas; 0 for none.
  void watch(Fl_Widget *w) {
    if (canvas_) canvas_->unwatch(this);
    canvas_ = w ? ofl::ref_of(w) : 0;
    if (canvas_) canvas_->watch(this);
  }
  void widget_gone() override {
    gif()->*member(CanvasOf()) = 0;
    canvas_ = 0;
  }

private:
  ofl::Ref *canvas_;  // the canvas's
};

Anim *anim(intptr_t a) { return reinterpret_cast<Anim *>(a); }

// Makes widget w (0 for none) a's canvas, as Fl_Anim_GIF_Image::canvas
// does with flags. FLTK takes the old canvas's image away, and shows the
// animation in the new one unless DONT_SET_AS_IMAGE: the widgets' holds
// follow.
void set_canvas(Anim *a, intptr_t w, int32_t flags) {
  Fl_Anim_GIF_Image *g = a->gif();
  Fl_Widget *old = g->canvas();
  Fl_Widget *c = w ? ofl::widget(w) : 0;
  g->canvas(c, static_cast<unsigned short>(flags));
  if (old) ofl::ref_of(old)->hold(ofl::Ref::image, 0);
  if (c && !(flags & Fl_Anim_GIF_Image::DONT_SET_AS_IMAGE)) {
    ofl::ref_of(c)->hold(ofl::Ref::image, a);
  }
  a->watch(c);
}

// g, loaded, as an Anim, with canvas w and flags; 0 (and g deleted) if it
// failed. g was made with DONT_START and no canvas, so a failure leaves
// no widget showing it; the canvas is set, and the animation started,
// as FLTK's constructor would.
intptr_t open_anim(Fl_Anim_GIF_Image *g, intptr_t w, int32_t flags) {
  if (!g->valid() || g->frames() <= 0 || g->w() <= 0 || g->h() <= 0) {
    delete g;
    return 0;
  }
  Anim *a = new Anim(g);
  set_canvas(a, w, flags);
  if (!(flags & Fl_Anim_GIF_Image::DONT_START)) g->start();
  return reinterpret_cast<intptr_t>(a);
}

// A multi-label: two parts, drawn side by side, each nothing, text (its
// own copy), an image or another multi-label, which it holds. FLTK keeps
// the pointers to it and its parts, and owns none of them.
class Multi : public ofl::Shared {
public:
  Multi() {
    for (int i = 0; i < 2; i++) {
      text_[i] = 0;
      part_[i] = 0;
    }
    ml.labela = ml.labelb = 0;
    ml.typea = ml.typeb = FL_NO_LABEL;
  }
  ~Multi() {
    for (int i = 0; i < 2; i++) set(i, FL_NO_LABEL, 0, 0, 0);
  }
  // Part i becomes value, of label type t: text, copied, or the label of
  // what part holds (an image or a multi-label).
  void set(int i, Fl_Labeltype t, const char *value, char *text,
           ofl::Shared *part) {
    if (part) part->hold();
    char *old_text = text_[i];
    ofl::Shared *old_part = part_[i];
    (i == 0 ? ml.labela : ml.labelb) = value;
    (i == 0 ? ml.typea : ml.typeb) = static_cast<uchar>(t);
    text_[i] = text;
    part_[i] = part;
    free(old_text);
    if (old_part) old_part->release();
  }
  // Whether this is m, or holds it, however deeply.
  bool contains(const Multi *m) const {
    if (m == this) return true;
    for (int i = 0; i < 2; i++) {
      const Multi *p = dynamic_cast<const Multi *>(part_[i]);
      if (p && p->contains(m)) return true;
    }
    return false;
  }
  Fl_Multi_Label ml;

private:
  char *text_[2];
  ofl::Shared *part_[2];
};

Multi *multi(intptr_t m) { return reinterpret_cast<Multi *>(m); }

// i, made by FLTK, as an Img; 0 (and i deleted) if it failed.
intptr_t make(Fl_Image *i) {
  if (i == 0) return 0;
  if (i->fail() || i->w() <= 0 || i->h() <= 0) {
    delete i;
    return 0;
  }
  return reinterpret_cast<intptr_t>(new Img(i));
}

bool starts(const unsigned char *p, size_t n, const char *magic) {
  size_t m = strlen(magic);
  return n >= m && memcmp(p, magic, m) == 0;
}

// Whether the n bytes at p begin an SVG document: "<svg" within them,
// after an XML declaration or comments.
bool svg(const unsigned char *p, size_t n) {
  for (size_t i = 0; i + 4 <= n; i++) {
    if (memcmp(p + i, "<svg", 4) == 0) return true;
  }
  return n >= 2 && p[0] == 0x1f && p[1] == 0x8b;  // svgz, gzipped
}

enum Format { unknown, png, jpeg, gif, bmp, xpm, pnm, svgf };

// The format of an image beginning with the n bytes at p, by its magic
// number, as Fl_Shared_Image's handlers decide it.
Format format(const unsigned char *p, size_t n) {
  if (starts(p, n, "\x89PNG")) return png;
  if (starts(p, n, "\xff\xd8\xff")) return jpeg;
  if (starts(p, n, "GIF87a") || starts(p, n, "GIF89a")) return gif;
  if (starts(p, n, "BM")) return bmp;
  if (starts(p, n, "/* XPM */")) return xpm;
  if (n >= 2 && p[0] == 'P' && p[1] >= '1' && p[1] <= '7') return pnm;
  if (svg(p, n)) return svgf;
  return unknown;
}

// The maxval of the binary PNM (P5, P6) beginning with the n bytes at p:
// its fourth number, after the magic, width and height, with comments;
// 0 for another form, or a header it can't read.
int pnm_maxval(const unsigned char *p, size_t n) {
  if (n < 2 || p[0] != 'P' || (p[1] != '5' && p[1] != '6')) return 0;
  size_t i = 2;
  int v = 0;
  for (int field = 0; field < 3; field++) {
    for (;;) {  // white space and comments
      while (i < n && (p[i] == ' ' || p[i] == '\t' || p[i] == '\r' ||
                       p[i] == '\n')) {
        i++;
      }
      if (i < n && p[i] == '#') {
        while (i < n && p[i] != '\n') i++;
      } else {
        break;
      }
    }
    if (i >= n || p[i] < '0' || p[i] > '9') return 0;
    for (v = 0; i < n && p[i] >= '0' && p[i] <= '9'; i++) {
      v = v * 10 + (p[i] - '0');
      if (v > 65535) return 0;
    }
  }
  return v;
}

// Fl_PNM_Image reads the samples of a binary PNM with a maxval under 255
// as they are, not scaled to 0 to 255 as it scales the text forms
// (doc/fltk-issues.md, 45); this scales them.
void scale_pnm(Fl_Image *i, int maxval) {
  Fl_RGB_Image *r = dynamic_cast<Fl_RGB_Image *>(i);
  if (r == 0 || maxval <= 0 || maxval >= 255 || r->fail()) return;
  unsigned char *a = const_cast<unsigned char *>(r->array);
  int ld = r->ld() ? r->ld() : r->data_w() * r->d();
  for (int y = 0; y < r->data_h(); y++) {
    for (int x = 0; x < r->data_w() * r->d(); x++) {
      unsigned char *p = a + y * ld + x;
      *p = static_cast<unsigned char>(*p * 255 / maxval);
    }
  }
  r->uncache();
}

}  // namespace

extern "C" {

// Images

// The image in file name, of a format told by its first bytes; 0 if it
// can't be read or decoded.
intptr_t ofl_image_load(const char *name) {
  unsigned char head[1024];
  FILE *f = fopen(name, "rb");
  if (!f) return 0;
  size_t n = fread(head, 1, sizeof head, f);
  fclose(f);
  switch (format(head, n)) {
    case png: return make(new Fl_PNG_Image(name));
    case jpeg: return make(new Fl_JPEG_Image(name));
    case gif: return make(new Fl_GIF_Image(name));
    case bmp: return make(new Fl_BMP_Image(name));
    case xpm: return make(new Fl_XPM_Image(name));
    case pnm: {
      Fl_Image *i = new Fl_PNM_Image(name);
      scale_pnm(i, pnm_maxval(head, n));
      return make(i);
    }
    case svgf: return make(new Fl_SVG_Image(name));
    default: return 0;
  }
}

// The image in the n bytes at data, which FLTK decodes into its own
// memory (SVG copies the text); 0 for a format FLTK reads only from files
// (XPM, PNM), or data it can't decode.
intptr_t ofl_image_load_data(const unsigned char *data, int32_t n) {
  if (n <= 0) return 0;
  switch (format(data, static_cast<size_t>(n))) {
    case png: return make(new Fl_PNG_Image(0, data, n));
    case jpeg: return make(new Fl_JPEG_Image(0, data, n));
    case gif: return make(new Fl_GIF_Image(0, data, static_cast<size_t>(n)));
    case bmp: return make(new Fl_BMP_Image(0, data, n));
    case svgf: return make(new Fl_SVG_Image(0, data, static_cast<size_t>(n)));
    default: return 0;
  }
}

// The pixmap in the n XPM lines at lines, each in stride bytes ending in
// a 0: the values, the colors, then the rows of pixels, as the strings of
// an XPM file. Fl_Pixmap keeps the lines and trusts the values, so a
// short line or array would be read past its end: they are checked
// against the values first, and the pixmap copies them (copy_data). 0
// if they don't match, or FLTK's own form (fewer than 1 color) is used.
intptr_t ofl_image_xpm(const char *lines, int32_t n, int32_t stride) {
  if (n < 1 || stride < 1) return 0;
  for (int32_t i = 0; i < n; i++) {
    if (!memchr(lines + static_cast<size_t>(i) * stride, 0, stride)) return 0;
  }
  int w, h, colors, cpp;
  if (sscanf(lines, "%d %d %d %d", &w, &h, &colors, &cpp) != 4) return 0;
  if (w < 1 || h < 1 || colors < 1 || cpp < 1 || cpp > 2) return 0;
  if (static_cast<long>(n) != 1L + colors + h) return 0;
  std::vector<const char *> p(n);
  for (int32_t i = 0; i < n; i++) {
    p[i] = lines + static_cast<size_t>(i) * stride;
    size_t need = i == 0 ? 0 : i <= colors ? static_cast<size_t>(cpp)
                                           : static_cast<size_t>(w) * cpp;
    if (strlen(p[i]) < need) return 0;
  }
  Fl_Pixmap given(p.data());
  return make(given.copy());
}

// An RGB image of w by h pixels of d bytes each (1 gray, 2 gray and alpha,
// 3 RGB, 4 RGBA), from bits, rows ld bytes apart (0 for w * d); copied,
// since Fl_RGB_Image keeps the pointer it is given.
intptr_t ofl_image_rgb(const unsigned char *bits, int32_t w, int32_t h,
                       int32_t d, int32_t ld) {
  int row = ld ? ld : w * d;
  unsigned char *copy = new (std::nothrow) unsigned char[row * h];
  if (copy == 0) return 0;
  memcpy(copy, bits, static_cast<size_t>(row) * h);
  Fl_RGB_Image *i = new Fl_RGB_Image(copy, w, h, d, ld);
  i->alloc_array = 1;
  return make(i);
}

// The program lets go of its image; widgets showing it keep it.
void ofl_image_close(intptr_t i) { img(i)->close(); }

// what: 0 w, 1 h, 2 d, 3 data_w, 4 data_h, 5 kind (0 RGB, 1 pixmap, 2
// other, 3 animation).
int32_t ofl_image_get(intptr_t i, int32_t what) {
  Fl_Image *m = img(i)->image;
  switch (what) {
    case 1: return m->h();
    case 2:
      if (Fl_RGB_Image *r = img(i)->rgb()) return r->d();
      return m->d();
    case 3: return m->data_w();
    case 4: return m->data_h();
    case 5:
      if (dynamic_cast<Fl_RGB_Image *>(m)) return 0;
      if (dynamic_cast<Fl_Anim_GIF_Image *>(m)) return 3;
      if (dynamic_cast<Fl_Pixmap *>(m)) return 1;
      return 2;
    default: return m->w();
  }
}

// A copy of the image's data, w by h pixels; 0 if FLTK couldn't make it.
// A tiled image's copy tiles the same image, which the original may own
// (after color_average), so the copy holds the original. An animation's
// copy has no canvas, and plays if the original does.
intptr_t ofl_image_copy(intptr_t i, int32_t w, int32_t h) {
  Fl_Image *m = img(i)->image;
  if (dynamic_cast<Fl_Tiled_Image *>(m)) {
    return reinterpret_cast<intptr_t>(new Img(m->copy(w, h), img(i)));
  }
  if (dynamic_cast<Fl_Anim_GIF_Image *>(m)) {
    Fl_Anim_GIF_Image *c = static_cast<Fl_Anim_GIF_Image *>(m->copy(w, h));
    if (!c->valid()) {
      delete c;
      return 0;
    }
    return reinterpret_cast<intptr_t>(new Anim(c));
  }
  return make(m->copy(w, h));
}

// Image t, repeated to fill w by h pixels, or the window it is drawn in
// if both are 0. Fl_Tiled_Image keeps t's pointer, so the new image holds
// t.
intptr_t ofl_image_tiled(intptr_t t, int32_t w, int32_t h) {
  return reinterpret_cast<intptr_t>(
      new Img(new Fl_Tiled_Image(img(t)->image, w, h), img(t)));
}

// The size it is drawn at, its data unchanged.
void ofl_image_scale(intptr_t i, int32_t w, int32_t h, int32_t proportional,
                     int32_t expand) {
  img(i)->image->scale(w, h, proportional, expand);
}

// what: 0 color_average(c, weight), 1 desaturate.
void ofl_image_change(intptr_t i, int32_t what, int32_t c, double weight) {
  if (what == 1) {
    img(i)->image->desaturate();
  } else {
    img(i)->image->color_average(static_cast<Fl_Color>(c),
                                 static_cast<float>(weight));
  }
  img(i)->changed();
}

void ofl_image_draw(intptr_t i, int32_t x, int32_t y, int32_t w, int32_t h,
                    int32_t cx, int32_t cy) {
  img(i)->image->draw(x, y, w, h, cx, cy);
}

// Pixel x, y of the image's data as r, g, b, a; 0 if it has no pixels to
// read (a bitmap). A gray pixel has r = g = b; alpha is 255 without an
// alpha channel.
int32_t ofl_image_pixel(intptr_t i, int32_t x, int32_t y, int32_t *r,
                        int32_t *g, int32_t *b, int32_t *a) {
  Fl_RGB_Image *m = img(i)->rgb();
  if (m == 0 || m->count() == 0 || m->array == 0) return 0;
  int d = m->d();
  int ld = m->ld() ? m->ld() : m->data_w() * d;
  const unsigned char *p = m->array + y * ld + x * d;
  *a = 255;
  if (d <= 2) {
    *r = *g = *b = p[0];
    if (d == 2) *a = p[1];
  } else {
    *r = p[0];
    *g = p[1];
    *b = p[2];
    if (d == 4) *a = p[3];
  }
  return 1;
}

// 1 if the image was written to file name as PNG.
int32_t ofl_image_save_png(intptr_t i, const char *name) {
  Fl_RGB_Image *m = img(i)->rgb();
  return m != 0 && fl_write_png(name, m) == 0;
}

// The clipboard

// Puts the image on the clipboard, by drawing it on an Fl_Copy_Surface,
// which FLTK sends to the clipboard as it is deleted.
void ofl_image_copy_to_clipboard(intptr_t i) {
  Fl_Image *m = img(i)->image;
  fl_open_display();  // as Fl.cpp's ofl_copy (doc/fltk-issues.md, 49)
  Fl_Copy_Surface *s = new Fl_Copy_Surface(m->w(), m->h());
  Fl_Surface_Device::push_current(s);
  m->draw(0, 0);
  Fl_Surface_Device::pop_current();
  delete s;
}

// In an FL_PASTE, the image pasted, now the program's (Fl::e_clipboard_data
// set to 0, so neither FLTK nor ofl::drop_pasted_image deletes it); 0 if
// the event carries none.
intptr_t ofl_take_pasted_image(void) {
  if (Fl::event_clipboard_type() != Fl::clipboard_image) return 0;
  Fl_Image *m = static_cast<Fl_RGB_Image *>(Fl::event_clipboard());
  Fl::e_clipboard_data = 0;
  return make(m);
}

// Widget labels

// slot: 0 the label image, 1 the inactive one. i 0 for none.
void ofl_widget_image(intptr_t w, int32_t slot, intptr_t i) {
  Fl_Widget *wd = ofl::widget(w);
  Fl_Image *m = i ? img(i)->image : 0;
  if (slot) {
    wd->deimage(m);
  } else {
    wd->image(m);
  }
  ofl::ref_of(wd)->hold(slot ? ofl::Ref::deimage : ofl::Ref::image, img(i));
  wd->redraw();
}

// The window system's icon for window w, i 0 for none. FLTK's X11 driver
// copies it; Wayland's has no icons, and ignores it (doc/fltk-issues.md,
// 44).
void ofl_window_icon(intptr_t w, intptr_t i) {
  Fl_Window *win = ofl::as<Fl_Window>(w);
  win->icon(i ? img(i)->rgb() : 0);
}

// Window w's shape, from image i: its pixels that aren't black or
// transparent. 0 if i has no pixels to read (a bitmap, a tiled image).
// FLTK keeps the image's pointer, and X11's driver reads w() by h()
// pixels of its data, past their end if the image is drawn larger than
// they are (doc/fltk-issues.md, 61): FLTK is given a copy, w() by h(),
// which the window holds.
int32_t ofl_window_shape(intptr_t w, intptr_t i) {
  Fl_RGB_Image *r = img(i)->rgb();
  if (r == 0) return 0;
  Fl_Image *c = r->copy(r->w(), r->h());
  if (Fl_SVG_Image *s = dynamic_cast<Fl_SVG_Image *>(c)) s->normalize();
  if (c == 0 || c->fail() || c->w() <= 0 || c->h() <= 0) {
    delete c;
    return 0;
  }
  Img *m = new Img(c);
  Fl_Window *win = ofl::as<Fl_Window>(w);
  win->shape(c);
  ofl::ref_of(win)->hold(ofl::Ref::shape, m);
  m->close();  // the window's hold is its only one
  return 1;
}

// The icon of browser b's line, i 0 for none. The browser holds the
// image while a line shows it (ofl::drop_icons).
void ofl_browser_icon(intptr_t b, int32_t line, intptr_t i) {
  Fl_Browser *br = ofl::as<Fl_Browser>(b);
  Fl_Image *m = i ? img(i)->image : 0;
  br->icon(line, m);
  if (i) ofl::ref_of(br)->keep(img(i), m);
  ofl::drop_icons(br);
}

// Animated GIFs

// The animation in file name, or in the n bytes at data if name is 0, as
// open_anim makes it; 0 unless it is a GIF FLTK can decode.
intptr_t ofl_anim_load(const char *name, const unsigned char *data,
                       int32_t n, intptr_t canvas, int32_t flags) {
  unsigned short f =
      static_cast<unsigned short>(flags | Fl_Anim_GIF_Image::DONT_START);
  if (name) {
    unsigned char head[16];
    FILE *file = fopen(name, "rb");
    if (!file) return 0;
    size_t got = fread(head, 1, sizeof head, file);
    fclose(file);
    if (format(head, got) != gif) return 0;
    return open_anim(new Fl_Anim_GIF_Image(name, 0, f), canvas, flags);
  }
  if (n <= 0 || format(data, static_cast<size_t>(n)) != gif) return 0;
  return open_anim(
      new Fl_Anim_GIF_Image(0, data, static_cast<size_t>(n), 0, f), canvas,
      flags);
}

void ofl_anim_canvas(intptr_t a, intptr_t w, int32_t flags) {
  set_canvas(anim(a), w, flags);
}

// The canvas's Oberon object, or 0.
intptr_t ofl_anim_canvas_object(intptr_t a) {
  Fl_Widget *c = anim(a)->gif()->canvas();
  return c ? ofl::object_of(c) : 0;
}

// what: 0 frames, 1 frame, 2 canvas_w, 3 canvas_h, 4 playing, 5
// frame_uncache, 6 is_animated.
int32_t ofl_anim_get(intptr_t a, int32_t what) {
  Fl_Anim_GIF_Image *g = anim(a)->gif();
  switch (what) {
    case 1: return g->frame();
    case 2: return g->canvas_w();
    case 3: return g->canvas_h();
    case 4: return g->playing();
    case 5: return g->frame_uncache();
    case 6: return g->is_animated();
    default: return g->frames();
  }
}

// Frame n's x, y, w or h, by what (0 to 3).
int32_t ofl_anim_frame_get(intptr_t a, int32_t what, int32_t n) {
  Fl_Anim_GIF_Image *g = anim(a)->gif();
  switch (what) {
    case 1: return g->frame_y(n);
    case 2: return g->frame_w(n);
    case 3: return g->frame_h(n);
    default: return g->frame_x(n);
  }
}

// what: 0 start, 1 stop, 2 next, 3 frame_uncache(true), 4
// frame_uncache(false).
void ofl_anim_do(intptr_t a, int32_t what) {
  Fl_Anim_GIF_Image *g = anim(a)->gif();
  switch (what) {
    case 1: g->stop(); break;
    case 2: g->next(); break;
    case 3: g->frame_uncache(true); break;
    case 4: g->frame_uncache(false); break;
    default: g->start(); break;
  }
}

void ofl_anim_set_frame(intptr_t a, int32_t n) { anim(a)->gif()->frame(n); }

double ofl_anim_delay(intptr_t a, int32_t n) {
  return anim(a)->gif()->delay(n);
}

void ofl_anim_set_delay(intptr_t a, int32_t n, double d) {
  anim(a)->gif()->delay(n, d);
}

double ofl_anim_speed(intptr_t a) { return anim(a)->gif()->speed(); }

void ofl_anim_set_speed(intptr_t a, double s) { anim(a)->gif()->speed(s); }

// Resizes the frames to w by h, or to the canvas if both are 0; by
// scale if w is -1.
void ofl_anim_resize(intptr_t a, int32_t w, int32_t h, double scale) {
  if (w == -1) {
    anim(a)->gif()->resize(scale);
  } else {
    anim(a)->gif()->resize(w, h);
  }
}

// The name it was loaded from, into buf of n characters, truncated; ""
// for one loaded from memory.
void ofl_anim_name(intptr_t a, char *buf, int32_t n) {
  const char *s = anim(a)->gif()->name();
  ofl::copy_out(s ? s : "", buf, n);
}

// A copy of frame n's image, as the animation draws it; 0 if it has none.
intptr_t ofl_anim_frame_image(intptr_t a, int32_t n) {
  Fl_Image *f = anim(a)->gif()->image(n);
  return f ? make(f->copy()) : 0;
}

// FLTK's settings for every animation and RGB image: which = 0 the least
// delay between frames, 1 the scaling algorithm, 2 whether GIFs FLTK
// loads itself (a file chooser's preview) are animated.
double ofl_image_setting(int32_t which) {
  switch (which) {
    case 1: return Fl_Image::scaling_algorithm();
    case 2: return Fl_GIF_Image::animate;
    default: return Fl_Anim_GIF_Image::min_delay;
  }
}

void ofl_image_set_setting(int32_t which, double v) {
  switch (which) {
    case 1:
      Fl_Image::scaling_algorithm(static_cast<Fl_RGB_Scaling>(v));
      break;
    case 2: Fl_GIF_Image::animate = v != 0; break;
    default: Fl_Anim_GIF_Image::min_delay = v; break;
  }
}

// Multi-labels

intptr_t ofl_multi_new() { return reinterpret_cast<intptr_t>(new Multi); }

void ofl_multi_close(intptr_t m) { multi(m)->close(); }

// Part i of m becomes, by kind: 0 nothing, 1 text s of label type t, 2
// the image p, 3 the multi-label p.
void ofl_multi_set(intptr_t m, int32_t i, int32_t kind, const char *s,
                   int32_t t, intptr_t p) {
  switch (kind) {
    case 1: {
      char *copy = strdup(s);
      if (copy == 0) return;
      multi(m)->set(i, static_cast<Fl_Labeltype>(t), copy, copy, 0);
      break;
    }
    case 2:
      multi(m)->set(i, FL_IMAGE_LABEL,
                    reinterpret_cast<const char *>(img(p)->image), 0, img(p));
      break;
    case 3:
      multi(m)->set(i, FL_MULTI_LABEL,
                    reinterpret_cast<const char *>(&multi(p)->ml), 0,
                    multi(p));
      break;
    default: multi(m)->set(i, FL_NO_LABEL, 0, 0, 0);
  }
}

int32_t ofl_multi_contains(intptr_t m, intptr_t n) {
  return multi(m)->contains(multi(n));
}

// Widget w shows multi-label m as its label, or no label if m is 0.
// Fl_Widget::label(type, value) doesn't free a label copy_label made, and
// leaves it marked to be freed (doc/fltk-issues.md, 55), so label(0)
// frees it first.
void ofl_widget_multi_label(intptr_t w, intptr_t m) {
  Fl_Widget *wd = ofl::widget(w);
  wd->label(static_cast<const char *>(0));
  if (m) {
    wd->label(FL_MULTI_LABEL, reinterpret_cast<const char *>(&multi(m)->ml));
  } else {
    wd->labeltype(FL_NORMAL_LABEL);
  }
  ofl::ref_of(wd)->hold(ofl::Ref::label, m ? multi(m) : 0);
  wd->redraw();
}

// Item i of menu mn shows, by kind: 0 its text, 1 the image p, 2 the
// multi-label p. The item gets an ofl::ItemLabel, which takes its text
// (Fl_Menu_::insert's own copy) as its name.
void ofl_menu_item_label(intptr_t mn, int32_t i, int32_t kind, intptr_t p) {
  Fl_Menu_ *m = ofl::as<Fl_Menu_>(mn);
  Fl_Menu_Item *it = const_cast<Fl_Menu_Item *>(m->menu()) + i;
  char *name;
  if (ofl::ItemLabel *old = ofl::item_label(m, it)) {
    name = strdup(old->name);
    if (name == 0) return;
  } else {
    name = const_cast<char *>(it->text);
  }
  if (kind == 0) {
    it->label(FL_NORMAL_LABEL, name);
  } else {
    ofl::ItemLabel *l;
    if (kind == 1) {
      l = new ofl::ItemLabel(name, img(p));
      l->ml.typea = FL_IMAGE_LABEL;
      l->ml.labela = reinterpret_cast<const char *>(img(p)->image);
    } else {
      l = new ofl::ItemLabel(name, multi(p));
      l->ml.typea = FL_MULTI_LABEL;
      l->ml.labela = reinterpret_cast<const char *>(&multi(p)->ml);
    }
    ofl::ref_of(m)->keep(l, &l->ml);
    l->close();  // the menu's hold is its only one
    it->label(FL_MULTI_LABEL, reinterpret_cast<const char *>(&l->ml));
  }
  ofl::drop_item_labels(m);
  m->redraw();
}

// Image surfaces: drawing into an image, offscreen.

intptr_t ofl_surface_new(int32_t w, int32_t h) {
  return reinterpret_cast<intptr_t>(new Fl_Image_Surface(w, h));
}

void ofl_surface_close(intptr_t s) {
  delete reinterpret_cast<Fl_Image_Surface *>(s);
}

// Makes the surface where drawing goes, or the one before it again.
void ofl_surface_begin(intptr_t s) {
  Fl_Surface_Device::push_current(reinterpret_cast<Fl_Image_Surface *>(s));
}

void ofl_surface_end() { Fl_Surface_Device::pop_current(); }

// Draws widget w with its top left at x, y.
void ofl_surface_draw(intptr_t s, intptr_t w, int32_t x, int32_t y) {
  reinterpret_cast<Fl_Image_Surface *>(s)->draw(ofl::widget(w), x, y);
}

// What has been drawn, as a new image.
intptr_t ofl_surface_image(intptr_t s) {
  return make(reinterpret_cast<Fl_Image_Surface *>(s)->image());
}

// The w by h pixels at x, y of the surface drawn on, as a new RGB image
// (RGBA if alpha); 0 if FLTK couldn't read them.
intptr_t ofl_read_image(int32_t x, int32_t y, int32_t w, int32_t h,
                        int32_t alpha) {
  unsigned char *p = fl_read_image(0, x, y, w, h, alpha ? 255 : 0);
  if (p == 0) return 0;
  Fl_RGB_Image *i = new Fl_RGB_Image(p, w, h, alpha ? 4 : 3);
  i->alloc_array = 1;
  return make(i);
}

}  // extern "C"
