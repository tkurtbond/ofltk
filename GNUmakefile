# pofltk -- Oberon-2 binding to FLTK 1.4 for poc, the Peaseblossom Oberon
# Compiler.  See AGENTS.md and PLAN.md.
#
# poc builds a program from its main module's source, finding the modules
# it imports on the import path (src/, plus test/), and compiles every one
# of them again on each build; a module's C++ part, src/<Module>.cpp, is
# compiled by clang++ and linked with it, and a program with one is linked
# by clang++. What it writes - each module's .sym, .ll and .o, and the
# programs - goes into $(BUILD), so make must not build two at once.
#
# make install builds the poc library pofltk (-OC) in
# $(POC_OBERON_LIBRARIES)/pofltk, recording -lfltk_images -lfltk in its
# manifest, so a program using it needs only -library-path: no FLTK or C++
# flags.
# Both need poc 0.4.1: C++ parts, libraries that record link flags, and
# ORD of a SET under -OC.

POC      ?= poc
# The size model: decided in PLAN.md; never mix models.
POCFLAGS := -OC
VALGRIND ?= valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=none --error-exitcode=99 --suppressions=$(CURDIR)/test/poc-gc.supp
# Seconds a test may run before it counts as hung.
TIMEOUT  ?= 60
EXAMPLETIME ?= 3

BUILD := build

FLTK_CONFIG ?= fltk-config
# Only the -I and -D flags: the rest of --cxxflags is the distribution's
# own build flags (Fedora's -specs=... hardening files among them). Not
# -I/usr/include, which is searched anyway, and which ahead of the C++
# library's own directories breaks its #include_next.
FLTK_CXXFLAGS := $(filter-out -I/usr/include,$(filter -I% -D%,$(shell $(FLTK_CONFIG) --cxxflags)))
FLTK_LIBS     := $(shell $(FLTK_CONFIG) --use-images --ldflags)
# C++11, as FLTKAda's shim is, so code can move between them.
CXXFLAGS      := -std=c++11 -Wall -Wextra -Werror

