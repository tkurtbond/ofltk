#!/usr/bin/env python3
"""gen-constants.py: FLTK's constants for ofltk's modules, and the test of them.

Writes, from the SPEC below:
  - in each module's src/<Module>.Mod, the block between
    "(* BEGIN generated constants" and "(* END generated constants *)",
    each value taken from FLTK's headers by compiling and running a C++
    program, so it is right when written;
  - test/CConstants.cpp, a table of the same C expressions, and
    test/TestConstants.Mod, which checks each Oberon constant against it,
    so a later FLTK whose headers differ fails `make test`.

Run from the repository root after changing SPEC or upgrading FLTK:
  python3 tools/gen-constants.py
It needs clang++ and fltk-config. The Oberon names are PLAN.md's: events
take the prefix Ev, so FL_FOCUS can't clash with a procedure Focus, and
keys the prefix Key, so FL_End can't be the keyword END.
"""

import os, re, subprocess, sys, tempfile

# (Oberon name, C++ expression, kind, module): kind "int" is an INTEGER
# constant, "set" a SET constant (a bit-flag type, every bit below 32).
SPEC = []
MODULES = []  # in the order SPEC first names them
current = None

def module(name):
    global current
    current = name
    if name not in MODULES:
        MODULES.append(name)

def add(kind, pairs):
    for name, expr in pairs:
        SPEC.append((name, expr, kind, current))

def section(title):
    SPEC.append((title, None, "comment", current))

module("Fl")

section("events (Fl_Event), the argument of Handle")
add("int", [
    ("EvNone", "FL_NO_EVENT"), ("EvPush", "FL_PUSH"), ("EvRelease", "FL_RELEASE"),
    ("EvEnter", "FL_ENTER"), ("EvLeave", "FL_LEAVE"), ("EvDrag", "FL_DRAG"),
    ("EvFocus", "FL_FOCUS"), ("EvUnfocus", "FL_UNFOCUS"), ("EvKeyDown", "FL_KEYDOWN"),
    ("EvKeyUp", "FL_KEYUP"), ("EvClose", "FL_CLOSE"), ("EvMove", "FL_MOVE"),
    ("EvShortcut", "FL_SHORTCUT"), ("EvDeactivate", "FL_DEACTIVATE"),
    ("EvActivate", "FL_ACTIVATE"), ("EvHide", "FL_HIDE"), ("EvShow", "FL_SHOW"),
    ("EvPaste", "FL_PASTE"), ("EvSelectionClear", "FL_SELECTIONCLEAR"),
    ("EvMouseWheel", "FL_MOUSEWHEEL"), ("EvDndEnter", "FL_DND_ENTER"),
    ("EvDndDrag", "FL_DND_DRAG"), ("EvDndLeave", "FL_DND_LEAVE"),
    ("EvDndRelease", "FL_DND_RELEASE"),
    ("EvScreenConfigurationChanged", "FL_SCREEN_CONFIGURATION_CHANGED"),
    ("EvFullscreen", "FL_FULLSCREEN"), ("EvZoomGesture", "FL_ZOOM_GESTURE"),
    ("EvZoomEvent", "FL_ZOOM_EVENT"),
])

section("when a widget calls its Callback (Fl_When)")
add("set", [
    ("WhenNever", "FL_WHEN_NEVER"), ("WhenChanged", "FL_WHEN_CHANGED"),
    ("WhenNotChanged", "FL_WHEN_NOT_CHANGED"), ("WhenRelease", "FL_WHEN_RELEASE"),
    ("WhenReleaseAlways", "FL_WHEN_RELEASE_ALWAYS"), ("WhenEnterKey", "FL_WHEN_ENTER_KEY"),
    ("WhenEnterKeyAlways", "FL_WHEN_ENTER_KEY_ALWAYS"),
    ("WhenEnterKeyChanged", "FL_WHEN_ENTER_KEY_CHANGED"), ("WhenClosed", "FL_WHEN_CLOSED"),
])

