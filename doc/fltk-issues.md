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

Entries keep their numbers, since comments in the code cite them; a
new one takes the next number, in whichever section it belongs.

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

### 21. `Fl_Grid::widget` writes past its rows for a row or column just out of range

- **What happens**: `widget(w, row, col, ...)` documents that it returns
  NULL if `row` or `col` is out of bounds. For `row == rows()` (or
  `col == cols()`) it returns a cell instead, made by reading and
  writing one past the end of the grid's row array. Found 2026-10-06.
- **Cause**: `Fl_Grid::widget(Fl_Widget *, int, int, int, int,
  Fl_Grid_Align)` (`src/Fl_Grid.cxx`) checks `row > rows_` and
  `col > cols_` where `cell()` checks `>=`, then `add_cell(row, col)`
  indexes `Rows_[row]`.
- **Effect on ofltk**: `Grid.PlaceSpan` and `Grid.Place` halt with
  `IndexOutOfRange` unless the whole span is inside the grid, before
  calling FLTK.
- **Confirmed**: a C++ program placing a box at row 2 of a 2 by 2 grid,
  under valgrind: an invalid read and an invalid write of 8 bytes just
  after the block `layout(2, 2)` allocated, and a non-NULL result.
  `test/HaltGridRange.Mod` checks the halt.

### 28. A menu popped up over a window not yet on the screen is fatal (Wayland)

- **What happens**: `Fl_Menu_Button::popup()` just after the window's
  `show()`, before the compositor has put the window on the screen,
  ends the program: FLTK prints "Fatal error no 1 in Wayland protocol:
  xdg_surface" and exits 1. Found 2026-10-06.
- **Cause**: the pop-up's `xdg_popup` is made against a parent surface
  not yet configured, a protocol error the compositor answers by
  disconnecting. FLTK waits for the menu window itself to be exposed
  (`Fl_Wayland_Window_Driver::makeWindow`), but not for its parent.
- **Effect on ofltk**: `MenuButton.Popup` calls `wait_for_expose()` on
  the button's window first, which returns at once once the window is
  there, and on X11; `Window.WaitForExpose` binds it for programs.
- **Confirmed**: a C++ program that shows a window and pops up a menu
  died this way every time; with `wait_for_expose()` between them, three
  runs of three worked. On X11 it works either way. `TestMenus` can't
  check it, since under Wayland the pop-up is closed at once (29).

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

### 22. `Fl_Flex::end` hides `Fl_Group::end`

- It isn't virtual, and it asks for a layout (`need_layout(1)`), so a
  flex ended through an `Fl_Group *` doesn't lay its children out when
  first drawn.
- **ofltk**: `ofl_group_end` (`src/Fl.cpp`) calls a flex as a flex.
  `TestLayout` draws a flex row after `End`, and fails without it.

### 23. `Fl_Group::clear` deletes the parts some groups are made of

- An `Fl_Scroll`'s scrollbars and an `Fl_Spinner`'s field and buttons
  are its children, and members of it, not allocated by themselves;
  `Fl_Group::clear` would `delete` them. `Fl_Scroll::clear` takes the
  scrollbars out first, and `Fl_Pack::clear` also clears the pack's
  `resizable()`, but neither is virtual, so through an `Fl_Group *`
  `Fl_Group::clear` runs instead.
- **ofltk**: `Group.Clear` (`ofl_group_clear` in `src/Fl.cpp`) deletes
  only the children ofltk opened, and clears a pack's `resizable()`.
  `TestLayout` clears a scroll, a spinner and a pack, and checks what
  is left; it fails without the pack's case.

### 24. `Fl_Tile` size ranges set after a move put the children back

- Without size ranges, `move_intersection` moves the children but
  leaves the sizes saved by `init_sizes()` as they were. Once a size
  range is set, `move_intersection` starts from those saved sizes
  (`drag_intersection`), so the next move puts the children back where
  they were first. A plain C++ program: after moving the border from
  150 to 100, setting a range and moving it from 100 to 20 left it at
  150. With the range set first, it stopped at the range, 80.
- **ofltk**: `Tile.SizeRange` and `Tile.InitSizeRange` call
  `init_sizes()` first (`src/FlLayout.cpp`). With ranges, FLTK saves
  the sizes after every move anyway, so that changes nothing else.
  `TestLayout` moves a border, sets a range, and moves it again; it
  fails without the fix.

### 25. `Fl_Pack` sets its own size as it draws

