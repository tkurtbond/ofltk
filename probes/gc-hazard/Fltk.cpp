#include <FL/Fl.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Button.H>
#include <stdint.h>
extern "C" {
typedef void (*ofl_cb)(intptr_t, intptr_t);
intptr_t ofl_window_new(int32_t w, int32_t h, const char *l) { Fl_Window *win = new Fl_Window(w, h); win->copy_label(l); return (intptr_t)win; }
intptr_t ofl_button_new(int32_t x, int32_t y, int32_t w, int32_t h, const char *l) { Fl_Button *b = new Fl_Button(x, y, w, h); b->copy_label(l); return (intptr_t)b; }
void ofl_group_end(intptr_t g) { ((Fl_Group *)g)->end(); }
void ofl_window_show(intptr_t w) { ((Fl_Window *)w)->show(); }
void ofl_hide(intptr_t w) { ((Fl_Widget *)w)->hide(); }
void ofl_widget_copy_label(intptr_t w, const char *l) { ((Fl_Widget *)w)->copy_label(l); }
void ofl_widget_callback(intptr_t w, ofl_cb cb, intptr_t d) { ((Fl_Widget *)w)->callback((Fl_Callback *)cb, (void *)d); }
int32_t ofl_run(void) { return Fl::run(); }
}
extern "C" {
typedef void (*ofl_tcb)(intptr_t);
void ofl_add_timeout(double t, ofl_tcb cb, intptr_t d) { Fl::add_timeout(t, (Fl_Timeout_Handler)cb, (void *)d); }
void ofl_do_callback(intptr_t w) { ((Fl_Widget *)w)->do_callback(); }
}
