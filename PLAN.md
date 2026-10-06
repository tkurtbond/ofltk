# ofltk design plan

ofltk is an Oberon-2 binding to FLTK, the Fast Light Toolkit, compiled
with poc, the Peaseblossom Oberon Compiler. `doc/design.md` is the
feasibility analysis that started it (2026-10-06): what was tested, what
broke, and why the binding is worth writing. This file is the design and
roadmap. AGENTS.md has the operational notes: tool paths, build commands,
and the confirmed poc and FLTK facts this plan relies on.

Organize additions by section: append to the relevant section rather than
starting a new document, mark a finished phase `[done]`, and strike
through an open question once it's decided, saying what was decided.

## Prior art

- **FLTKAda** (`/usr/local/sw/src/tkb/fltkada`), a thick Ada binding to
  FLTK, public domain (Unlicense). Its C++ shim (`body/c_fl_*.cpp`, about
  180 classes, 17k lines) flattens FLTK to `extern "C"`, and its
  `doc/binding_architecture.md` explains the `My_X` subclasses that send
  FLTK's virtual `draw()`/`handle()` back into Ada. Its pitfalls (§8) and
  1.4.5 gap analysis (§7) apply to any FLTK binding. Its `test/` has Ada
  ports of FLTK's test programs, a ready list of examples to port.
- **polibfyaml** (`~/Repos/Oberon/polibfyaml`), an Oberon-2 binding to a C
  library with poc. Its build, test layout, halt tests, valgrind setup and
  conventions are this repo's model; its AGENTS.md lists poc facts that
  still apply (AGENTS.md here repeats the ones that matter).
- **The prototype** (`prototype/`) and **probes** (`probes/`): the code
  behind `doc/design.md`. Throwaway, but the starting point for Phase 0.

## Scope

In scope: an Oberon-2-idiomatic binding to the parts of FLTK 1.4 an
application uses:
- widgets, groups and windows;
- the event loop, timeouts, idle and file-descriptor callbacks;
- custom widgets (overriding draw, handle and resize);
- the drawing API, menus, dialogs, text editing, browsers, images, and
  the clipboard.

Out of scope, at least at first:
- **Threads** (`Fl::lock`, `Fl::awake`): poc's collector scans one stack.
- **OpenGL and GLUT.**
- **Printing and the file surfaces** (PDF, EPS, SVG).
- **`Fl_Terminal`**: a large API, and FLTKAda hasn't bound it either.
- **The platform graphics drivers and the FLTK 1.3 API.**

Later, if wanted: a FLUID back end that writes Oberon-2 instead of C++.

## Target versions

- FLTK **1.4.5** (Fedora `fltk-devel-1.4.5`; source in
  `/usr/local/sw/src/lang/C++/fltk`). 1.4 is required: `Fl_Flex`,
  `Fl_Grid`, and `AUTO_DELETE_USER_DATA` (the deletion hook below) are
  new in 1.4.
- poc **0.3.1** or later. A poc release is being prepared (2026-10-06)
  that lets a library record its native link flags and accepts a C++
  module part (AGENTS.md, "poc friction"). Adopt both when it is
  installed; until then use the 0.3.1 workarounds.
- Platforms: x86_64 Fedora first, under Wayland and X11. The BSDs poc runs
  on come later; FLTKAda's readme has NetBSD notes.

## Architecture

```
application modules           (Oberon-2; extend Fl types, override methods)
        |
ofltk modules  Fl, FlDraw, ...      (Oberon-2: objects, registry, policy)
        |      ["C"] procedures, unexported
C++ parts      Fl.c, FlDraw.c, ...  (extern "C" shim, My_X subclasses)
        |
FLTK 1.4 (C++)
```

### Modules

Oberon modules are flat, and a type-bound procedure must be declared in
its receiver type's module, so each module holds a family of widget types
together with their methods and their part of the shim:

