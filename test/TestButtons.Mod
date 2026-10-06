MODULE TestButtons; (* FlButtons: values, kinds, radio groups, shortcuts, repeating *)

(* Clicks and keys are sent as from the window system (Probe), to a window
   never shown. *)

IMPORT Fl, FlButtons, Check, Probe;

TYPE
  (* counts its Callback runs, and notes its value in the last one *)
  Counted = POINTER TO RECORD (FlButtons.ButtonDesc) calls: INTEGER; seen, changed: BOOLEAN END;

VAR
  win: Fl.Window;
  push: Counted;
  toggle: FlButtons.ToggleButton;
  check: FlButtons.CheckButton;
  light: FlButtons.LightButton;
  round: FlButtons.RoundButton;
  ret: FlButtons.ReturnButton;
  rep: FlButtons.RepeatButton;
  group: Fl.Group;
  r1: FlButtons.RadioButton; r2: FlButtons.RadioLightButton; r3: FlButtons.RadioRoundButton;
  r4: FlButtons.CheckButton;
  calls, before, i: INTEGER;
  held: BOOLEAN;
  key: INTEGER; state: SET;
  timer: Fl.Timer;
  done: BOOLEAN;

PROCEDURE (b: Counted) Callback*;
BEGIN INC(b.calls); b.seen := b.Value(); b.changed := b.Changed()
END Callback;

PROCEDURE Count(w: Fl.Widget);
BEGIN INC(calls)
END Count;

PROCEDURE Done(t: Fl.Timer);
BEGIN done := TRUE
END Done;

(* Handles events for seconds. *)
PROCEDURE WaitFor(seconds: LONGREAL);
BEGIN
  done := FALSE; Fl.AddTimeout(timer, seconds);
  WHILE ~done DO Fl.Wait(1.0D0) END
END WaitFor;

PROCEDURE Press(w: Fl.Widget);
BEGIN held := Probe.Mouse(win, Fl.EvPush, w.X() + 5, w.Y() + 5, Fl.LeftMouse, Fl.Button1, 0)
END Press;

PROCEDURE Release(w: Fl.Widget);
BEGIN held := Probe.Mouse(win, Fl.EvRelease, w.X() + 5, w.Y() + 5, Fl.LeftMouse, {}, 0)
END Release;

PROCEDURE Click(w: Fl.Widget);
BEGIN Press(w); Release(w)
END Click;