section("box types (Fl_Boxtype); Fl.cpp defines every one at start-up")
BOXES = """NO_BOX FLAT_BOX UP_BOX DOWN_BOX UP_FRAME DOWN_FRAME THIN_UP_BOX
THIN_DOWN_BOX THIN_UP_FRAME THIN_DOWN_FRAME ENGRAVED_BOX EMBOSSED_BOX
ENGRAVED_FRAME EMBOSSED_FRAME BORDER_BOX SHADOW_BOX BORDER_FRAME SHADOW_FRAME
ROUNDED_BOX RSHADOW_BOX ROUNDED_FRAME RFLAT_BOX ROUND_UP_BOX ROUND_DOWN_BOX
DIAMOND_UP_BOX DIAMOND_DOWN_BOX OVAL_BOX OSHADOW_BOX OVAL_FRAME OFLAT_BOX
PLASTIC_UP_BOX PLASTIC_DOWN_BOX PLASTIC_UP_FRAME PLASTIC_DOWN_FRAME
PLASTIC_THIN_UP_BOX PLASTIC_THIN_DOWN_BOX PLASTIC_ROUND_UP_BOX
PLASTIC_ROUND_DOWN_BOX GTK_UP_BOX GTK_DOWN_BOX GTK_UP_FRAME GTK_DOWN_FRAME
GTK_THIN_UP_BOX GTK_THIN_DOWN_BOX GTK_THIN_UP_FRAME GTK_THIN_DOWN_FRAME
GTK_ROUND_UP_BOX GTK_ROUND_DOWN_BOX GLEAM_UP_BOX GLEAM_DOWN_BOX GLEAM_UP_FRAME
GLEAM_DOWN_FRAME GLEAM_THIN_UP_BOX GLEAM_THIN_DOWN_BOX GLEAM_ROUND_UP_BOX
GLEAM_ROUND_DOWN_BOX OXY_UP_BOX OXY_DOWN_BOX OXY_UP_FRAME OXY_DOWN_FRAME
OXY_THIN_UP_BOX OXY_THIN_DOWN_BOX OXY_THIN_UP_FRAME OXY_THIN_DOWN_FRAME
OXY_ROUND_UP_BOX OXY_ROUND_DOWN_BOX OXY_BUTTON_UP_BOX OXY_BUTTON_DOWN_BOX
FREE_BOXTYPE""".split()
WORDS = {"RSHADOW": "RShadow", "RFLAT": "RFlat", "OSHADOW": "OShadow",
         "OFLAT": "OFlat", "BOXTYPE": "Boxtype"}

def camel(c_name):
    return "".join(WORDS.get(w, w.capitalize()) for w in c_name.split("_"))

add("int", [(camel(b), "FL_" + b) for b in BOXES])

section("label types (Fl_Labeltype); multi, icon and image labels come with images")
add("int", [
    ("NormalLabel", "FL_NORMAL_LABEL"), ("NoLabel", "FL_NO_LABEL"),
    ("ShadowLabel", "FL_SHADOW_LABEL"), ("EngravedLabel", "FL_ENGRAVED_LABEL"),
    ("EmbossedLabel", "FL_EMBOSSED_LABEL"),
])

section("label alignment (Fl_Align)")
ALIGNS = """CENTER TOP BOTTOM LEFT RIGHT INSIDE TEXT_OVER_IMAGE IMAGE_OVER_TEXT
CLIP WRAP IMAGE_NEXT_TO_TEXT TEXT_NEXT_TO_IMAGE IMAGE_BACKDROP TOP_LEFT
TOP_RIGHT BOTTOM_LEFT BOTTOM_RIGHT LEFT_TOP RIGHT_TOP LEFT_BOTTOM
RIGHT_BOTTOM NOWRAP POSITION_MASK IMAGE_MASK""".split()
WORDS["NOWRAP"] = "NoWrap"
add("set", [("Align" + camel(a), "FL_ALIGN_" + a) for a in ALIGNS])