| Module | Contents |
|---|---|
| `Fl` | `Widget`, `Group`, `Window`, `DoubleWindow`, `Box`; the registry; the event loop, timeouts, idle and fd callbacks; colors, fonts, box and label types; event queries (`Fl::event_x` and friends); schemes |
| `FlDraw` | the `fl_draw.H` API: colors, lines, shapes, text, fonts, clipping, measuring, offscreen |
| `FlButtons` | `Button`, `CheckButton`, `LightButton`, `RoundButton`, `RadioButton`, `ReturnButton`, `RepeatButton`, `ToggleButton` |
| `FlInputs` | `Input`, `IntInput`, `FloatInput`, `MultilineInput`, `SecretInput`, `Output`, `MultilineOutput` |
| `FlValuators` | `Slider` (and its kinds), `Counter`, `Dial`, `Roller`, `Spinner`, `Adjuster`, `ValueInput`, `ValueOutput`, `Scrollbar`, `Progress` |
| `FlLayout` | `Flex`, `Grid`, `Pack`, `Scroll`, `Tabs`, `Tile`, `Wizard` |
| `FlMenus` | `MenuBar`, `MenuButton`, `Choice`, menu items |
| `FlDialogs` | `fl_alert`/`fl_ask`/`fl_choice`/`fl_input`, `NativeFileChooser`, `FileChooser`, `ColorChooser` |
| `FlText` | `TextBuffer`, `TextDisplay`, `TextEditor`, style tables |
| `FlBrowsers` | `Browser`, `HoldBrowser`, `MultiBrowser`, `SelectBrowser`, `CheckBrowser`, `FileBrowser`, `Tree` |
| `FlImages` | `Image`, `RGBImage`, PNG, JPEG, GIF, SVG, BMP, XPM loading (`-lfltk_images`) |

`Fl` exports a few procedures that only the other ofltk modules should
use (attaching a new widget's handle, registering it), as polibfyaml's
`Fyaml` exports its "For FyamlStreams" hooks: Oberon has no friend
modules. Mark them so in their comments, and keep application code off
them.

### Object model

- `Widget* = POINTER TO WidgetDesc`. The record holds the C++ handle as a
  read-only `SYSTEM.ADDRESS`, plus a registry link. Each FLTK class is an
  extension; an application extends those in turn.
- **Construction**: `NEW(w); FlButtons.OpenButton(w, x, y, w, h, label)`
  style, so an application's own extension can be allocated by its own
  `NEW` and still be opened as the FLTK class it extends. The prototype
  already works this way. FLTKAda's `Forge` packages solve the same
  problem in Ada.
- **Groups**: FLTK's implicit `begin()`/`end()` "current group" is kept,
  because FLTK's own docs and examples assume it. Explicit `Add`/`Insert`
  are bound too.
- **Overridable behaviour** is type-bound procedures:
  - `Draw`, `Handle(event): BOOLEAN` and `Resize(x, y, w, h)` are called
    by FLTK through a `My_X` C++ subclass. Each shim class also gives the
    base class's own `draw`/`handle` (qualified, so not virtual) for the
    default method to call, FLTKAda's `fl_box_draw` pattern.
  - `Callback` is FLTK's "when" callback. The default `Callback` calls
    the widget's `action` field, a procedure value, if it is set. So
    simple programs need no extension, and extending programs override
    `Callback`.
- **Dispatch from C++ to Oberon**: one dispatcher per hook kind (draw,
  handle, resize, callback, deleted, ...), each an Oberon procedure that
  C++ calls with the widget's `user_data()`. Prefer registering their
  addresses from `Fl`'s body (the prototype's way, which uses only
  documented poc behaviour) over naming poc's symbols from C++ (AGENTS.md:
  it works in 0.3.1 but isn't promised).

### Lifetime and the collector

This is the hard part; `doc/design.md` has the failures that motivate it.

- **FLTK owns widgets.** A widget lives until it is deleted: explicitly,
  or with its parent group. An Oberon `Widget` lives at least as long as
  its C++ widget. This is the reverse of FLTKAda, where an Ada controlled
  object owns and frees its C++ widget, because a garbage collector's
  finalizer runs at no predictable time and must not delete a visible
  widget.
- **The registry.** Every opened widget is reachable from a module-level
  root in `Fl` until its C++ widget is destroyed, since poc's collector
  never sees pointers that only C++ memory holds. It is a doubly linked
  list (the prototype's singly linked one was O(n) to remove from).
- **The deletion hook.** `user_data()` points at a small C++ object,
  derived from `Fl_Callback_User_Data`, that holds the Oberon widget's
  address. With `AUTO_DELETE_USER_DATA`, FLTK deletes it when the widget
  is destroyed, for every class and however the widget died (explicitly,
  with its parent, or by `Fl::delete_widget` after a callback). Its
  destructor tells `Fl` to unregister the widget and zero its handle. The
  `My_X` subclasses then need no destructors of their own.
  - Confirmed in Phase 0 for all of these, and for a shown window.
    Replacing the user data also deletes the old one, so it is set once.
  - **For each class bound**, check in the FLTK source that the class
    doesn't set its own `user_data()` or callback. If it does, the
    deletion hook would be lost.
- **Dead handles.** A method of a widget that isn't open (never opened,
  or deleted) is a programmer error, `ASSERT` code 70 (see "Halt codes").
  `IsOpen()` lets a program ask first. This replaces the prototype's
  silent no-op `Redraw`.