BEGIN
  NEW(timer); timer.action := Done;
  NEW(win); Fl.OpenWindow(win, 400, 300, "TestButtons");
  NEW(push); FlButtons.OpenButton(push, 10, 10, 80, 25, "push");
  NEW(toggle); FlButtons.OpenToggleButton(toggle, 100, 10, 80, 25, "toggle");
  NEW(check); FlButtons.OpenCheckButton(check, 190, 10, 80, 25, "check");
  NEW(light); FlButtons.OpenLightButton(light, 280, 10, 80, 25, "light");
  NEW(round); FlButtons.OpenRoundButton(round, 10, 40, 80, 25, "round");
  NEW(ret); FlButtons.OpenReturnButton(ret, 100, 40, 80, 25, "return");
  NEW(rep); FlButtons.OpenRepeatButton(rep, 190, 40, 80, 25, "repeat");
  NEW(group); Fl.OpenGroup(group, 10, 100, 380, 40, "");
  NEW(r1); FlButtons.OpenRadioButton(r1, 10, 100, 80, 25, "r1");
  NEW(r2); FlButtons.OpenRadioLightButton(r2, 100, 100, 80, 25, "r2");
  NEW(r3); FlButtons.OpenRadioRoundButton(r3, 190, 100, 80, 25, "r3");
  NEW(r4); FlButtons.OpenCheckButton(r4, 280, 100, 80, 25, "r4");
  group.End;
  win.End;

  (* a push button *)
  Check.Check(~push.Value() & (push.Kind() = FlButtons.Normal) & (push.When() = Fl.WhenRelease),
    "a push button starts off, Normal, calling back on release");
  Press(push);
  Check.Check(held & push.Value() & (push.calls = 0), "it is on while held, and hasn't called back");
  Release(push);
  Check.Check(~push.Value() & (push.calls = 1) & ~push.seen,
    "released over it: one Callback, which sees it off again");
  Check.Check(push.changed & ~push.Changed(),
    "Changed is TRUE in the Callback, and FALSE once it returns");
  push.SetValue(TRUE);
  Check.Check(push.Value() & (push.calls = 1), "SetValue sets the value, without a Callback");
  push.SetValue(FALSE);

  (* toggles *)
  toggle.action := Count; calls := 0;
  Click(toggle);
  Check.Check(toggle.Value() & (calls = 1), "a toggle button: one click turns it on");
  Click(toggle);
  Check.Check(~toggle.Value() & (calls = 2), "and one more off");
  Check.Check((toggle.Kind() = FlButtons.Toggle) & (check.Kind() = FlButtons.Toggle)
    & (light.Kind() = FlButtons.Toggle) & (round.Kind() = FlButtons.Toggle),
    "toggle, check, light and round buttons are Toggle");
  Click(check); Click(light); Click(round);
  Check.Check(check.Value() & light.Value() & round.Value(), "and each toggles when clicked");

  (* radio groups *)
  Check.Check((r1.Kind() = FlButtons.Radio) & (r2.Kind() = FlButtons.Radio) & (r3.Kind() = FlButtons.Radio),
    "the Radio types are Radio");
  r4.SetKind(FlButtons.Radio);
  Click(r2);
  Check.Check(~r1.Value() & r2.Value() & ~r3.Value() & ~r4.Value(), "clicking a radio button turns it on");
  Click(r3);
  Check.Check(~r1.Value() & ~r2.Value() & r3.Value() & ~r4.Value(), "and its group's others off");
  Click(r4);
  Check.Check(~r3.Value() & r4.Value(), "a check button made Radio joins the group");
  Click(r4);
  Check.Check(r4.Value(), "clicking an on radio button leaves it on");
  r1.SetOnly;
  Check.Check(r1.Value() & ~r2.Value() & ~r3.Value() & ~r4.Value(), "SetOnly is a click without the Callback");
  r2.SetValue(TRUE);
  Check.Check(r1.Value() & r2.Value(), "SetValue on a radio button leaves the others");

  (* shortcuts *)
  push.SetShortcut(ORD("x"), Fl.Ctrl);
  push.Shortcut(key, state);
  Check.Check((key = ORD("x")) & (state = Fl.Ctrl), "a shortcut reads back as key and state");
  before := push.calls;
  Check.Check(Probe.Shortcut(win, ORD("x"), Fl.Ctrl, "x") & (push.calls = before + 1),
    "typing the shortcut clicks the button");
  Check.Check(~Probe.Shortcut(win, ORD("x"), {}, "x") & (push.calls = before + 1),
    "the key without Ctrl doesn't");
  ret.action := Count; calls := 0;
  Check.Check(Probe.Shortcut(win, Fl.KeyEnter, {}, 0DX) & (calls = 1),
    "Enter clicks a return button");
  push.SetShortcut(0, {});

  (* other settings *)
  push.SetDownBox(Fl.FlatBox);
  Check.Check(push.DownBox() = Fl.FlatBox, "the down box reads back");

  (* repeating: FLTK waits 0.5 s, then repeats every 0.1 s *)
  rep.action := Count; calls := 0;
  Press(rep);
  (* up to 5 s, not 1: valgrind is slow *)
  i := 0; WHILE (calls < 3) & (i < 20) DO WaitFor(0.25D0); INC(i) END;
  Check.Check(calls >= 3, "a held repeat button calls back again and again");
  rep.Deactivate;
  before := calls;
  WaitFor(0.5D0);
  Check.Check((calls = before) & ~rep.Active(),
    "deactivating it stops the repeating (FLTK's FL_DEACTIVATE, through Handle)");
  Release(rep);

  win.Delete;
  Check.Check((Fl.OpenWidgets() = 0) & (Fl.PendingTimers() = 0), "every widget deleted, no timer pending");
  Check.Summary
END TestButtons.