section("fonts (Fl_Font); add Bold, Italic or BoldItalic to Helvetica, Courier or Times")
FONTS = """HELVETICA HELVETICA_BOLD HELVETICA_ITALIC HELVETICA_BOLD_ITALIC COURIER
COURIER_BOLD COURIER_ITALIC COURIER_BOLD_ITALIC TIMES TIMES_BOLD TIMES_ITALIC
TIMES_BOLD_ITALIC SYMBOL SCREEN SCREEN_BOLD ZAPF_DINGBATS FREE_FONT BOLD ITALIC
BOLD_ITALIC""".split()
add("int", [(camel(f), "FL_" + f) for f in FONTS])

section("colors (Fl_Color): an index into FLTK's colormap, or RGB(r, g, b)")
COLORS = """FOREGROUND_COLOR BACKGROUND2_COLOR INACTIVE_COLOR SELECTION_COLOR
GRAY0 DARK3 DARK2 DARK1 BACKGROUND_COLOR LIGHT1 LIGHT2 LIGHT3 GRAY BLACK RED
GREEN YELLOW BLUE MAGENTA CYAN DARK_RED DARK_GREEN DARK_YELLOW DARK_BLUE
DARK_MAGENTA DARK_CYAN WHITE FREE_COLOR NUM_FREE_COLOR NUM_GRAY NUM_RED
NUM_GREEN NUM_BLUE""".split()
add("int", [(camel(c), "FL_" + c) for c in COLORS])

section("keys (Fl::event_key): a character's code for most; KeyF + n is F<n>, KeyKP + c keypad c")
KEYS = """Button BackSpace Tab Iso_Key Enter Pause Scroll_Lock Escape Kana Eisu Yen
JIS_Underscore Home Left Up Right Down Page_Up Page_Down End Print Insert Menu
Help Num_Lock KP KP_Enter KP_Last F F_Last Shift_L Shift_R Control_L Control_R
Caps_Lock Meta_L Meta_R Alt_L Alt_R Delete Alt_Gr Volume_Down Volume_Mute
Volume_Up Media_Play Media_Stop Media_Prev Media_Next Home_Page Mail Search
Back Forward Stop Refresh Sleep Favorites""".split()
WORDS.update({"KP": "KP", "JIS": "JIS", "BACKSPACE": "BackSpace"})
add("int", [("Key" + camel(k.upper()), "FL_" + k) for k in KEYS])

section("mouse buttons (Fl::event_button)")
add("int", [(camel(b), "FL_" + b) for b in
            "LEFT_MOUSE MIDDLE_MOUSE RIGHT_MOUSE BACK_MOUSE FORWARD_MOUSE".split()])

section("the shift keys and mouse buttons held (Fl::event_state); Command is Ctrl, but Meta on macOS")
add("set", [(camel(b), "FL_" + b) for b in
            """SHIFT CAPS_LOCK CTRL ALT NUM_LOCK META SCROLL_LOCK BUTTON1 BUTTON2
            BUTTON3 BUTTON4 BUTTON5 BUTTONS COMMAND CONTROL""".split()])

section("what needs redrawing (Fl_Damage), Widget.Damage")
add("set", [("Damage" + camel(d), "FL_DAMAGE_" + d) for d in
            "CHILD EXPOSE SCROLL OVERLAY USER1 USER2 ALL".split()])

section("mouse cursors (Fl_Cursor), Window.SetCursor")
add("int", [("Cursor" + camel(c), "FL_CURSOR_" + c) for c in
            """DEFAULT ARROW CROSS WAIT INSERT HAND HELP MOVE NS WE NWSE NESW N NE
            E SE S SW W NW NONE""".split()])

module("FlDraw")
WORDS.update({"DASHDOT": "DashDot", "DASHDOTDOT": "DashDotDot"})
section("line styles (LineStyle): a dash pattern, plus a cap and a join")
add("int", [(camel(c), "FL_" + c) for c in
            """SOLID DASH DOT DASHDOT DASHDOTDOT CAP_FLAT CAP_ROUND CAP_SQUARE
            JOIN_MITER JOIN_ROUND JOIN_BEVEL""".split()])

