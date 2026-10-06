# AGENTS.md

ofltk is an Oberon-2 binding to FLTK 1.4, the Fast Light Toolkit, compiled
with poc, the Peaseblossom Oberon Compiler. PLAN.md is the design and
roadmap; `doc/design.md` is the feasibility analysis that started it. This
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

As of 2026-10-06, Phase 0 of PLAN.md is done, and Phase 1 is next: `src/`
has the core of the `Fl` module, and the tests pass. Also kept:

- `doc/design.md`: the feasibility analysis.
- `prototype/`: the object-style sketch `FL.Mod`, its C++ part `FL.c`,
  and `Demo.Mod`. It stays until `src/` has its custom drawing (Phase 2)
  and buttons (Phase 3).
- `probes/callback/`: C calling an Oberon procedure value.
- `probes/gc-hazard/`: a flat binding (`Fltk.Mod`, `Fltk.c`). `Hazard.Mod`
  shows a callback's `user_data` being collected; `Hello.Mod` is a
  one-button window that waits for real clicks.

## Layout

- `src/ofltk.h`: what every module's C++ part shares:
  - `ofl::W<B>`, the FLTK class `B` with `draw()`/`handle()` sent to
    Oberon;
  - `ofl::open`, which attaches a widget to its Oberon object;
  - the `Ref` user data, whose destructor is the deletion hook;
  - the dispatch depth.
- `src/Fl.Mod`, `src/Fl.cpp`: the core module. Its "For ofltk's modules
  only" procedures (`BeginOpen`, `EndOpen`) are how another module
  opens a widget of its own class. Keep application code off them.
- `test/`:
  - one main module per concern, `Test*.Mod`, using `Check.Mod`;
  - halt tests, `Halt*.Mod`, one per code;
  - `poc-gc.supp`, and `vg-check.sh` (Valgrind, below).
- `GNUmakefile`: build and test (Build, below).
- `build/`: poc and clang output (ignored by git).
- `PLAN.md`: design, decisions and findings, by section and phase.

## Reference material