- **Deleting during a dispatch** goes through `Fl::delete_widget`
  (deferred), as FLTKAda's `fl_inside_callback` guard does. A dispatch is
  a `Callback`, `Draw`, `Handle` or `Fire`, counted in `ofl::depth`. At
  any other time `Delete` deletes at once.
- **Resources Oberon owns** (`TextBuffer`, `Image`, `Preferences`) follow
  polibfyaml's `Document` rule:
  - explicit `Close` as the primary cleanup, idempotent, setting the
    handle to 0;
  - a finalizer as a backstop;
  - every widget using one keeps an Oberon reference to it, so it can't
    be collected while attached. For example, a `TextDisplay` keeps its
    `TextBuffer`.

### Strings and memory handed to FLTK

- **Labels, tooltips and window titles are always copied**
  (`copy_label`, `copy_tooltip`). FLTK's `label()` keeps the pointer, and
  an Oberon string may be a value parameter copied into a frame that dies
  on return. Valgrind can't see that bug (polibfyaml, "Buffer lifetime").
- **Any other pointer FLTK keeps is either copied by FLTK or owned by an
  Oberon object that outlives the FLTK object.** Before binding a call
  that takes a pointer, find out from the FLTK source which it is.
  Examples:
  - `Fl_RGB_Image`'s pixel data is not copied unless `alloc_array` is set;
  - `Fl_Menu_::add` copies its text.