module("FlButtons")
section("kinds of button (Button.SetKind); not ToggleButton and RadioButton, the types")
add("int", [("Normal", "FL_NORMAL_BUTTON"), ("Toggle", "FL_TOGGLE_BUTTON"),
            ("Radio", "FL_RADIO_BUTTON"), ("Hidden", "FL_HIDDEN_BUTTON")])

module("FlValuators")
section("kinds of valuator (Valuator.SetKind): of a roller, scrollbar or other valuator")
add("int", [("Vertical", "FL_VERTICAL"), ("Horizontal", "FL_HORIZONTAL")])
section("of a slider or value slider")
add("int", [(camel(k), "FL_" + k) for k in
            """VERT_SLIDER HOR_SLIDER VERT_FILL_SLIDER HOR_FILL_SLIDER
            VERT_NICE_SLIDER HOR_NICE_SLIDER""".split()])
section("of a dial")
add("int", [(camel(k), "FL_" + k) for k in "NORMAL_DIAL LINE_DIAL FILL_DIAL".split()])
section("of a counter")
add("int", [(camel(k), "FL_" + k) for k in "NORMAL_COUNTER SIMPLE_COUNTER".split()])
section("of a spinner (Spinner.SetKind): whole numbers, or real ones")
add("int", [("IntSpinner", "FL_INT_INPUT"), ("FloatSpinner", "FL_FLOAT_INPUT")])

module("FlLayout")
section("kinds of flex (Flex.SetKind): one column, or one row")
add("int", [("Column", "Fl_Flex::COLUMN"), ("Row", "Fl_Flex::ROW")])
section("kinds of pack (Pack.SetKind)")
add("int", [("PackVertical", "Fl_Pack::VERTICAL"), ("PackHorizontal", "Fl_Pack::HORIZONTAL")])
section("kinds of scroll (Scroll.SetKind): which scrollbars, shown when needed or Always")
add("int", [("Scroll" + camel(k), "Fl_Scroll::" + k) for k in
            """HORIZONTAL VERTICAL BOTH ALWAYS_ON HORIZONTAL_ALWAYS VERTICAL_ALWAYS
            BOTH_ALWAYS""".split()])
section("a widget's place in its grid cell (Grid.Place)")
add("set", [("Grid" + camel(k), "FL_GRID_" + k) for k in
            """CENTER TOP BOTTOM LEFT RIGHT HORIZONTAL VERTICAL FILL PROPORTIONAL
            TOP_LEFT TOP_RIGHT BOTTOM_LEFT BOTTOM_RIGHT""".split()])
section("what tabs do when there are too many to fit (Tabs.HandleOverflow)")
add("int", [("Overflow" + camel(k), "Fl_Tabs::OVERFLOW_" + k) for k in
            "COMPRESS CLIP PULLDOWN DRAG".split()])

module("FlMenus")
section("a menu item's flags (Menu.Add, Menu.ItemFlags); not FL_SUBMENU_POINTER")
add("set", [("MenuInactive", "FL_MENU_INACTIVE"), ("MenuToggle", "FL_MENU_TOGGLE"),
            ("MenuValue", "FL_MENU_VALUE"), ("MenuRadio", "FL_MENU_RADIO"),
            ("MenuInvisible", "FL_MENU_INVISIBLE"), ("Submenu", "FL_SUBMENU"),
            ("MenuDivider", "FL_MENU_DIVIDER")])
section("kinds of menu button (MenuButton.SetKind): the mouse buttons that pop it up")
add("int", [("Popup" + k, "Fl_Menu_Button::POPUP" + k) for k in
            "1 2 12 3 13 23 123".split()])

module("FlDialogs")
section("kinds of beep (Beep)")
add("int", [("Beep" + camel(k), "FL_BEEP_" + k) for k in
            "DEFAULT MESSAGE ERROR QUESTION PASSWORD NOTIFICATION".split()])