- `Fl_Pack::draw` places the children and then resizes the pack to fit
  them (`Fl_Widget::resize`, `src/Fl_Pack.cxx`): a vertical pack's
  height becomes theirs, plus the spacing. So its size before it is
  first drawn isn't the size it will have, and an image of it made at
  its old size doesn't match it.
- **ofltk**: nothing to change; `TestLayout` allows for it.

### 26. Inserting or removing menu items moves the item chosen

- `Fl_Menu_` keeps the item chosen (`value()`, `mvalue()`) as a pointer
  into its array, and `insert` and `remove` move the items after the
  change along the array without moving it. So inserting an item before
  it makes another item the one chosen, which a choice then shows, and
  removing it leaves it naming the item that took its place. A C++
  program: a choice with "A" and "B", "B" chosen, then "Z" inserted at
  0, had value 1, "A".
- **ofltk**: `ofl_menu_insert`, `ofl_menu_remove` and
  `ofl_menu_clear_submenu` (`src/FlMenus.cpp`) find the item chosen
  again afterwards by its text pointer, each item's own copy, which
  neither moves nor is freed by the change unless it is the item
  removed; then the menu has none chosen. `TestMenus` inserts and
  removes around a choice's value, and fails without it.

### 27. A deleted `global()` menu is used by the next shortcut

- `Fl_Menu_::global()` keeps the menu in a static pointer that nothing
  clears, and adds a handler that uses it for every shortcut no window
  takes. FLTK's documentation says not to destroy the menu. Deleted, it
  is used anyway: valgrind showed invalid reads in the handler
  (`src/Fl_Menu_global.cxx`), in a C++ program.
- **ofltk**: `Menu.Global` uses ofltk's own handler and pointer
  (`src/FlMenus.cpp`), which the menu's class clears in its destructor.
  `TestMenus` deletes a global menu and types its shortcut; without the
  clearing it crashes.

### 29. Under Wayland a pop-up menu of a window without the focus closes at once

- A menu popped up in a window the user hasn't clicked or typed in (so
  without the keyboard focus) is closed by the compositor
  (`popup_done`, in `Fl_Wayland_Window_Driver.cxx`) before it can be
  used, and `popup()` returns NULL. FLTK's own comment there notes that
  sway does the same when an application loses the focus.
- **ofltk**: nothing to change; a real program pops up a menu in answer
  to the user. `TestMenus` checks `Popup` only on X11 (`Probe.Wayland`),
  where `make test-headless` runs it.
- **Confirmed**: a C++ program, after `wait_for_expose()`: under
  Wayland the pop-up returned at once, before the timer that would have
  answered it; on X11 the timer's keys picked an item.

### 30. `fl_file_chooser` keeps its title pointer

- `fl_file_chooser` and `fl_dir_chooser` make one `Fl_File_Chooser` for
  the program, and set its title with `Fl_File_Chooser::label`, which is
  `Fl_Window::label`: it keeps the pointer, so the title outlives the
  call in the hidden window (`src/fl_file_dir.cxx`,
  `src/Fl_File_Chooser.cxx`). The pattern and file name are copied.
- **ofltk**: `ofl_file_chooser` (`src/FlDialogs.cpp`) copies the title
  into a static buffer first. Found in the source; no failure seen.

### 31. The common dialogs take a printf format

- `fl_message`, `fl_alert`, `fl_choice`, `fl_input` and `fl_password`
  take a printf format and arguments, so a message holding a `%` would
  be read as one.
- **ofltk**: `src/FlDialogs.cpp` passes every text as the argument of
  `"%s"`. Found in the header (`__printf__` attributes); `TestDialogs`
  shows "100% done", but doesn't read the text back.

### 32. A key sent from a timer doesn't end a dialog until another event

- `Fl::wait` runs the timers due, then waits for an event. A key sent
  to a dialog from a timer (as the tests answer them) ends its loop only
  when the next event comes, and under Xvfb, with no window manager, none
  does: `fl_show_colormap` handled the Escape but never returned.
  Wayland's compositor sends events that wake it, and a real key is an
  event, so only programs answering their own dialogs meet this.
- **ofltk**: nothing to change. `TestDialogs` fires its timer once more
  after its keys.

### 33. `Fl_Choice::value(int)` hides `Fl_Menu_::value(int)`

- It isn't virtual, and the choice's also redraws, since a choice shows
  its value. Through an `Fl_Menu_ *` a choice shows its old value until
  something else redraws it.
- **ofltk**: `set_value` (`src/FlMenus.cpp`) calls a choice as a
  choice. `TestMenus` checks the damage, and fails without it.

