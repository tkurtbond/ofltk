# ofltk: an FLTK binding for Oberon-2 — feasibility and design

*Analysis of 2026-10-06, against poc 0.3.1 (d9f505e), clang 22.1.8 and
FLTK 1.4.5 on Fedora 44, x86_64.*

## Verdict

Writing an FLTK binding for Oberon-2 with poc is both useful and
practical. Working FLTK programs were built and run with poc as installed,
with no changes to the compiler. The real work is designing the binding
layer, not getting the compiler to cooperate.

## What was tested

| Question | Result |
|---|---|
| Can C call an Oberon procedure value? | **Yes.** A top-level procedure compiles to a plain C-ABI function with no hidden parameters (`define void @Cb.Handler(i64 %p.w, i64 %p.data)`), so it works directly as an FLTK callback or timeout handler. |
| Can the C++ glue live in the module's C part? | **Yes, with flags.** `poc -c-flag -xc++ -link -lfltk -link -lstdc++ Main.Mod` compiles `FL.c` as C++ with `extern "C"` entry points. |
| Can C++ virtual methods dispatch to Oberon? | **Yes.** A C++ subclass forwarding `draw()`/`handle()` to type-bound procedures worked: an Oberon `Swatch` extension of `FL.Box` drew itself, and a `Next` button's overridden `Clicked` ran. |
| Does it survive garbage collection? | **Only with a registry** (see "Problems found"). |
| Can it be packaged as a poc library? | **Yes**, `poc -c-flag -xc++ -output-dir lib -library ofltk FL.Mod` works, but clients must pass the FLTK and C++ link flags themselves (see "Friction in poc"). |

## Problems found, with fixes

1. **The GC can't see pointers held by FLTK (confirmed).** A record passed
   as `user_data`, with no Oberon reference to it, was freed by forced
   collections: `GarbageCollectedHeap.IsAllocated` reported it gone, and the
   callback then ran on reused memory (the counter kept resetting). The
   collector scans only module roots and the machine stack, never C++ heap
   memory.
   - **Fix:** a module-level registry of live widget objects. With it,
     objects created only in local variables survived the same forced
     collections.
2. **Widgets can be deleted from under Oberon.** FLTK deletes children with
   their parent, leaving stale handles. In the demo, calling `Redraw` on a
   deleted box segfaulted on the NULL handle until a check was added.
   - **Fix:** unregister and zero the handle when the C++ object dies.
     FLTK 1.4's `AUTO_DELETE_USER_DATA` (user data derived from
     `Fl_Callback_User_Data`, whose virtual destructor runs when the widget
     is destroyed) gives that hook for every widget class without
     subclassing each one. Methods then check `h # 0`.
3. **Labels must be copied.** FLTK's `label()` keeps the pointer, and
   Oberon strings live on the stack or the collected heap. The shim must
   always use `copy_label()`, and do the same for tooltips and menu text.
4. **Text drawing needs a font set first.** `fl_draw` of text crashed under
   Wayland/Cairo until the shim called `fl_font()`. This was a shim bug, but
   it is a pitfall of an immediate-mode drawing API.

## Friction in poc (all small)

- **Library manifests can't record link dependencies.** The `.library`
  file has no line for native libraries, so every client repeats
  `-link -lfltk -link -lstdc++`; without them the link fails on
  `__gxx_personality_v0`. A `link <arg>` manifest line would remove this.
- **The C part must be named `.c`.** A C++ file needs `-c-flag -xc++`.
  Accepting `Module.cpp` would be cleaner.
- **Two library builds are needed**, one each for `-O2` and `-OC`. Using
  `SYSTEM.INT32` and `SYSTEM.ADDRESS` in the C-facing declarations keeps the
  source the same under both.

## Design sketched by the prototype

- `Widget` is a pointer to a record holding the `Fl_Widget*` handle
  (read-only exported `h-`) and a registry link; window, button and box
  types extend it.
- Overridable behaviour (`Clicked`, `Draw`, `Handle`) is type-bound
  procedures. The C++ side holds the Oberon object's address and calls one
  Oberon dispatcher per event kind, registered once at module
  initialization; the dispatcher calls the type-bound procedure.
- Custom widgets are a C++ subclass (for example `OBox : Fl_Box`) whose
  virtual `draw()`/`handle()` call the dispatchers, and whose destructor
  unregisters the Oberon object.
- Every C entry point takes and returns `intptr_t`/`int32_t`, declared on
  the Oberon side as `SYSTEM.ADDRESS`/`SYSTEM.INT32`.

The prototype is in `prototype/`: `FL.Mod` and its C++ part `FL.c` (the
binding), and `Demo.Mod`, which drives clicks from an FLTK timeout, forces
collections between them, and deletes a widget to exercise the registry.
Build and run it there with:

```
$ poc -c-flag -xc++ -link -lfltk -link -lstdc++ Demo.Mod
$ ./Demo
```

The prototype's `Button` is a plain `Fl_Button`, so only its `Box` (a C++
subclass) unregisters itself when deleted; the `AUTO_DELETE_USER_DATA` hook
above is the general fix and is not yet used.

The earlier probes are in `probes/`:

- `probes/callback/`: `Cb.Mod` hands an Oberon procedure to its C part,
  which calls it back (`poc Cb.Mod`).
- `probes/gc-hazard/`: a flat, handle-only binding, `Fltk.Mod` and
  `Fltk.c`. `Hazard.Mod` shows a callback's `user_data` being collected
  while FLTK still holds it. `Hello.Mod` is a one-button window that hides
  itself after three clicks; it builds but has not been run, since it waits
  for real clicks. Build either with
  `poc -c-flag -xc++ -link -lfltk -link -lstdc++ Hazard.Mod`.

## Why it's useful

- **It fills a gap.** Oberon-2 on Unix has essentially no maintained native
  GUI option.
- **FLTK fits Oberon well:**
  - Single inheritance maps onto record extension, and virtual
    `draw`/`handle` map onto type-bound procedures.
  - It has its own small event loop and no dependency on a large framework.
  - It is packaged on the Linux and BSD systems poc targets.
- **Scope is manageable.** A useful subset (windows, groups, Flex/Grid,
  buttons, inputs, text editor and buffer, browser, menus and choice,
  valuators, `fl_ask` and the file chooser, the drawing API, timeouts) is
  estimated at roughly 2–4k lines of shim plus Oberon. Much of the shim is
  mechanical enough to generate.
- **A ready-made C API exists** in cfltk (the layer under fltk-rs), but it
  isn't packaged on Fedora. A hand-written shim lets the Oberon interface be
  idiomatic rather than a flat port of a C API.
