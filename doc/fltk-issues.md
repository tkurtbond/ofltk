# FLTK issues found while writing ofltk

Problems in FLTK 1.4 found while building ofltk: bugs, which crash or
contradict FLTK's documentation, and pitfalls, which are FLTK working as
intended in a way a binding must allow for. Each was seen in a program
that ran, and where possible traced in FLTK's source
(`/usr/local/sw/src/lang/C++/fltk/fltk-1.4.5/`).

Record each new one here as it is found, in the same form:

- **What happens**, with the FLTK version and back end (Wayland, X11)
  it was seen on, and the date.
- **Cause**, with the source file and function, if found.
- **Effect on ofltk**, and the workaround, with where it lives.
- **How it was confirmed**: the test or scratch program.

Unless an entry says otherwise, the version is FLTK 1.4.5 (Fedora's
`fltk-1.4.5`), on Fedora 44, x86_64.

## Bugs

### 1. Drawing text before any `fl_font()` crashes (Cairo)

- **What happens**: `fl_draw(text, ...)` with no font set yet crashes
  under Wayland, where FLTK draws with Cairo. Found 2026-10-06 in the
  prototype (`doc/design.md`, "Problems found").
- **Cause**: `Fl_Cairo_Graphics_Driver::draw(const char *, int, float,
  float)` and `descent()` use `font_descriptor()` without checking it,
  and it is 0 until a font is set. `height()` and `width()` check it,
  and set a font or return -1, so the driver is inconsistent with
  itself.
- **Effect on ofltk**: every `FlDraw` text procedure sets FLTK's normal
  font first if none is set (`ensure_font` in `src/FlDraw.cpp`).
- **Confirmed**: the prototype's crash; source read 2026-10-06.

### 2. `fl_clip_box` returns the reverse of its documentation (Cairo)

- **What happens**: `fl_clip_box(x, y, w, h, X, Y, W, H)` is documented
  to return non-zero "if the resulting rectangle is different to the
  original". It returns 0 for a box that was clipped, and 1 for one
  wholly inside the clip, on both back ends: the image surface draws
  with Cairo on X11 too. For a box wholly outside the clip it sets `W`
  to 0 and leaves `H` (and possibly `X`, `Y`) unset. Found 2026-10-06.
- **Cause**: `Fl_Cairo_Graphics_Driver::clip_box`
  (`src/drivers/Cairo/Fl_Cairo_Graphics_Driver.cxx`) sets its result by
  comparing the box with the clip rectangle, not the result with the
  box. It returns as soon as `W < 0`, before setting `H`.
- **Effect on ofltk**: `FlDraw.ClipBox` is a proper procedure, giving
  only the rectangle; `ofl_draw_clip_box` drops FLTK's result and zeroes
  its outputs before the call.
- **Confirmed**: a C++ program in the scratchpad (on Wayland and on
  Xvfb), and `TestDraw`'s `ClipBox` checks.

### 3. A key no widget uses crashes when no window is shown

- **What happens**: `Fl::handle(FL_KEYBOARD, window)` for a key the
  focus widget and its parents don't use segfaults in `send_event`, when
  no window is shown and `Fl::belowmouse()` is set. Found 2026-10-06,
  sending synthesized events to a window never shown, on Wayland and
  on X11.