# Not constants of Fl, but values the test also checks against C: what Fl's
# procedures compute in Oberon.
CHECKS = [
    ("Fl.GrayRamp(0)", "fl_gray_ramp(0)"), ("Fl.GrayRamp(23)", "fl_gray_ramp(23)"),
    ("Fl.ColorCube(0, 0, 0)", "fl_color_cube(0, 0, 0)"),
    ("Fl.ColorCube(4, 7, 4)", "fl_color_cube(4, 7, 4)"),
    ("Fl.ColorCube(1, 2, 3)", "fl_color_cube(1, 2, 3)"),
    ("Fl.RGB(255, 0, 0)", "fl_rgb_color(255, 0, 0)"),
    ("Fl.RGB(1, 2, 3)", "fl_rgb_color(1, 2, 3)"),
    ("Fl.RGB(0, 0, 255)", "fl_rgb_color(0, 0, 255)"),
]

HEADERS = ("#include <FL/Fl.H>\n#include <FL/Enumerations.H>\n#include <FL/fl_draw.H>\n"
           "#include <FL/Fl_Button.H>\n#include <FL/Fl_Counter.H>\n#include <FL/Fl_Dial.H>\n"
           "#include <FL/Fl_Input_.H>\n#include <FL/Fl_Slider.H>\n#include <FL/Fl_Valuator.H>\n"
           "#include <FL/Fl_Flex.H>\n#include <FL/Fl_Grid.H>\n#include <FL/Fl_Pack.H>\n"
           "#include <FL/Fl_Scroll.H>\n#include <FL/Fl_Tabs.H>\n"
           "#include <FL/Fl_Menu_Item.H>\n#include <FL/Fl_Menu_Button.H>\n#include <FL/fl_ask.H>\n"
           "#include <stdint.h>\n#include <stdio.h>\n")

def oberon_set(v):
    bits = [str(i) for i in range(32) if v >> i & 1]
    assert v >> 32 == 0, v
    return "{" + ", ".join(bits) + "}"

def values():
    """Each SPEC expression's value, from a C++ program compiled against
    the installed FLTK."""
    exprs = [e for _, e, k, _ in SPEC if k != "comment"]
    prog = HEADERS + "int main() {\n" + "".join(
        '  printf("%%lld\\n", (long long)(int32_t)(%s));\n' % e for e in exprs) + "}\n"
    flags = subprocess.check_output(["fltk-config", "--cxxflags"], text=True).split()
    flags = [f for f in flags if f.startswith(("-I", "-D")) and f != "-I/usr/include"]
    libs = subprocess.check_output(["fltk-config", "--ldflags"], text=True).split()
    with tempfile.TemporaryDirectory() as d:
        src, exe = os.path.join(d, "v.cpp"), os.path.join(d, "v")
        open(src, "w").write(prog)
        subprocess.check_call(["clang++", "-std=c++11", *flags, src, "-o", exe, *libs])
        out = subprocess.check_output([exe], text=True).split()
    return dict(zip(exprs, (int(v) for v in out)))

def oberon_block(vals, mod):
    lines = ["(* BEGIN generated constants: tools/gen-constants.py writes this block,",
             "   from FLTK's headers; edit the script, not the block. *)"]
    for name, expr, kind, m in SPEC:
        if m != mod:
            continue
        if kind == "comment":
            lines += ["", "  (* %s *)" % name]
            continue
        v = vals[expr]
        text = oberon_set(v & 0xFFFFFFFF) if kind == "set" else str(v)
        lines.append("  %s* = %s;" % (name, text))
    lines.append("(* END generated constants *)")
    return "\n".join(lines)

def write_modules(vals):
    pat = re.compile(r"\(\* BEGIN generated constants.*?\(\* END generated constants \*\)", re.S)
    for mod in MODULES:
        path = "src/%s.Mod" % mod
        s = open(path).read()
        if not pat.search(s):
            sys.exit("gen-constants.py: no generated-constants block in " + path)
        s = pat.sub(lambda m: oberon_block(vals, mod), s)
        open(path, "w").write(s)

