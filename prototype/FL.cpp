#include <FL/Fl.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Box.H>
#include <FL/fl_draw.H>
#include <stdint.h>
extern "C" {
/* Oberon side: one dispatcher per event kind, taking the Oberon object's address */
typedef void (*draw_fn)(intptr_t self);
typedef int32_t (*handle_fn)(intptr_t self, int32_t ev);
typedef void (*cb_fn)(intptr_t self);
typedef void (*gone_fn)(intptr_t self);
static draw_fn d_draw; static handle_fn d_handle; static cb_fn d_cb; static gone_fn d_gone;
void ofl_init(draw_fn d, handle_fn h, cb_fn c, gone_fn g) { d_draw = d; d_handle = h; d_cb = c; d_gone = g; }
}
/* A box whose draw() and handle() are the Oberon object's methods */
class OBox : public Fl_Box {
public:
  intptr_t self;
  OBox(int x, int y, int w, int h, intptr_t s) : Fl_Box(x, y, w, h), self(s) {}
  ~OBox() { d_gone(self); }
  void draw() override { d_draw(self); }
  int handle(int e) override { int r = d_handle(self, e); return r ? r : Fl_Box::handle(e); }
  void super_draw() { Fl_Box::draw(); }
};
static void trampoline(Fl_Widget *, void *s) { d_cb((intptr_t)s); }
extern "C" {
intptr_t ofl_window_new(int32_t w, int32_t h, const char *l) { auto *x = new Fl_Double_Window(w, h); x->copy_label(l); return (intptr_t)x; }
intptr_t ofl_button_new(int32_t x, int32_t y, int32_t w, int32_t h, const char *l, intptr_t self) {
  auto *b = new Fl_Button(x, y, w, h); b->copy_label(l); b->callback(trampoline, (void *)self); return (intptr_t)b; }
intptr_t ofl_obox_new(int32_t x, int32_t y, int32_t w, int32_t h, intptr_t self) { return (intptr_t)new OBox(x, y, w, h, self); }
void ofl_end(intptr_t g) { ((Fl_Group *)g)->end(); }
void ofl_show(intptr_t w) { ((Fl_Window *)w)->show(); }
void ofl_redraw(intptr_t w) { ((Fl_Widget *)w)->redraw(); }
void ofl_delete(intptr_t w) { Fl::delete_widget((Fl_Widget *)w); }
void ofl_do_callback(intptr_t w) { ((Fl_Widget *)w)->do_callback(); }
void ofl_geom(intptr_t w, int32_t *x, int32_t *y, int32_t *ww, int32_t *hh) { auto *p = (Fl_Widget *)w; *x = p->x(); *y = p->y(); *ww = p->w(); *hh = p->h(); }
void ofl_color(uint32_t c) { fl_color(c); }
void ofl_rectf(int32_t x, int32_t y, int32_t w, int32_t h) { fl_rectf(x, y, w, h); }
void ofl_text(const char *s, int32_t x, int32_t y) { fl_font(FL_HELVETICA, 14); fl_draw(s, x, y); }
void ofl_add_timeout(double t, void (*cb)(intptr_t), intptr_t d) { Fl::add_timeout(t, (Fl_Timeout_Handler)cb, (void *)d); }
void ofl_hide(intptr_t w) { ((Fl_Widget *)w)->hide(); }
int32_t ofl_run(void) { return Fl::run(); }
}
