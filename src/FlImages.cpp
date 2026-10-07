// The C++ part of FlImages: images, loaded or made from pixels, drawn, and
// shown as widget labels; image surfaces, offscreen drawing. See pofltk.h
// for the conventions.

#include "pofltk.h"

#include <FL/Fl_BMP_Image.H>
#include <FL/Fl_Copy_Surface.H>
#include <FL/Fl_GIF_Image.H>
#include <FL/Fl_Image.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_JPEG_Image.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_PNM_Image.H>
#include <FL/Fl_Pixmap.H>
#include <FL/Fl_SVG_Image.H>
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
  explicit Img(Fl_Image *i) : image(i), rgb_(0) {}
  ~Img() {
    delete rgb_;
    delete image;
  }
  // The image as RGB pixels, for reading: itself, or a copy of a pixmap
  // made once, until the image changes; 0 for a bitmap.
  Fl_RGB_Image *rgb() {
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
};

Img *img(intptr_t i) { return reinterpret_cast<Img *>(i); }

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
// other).
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
      if (dynamic_cast<Fl_Pixmap *>(m)) return 1;
      return 2;
    default: return m->w();
  }
}

// A copy of the image's data, w by h pixels; 0 if FLTK couldn't make it.
intptr_t ofl_image_copy(intptr_t i, int32_t w, int32_t h) {
  return make(img(i)->image->copy(w, h));
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