- **Strings coming back** (`Input::value`, a text buffer's text) are
  copied into a `VAR ARRAY OF CHAR`, or returned as a
  `POINTER TO ARRAY OF CHAR`. Anything FLTK returns that the caller must
  free is freed in the shim.
- Text is UTF-8 bytes in `CHAR` arrays; FLTK's `fl_utf8*` helpers can be
  bound as needed.

### Types at the C boundary

- **Size model: `-OC`** (as polibfyaml chose): `INTEGER` is C's
  `int`, which is what every FLTK coordinate, size and enum is, and
  `LONGINT` is 64 bits. Code using ofltk must be built `-OC` too.
- The shim's `extern "C"` functions use only `int32_t`, `uint32_t`,
  `intptr_t` and `double`. On the Oberon side they are `SYSTEM.INT32`,
  `SYSTEM.ADDRESS` and `LONGREAL`, whatever the model.
  - **No `BOOLEAN` crosses**: use `int32_t` 0 or 1.
  - **No C struct is mirrored as an Oberon record**: read fields in the
    shim.
- `Fl_Color` is an unsigned 32-bit `RGBI` value: an `INTEGER` (or
  `SYSTEM.INT32`) in Oberon, with `Fl.RGB(r, g, b)` building one.
- Enum and flag values are exported Oberon constants, written by
  `tools/gen-constants.py`, which takes each value from the installed
  FLTK's headers. The same script writes `TestConstants`, which checks
  each Oberon constant against a table compiled against the current
  headers. So a changed FLTK value fails `make test`, a removed one fails
  the build, and running the script again picks up the change. A constant
  FLTK adds appears only once it is added to the script's list.
- Bit-flag enums (`when`, damage, menu flags, alignment) are `SET`s where
  every bit is below 32; otherwise integers with documented constants. A
  `SET` crosses to C as `SYSTEM.VAL(SYSTEM.INT32, s)`, not `ORD(s)`
  (AGENTS.md, "poc 0.3.1 problems").
- **Names.** FLTK's names in Oberon case, without `FL_`: `UpBox`,
  `AlignTopLeft`, `HelveticaBold`, `DarkRed`, `WhenRelease`. Two
  exceptions avoid clashes:
  - events take the prefix `Ev` (`EvPush`, `EvFocus`), because
    `Fl::focus()` and `Fl::paste()` will be procedures `Focus` and
    `Paste`;
  - a widget's `box()` is `BoxType`/`SetBoxType`, since `Box` is a type,
    and `Fl::set_color` is `SetIndexColor`, so it doesn't read as a
    widget's `SetColor`.
- **Box and label types that FLTK defines on first use** (the macro
  `FL_ROUND_UP_BOX` is a call of `fl_define_FL_ROUND_UP_BOX()`) are all
  defined when Fl starts, so their constants are plain values.

### Halt codes

Programmer errors halt, as in polibfyaml. poc's `ASSERT(x, n)` prints
`assertion failed (n)` and exits with status 10. Codes:

| Code | Meaning |
|---|---|
| 70 | a method of a widget that isn't open: never opened, or deleted (`Fl.NotOpen`) |
| 71 | a widget opened twice (`Fl.OpenedTwice`) |
| 72 | a NIL argument where a widget or timer is required (`Fl.NilArgument`) |
| 73 | a closed resource used |
| 74 | an index out of range: group child, browser line, menu item (`Fl.IndexOutOfRange`) |
| 75 | `RepeatTimeout` outside its own timer's `Fire` (`Fl.NotFiring`) |

Bad data from outside the program is never a halt: an image that fails
to load, a file chooser cancelled. Those come back as `BOOLEAN` results.

## Build and test

`GNUmakefile`, modelled on polibfyaml's:
- `make`, `make test`, `make valgrind`, `make clean`; later
  `make install`/`uninstall` (the poc library `ofltk`, `-OC`);
- output in `build/`, `.NOTPARALLEL`;
- `fltk-config`'s `-I`/`-D` flags and `--ldflags`, passed as
  `-c-flag`/`-link`;
- C++ parts are `src/<Module>.cpp`, as poc 0.4.0 takes them. With an
  older poc, detected from `poc -version`, the makefile stages each
  module into `build/src/` with its part renamed `.c`, and adds
  `-c-flag -xc++ -link -lstdc++`.

Tests need a display. FLTK 1.4 opens one even to draw offscreen.

- **Where tests run.** `make test` needs `DISPLAY` or `WAYLAND_DISPLAY`
  and stops with a message if neither is set. `make test-headless` and
  `make valgrind-headless` run them on Xvfb: `xvfb-run` (package
  `xorg-x11-server-Xvfb`) with `WAYLAND_DISPLAY` unset. FLTK prefers
  Wayland whenever `WAYLAND_DISPLAY` is set, even under `xvfb-run`, which
  sets only `DISPLAY`. Unset, FLTK uses X11 by itself; `FLTK_BACKEND=x11`
  forces X11 regardless.
- **Behaviour tests** need no clicks. They drive the program the way the
  prototype's `Demo` does:
  - `do_callback`, and `Fl::handle` with synthesized events;
  - `Fl::add_timeout` to sequence steps;
  - `Fl::check`/`Fl::wait(0)` to let FLTK process;
  - each test hides its windows and exits, under a timeout.
- **Drawing tests** render a widget into an `Fl_Image_Surface` and check
  pixels, so `Draw` overrides are tested by value, not by eye.
- **Liveness tests** force `GarbageCollectedHeap.Collect` between steps.
  They check that widgets held only by FLTK survive, and that deleted
  ones leave the registry (`Fl.OpenWidgets`).
- **Halt tests**: one small program per code, as `test/Halt*.Mod`.
- **Valgrind**: polibfyaml's `poc-gc.supp`, and no suppressions for
  FLTK, whose display stack leaks too much to list (Phase 0). Memory
  errors fail a test. Leaks don't count as valgrind errors; instead
  `test/vg-check.sh` fails on any leaked block whose allocator is
  ofltk's own code.
- **Examples**: ports of FLTK's `test/` and `examples/` programs, taking
  FLTKAda's ports as a checklist. Each one that can end by itself is run
  by `make test`.

## Phased roadmap

Each phase ends with every test passing, `make valgrind` clean, and its
findings written into this file and AGENTS.md.

0. **`[done]` Skeleton and the deciding experiments** (2026-10-06, poc
   0.3.1, FLTK 1.4.5, Fedora 44 under Wayland).
   - `GNUmakefile` (see "Build and test"), `build/` in `.gitignore`,
     `test/Check.Mod` and `test/poc-gc.supp` from polibfyaml, and
     `test/vg-check.sh`.
   - `src/Fl.Mod`, `src/Fl.cpp` and `src/ofltk.h`: the core of Phase 1,
     enough to test the object model. It has:
     - `Widget`, `Group`, `Window`, `DoubleWindow`, `Box`;
     - the registry, a doubly linked list, and the deletion hook;
     - `Callback` and `action`, `Draw`, `Handle`;
     - `Child`, which finds a child's Oberon object through FLTK;
     - labels (copied), geometry, show, hide;
     - `Run`, `Check`, `Wait`, and `Timer` with add, repeat and remove.
   - Tests: `TestLiveness` (5 checks), `TestDelete` (12), `TestTimer`
     (8), and 6 halt tests, one per code 70, 71, 72, 74 and 75 (70
     twice). All pass under Wayland and under `FLTK_BACKEND=x11`, and
     `make valgrind` is clean: 0 errors.
   - **The tests catch what they're for.** In a scratch copy:
     - with the registry no longer a root, `TestLiveness` failed and then
       crashed calling a freed object's callback, the original bug;
     - with `AUTO_DELETE_USER_DATA` off, 9 checks failed;
     - a program that never deletes its box failed `make valgrind`.

   Findings, confirmed live (C++ programs in the scratchpad, then the
   tests above):
   - **The deletion hook covers every way a widget dies**:
     - explicit `delete`;
     - with its parent group, at any depth;
     - `Fl::delete_widget` from inside its own callback, at the next
       `Fl::check`;
     - a shown top-level window, with its children.
   - **Replacing a widget's user data deletes the old one** (FLTK frees
     the previous `Fl_Callback_User_Data`), which would unregister a live
     widget. So `ofl::open` sets it once, and nothing sets it again.
   - **The callback must be ofltk's for every widget**, so FLTK's own
     defaults are bound for the Oberon defaults to call:
     `Fl_Widget::default_callback` queues the widget for
     `Fl::readqueue`, and `Fl_Window::default_callback` calls
     `Fl::atclose`, which hides the window.
   - **`FLTK_BACKEND=x11` switches FLTK 1.4.5 to X11**, checked with
     `fl_x11_display()`/`fl_wl_display()`; here it goes through XWayland.
     With no display at all, FLTK prints "Can't open display" and exits
     1.
   - **Headless runs work on Xvfb**, and the tests pass there, including
     under valgrind. But a plain `xvfb-run` in a Wayland session leaves
     `WAYLAND_DISPLAY` set, and FLTK then quietly uses the real desktop.
     Hence `make test-headless`, which unsets it.
   - **Pixel checks work**: a widget never shown, drawn into an
     `Fl_Image_Surface`, reads back exactly (`FL_RED` is 255,0,0), under
     both back ends. Binding it is Phase 2's.
   - **FLTK's display stack leaks by design.** A C++ program that deletes
     everything it makes shows about 390 KB "definitely lost" and 1,225
     (X11) or 8,559 (Wayland) loss records, all allocated by fontconfig
     and Pango's font cache, and under Wayland by GTK's window
     decorations. It shows **no memory errors** on either back end. Hence
     `vg-check.sh`'s rule above, rather than suppressions.
   - `fltk-config --cxxflags` includes `-I/usr/include` and Fedora's
     build flags, so the makefile passes only its `-I`/`-D` flags, without
     `-I/usr/include`.

   Not done, and why:
   - `prototype/` stays. Its custom drawing (Phase 2's `FlDraw`) and
     buttons (Phase 3's `FlButtons`) are not in `src/` yet. Retire it
     when they are.
1. **`[done]` Core object model** (`Fl`; 2026-10-06, poc 0.3.1). On top of
   Phase 0's core:
   - **Constants**: 188 of them (events, when, box types, label types,
     alignment, fonts, colors), from `tools/gen-constants.py`.
   - **Widget**:
     - label font, size, color and type; box type;
     - color and selection color; alignment; `when`;
     - activate, deactivate, `Active`, `ActiveR`, `VisibleR`;
     - tooltips (copied); position and size; `Parent`.
   - **Group**: `Add`, `Insert`, `Remove`, `Find`, `Clear` (deferred
     inside a dispatch, like `Delete`), resizable.
   - **Window**: `Shown`, `SizeRange`, modal and non-modal, fullscreen.
     The title is the label, set through `Fl_Window::copy_label`.
   - **Colors**: `RGB`, `GrayRamp`, `ColorCube` (in Oberon, checked
     against C), `SetIndexColor`, `GetRGB`, background, background2 and
     foreground, `ColorAverage`, `Lighter`, `Darker`, `Contrast`,
     `Inactive`.
   - **Other globals**: `NormalSize`, schemes.
   - **Tests**:
     - `TestConstants` (196 values; a deliberately wrong constant fails
       it and is named);
     - `TestWidget` (33 checks).

     All pass on Wayland, on Xvfb, and under valgrind (0 errors).
   - **Example**: `examples/Hello.Mod`, FLTK's `test/hello.cxx`, built by
     `make`. A screenshot under Xvfb showed it as FLTK draws it: an up
     box, and a bold italic shadow label of size 36.
   - **Found**: poc 0.3.1 can't compile `ORD` of a `SET` under `-OC`. Any
     use emits LLVM `trunc i32 to i32`, which clang rejects; `-O2` is
     fine. `SYSTEM.VAL(SYSTEM.INT32, s)` gives the same bits, and is used
     instead (AGENTS.md, "poc 0.3.1 problems").
   - **Left for later**:
     - `Fl_Window` icons, `xclass`, and border control;
     - `Fl::readqueue`;
     - multi, icon and image labels, which come with images in Phase 7;
     - the prototype's demo, which needs Phase 2's drawing and Phase 3's
       buttons.
2. **Custom widgets and drawing** (`Fl`, `FlDraw`):
   - `Draw`/`Handle`/`Resize` overrides, through a C++ template that
     makes `My_X` for any class;
   - event queries; the `fl_draw.H` API.

   Tests: pixels of a custom `Draw`; synthesized events reaching `Handle`.
3. **Buttons, inputs and valuators** (`FlButtons`, `FlInputs`,
   `FlValuators`). Values in and out, `when` flags, radio groups.
4. **Layout** (`FlLayout`): `Flex` and `Grid` first, then `Pack`,
   `Scroll`, `Tabs`, `Tile`, `Wizard`, and `resizable`.
5. **Menus and dialogs** (`FlMenus`, `FlDialogs`). Each menu item's
   callback reaches an Oberon procedure or method; FLTKAda's
   `menu_item_callback_hook` and its `test_shortcut` pitfall apply.
   Dialogs return their results; a cancel is not an error.
6. **Text and browsers** (`FlText`, `FlBrowsers`):
   - `TextBuffer` as an Oberon-owned resource; `TextDisplay`,
     `TextEditor`, style buffers;
   - the browser family; `Tree`, following FLTKAda's
     `experimental/fl-tree-binding` scope.
7. **Images and the rest** (`FlImages`, `Fl`):
   - shared and RGB images (data copied);
   - the clipboard, drag and drop, `Preferences`, `NativeFileChooser`,
     `Table`.
8. **Release.** README, `make install` as a poc library, the examples
   complete, and the poc-release flags (native link dependencies, C++
   parts) adopted.

## Open questions

Decided 2026-10-06, with the user, as recommended when this plan was
written:

- ~~**Vendor FLTKAda's shim, or write ofltk's own?**~~ Decided: ofltk's
  own shim, using FLTKAda's as the reference for each class and copying
  its code where it fits (it is public domain).
  - Vendoring would have given about 180 bound classes at once, with
    ofltk defining the 33 `*_hook` symbols in one C++ file. But its
    lifecycle is shaped for Ada controlled types: the
    `*_extra_init_hook` calls, per-type `Draw_Ptr`, and Ada owning and
    freeing the C++ widget. It also has gaps against FLTK 1.4.
  - An own shim follows this plan's ownership model and is smaller per
    class through a `My_X` template.
- ~~**Module split.**~~ Decided: the table under "Modules", with one C++
  part per module, beside it.
- ~~**Size model.**~~ Decided: `-OC` (see "Types at the C boundary").
- ~~**Callbacks as methods only, or `action` too?**~~ Decided: both. The
  default `Callback` method calls `action` when it is set.
- ~~**Constructor naming.**~~ Decided: a plain procedure per class,
  `OpenButton(b, ...)`. A type-bound `Open` can't be redefined with
  different parameters in an extension.
- ~~**Halt code range.**~~ Decided: 70–79 (see "Halt codes"), clear of
  polibfyaml's 61–64 so a program using both can tell them apart.

Still open:

- **How much of `fl_draw.H` to bind before it's needed**: all of the
  common calls in Phase 2, or only what the examples use.
