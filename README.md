# pofltk - an Oberon-2 binding to FLTK for poc

An Oberon-2 binding to [FLTK](https://www.fltk.org) 1.4, the Fast Light
Toolkit, for poc, the
[Peaseblossom](https://github.com/tkurtbond/peaseblossom) Oberon
compiler. It is a thick binding:
- FLTK's classes are Oberon record types, which a program extends.
- FLTK's virtual `draw()` and `handle()` are type-bound procedures a
  program overrides.
- Widgets FLTK deletes are seen as deleted, not left dangling.
- Programmer errors halt with a code naming the mistake.

It covers:
- windows, groups and boxes, and the event loop, timers and events;
- drawing (`fl_draw.H`), custom widgets;
- buttons, inputs, valuators;
- layout: flex, grid, pack, scroll, tabs, tile and wizard;
- menus and FLTK's common dialogs, the desktop's native file chooser;
- text buffers, displays and editors;
- browsers and trees, tables;
- images (PNG, JPEG, GIF, BMP, XPM, PNM, SVG), offscreen drawing;
- the clipboard, preferences, command-line options, screens.

## Requirements

- poc 0.4.1 or later, on `PATH`; or `make POC=/path/to/poc`.
- clang and clang++, which poc runs.
- FLTK 1.4 with its headers, found through `fltk-config`, and its image
  library (`fltk-config --use-images`).
- A display (X11 or Wayland) to run anything, even the tests.
- Optional:
  - valgrind (`make valgrind`);
  - Xvfb (`xvfb-run`) for `make test-headless`;
  - sway for `make test-sway`.

## Building and testing

```sh
make            # the tests and examples, into build/
make test       # every test, halt test and example, on the current display
make valgrind   # the tests under valgrind
make test-headless      # make test on Xvfb, with no window on the desktop
make valgrind-headless
make test-sway          # make test on Wayland, on a headless sway
make valgrind-sway
make clean
```

The tests drive themselves: events are sent to windows never shown, and
dialogs are answered by timers. Windows still appear on the current
display, and a user's typing could reach them, so `test-headless` and
`test-sway` are the ones to use while working at the same desktop. The
examples wait for the user; `make test` checks that each one is still
running after a few seconds.

## Using it

**Compile everything with `-OC`**, as the binding is: symbol files
differ between poc's size models.

Install it once as a poc library:

```sh
make install    # into $(POC_OBERON_LIBRARIES)/pofltk
make uninstall
```

`POC_OBERON_LIBRARIES` defaults to `/usr/local/sw/versions/oberon/poc/lib`.
The library records its C++ parts and its link flags (`-lfltk_images
-lfltk`). A program then needs only the library path:

```sh
poc -OC -library-path /usr/local/sw/versions/oberon/poc/lib/pofltk \
    -o Hello Hello.Mod
```

A library records the poc that built it, and another poc refuses it:
run `make install` again after upgrading poc.

## Example

This is `examples/Hello.Mod`, FLTK's `test/hello.cxx`:

```oberon
MODULE Hello; (* FLTK's test/hello.cxx in Oberon-2 *)

IMPORT Fl;

VAR
  window: Fl.Window;
  box: Fl.Box;

BEGIN
  NEW(window); Fl.OpenWindow(window, 340, 180, "Hello");
  NEW(box); Fl.OpenBox(box, 20, 40, 300, 100, "Hello, World!");
  box.SetBoxType(Fl.UpBox);
  box.SetLabelFont(Fl.Bold + Fl.Italic);
  box.SetLabelSize(36);
  box.SetLabelType(Fl.ShadowLabel);
  window.End;
  window.Show;
  Fl.Run
END Hello.
```

`examples/` has more:
- `Scribble`: a custom widget drawn and driven by the mouse.
- `Swatch`: a custom-drawn box.
- `Menus`: a menu bar, a choice and the dialogs.
- Ports of FLTK's own `examples/` programs, each named for FLTK's file
  in CamelCase, without `howto-`:
  - each module's simplest use: `TableSimple`, `TreeSimple`,
    `TextEditorSimple`, `BrowserSimple`, `GridSimple`, `FlexSimple`,
    `TabsSimple`, `WizardSimple`, `ProgressSimple`,
    `NativeFileChooserSimple`, `SvgSimple`;
  - `Callbacks` (a callback's own arguments, as a widget's fields),
    `DrawAnX`, `TextOverImageButton`, `DragAndDrop`;
  - tables: `TableAsContainer`, `TableWithKeynav`,
    `TableWithRightClickMenu`, `TableWithRightColumnStretchFit`,
    `TableSpreadsheetWithKeyboardNav`;
  - text: `TextDisplayWithColors`, `TextEditorWithDynamicColors`;
  - `NativeFileChooserSimpleApp`: File/Open, Save and Save As;
  - `DraggableGroup`, `TableSpreadsheet`, `TreeCustomSort`;
  - images in lists and menus: `BrowserWithIcons`, `MenuWithImages`;
  - `MenubarAdd`, and `ParseArgs`: a program's own command-line
    options beside FLTK's;
  - the event loop: `AddFdAndPopen` (a command's output, read as it
    comes), `RemapNumpadKeyboardKeys` (an event dispatch), `TableSort`
    (a table of `ls -l`, sorted by the column clicked). The first and
    last run commands through `examples/Pipe`, an example module with
    a C++ part, since running a command isn't FLTK's.

## Modules

| Module | Contents |
|---|---|
| `Fl` | `Widget`, `Group`, `Window`, `DoubleWindow`, `Box`; the event loop, timers, idle callbacks, file descriptors' watches, the event dispatch, events, colors, fonts, box and label types, schemes, options, the clipboard, command-line options, screens, opening URIs |
| `FlDraw` | `fl_draw.H`: lines, shapes, paths, transformations, text, fonts, clipping, boxes and symbols |
| `FlButtons` | `Button` and its kinds: check, light, round, radio, return, repeat, toggle |
| `FlInputs` | `Input` and its kinds, `Output`, `MultilineOutput` |
| `FlValuators` | sliders, `Counter`, `Dial`, `Roller`, `Spinner`, `Adjuster`, `ValueInput`, `ValueOutput`, `Scrollbar`, `Progress` |
| `FlLayout` | `Flex`, `Grid`, `Pack`, `Scroll`, `Tabs`, `Tile`, `Wizard` |
| `FlMenus` | `MenuBar`, `MenuButton`, `Choice`, menu items |
| `FlDialogs` | messages, questions, input, colors, file choosers, `NativeFileChooser` |
| `FlText` | `TextBuffer`, `TextDisplay`, `TextEditor`, styles |
| `FlBrowsers` | `Browser` and its kinds, `CheckBrowser`, `FileBrowser`, `Tree`, `TreeItem` |
| `FlImages` | `Image` (loaded, decoded, or from pixels), `MultiLabel`; images on widgets, browser lines and menu items; `Surface` (offscreen drawing) |
| `FlPreferences` | `Preferences`: FLTK's settings databases |
| `FlTable` | `Table`, `TableRow`: cells the program draws |

Each module has a C++ part (`src/<Module>.cpp`), compiled by poc, which
flattens FLTK to C functions; `src/pofltk.h` is what they share.

## Concepts

**Opening widgets.** A widget is a record a program allocates itself,
then opens as the FLTK class it extends:
`NEW(b); FlButtons.OpenButton(b, x, y, w, h, "label")`. So a program's
own extension, with fields and methods of its own, is opened the same
way. (Its fields can't be called `h`: every widget has the read-only
`h`, its handle.) FLTK's current group is kept: a group (or window) collects the
widgets opened until its `End`.

**Overriding.**
- `Draw`, `Handle(event): BOOLEAN` and `Resize` are called by FLTK.
  Their defaults are FLTK's own.
- `Callback` is called when the widget acts. Its default calls the
  widget's `action` field, a procedure, if one is set, so simple
  programs need no extension.
- A table's `DrawCell` draws its cells.

**Lifetime.** FLTK deletes a group's children with it, and a window
the user closes may be deleted by the program's callback. pofltk hears of
every deletion: a deleted widget's `IsOpen()` is FALSE, and using it
halts. Every open widget, and every timer, idle and file descriptor's watch
FLTK may call, is kept reachable for poc's collector, which can't see
FLTK's pointers. Delete a widget with `Delete`. Inside a
callback, or a `Draw` or `Handle`, FLTK deletes it later, when its
event loop next runs (`Fl::delete_widget`), since FLTK may still be
using it.

**Resources.** `TextBuffer`, `Image`, `MultiLabel`, `Surface`,
`Preferences` and `NativeFileChooser` belong to the program: `Close`
them when done (`Close` is idempotent, and the collector closes one lost
without it). A widget using one keeps it, so closing a buffer a display
shows, or an image a box, a browser line or a menu item shows, is safe.

**Strings.** Labels and other text FLTK keeps are copied, so an Oberon
string may die with its procedure.

**Errors and halts.** Bad data from outside comes back as FALSE: an
image that can't be decoded, a file that can't be read, a cancelled
dialog. A programming mistake halts with `ASSERT`, exit status 10, and
prints `assertion failed (n)`:

| Code | Mistake |
|---|---|
| 70 | a widget not open: never opened, or deleted (`Fl.NotOpen`) |
| 71 | a widget opened twice (`Fl.OpenedTwice`) |
| 72 | NIL where a widget or timer is needed (`Fl.NilArgument`) |
| 73 | a closed resource used, or one missing: a closed buffer, image or preferences, a removed tree item (`Fl.ClosedResource`) |
| 74 | an index out of range: a group's child, a grid cell, a browser line, a menu item, a table row (`Fl.IndexOutOfRange`) |
| 75 | `RepeatTimeout` outside its timer's `Fire`, `HandleDefault` outside the event dispatch (`Fl.NotFiring`) |
| 76 | a widget that must be a group's child isn't (`Fl.NotAChild`) |
| 77 | a surface's `Begin` and `End` out of order (`Fl.OutOfOrder`) |
| 78 | an argument a call can't take: a multi-label for a window, or put in itself; a file descriptor's conditions empty or unknown (`Fl.Unsupported`) |

## FLTK's problems

Writing pofltk found bugs and pitfalls in FLTK 1.4.5:
- crashes, such as `Fl::copy` before a window is shown on X11;
- leaks and use-after-free;
- non-virtual methods that hide their base's, such as `Fl_Table`'s
  child methods;
- behaviour that differs between X11 and Wayland.

`doc/fltk-issues.md` lists each, with its cause in FLTK's source and
pofltk's workaround.

## Documents

- `PLAN.md`: the design, its decisions, and what each phase found.
- `doc/design.md`: the feasibility analysis that started it.
- `doc/fltk-issues.md`: FLTK's bugs and pitfalls.
- `AGENTS.md`: working notes, including confirmed facts about poc and
  FLTK.
