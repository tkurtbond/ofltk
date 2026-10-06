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

As of 2026-10-06, Phase 0 of PLAN.md has not started, though the git
repository exists (branch `main`, no commits yet). There is no
`GNUmakefile`, `src/` or `test/` yet. What exists:

- `doc/design.md`: the feasibility analysis.
- `prototype/`: `FL.Mod` and its C++ part `FL.c`, an object-style binding
  sketch, plus `Demo.Mod`, which exercises it.
- `probes/callback/`: C calling an Oberon procedure value.
- `probes/gc-hazard/`: a flat binding (`Fltk.Mod`, `Fltk.c`). `Hazard.Mod`
  shows a callback's `user_data` being collected; `Hello.Mod` is a
  one-button window that waits for real clicks.

Update this section as Phase 0 replaces them.

## Reference material

| What | Where |
|---|---|
| FLTK headers (1.4.5) | `/usr/include/FL/` (`fltk-devel-1.4.5`); flags from `fltk-config --cxxflags`/`--ldflags` (`-lfltk`) |
| FLTK source (1.4.5) | `/usr/local/sw/src/lang/C++/fltk` (tag `fltk-1.4.5`) |
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

Until Phase 0's `GNUmakefile` exists, build by hand, from the directory
holding the main module:

```sh
poc -OC -c-flag -xc++ -link -lfltk -link -lstdc++ Demo.Mod
./Demo
```

- `-c-flag -xc++` makes clang compile the module's C part, `<Module>.c`,
  as C++. poc 0.3.1 looks only for a `.c` file.
- `-link -lfltk -link -lstdc++` is needed by every program, even one that
  uses a poc library of ofltk, because a poc 0.3.1 library doesn't record
  native link flags. Without `-lstdc++` the link fails on
  `__gxx_personality_v0`.
- Put build output elsewhere with `-output-dir <dir>` and `-o <exe>`
  (into the scratchpad for experiments); otherwise poc writes `.sym`,
  `.ll`, `.o` and `.c.o` files beside the sources.
- `-verbose` shows the clang commands poc runs.
- A poc release that removes the `-xc++` and link-flag workarounds is
  being prepared. Check `poc -version` and the installed Reference Guide
  before writing build rules, and update this section when it lands.

Tests and demos need a display (`DISPLAY` or `WAYLAND_DISPLAY`). The
user's desktop is Wayland, and FLTK 1.4 uses its Wayland back end there.
There is no input-automation tool installed (no `xdotool`, no Xvfb), so
drive a program from inside: `do_callback`, `Fl::add_timeout`, then hide
the windows so `Fl::run` returns, and always run it under `timeout`.

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
- **`AUTO_DELETE_USER_DATA`** exists in `Fl_Widget.H` (1.4.5), with
  `Fl_Callback_User_Data` and its virtual destructor. Whether it covers
  every way a widget dies is a Phase 0 experiment, not a fact yet.

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