def write_test():
    entries = [(n, e, k, m) for n, e, k, m in SPEC if k != "comment"]
    table = ",\n".join('  {"%s", (int32_t)(%s)}' % (e, e) for _, e, _, _ in entries)
    table += ",\n" + ",\n".join('  {"%s", (int32_t)(%s)}' % (c, c) for _, c in CHECKS)
    open("test/CConstants.cpp", "w").write(
        "// Written by tools/gen-constants.py: FLTK's values of the constants\n"
        "// TestConstants checks Fl's against. Edit the script, not this file.\n\n"
        + HEADERS + "#include <string.h>\n\nnamespace {\n\nstruct Entry {\n"
        "  const char *name;\n  int32_t value;\n};\n\nconst Entry entries[] = {\n"
        + table + "\n};\n\n}  // namespace\n\nextern \"C\" {\n\n"
        "// The value of the C expression name, in *value; 0 if the table hasn't it.\n"
        "int32_t ofltest_constant(const char *name, int32_t *value) {\n"
        "  for (const Entry &e : entries) {\n"
        "    if (strcmp(e.name, name) == 0) {\n"
        "      *value = e.value;\n      return 1;\n    }\n  }\n  return 0;\n}\n\n"
        "}  // extern \"C\"\n")
    open("test/CConstants.Mod", "w").write(
        "MODULE CConstants; (* FLTK's values of C expressions, for TestConstants *)\n\n"
        "(* Written by tools/gen-constants.py; its C++ part is CConstants.cpp. *)\n\n"
        "IMPORT SYSTEM;\n\n"
        'PROCEDURE ["C", "ofltest_constant"] CConstant(name: ARRAY OF CHAR; VAR value: SYSTEM.INT32): SYSTEM.INT32;\n\n'
        "(* The value of the C expression name, in value; FALSE if there is none. *)\n"
        "PROCEDURE Value*(name-: ARRAY OF CHAR; VAR value: INTEGER): BOOLEAN;\n"
        "  VAR v: SYSTEM.INT32;\n"
        "BEGIN\n  v := 0;\n  IF CConstant(name, v) # 0 THEN value := v; RETURN TRUE END;\n"
        "  RETURN FALSE\nEND Value;\n\nEND CConstants.\n")
    checks = []
    for name, expr, kind, mod in entries:
        # A SET's bits by SYSTEM.VAL: poc can't compile ORD of a SET under
        # -OC (AGENTS.md, "poc problems").
        q = "%s.%s" % (mod, name)
        o = "SYSTEM.VAL(INTEGER, %s)" % q if kind == "set" else q
        checks.append('  Same(%s, "%s");' % (o, expr))
    for o, c in CHECKS:
        checks.append('  Same(%s, "%s");' % (o, c))
    open("test/TestConstants.Mod", "w").write(
        "MODULE TestConstants; (* ofltk's constants are FLTK's *)\n\n"
        "(* Written by tools/gen-constants.py: one check per constant, against the\n"
        "   value the installed FLTK's headers give (CConstants). A failure means\n"
        "   FLTK's headers changed: run the script again, and see what moved. *)\n\n"
        "IMPORT SYSTEM, Out, " + ", ".join(MODULES) + ", Check, CConstants;\n\n"
        "VAR checked, wrong: INTEGER;\n\n"
        "PROCEDURE Same(oberon: INTEGER; c-: ARRAY OF CHAR);\n"
        "  VAR v: INTEGER;\nBEGIN\n  INC(checked);\n"
        "  IF ~CConstants.Value(c, v) OR (v # oberon) THEN\n"
        '    INC(wrong); Out.String("  differs from C: "); Out.String(c); Out.Ln\n'
        "  END\nEND Same;\n\nBEGIN\n  checked := 0; wrong := 0;\n"
        + "\n".join(checks) + "\n"
        '  Check.Check((wrong = 0) & (checked = %d), "each of %d constants and values is FLTK\'s");\n'
        % (len(checks), len(checks))
        + "  Check.Summary\nEND TestConstants.\n")

def main():
    vals = values()
    write_modules(vals)
    write_test()
    print("gen-constants.py: %d constants, %d other values" %
          (sum(1 for s in SPEC if s[2] != "comment"), len(CHECKS)))

main()
