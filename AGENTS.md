# AGENTS.md

pofltk is an Oberon-2 binding to FLTK 1.4, the Fast Light Toolkit, compiled
with poc, the Peaseblossom Oberon Compiler. PLAN.md is the design and
roadmap; `doc/design.md` is the feasibility analysis that started it;
`doc/fltk-issues.md` lists the FLTK bugs and pitfalls found so far. This
file is operational notes for an agent working in this repo, not a design
doc.

Two existing projects shape this one; read their notes before redesigning
anything:

- **FLTKAda** (`/usr/local/sw/src/tkb/fltkada`): the user's fork of a thick
  Ada binding to FLTK. Its `doc/binding_architecture.md` explains how FLTK's
  virtual `draw()`/`handle()` are sent back into the host language, and
  lists FLTK pitfalls. Its C++ shim (`body/c_fl_*.cpp`, public domain) is
  the reference for binding any class.
- **polibfyaml** (`~/Repos/Oberon/polibfyaml`): an Oberon-2 binding to a C
  library with poc. Its build, tests, valgrind setup and conventions are
  this repo's model, and its AGENTS.md holds hard-won poc facts.

## Status

As of 2026-10-07, Phases 0 to 13 of PLAN.md are done, and `README.md`
is the user's guide. Phases 9 to 13 (planned 2026-10-07) ported the rest
of FLTK's `examples/` and bound what they needed. `src/` has the `Fl`, `FlDraw`, `FlButtons`,
`FlInputs`, `FlValuators`, `FlLayout`, `FlMenus`, `FlDialogs`, `FlText`,
`FlBrowsers`, `FlImages`, `FlPreferences` and `FlTable` modules, and the
tests pass. Also kept:

- `doc/design.md`: the feasibility analysis.
- `doc/fltk-issues.md`: every FLTK bug and pitfall found, with its
  cause in FLTK's source and pofltk's workaround.
- `prototype/` was retired in Phase 3, when `src/` had all it had; it
  is in git up to commit f57262b. Its demo is `examples/Swatch.Mod`.
- `probes/callback/`: C calling an Oberon procedure value.
- `probes/gc-hazard/`: a flat binding (`Fltk.Mod`, `Fltk.cpp`). `Hazard.Mod`
  shows a callback's `user_data` being collected; `Hello.Mod` is a
  one-button window that waits for real clicks.

The project was called ofltk until 2026-10-07, when it was renamed
pofltk (PLAN.md, "Rename to pofltk"). PLAN.md's phases, its open
questions and `doc/design.md` keep the old name, as history. The `ofl`
prefix of the C++ parts (`ofl::`, `ofl_`) was kept.

## Layout