POC_VERSION := $(shell $(POC) -version | sed -n 's/^poc \([0-9.]*\).*/\1/p')
# The case patterns are written (pattern) so make sees balanced parentheses.
ifeq ($(shell case "$(POC_VERSION)" in (0.[0-3].*|0.4.0) echo old;; esac),old)
  $(error pofltk needs poc 0.4.1 or later (C++ parts, libraries' link flags, ORD of a SET); $(POC) is $(POC_VERSION))
endif

MODULES := Fl FlDraw FlButtons FlInputs FlValuators FlLayout FlMenus FlDialogs FlText FlBrowsers FlImages FlPreferences FlTable
HEADERS := src/pofltk.h
LIBSRC  := $(MODULES:%=src/%.Mod) $(MODULES:%=src/%.cpp) $(HEADERS)
# Test modules with a C++ part (test/<Module>.cpp).
TESTCXX := CConstants Probe
TESTSRC := $(TESTCXX:%=test/%.Mod) $(TESTCXX:%=test/%.cpp)

CFLAGS := $(foreach f,$(FLTK_CXXFLAGS) $(CXXFLAGS),-c-flag $(f))
LINK   := $(CFLAGS) $(foreach f,$(FLTK_LIBS),-link $(f))

# Each library in its own directory under POC_OBERON_LIBRARIES, so a
# program names only the libraries it uses (as polibfyaml does).
POC_OBERON_LIBRARIES ?= /usr/local/sw/versions/oberon/poc/lib
LIBRARY := pofltk
LIBDIR   = $(POC_OBERON_LIBRARIES)/$(LIBRARY)
TRIPLE   = $(shell $(POC) -version | sed -n 's/^target \([^ ]*\).*/\1/p')

# Test programs (test/<name>.Mod, each a main module).
TESTS := TestLiveness TestDelete TestTimer TestConstants TestWidget TestDraw TestEvents TestButtons TestInputs TestValuators TestLayout TestMenus TestDialogs TestText TestBrowsers TestTree TestImages TestClipboard TestPreferences TestTable
# Programs that must halt (test/<name>.Mod), as name:ASSERT-code. poc's
# ASSERT(x, n) prints "assertion failed (n)" on standard error and exits
# with status 10, so `make test` requires both.
HALTTESTS := HaltNotOpen:70 HaltDeleted:70 HaltOpenTwice:71 HaltNil:72 HaltIndex:74 HaltRepeat:75 HaltGridRange:74 HaltNotAChild:76 HaltMenuItem:74 HaltClosedBuffer:73 HaltNoBuffer:73 HaltBrowserLine:74 HaltTreeItem:73 HaltClosedImage:73 HaltSurfaceOrder:77 HaltClosedGroup:73 HaltTableRow:74
ASSERTSTATUS := 10

# Example programs (examples/<name>.Mod). They wait for the user, so make
# builds them and make test doesn't run them.
EXAMPLES := Hello Scribble Swatch Menus TableSimple TreeSimple TextEditorSimple BrowserSimple GridSimple FlexSimple TabsSimple WizardSimple ProgressSimple NativeFileChooserSimple SvgSimple Callbacks DrawAnX TextOverImageButton DragAndDrop TableAsContainer TableWithKeynav TableWithRightClickMenu TableWithRightColumnStretchFit TableSpreadsheetWithKeyboardNav TextDisplayWithColors TextEditorWithDynamicColors NativeFileChooserSimpleApp

TESTBINS := $(TESTS:%=$(BUILD)/%)
HALTBINS := $(foreach h,$(HALTTESTS),$(BUILD)/$(firstword $(subst :, ,$(h))))
EXAMPLEBINS := $(EXAMPLES:%=$(BUILD)/%)

.PHONY: all tests test valgrind test-headless valgrind-headless test-sway valgrind-sway install uninstall clean display
.NOTPARALLEL:

all: tests

tests: $(TESTBINS) $(HALTBINS) $(EXAMPLEBINS)

$(BUILD):
	mkdir -p $@

$(BUILD)/Test%: test/Test%.Mod test/Check.Mod $(LIBSRC) $(TESTSRC) | $(BUILD)
	$(POC) $(POCFLAGS) -import-path src -import-path test -output-dir $(BUILD) $(LINK) -o $@ $<

$(EXAMPLEBINS): $(BUILD)/%: examples/%.Mod $(LIBSRC) | $(BUILD)
	$(POC) $(POCFLAGS) -import-path src -output-dir $(BUILD) $(LINK) -o $@ $<

$(BUILD)/Halt%: test/Halt%.Mod $(LIBSRC) | $(BUILD)
	$(POC) $(POCFLAGS) -import-path src -output-dir $(BUILD) $(LINK) -o $@ $<

# FLTK needs a display even for widgets never shown (PLAN.md, "Build and
# test"): run under X11 or Wayland, or headless (test-headless and
# test-sway below).
display:
	@if [ -z "$$DISPLAY$$WAYLAND_DISPLAY" ]; then \
	  echo "pofltk's tests need a display: set DISPLAY or WAYLAND_DISPLAY, or use make test-headless or make test-sway"; exit 1; \
	fi

# Run every test from test/; report all, fail at the end if any failed.
# Each halt test must exit with poc's ASSERT status and name its code on
# standard error. Each example waits for the user, so it must still be
# running after EXAMPLETIME seconds, when timeout ends it (status 124):
# it started, drew, and didn't crash.
test: tests display
	@status=0; for t in $(TESTS); do \
	  echo "== $$t"; (cd test && timeout $(TIMEOUT) ../$(BUILD)/$$t) || status=1; \
	done; \
	for h in $(HALTTESTS); do \
	  t=$${h%%:*}; code=$${h##*:}; echo "== $$t (must fail ASSERT code $$code)"; \
	  (cd test && timeout $(TIMEOUT) ../$(BUILD)/$$t) 2> $(BUILD)/$$t.err; got=$$?; \
	  if [ $$got -eq $(ASSERTSTATUS) ] && grep -q "assertion failed ($$code)" $(BUILD)/$$t.err; then \
	    echo "ok   - $$t: $$(cat $(BUILD)/$$t.err)"; \
	  else echo "FAIL - $$t exited with $$got: $$(cat $(BUILD)/$$t.err)"; status=1; fi; \
	done; \
	for e in $(EXAMPLES); do \
	  echo "== $$e (example: must still be running after $(EXAMPLETIME) s)"; \
	  (cd examples && timeout $(EXAMPLETIME) ../$(BUILD)/$$e) > $(BUILD)/$$e.out 2>&1; got=$$?; \
	  if [ $$got -eq 124 ]; then echo "ok   - $$e"; \
	  else echo "FAIL - $$e exited with $$got: $$(cat $(BUILD)/$$e.out)"; status=1; fi; \
	done; exit $$status

# Memory errors fail a test (--error-exitcode); leaks don't count as
# errors (--errors-for-leak-kinds=none), because FLTK's font cache and
# window decorations leak by design. test/vg-check.sh fails instead on any
# leaked block that pofltk allocated.
valgrind: tests display
	@status=0; for t in $(TESTS); do \
	  echo "== valgrind $$t"; \
	  (cd test && $(VALGRIND) --log-file=../$(BUILD)/$$t.vg ../$(BUILD)/$$t) || status=1; \
	  grep -E 'ERROR SUMMARY' $(BUILD)/$$t.vg; \
	  test/vg-check.sh $(BUILD)/$$t.vg || { echo "FAIL - $$t: memory pofltk allocated was not freed"; status=1; }; \
	done; exit $$status

# The same, on a virtual X server (Xvfb), not the desktop. WAYLAND_DISPLAY
# is unset because FLTK prefers Wayland when it is set, even under
# xvfb-run, which sets only DISPLAY; without it FLTK uses X11 (confirmed,
# PLAN.md Phase 0).
test-headless: tests
	env -u WAYLAND_DISPLAY xvfb-run -a $(MAKE) test

valgrind-headless: tests
	env -u WAYLAND_DISPLAY xvfb-run -a $(MAKE) valgrind

# The same on Wayland, on a headless sway (tools/with-sway.sh): a compositor
# with no screen, so no window appears on the desktop, where the user's
# input could reach it.
test-sway: tests
	tools/with-sway.sh $(MAKE) test

valgrind-sway: tests
	tools/with-sway.sh $(MAKE) valgrind

# Install only a library whose tests build: every test imports it. Built
# in $(BUILD)/lib/ with FLTK's -link flags, which the manifest records,
# then copied by poc -install-library: the archive (with Fl.cpp's object),
# the shared object, the manifest, and each module's .sym and .owner. A
# library records the poc that built it, and another poc refuses it:
# install again after upgrading poc.
install: tests
	cd src && $(POC) $(POCFLAGS) -output-dir $(abspath $(BUILD))/lib $(LINK) \
	  -library $(LIBRARY) $(MODULES:%=%.Mod)
	install -d $(LIBDIR)
	$(POC) $(POCFLAGS) -library-path $(BUILD)/lib -output-dir $(LIBDIR) -install-library $(LIBRARY)

# Remove what make install wrote, and only that.
uninstall:
	d=$(LIBDIR)/$(TRIPLE)/OC; \
	rm -f $$d/lib$(LIBRARY).a $$d/lib$(LIBRARY).so $$d/$(LIBRARY).library \
	  $(foreach x,$(MODULES),$$d/$(x).sym $$d/$(x).owner); \
	rmdir $$d 2>/dev/null; true

clean:
	rm -rf $(BUILD)