| What | Where |
|---|---|
| FLTK headers (1.4.5) | `/usr/include/FL/` (`fltk-devel-1.4.5`); flags from `fltk-config --cxxflags`/`--ldflags` (`-lfltk`) |
| FLTK source (1.4.5) | `/usr/local/sw/src/lang/C++/fltk/fltk-1.4.5/` (`src/`, `FL/`, `test/`, `examples/`) |
| FLTK docs (HTML) | `/usr/share/doc/fltk-devel/html/` |
| FLTK 1.3 | also installed (`fltk1.3`, runtime only); never build against it |
| FLUID | `fltk-fluid-1.4.5` |
| poc | `/usr/bin/poc` (Peaseblossom RPM 0.3.1); `poc(1)`; `/usr/share/doc/peaseblossom/users-guide.md` (§9, "Calling C") and `reference-guide.md` |
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
make test       # every test and halt test; needs a display
make valgrind   # the tests under valgrind, then test/vg-check.sh on each log
make test-headless      # make test on Xvfb, not the desktop
make valgrind-headless  # make valgrind on Xvfb
make clean      # rm -rf build
```

- `make POC=/path/to/poc` uses another poc.
- **A new test** needs its name added to `TESTS`, a halt test to
  `HALTTESTS` (as `name:code`).
- **A new module** needs its name added to `MODULES`, and a new header to
  `HEADERS`.
- **C++ parts are `src/<Module>.cpp`**, poc 0.4.0's form. With poc 0.3.1,
  detected from `poc -version`, the makefile stages `src/` into
  `build/src/`, renaming each `.cpp` to `.c`, and adds
  `-c-flag -xc++ -link -lstdc++`. Without `-lstdc++` the link fails on
  `__gxx_personality_v0`. When 0.4.0 is the oldest poc in use, delete the
  staging.
- The C++ parts are compiled `-std=c++11 -Wall -Wextra -Werror`, as
  FLTKAda's shim is, so code can move between them.
- `-verbose` on a poc command shows the clang commands it runs.

By hand, as for an experiment in the scratchpad (poc 0.3.1):

```sh
poc -OC -output-dir out -o out/Demo -c-flag -xc++ -link -lfltk -link -lstdc++ Demo.Mod
```

`-output-dir` and `-o` keep poc's `.sym`, `.ll`, `.o` and `.c.o` files
out of the source directory.

### Tests and the display

Tests and demos need a display (`DISPLAY` or `WAYLAND_DISPLAY`), even for
widgets never shown; `make test` stops with a message without one.

- The user's desktop is Wayland, and FLTK 1.4 uses its Wayland back end
  there. `FLTK_BACKEND=x11 make test` runs the tests on X11 (XWayland).
- **`make test-headless`** runs them on Xvfb instead, so no windows
  appear on the desktop. It unsets `WAYLAND_DISPLAY`: a plain `xvfb-run`
  in a Wayland session leaves it set, and FLTK then uses the real desktop
  (confirmed).
- No input-automation tool is installed (no `xdotool`), so a test drives
  itself:
  - `DoCallback`;
  - `Fl.AddTimeout`, or `Fl.Wait`/`Fl.Check` in a loop;
  - deleting its windows before it ends.

  `make test` runs each test under `timeout`.

### Valgrind

- **Memory errors fail a test.** The flags are `--error-exitcode`, plus
  `test/poc-gc.supp` for the collector's conservative stack scan.
- **FLTK's display stack leaks by design**: fontconfig and Pango's font
  cache, and GTK's decorations under Wayland. That is hundreds of KB and
  thousands of records, from programs that free everything they made
  (PLAN.md, Phase 0). So leaks don't count as valgrind errors
  (`--errors-for-leak-kinds=none`).
- **`test/vg-check.sh` fails on any leak record whose allocator is
  ofltk's**: the first frame after `malloc`/`calloc`/`realloc`/
  `operator new` is an `ofl_` function, the `ofl` namespace, or an `Fl*`
  module.
  - So **a test must delete every widget it opens**, or it fails
    `make valgrind`.
  - A box never deleted was caught this way. Before the
    `operator new(unsigned long)` pattern was fixed, it wasn't: check
    that the script still catches a deliberate leak whenever you change
    it.

## Confirmed facts (poc 0.3.1, FLTK 1.4.5)

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

  This is ofltk's deletion hook (`src/ofltk.h`, `Ref`).
- **Replacing a widget's user data deletes the old one**, so ofltk sets
  it once (`ofl::open`), and nothing may set it or the callback again.
  This applies to C++ code for a new class too.
- **FLTK's own default callbacks**:
  - `Fl_Widget::default_callback` queues the widget for `Fl::readqueue`;
  - `Fl_Window::default_callback` calls `Fl::atclose`, which hides the
    window.

  ofltk's callback replaces them on every widget, so the Oberon
  `Callback` defaults call them.
- **`FLTK_BACKEND=x11`** puts FLTK 1.4.5 on X11 (XWayland here). With no
  display, FLTK prints "Can't open display" and exits 1.
- **FLTK prefers Wayland whenever `WAYLAND_DISPLAY` is set**, even when
  `DISPLAY` names an Xvfb server. With it unset, FLTK uses X11 by itself.
- **`Fl_Image_Surface` draws a widget that was never shown**, and its
  pixels read back exactly (`FL_RED` is 255,0,0), on both back ends.
- **`fltk-config --cxxflags`** includes `-I/usr/include` and Fedora's
  build flags (`-specs=...`). Pass only its `-I`/`-D` flags, without
  `-I/usr/include`.
- **No memory errors under valgrind** in FLTK's display stack, on either
  back end, only leaks (Valgrind, above).

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
- **Record decisions and findings in PLAN.md as they happen**: append to
  the relevant section, mark finished phases `[done]`, and strike through
  decided open questions.
- **Commit only when asked.** Commit messages are short and say why, as
  in polibfyaml and FLTKAda.