- `src/pofltk.h`: what every module's C++ part shares:
  - `ofl::W<B>`, the FLTK class `B` with `draw()`, `handle()` and
    `resize()` sent to Oberon;
  - `ofl::Hooks`, through which Oberon reaches `B`'s own `draw()`,
    `handle()` and `resize()`, and `Fl_Widget`'s protected `draw_box()`,
    `draw_label()` and `draw_focus()`;
  - `ofl::open`, which attaches a widget to its Oberon object;
  - the `Ref` user data, whose destructor is the deletion hook, and
    which holds the images and multi-label a widget shows (its slots),
    and any number of things beside (`keep`, for a browser's line
    icons and a menu's item labels), let go by `drop_unused`;
  - `ofl::Shared`, a reference count for what widgets share (images,
    multi-labels);
  - `ofl::ItemLabel`, a menu item's image or multi-label, which keeps
    the item's text (`doc/fltk-issues.md`, 54);
  - `ofl::label_text`, which every label goes through ("" is none);
  - the dispatch depth.
- `src/Fl.Mod`, `src/Fl.cpp`: the core module. Its "For pofltk's modules
  only" procedures (`BeginOpen`, `EndOpen`) are how another module
  opens a widget of its own class. Keep application code off them.
- `src/FlDraw.Mod`, `src/FlDraw.cpp`: `fl_draw.H`, for `Draw` methods.
- `src/FlButtons`, `src/FlInputs`, `src/FlValuators`, `src/FlLayout`,
  `src/FlMenus`, `src/FlText`, `src/FlBrowsers` (`.Mod` and `.cpp`):
  the widget families of PLAN.md's module table. Each C++ part
  has one `ofl_<family>_new(kind, ...)` that makes the class `kind`
  numbers as `ofl::W<class>`, copies the label and calls `ofl::open`;
  each Oberon `Open<Type>` passes it `Fl.BeginOpen(w)` and gives the
  result to `Fl.EndOpen`. Methods get the handle with `Fl.Live(w)`.
- `src/FlDialogs.Mod`, `src/FlDialogs.cpp`: FLTK's common dialogs,
  procedures with no widget of their own, and `NativeFileChooser`. A
  test turns zenity, kdialog and GTK off (`Fl.SetOption`), so the
  chooser is FLTK's and keys can answer it.
- `src/FlImages.Mod`, `src/FlImages.cpp`: images (loaded by their
  contents, not their names, or from RGB pixels, which are copied),
  widgets' images, image surfaces, and images on the clipboard. It
  links `-lfltk_images`.
- `src/FlBrowsers.cpp`'s tree: `Tr` is the tree's class, which hears
  a widget leave it (`on_remove`) and forgets a removed last-clicked
  item after each event (`handle`); `Mine` is an item the program
  made, whose `draw_item_content` is sent to Oberon through a
  dispatcher FlBrowsers' body registers (`ofl_tree_register`), and
  whose destructor drops the Oberon object from FlBrowsers' `made`
  list. A private member is reached, where nothing else will do, by an
  explicit instantiation (`Reach`, for `Fl_Tree::_lastselect`).
- `src/FlPreferences.Mod`, `src/FlPreferences.cpp`: `Fl_Preferences`. A
  group is its database and a path, not an `Fl_Preferences` kept.
- `src/FlTable.Mod`, `src/FlTable.cpp`: `Fl_Table` and `Fl_Table_Row`.
  `draw_cell` is a fourth virtual sent to Oberon, through a dispatcher
  FlTable's body registers (`ofl_table_register`), as Fl's body
  registers `Draw`'s.
- **What a widget's C++ part keeps beside FLTK's object** goes in a base
  class listed before `ofl::W<B>`, so it is destroyed after FLTK's
  object, and is reached by `dynamic_cast`: `Holds` (`FlText`: the
  buffers a display shows), `Keeps` (`FlBrowsers`: copies of pointers
  FLTK keeps), `Items` (`FlBrowsers`: a tree's live items, and which
  item shows each widget). Never
  `static_cast` an `ofl::widget` to a template class: the kind decides
  which instance it is.
- `test/`:
  - one main module per concern, `Test*.Mod`, using `Check.Mod`;
  - halt tests, `Halt*.Mod`, one per code;
  - `poc-gc.supp`, and `vg-check.sh` (Valgrind, below);
  - `TestConstants.Mod`, `CConstants.Mod` and `CConstants.cpp`, written
    by `tools/gen-constants.py`. `CConstants` is a test module with a C++
    part;
  - `Probe.Mod` and `Probe.cpp`, a test module with a C++ part: a
    widget's pixels, captured into an `Fl_Image_Surface`; mouse, wheel
    and key events sent as the window system would; the modal window (a
    dialog) and keys sent to it; whether FLTK uses Wayland; and how
    many things a widget keeps (`Kept`, `Ref::keep`); and pipes
    (`Pipe`, `Write`, `Read`, `Close`), for `TestLoop`'s fd watches.
  - `images/`: one 4x2 image, red left and blue right, in each format
    `TestImages` reads; and `anim.gif`, three frames of it, for
    `TestAnimGIF`;
  - `names/`: empty files whose names each directory sort orders
    differently (`TestDialogs`, `TestBrowsers`).
- `tools/gen-constants.py`: writes each module's constants and their
  test, from FLTK's headers (constants, below).
- `tools/with-sway.sh`: runs a command on a headless sway (`make
  test-sway`, below).
- `examples/`: example programs (`Hello`, FLTK's hello; `Scribble`,
  drawing with the mouse; `Swatch`, the prototype's demo; `Menus`, a
  menu bar, a choice and the dialogs; and ports of FLTK's `examples/`,
  named for FLTK's file in CamelCase without `howto-`). A port is
  checked against FLTK's own build of it (in FLTK's `examples/`): both
  run under Xvfb, driven by the same `xdotool` input, and their screens
  compared (`magick compare -metric AE -fuzz 1%`). On Xvfb with no
  window manager a window sits 20 pixels below its y, so add 20 to a
  click's y. `make` builds them. They wait for the user, so
  `make test` runs each for `EXAMPLETIME` seconds and checks it is still
  running then. `Pipe.Mod` and `Pipe.cpp` are an example module with a
  C++ part (`popen`), listed in `EXAMPLECXX`; examples are built with
  `-import-path examples` to find it.
- `GNUmakefile`: build and test (Build, below).
- `build/`: poc and clang output (ignored by git).
- `PLAN.md`: design, decisions and findings, by section and phase.
- `README.md`: for the binding's users: building, installing, the
  modules and concepts. Keep its example the same as `examples/Hello.Mod`.

## Reference material

| What | Where |
|---|---|
| FLTK headers (1.4.5) | `/usr/include/FL/` (`fltk-devel-1.4.5`); flags from `fltk-config --cxxflags`/`--ldflags` (`-lfltk`) |
| FLTK source (1.4.5) | `/usr/local/sw/src/lang/C++/fltk/fltk-1.4.5/` (`src/`, `FL/`, `test/`, `examples/`) |
| FLTK docs (HTML) | `/usr/share/doc/fltk-devel/html/` |
| FLTK 1.3 | also installed (`fltk1.3`, runtime only); never build against it |
| FLUID | `fltk-fluid-1.4.5` |
| poc | `/usr/bin/poc` (Peaseblossom RPM 0.4.1); `poc(1)`; `/usr/share/doc/peaseblossom/users-guide.md` (§9, "Calling C") and `reference-guide.md` |
| poc source | `~/Repos/Oberon/Peaseblossom` |
| FLTKAda | `/usr/local/sw/src/tkb/fltkada` (`AGENTS.md`, `doc/binding_architecture.md`, `progress.txt`, `test/`) |
| polibfyaml | `~/Repos/Oberon/polibfyaml` (`AGENTS.md`, `GNUmakefile`, `test/Check.Mod`, `test/poc-gc.supp`) |
| Oberon-2 report | `~/Reference/Computer/Languages/Oberon/Oberon2.pdf` |
| Installed poc libraries | `/usr/local/sw/versions/oberon/poc/lib` (`POC_OBERON_LIBRARIES` in polibfyaml's makefile) |

Before assuming an FLTK function is missing or behaves as its header
comment says, check the source: FLTKAda's notes record several header
comments that are wrong.

## Build

```sh
make            # the test programs, into build/
make test       # every test, halt test and example; needs a display
make valgrind   # the tests under valgrind, then test/vg-check.sh on each log
make test-headless      # make test on Xvfb, not the desktop
make valgrind-headless  # make valgrind on Xvfb
make test-sway          # make test on Wayland, on a headless sway
make valgrind-sway      # make valgrind on a headless sway
make clean      # rm -rf build
```

- `make POC=/path/to/poc` uses another poc.
- **A new test** needs its name added to `TESTS`, a halt test to
  `HALTTESTS` (as `name:code`). `TestArgs` alone is given a command
  line, `TESTARGS`, by both test loops.
- **A new module** needs its name added to `MODULES`, and a new header to
  `HEADERS`. A test module with a C++ part goes in `TESTCXX`, an example
  in `EXAMPLES`, and an example's module with a C++ part in
  `EXAMPLECXX`. `EXAMPLES` is one long line: edit it by matching its
  text, as `sed 's/^\(EXAMPLES := .*Last\)$/\1 New/'`, not by line
  number. An example that needs a command line under `make test` gets
  one in `EXAMPLEARGS`, as `name=argument`.
- **Constants**: never edit the block of a module between
  `BEGIN generated constants` and `END generated constants`. Add the
  name and C expression to `SPEC` in `tools/gen-constants.py`, after
  the `module(...)` line naming the module (whose source must already
  have the empty block), then run
  `python3 tools/gen-constants.py` from the repository root (it needs
  `clang++` and `fltk-config`). After an FLTK upgrade, run it again, and
  read the diff: `TestConstants` fails until you do if a value moved.
- **C++ parts are `src/<Module>.cpp`**, compiled by clang++, which also
  links any program that has one. That needs poc 0.4.0, and `ORD` of a
  `SET` needs 0.4.1, which the makefile requires.
- The C++ parts are compiled `-std=c++11 -Wall -Wextra -Werror`, as
  FLTKAda's shim is, so code can move between them.
- `-verbose` on a poc command shows the clang commands it runs.

```sh
make install    # the poc library pofltk, into $(POC_OBERON_LIBRARIES)/pofltk
make uninstall  # remove exactly what make install wrote
```

`POC_OBERON_LIBRARIES` defaults to `/usr/local/sw/versions/oberon/poc/lib`,
as polibfyaml's does. Try it elsewhere first with
`make install POC_OBERON_LIBRARIES=<scratch dir>`. The manifest records
`c++`, `-lfltk_images` and `-lfltk`, so a program using the installed library needs only:

```sh
poc -OC -library-path $POC_OBERON_LIBRARIES/pofltk Main.Mod
```

A library records the poc that built it, and another poc refuses it, so
install again after upgrading poc.

By hand, as for an experiment in the scratchpad:

```sh
poc -OC -output-dir out -o out/Demo -link -lfltk Demo.Mod
```

`-output-dir` and `-o` keep poc's `.sym`, `.ll`, `.o` and `.cpp.o` files
out of the source directory.

### Tests and the display

Tests and demos need a display (`DISPLAY` or `WAYLAND_DISPLAY`), even for
widgets never shown; `make test` stops with a message without one.

- The user's desktop is Wayland, and FLTK 1.4 uses its Wayland back end
  there. `FLTK_BACKEND=x11 make test` runs the tests on X11 (XWayland).
- **An agent never opens windows on the user's desktop**: not
  `make test`, not `FLTK_BACKEND=x11 make test` (XWayland is the
  desktop too), not a scratch program run directly. Use
  `make test-sway`/`valgrind-sway` (Wayland) and
  `make test-headless`/`valgrind-headless` (X11), and
  `tools/with-sway.sh` or `env -u WAYLAND_DISPLAY xvfb-run -a` for a
  single program (the user's instruction, 2026-10-06).
- Under Wayland a test's windows and dialogs appear on the real
  desktop, where the user's typing or clicking can reach them: a
  `TestDialogs` run failed its `Choice` checks this way once
  (2026-10-06), and passed when run again.
- **`make test-headless`** runs them on Xvfb instead, so no windows
  appear on the desktop. It unsets `WAYLAND_DISPLAY`: a plain `xvfb-run`
  in a Wayland session leaves it set, and FLTK then uses the real desktop
  (confirmed).
- **`make test-sway`** runs them on Wayland without the desktop: on a
  headless sway, through `tools/with-sway.sh` (2026-10-06). sway's
  headless back end (`WLR_BACKENDS=headless`, software rendering with
  `WLR_RENDERER=pixman`, no input devices) has an output but no screen.
  sway runs the command itself, from an `exec` in its own config, so the
  command gets sway's `WAYLAND_DISPLAY`, and finding the socket can't
  race another compositor; `DISPLAY` is unset, so FLTK can't fall back
  to X11. The kernel's VKMS driver would need root and a seat for no
  gain here.
  - Pop-up menus are closed at once there too (three runs of three), as
    on the desktop, so `TestMenus` still tests them on X11 alone.
  - So the four runs that leave the desktop alone are `test-headless`
    and `valgrind-headless` (X11) and `test-sway` and `valgrind-sway`
    (Wayland).
- A test drives itself, with no input tool:
  - `DoCallback`;
  - events from `test/Probe`, sent to a window never shown;
  - `Fl.AddTimeout`, or `Fl.Wait`/`Fl.Check` in a loop;
  - deleting its windows before it ends.

  `make test` runs each test under `timeout`.
- **`Probe` drives FLTK's own routing, so mind what FLTK does**:
  - a mouse event goes through `Fl::handle`, to the widget under the
    mouse, then to `Fl::pushed()`;
  - a push no widget uses shows the window (FLTK raises it), so put
    such a check last;
  - a key goes to the focus widget alone. Through `Fl::handle`, a key no
    widget uses crashes FLTK 1.4.5 when no window is shown and
    `BelowMouse` is set (`doc/fltk-issues.md`, 3);
  - drag and drop events go through `Probe.Mouse`. A window passes
    `EvDndLeave` to every child, and with no window shown an `Fl_Input`
    crashes on it (`doc/fltk-issues.md`, 53): test in a window with
    no input;
  - a key must carry the text the window system would give it
    (BackSpace `08X`, Enter `0DX`): under Wayland, FLTK takes a key with
    no text as composed text;
  - `Probe.Shortcut` offers a key to a window's widgets as a shortcut,
    for return buttons and shortcuts;
  - waits on timers allow for valgrind's slowness: loop until the
    condition holds, up to a generous limit;
  - `Probe.HandleKey` sends a key through `Fl::handle`: to a pop-up
    menu's grab, or as a shortcut to a window's widgets and then the
    event handlers (a global menu);
  - a dialog is answered by a timer that waits for `Probe.Modal`, then
    sends keys with `Probe.ModalKey`, then fires once more: FLTK runs
    timers and then waits for an event, and under Xvfb none comes to end
    the dialog's loop (`doc/fltk-issues.md`, 32);
  - under Wayland the compositor closes a pop-up menu of a window no
    user clicked, so `Popup` is tested on X11 alone (`Probe.Wayland`).
- **`xdotool` is installed** (2026-10-06), for trying an example by hand
  under Xvfb: run it in `xvfb-run -a -s '-screen 0 640x480x24' sh -c
  '...'` with `WAYLAND_DISPLAY` unset, move and click with `xdotool`, and
  look with `import -window root shot.png` (ImageMagick). Tests use
  `Probe`, not `xdotool`, so they need no window manager or timing.

### Valgrind

- **Memory errors fail a test.** The flags are `--error-exitcode`, plus
  `test/poc-gc.supp` for the collector's conservative stack scan.
- **FLTK's display stack leaks by design**: fontconfig and Pango's font
  cache, and GTK's decorations under Wayland. That is hundreds of KB and
  thousands of records, from programs that free everything they made
  (PLAN.md, Phase 0). So leaks don't count as valgrind errors
  (`--errors-for-leak-kinds=none`).
- **`test/vg-check.sh` fails on any leak record whose allocator is
  pofltk's**: the first frame after `malloc`/`calloc`/`realloc`/
  `operator new` is an `ofl_` function, the `ofl` namespace, or an `Fl*`
  module.
  - So **a test must delete every widget it opens**, or it fails
    `make valgrind`.
  - A box never deleted was caught this way. Before the
    `operator new(unsigned long)` pattern was fixed, it wasn't: check
    that the script still catches a deliberate leak whenever you change
    it.

## Confirmed facts (poc 0.3.1 to 0.4.1, FLTK 1.4.5)

Each was confirmed by a program that ran, in the session of 2026-10-06
unless it says otherwise.

### Calling between Oberon and C++

- **A top-level Oberon procedure is a plain C-ABI function** with no hidden
  parameters. Its address, passed as a procedure value, works as an FLTK
  callback or timeout handler.
- **C can call an Oberon procedure by its symbol**, `Module.Proc`,
  exported or not, through an `__asm__` label:
  `extern void hook(int32_t) __asm__("Hk.DrawHook");`. This works with
  `-lto` too. The Reference Guide doesn't promise these names, so prefer
  passing procedure values to the C++ side from a module body.
- **Exported `["C"]` procedures can be called from other modules** in
  0.3.1. In 0.1.0 they couldn't (polibfyaml's "poc 0.1.0 problems").
- **`poc -check` uses the right word size** in 0.3.1: `poc -OC -check`
  accepts `ADDRESS := LONGINT`, which 0.1.0 rejected.
- **An open array argument to a `["C"]` procedure** is passed as its
  first element's address alone. An Oberon `ARRAY OF CHAR` therefore
  arrives as a `const char *`, and must contain a `0X`.
- **The prototype builds and runs under both `-O2` and `-OC`**, because
  its C boundary uses only `SYSTEM.INT32` and `SYSTEM.ADDRESS`.

### The collector

poc's `GarbageCollectedHeap` doesn't move objects. It scans module
globals precisely and the stack conservatively, and **never sees pointers
held only in C++ memory**.

- An object passed to FLTK as `user_data`, with no Oberon reference, was
  freed by a forced `Collect` (`IsAllocated` false), and the callback
  then ran on reused memory.
- Every Oberon object FLTK can call back into must be reachable from a
  module-level root: PLAN.md's registry.

### FLTK's behaviour

- **FLTK deletes a group's children with it.** An Oberon handle to a
  child is then stale, and using it crashes in C++.
- **Text drawing needs a font set first.** `fl_draw` of text before any
  `fl_font()` call crashed under Wayland/Cairo.
- **`Fl_Widget::label()` keeps the pointer it is given.** Use
  `copy_label()`, since Oberon strings may die with a stack frame.
- **The `AUTO_DELETE_USER_DATA` user data is deleted however a widget
  dies.** That includes:
  - explicit `delete`;
  - with its parent group, at any depth;
  - `Fl::delete_widget` inside its own callback, at the next
    `Fl::check`;
  - a shown window with its children.

  This is pofltk's deletion hook (`src/pofltk.h`, `Ref`).
- **Replacing a widget's user data deletes the old one**, so pofltk sets
  it once (`ofl::open`), and nothing may set it or the callback again.
  This applies to C++ code for a new class too.
- **FLTK's own default callbacks**:
  - `Fl_Widget::default_callback` queues the widget for `Fl::readqueue`;
  - `Fl_Window::default_callback` calls `Fl::atclose`, which hides the
    window.

  pofltk's callback replaces them on every widget, so the Oberon
  `Callback` defaults call them.
- **`FLTK_BACKEND=x11`** puts FLTK 1.4.5 on X11 (XWayland here). With no
  display, FLTK prints "Can't open display" and exits 1.
- **FLTK prefers Wayland whenever `WAYLAND_DISPLAY` is set**, even when
  `DISPLAY` names an Xvfb server. With it unset, FLTK uses X11 by itself.
- **`Fl_Image_Surface` draws a widget that was never shown**, and its
  pixels read back exactly (`FL_RED` is 255,0,0), on both back ends.
  `Fl_Widget_Surface::draw(w, 0, 0)` puts a child widget's top left at
  0, 0, although it draws in its window's coordinates.
- **`fl_clip_box`'s result is backwards** (0 if clipped, 1 if not),
  against its documentation, and for a box wholly clipped it leaves `H`
  unset (source: `Fl_Cairo_Graphics_Driver::clip_box`). `FlDraw.ClipBox`
  drops the result.
- **A push no widget uses makes the window `Fl::pushed()` and shows
  it** (`Fl::handle_`, "raise windows that are clicked on").
- **Synthesized events work in a window never shown**: set `Fl::e_x`
  and the rest (public statics), then call `Fl::handle(event, window)`.
  Except keys no widget uses, and `FL_DND_LEAVE` to a window with an
  input (above).
- **Non-virtual methods hidden by a subclass** (`Fl_Window::copy_label`,
  `Fl_Slider::bounds`, `Fl_Spinner::color`, `Fl_Flex::end`,
  `Fl_Scroll::clear`, `Fl_Table`'s child methods and others): calling
  through an `Fl_Widget *` or `Fl_Group *` reaches the base's. Before
  binding a method, check the class's header for one that hides a
  base's, and call the class as itself in the shim
  (`doc/fltk-issues.md`).
- **`Fl_Grid::widget` overruns its rows** for a row equal to `rows()`
  or a column equal to `cols()` (it checks `>`, not `>=`): valgrind
  shows an invalid read and write. `Grid.PlaceSpan` checks first
  (`doc/fltk-issues.md`, 21).
- **`Fl_Tile` without size ranges doesn't save the sizes a move gives**,
  so a range set later makes the next move put the children back.
  `Tile.SizeRange` saves them first (`doc/fltk-issues.md`, 24).
- **`Fl_Pack` resizes itself as it draws**, to fit its children.
- **Menus** (`doc/fltk-issues.md`, 26 to 29, 33):
  - inserting or removing items moves `value()` to another item, so
    `FlMenus` finds it again by its text pointer;
  - a deleted `global()` menu is used by the next shortcut, so `FlMenus`
    keeps its own;
  - under Wayland a menu popped up over a window not yet exposed kills
    the program (`Popup` waits with `wait_for_expose`), and a pop-up of
    a window without the focus is closed at once;
  - `Fl_Choice::value(int)` hides `Fl_Menu_`'s;
  - clearing a menu in its own callback is safe in 1.4.5, despite
    FLTK's documentation;
  - an item showing an image or a multi-label holds it in its `text`,
    which `remove` and `replace` free and paths read as text (a bug,
    54): each such item has an `ofl::ItemLabel` of its own, and
    `FlMenus.cpp` swaps the item's text in around FLTK's calls;
  - `find_index` takes a path with its labels' `&`s.
- **Dialogs**: `fl_message` and the rest take a printf format, so pass
  text as `"%s"`; `fl_file_chooser`, and `Fl_Native_File_Chooser` using
  FLTK's chooser, keep their title pointer (`doc/fltk-issues.md`, 30,
  31).
- **Text** (`doc/fltk-issues.md`, 34 to 36):
  - a text buffer and its displays don't detach from each other, so a
    buffer deleted first is used after it is freed: `FlText` reference
    counts buffers;
  - a style buffer with no styles makes FLTK read before the style
    table;
  - `search_forward` and `search_backward` with `matchCase` read past
    the end of the text (a bug): the shim searches itself.
- **Browsers** (`doc/fltk-issues.md`, 37 to 40):
  - `column_widths`, `Fl_File_Browser::filter` and `load` keep their
    pointers: the shim keeps copies;
  - a browser finds its top line only as it draws, so `topline()` and
    `displayed()` are stale until then, and a browser never drawn takes
    no click: draw it first in a test (`Probe.Capture`);
  - `Fl_Browser::textsize` and `Fl_File_Browser::textsize` hide
    `Fl_Browser_`'s;
  - `Fl_Browser::icon` keeps the image, and a line removed drops it
    unseen (56): the browser keeps the images its lines show;
  - `Fl_Browser::load` adds an empty last line after a final newline;
    `Fl_File_Browser::load` returns the directory's entries;
  - a browser calls back on every release, changed or not, and a check
    browser not at all, to start with.
- **Trees** (`doc/fltk-issues.md`, 41 to 43, 58, 59):
  - FLTK makes and deletes items itself, so a `TreeItem` is checked
    against the tree's map of live items before every use;
  - `Fl_Tree::remove` leaves a descendant of the item as the last one
    clicked, and the callback item after removal: the shim removes
    descendants one by one, and clears the callback item;
  - `clear()` deletes the root;
  - `Fl_Tree_Item::is_visible()` is the item's own flag;
    `is_visible_r()` is whether its parents are open;
  - an item's widget is the tree's child, which FLTK leaves in the tree
    when the item goes, still taking clicks (58): the shim deletes it
    with the item;
  - an item removed in the tree's callback as it is pushed becomes the
    last one clicked after it is freed, and a drag moves it (a bug,
    59): the tree clears that after an event with removals;
  - `Fl_Tree::add`, `insert`, `remove` and `clear` hide `Fl_Group`'s;
    `Fl_Group::on_remove` is virtual in 1.4.
- **Images** (`doc/fltk-issues.md`, 44 to 47):
  - a widget keeps the image it is given, so `Ref` holds it, counted,
    until the widget dies;
  - an empty label is laid out as a line of text, which moves a label
    image: every label goes through `ofl::label_text`;
  - a binary PNM with a maxval under 255 is read unscaled (a bug): the
    shim scales it;
  - XPM color names are read only on X11; Wayland has no window icons;
  - `Fl_Multi_Label::label(Fl_Widget *)` leaves a copied label marked
    to be freed, so the widget frees the multi-label (a bug, 55): the
    shim clears the label first;
  - `copy_label` keeps the label type, so text set on a widget showing
    a multi-label sets the type back to `FL_NORMAL_LABEL`.
- **The clipboard** (`doc/fltk-issues.md`, 48 to 50):
  - X11's `Fl::copy` before the display is open crashes (a bug): the
    shim opens it first;
  - a pasted image FLTK makes must be deleted by the program unless it
    keeps it, and Wayland leaks the program's own (a bug): `W<B>::handle`
    deletes any not taken;
  - Wayland has no selection buffer.
- **Preferences** (`doc/fltk-issues.md`, 51): a group's `Fl_Preferences`
  outlives its node, deleted with the group or the database.
- **Tables** (`doc/fltk-issues.md`, 52): `Fl_Table` hides `Fl_Group`'s
  `begin`, `end`, `children`, `child`, `add` and the rest, which reach
  the inner group holding the cells' widgets: Fl.cpp calls a table as
  an `Fl_Table`.
- **Command-line options** (`doc/fltk-issues.md`, 57): FLTK keeps
  pointers into `argv`, and poc's `Args.argv` is C's own, which lasts
  the program's life. `Fl::args` returns 0 for an unknown option only
  until it has once stopped at a word that isn't an option: the shim
  decides from the word.
- **Charts** (`doc/fltk-issues.md`, 60, 65): `maxsize(0)` drops every
  entry, though 0 is no limit; an entry's label is cut to 18 bytes
  in the middle of a UTF-8 character.
- **Window shapes** (`doc/fltk-issues.md`, 61): X11's driver reads an
  RGB image's drawn size from its data, past their end if it is drawn
  larger, and keeps the image: FlImages gives it a copy. Wayland
  supports shapes too.
- **Animated GIFs** (`doc/fltk-issues.md`, 62, 64): an animation's
  timer redraws its canvas, deleted or not, so FlImages' animation
  watches the canvas; a copy plays whenever the original has a frame
  shown.
- **`fl_numericsort` is wrong** (`doc/fltk-issues.md`, 63): it skips
  the character after a run of digits, and reads past a name's end
  after one. pofltk sorts with its own (`ofl::numericsort`), and sets
  it as FLTK's file chooser's.
- **Screens**: `Fl::screen_num` is 0 for a point on no screen.
  xvfb-run's default screen is 640x480; `tools/with-sway.sh`'s output
  is 1280x800.
- **Name clashes with FLTK's keys**: the key constants take the prefix
  `Key`, since `FL_End` would be the keyword `END`. So `Fl::get_key` is
  `GetKey`, because `KeyDown` is the down arrow.
- **`fltk-config --cxxflags`** includes `-I/usr/include` and Fedora's
  build flags (`-specs=...`). Pass only its `-I`/`-D` flags, without
  `-I/usr/include`.
- **No memory errors under valgrind** in FLTK's display stack, on either
  back end, only leaks (Valgrind, above).

### poc problems

Worked around here. Check whether each new poc fixes them, then remove the
workaround.

None at present.

- **Fixed in 0.4.1: `ORD` of a `SET` under `-OC`** (2026-10-06). In
  0.3.1 and 0.4.0 any use failed to compile, poc emitting
  `trunc i32 %x to i32`, which clang rejects. 0.4.1 compiles
  `ORD({0, 2, 31})` into an `INTEGER`, a `SYSTEM.INT32` and a `HUGEINT`
  with the right value, and the `SYSTEM.VAL(SYSTEM.INT32, s)`
  workarounds are gone.

### Carried from polibfyaml, re-checked or documented for 0.3.1

- **`ASSERT(x, n)` exits with status 10**, printing
  `assertion failed (n)`, not with `n`. A NIL dereference, including a
  method call on NIL, exits 4. A constant-FALSE `ASSERT` is a compile
  error. (Reference Guide §6.)
- **String literals have no length limit** in 0.3.1, per the Reference
  Guide. 0.1.0's limit was 255.

### Carried from polibfyaml, not yet re-checked

- **No call chaining**: a function result isn't a designator, so
  `a.Parent().Label()` doesn't compile.
- **Comments nest, and `*)` ends a comment anywhere**: don't write C
  wildcards like `fl_*)` in comments, and quote text like `("*name")`.
- **`ORD` takes a `CHAR` or a `SET`, not a `BOOLEAN`.** Never pass a
  `BOOLEAN` across the C boundary; use an `int32_t` 0 or 1.
- **Real literals are `REAL` unless written with `D`.** Write `0.5D0`
  for a `LONGREAL` such as a timeout.
- **`Out` writes at once** (no buffering).
- **Finalizers run when the program ends**, by any path (return from
  the main module, `HALT`, `ASSERT`, a trap, `Platform.Exit`), so a
  valgrind leak report is meaningful.

## Conventions

- **Claim only what has been verified.** When a comment or decision
  depends on how FLTK or poc actually behaves, write a throwaway program
  in the scratchpad, run it, and only then record the result: here under
  "Confirmed facts", and in PLAN.md. Check actual values, not just the
  absence of a crash: valgrind can't see a pointer into a dead stack
  frame.
- **Before binding anything that takes a pointer**, find out from the
  FLTK source whether FLTK copies it or keeps it. If it keeps it, the
  memory must belong to an Oberon object that outlives the FLTK object
  (PLAN.md, "Strings and memory handed to FLTK").
- **The C++ parts** take and return only `int32_t`, `uint32_t`,
  `intptr_t` and `double`, inside `extern "C"`. They mirror no C++ struct
  as an Oberon record, and let no C++ exception escape. Copy FLTKAda's
  shim code where it fits (public domain), noting the source in a
  comment.
- **Keep `["C"]` procedures unexported.** Wrap each in an exported Oberon
  procedure, so the handle stays hidden and the wrapper can check for a
  dead widget.
- **Cleanup is idempotent.** Set a handle to 0 when its object is freed
  or found dead, and make every method check for 0.
- **Programmer errors halt** with the codes in PLAN.md, "Halt codes".
  Bad outside data never halts; it comes back as a `BOOLEAN` result.
- **Comments explain why.** Match the surrounding code's comment density
  and naming.
- **Record every FLTK problem in `doc/fltk-issues.md`** as it is found:
  a bug (a crash, or behaviour against FLTK's documentation) or a
  pitfall a binding must allow for. Use the form the file gives: what
  happens, the cause in FLTK's source, the effect on pofltk and its
  workaround, and how it was confirmed. Keep the shorter note under
  "FLTK's behaviour" below too.
- **Record decisions and findings in PLAN.md as they happen**: append to
  the relevant section, mark finished phases `[done]`, and strike through
  decided open questions.
- **Commit only when asked.** Commit messages are short and say why, as
  in polibfyaml and FLTKAda.