- **Cause**: `Fl::handle_` (`src/Fl.cxx`) then tries the key as a
  shortcut. In `case FL_SHORTCUT`, if the below-mouse widget's window
  isn't `first_window()`, it calls `send_event(FL_SHORTCUT,
  first_window(), first_window())`. With no window shown,
  `first_window()` is 0, and `send_event` calls `handle()` through it.
- **Effect on ofltk**: none on programs, since a real key can't arrive
  while no window is shown. The tests' `Probe.Key` (`test/Probe.cpp`)
  sends a key to the focus widget alone, as `Fl::handle_` does first,
  not through `Fl::handle`.
- **Confirmed**: `TestEvents` crashed this way (backtrace:
  `send_event` from `Fl::handle_` from `Fl::handle_`); source read.

### 4. A text input taking the focus before the display is open crashes (Wayland)

- **What happens**: under Wayland, `take_focus()` on an `Fl_Input`, or
  `Fl::focus()` of one, before any window is shown (so before the
  display is open) segfaults. A plain C++ program that does this before
  `show()`, a common way to choose the first field, crashes; on X11 it
  works. Found 2026-10-06.
- **Cause**: the input's `FL_FOCUS` handling (`Fl_Input_::handletext`)
  calls `Fl_Wayland_Screen_Driver::insertion_point_location`, which uses
  the screen driver's `seat` without checking it, and the seat is only
  set up when the display is opened.
- **Effect on ofltk**: `Widget.TakeFocus` and `Fl.SetFocus` call
  `fl_open_display()` first (`src/Fl.cpp`), which does nothing if the
  display is open.
- **Confirmed**: the C++ program (Wayland crash, X11 fine), and
  `TestInputs`, which gives inputs the focus in a window never shown:
  it crashed this way before the workaround, passes with it, and
  crashes again with it taken out.

## Pitfalls

### 5. FLTK keeps the label pointer it is given

- `Fl_Widget::label(const char *)` (and `tooltip()`, and menu item text)
  stores the pointer, not a copy. An Oberon string may live on the stack
  or the collected heap.
- **ofltk** always uses `copy_label()` and `copy_tooltip()`.

### 6. `Fl_Window::copy_label` hides `Fl_Widget::copy_label`

- It is not virtual. `Fl_Window`'s version also sets a shown window's
  title, but calling a window through an `Fl_Widget *` reaches
  `Fl_Widget`'s, and the title doesn't change.
- **ofltk**: `ofl_widget_copy_label` (`src/Fl.cpp`) calls a window as a
  window, through `as_window()`.

### 7. Replacing auto-deleted user data deletes the old data

- With `AUTO_DELETE_USER_DATA`, FLTK deletes a widget's
  `Fl_Callback_User_Data` when the widget dies (in every way: explicitly,
  with its parent, by `Fl::delete_widget`, a shown window with its
  children), but also when the user data or callback is replaced.
- **ofltk** uses that deletion as its hook (`Ref` in `src/ofltk.h`), so
  replacing the data would unregister a live widget. `ofl::open` sets it
  once, and no C++ code may set the user data or callback again.

### 8. Some box and label types are defined only on first use

- `FL_ROUND_UP_BOX`, `FL_SHADOW_LABEL` and others are macros that call
  `fl_define_FL_ROUND_UP_BOX()` and so on, which register the type's
  drawing code. Their plain values, as an Oberon constant holds them,
  draw nothing until that has been called.
- **ofltk**: `ofl_register` (`src/Fl.cpp`) calls every `fl_define_FL_*`
  function when `Fl` starts.

### 9. A click no widget uses shows the window and becomes `pushed()`

- `Fl::handle_`, `case FL_PUSH` (`src/Fl.cxx`), sets `pushed_` to the
  window before offering the push to its widgets. If none uses it, it
  calls `window->show()` ("raise windows that are clicked on"). A window
  never shown is then shown, and its widgets get `FL_SHOW`.
- **ofltk**: nothing to change; `TestEvents` checks it, last, since it
  shows the window.

### 10. `changed()` is cleared after every callback but FLTK's default

- `Fl_Widget::do_callback` (`src/Fl_Widget.cxx`) calls
  `clear_changed()` after the callback returns, unless the callback is
  `Fl_Widget::default_callback`. A program with its own callbacks sees
  `changed()` only inside them.
- **ofltk** sets its own callback on every widget, so `Widget.Changed`
  is TRUE only inside a `Callback`; its comment says so. Confirmed
  2026-10-06 by `TestButtons`.

### 11. A push button is turned off before its callback

- `Fl_Button::handle`, `case FL_RELEASE` (`src/Fl_Button.cxx`), sets a
  normal button's value back to 0 before calling back, so a `Callback`
  never sees a push button on. Toggle and radio buttons keep their new
  value. Confirmed by `TestButtons`.

### 12. Fl_Slider::bounds hides Fl_Valuator::bounds

- It is not virtual. `Fl_Slider`'s version also asks for a redraw
  (`damage(FL_DAMAGE_EXPOSE)`); called through an `Fl_Valuator *`, a
  slider's new bounds aren't drawn until something else redraws it.
- **ofltk**: `ofl_valuator_bounds` (`src/FlValuators.cpp`) calls a
  slider as a slider. `TestValuators` checks the damage, and fails
  without it.

### 13. Fl_Spinner's color, selection_color and type hide Fl_Widget's

- They are its input field's, and not virtual, so through an
  `Fl_Widget *` they set the group behind the field instead. Its
  `format(const char *)` keeps the pointer, and passes the string to
  `snprintf` as a format, so the string must outlive the spinner and be
  a safe format.
- **ofltk**: `FlValuators.Spinner` overrides `Color`, `SetColor`,
  `SelectionColor` and `SetSelectionColor`, and its `Kind` calls the
  spinner's `type()`. The format is not bound.

### 14. A key event with no text is composed text under Wayland

- `Fl_Wayland_Screen_Driver::compose` returns 1 (text to insert, here
  none) for a key whose `Fl::e_text` is empty, unless the key is a
  modifier, function or cursor key. The window system gives BackSpace
  the text `"\b"`, so a real one works, but a synthesized BackSpace
  with no text deletes nothing. On X11 it works either way.
- **ofltk**: only tests synthesize keys; `TestInputs` sends BackSpace
  with `08X`, as the window system does.

### 15. Enter in an `Fl_Input` calls back only if changed, and selects all

- With `FL_WHEN_ENTER_KEY`, Enter calls back only if the text changed
  since the last callback (`FL_WHEN_ENTER_KEY_ALWAYS` always does), and
  either way puts the cursor at the end and the mark at the start
  (`insert_position(size(), 0)`), so the next key typed replaces all
  the text.
- **ofltk**: nothing to change; `TestInputs` checks both.

### 16. Fl_Value_Input gives the focus to a field FLTK made

- Its `Fl_Input` is a member, not an ofltk widget, so after
  `TakeFocus`, `Fl.Focus()` is NIL (ofltk returns NIL for a widget FLTK
  made). Keys typed go to the field, and set the value.
- **ofltk**: nothing to change; `TestValuators` checks it.

### 17. FLTK needs a display even for widgets never shown

- FLTK opens the display even to draw a widget never shown into an
  `Fl_Image_Surface` (PLAN.md, Phase 0). With none, FLTK prints "Can't
  open display" and exits 1.
- **ofltk**: `make test` refuses to run without `DISPLAY` or
  `WAYLAND_DISPLAY`; `make test-headless` uses Xvfb.

### 18. FLTK prefers Wayland whenever `WAYLAND_DISPLAY` is set

- Even when `DISPLAY` names an Xvfb server, as under a plain `xvfb-run`
  in a Wayland session, FLTK uses the Wayland desktop. With
  `WAYLAND_DISPLAY` unset it uses X11 by itself; `FLTK_BACKEND=x11`
  forces X11.
- **ofltk**: `make test-headless` and `make valgrind-headless` unset it.

### 19. The display stack leaks by design

- A C++ program that deletes all it makes shows about 390 KB "definitely
  lost" under valgrind, in 1,225 (X11) or 8,559 (Wayland) loss records.
  All are allocated by fontconfig and Pango's font cache, and under
  Wayland by GTK's window decorations (libdecor). There are no memory
  errors, on either back end.
- **ofltk**: leaks aren't valgrind errors in `make valgrind`;
  `test/vg-check.sh` fails instead on any leak allocated by ofltk's own
  code.

### 20. `fltk-config --cxxflags` gives more than FLTK's flags

- It includes `-I/usr/include`, which, searched ahead of the C++
  library's own directories, breaks its `#include_next`. It also
  includes Fedora's own build flags (`-specs=...` hardening files).
- **ofltk**: the makefile and `tools/gen-constants.py` pass only its
  `-I` and `-D` flags, without `-I/usr/include`.
