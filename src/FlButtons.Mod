MODULE FlButtons; (* Buttons: push, toggle, radio, check, light, round, return, repeat *)

(* Each type is FLTK's class of the same name, opened by its own Open
   procedure, and extends the one FLTK's extends. A button's Callback runs
   when it is clicked (by default when the mouse is released over it:
   Fl.WhenRelease), or its shortcut is typed.

   A button's value is TRUE while it is on: a toggle or radio button
   between clicks, a push button while it is held. Radio buttons in the
   same group turn each other off. A check, light or round button is a
   toggle button unless it is one of the Radio types.

   The C++ part is FlButtons.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* kinds of button (Button.SetKind); not ToggleButton and RadioButton, the types *)
  Normal* = 0;
  Toggle* = 1;
  Radio* = 102;
  Hidden* = 3;
(* END generated constants *)

  (* the classes, as ofl_button_new numbers them *)
  button = 0; check = 1; light = 2; round = 3; radio = 4; radioLight = 5;
  radioRound = 6; return = 7; repeat = 8; toggle = 9;

  keyMask = 10000H;  (* FL_KEY_MASK + 1: a shortcut's key is below it *)

TYPE
  Button* = POINTER TO ButtonDesc;
  ButtonDesc* = RECORD (Fl.WidgetDesc) END;

  (* a toggle button with a light that shows its value *)
  LightButton* = POINTER TO LightButtonDesc;
  LightButtonDesc* = RECORD (ButtonDesc) END;

  (* a light button whose light is a check box, or a round one *)
  CheckButton* = POINTER TO CheckButtonDesc;
  CheckButtonDesc* = RECORD (LightButtonDesc) END;

  RoundButton* = POINTER TO RoundButtonDesc;
  RoundButtonDesc* = RECORD (LightButtonDesc) END;

  (* radio buttons: a plain one, a light one, a round one *)
  RadioButton* = POINTER TO RadioButtonDesc;
  RadioButtonDesc* = RECORD (ButtonDesc) END;

  RadioLightButton* = POINTER TO RadioLightButtonDesc;
  RadioLightButtonDesc* = RECORD (LightButtonDesc) END;

  RadioRoundButton* = POINTER TO RadioRoundButtonDesc;
  RadioRoundButtonDesc* = RECORD (RoundButtonDesc) END;

  (* a push button drawn as the default, whose shortcut is the Enter key *)
  ReturnButton* = POINTER TO ReturnButtonDesc;
  ReturnButtonDesc* = RECORD (ButtonDesc) END;

  (* a push button whose Callback runs again and again while it is held,
     until it is released or deactivated *)
  RepeatButton* = POINTER TO RepeatButtonDesc;
  RepeatButtonDesc* = RECORD (ButtonDesc) END;

  ToggleButton* = POINTER TO ToggleButtonDesc;
  ToggleButtonDesc* = RECORD (ButtonDesc) END;

PROCEDURE ["C", "ofl_button_new"] CNew(class, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_button_value"] CValue(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_button_set_value"] CSetValue(b: SYSTEM.ADDRESS; v: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_button_setonly"] CSetOnly(b: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_button_type"] CType(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_button_set_type"] CSetType(b: SYSTEM.ADDRESS; t: SYSTEM.INT32);
PROCEDURE ["C", "ofl_button_shortcut"] CShortcut(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_button_set_shortcut"] CSetShortcut(b: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_button_down_box"] CDownBox(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_button_set_down_box"] CSetDownBox(b: SYSTEM.ADDRESS; t: SYSTEM.INT32);

PROCEDURE Open(b: Button; class, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(b, CNew(class, x, y, w, h, label, Fl.BeginOpen(b)))
END Open;

(* Opening each type. x, y are relative to the window, as FLTK's are; the
   label is copied. *)

PROCEDURE OpenButton*(b: Button; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, button, x, y, w, h, label)
END OpenButton;

PROCEDURE OpenLightButton*(b: LightButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, light, x, y, w, h, label)
END OpenLightButton;

PROCEDURE OpenCheckButton*(b: CheckButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, check, x, y, w, h, label)
END OpenCheckButton;

PROCEDURE OpenRoundButton*(b: RoundButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, round, x, y, w, h, label)
END OpenRoundButton;

PROCEDURE OpenRadioButton*(b: RadioButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, radio, x, y, w, h, label)
END OpenRadioButton;

PROCEDURE OpenRadioLightButton*(b: RadioLightButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, radioLight, x, y, w, h, label)
END OpenRadioLightButton;

PROCEDURE OpenRadioRoundButton*(b: RadioRoundButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, radioRound, x, y, w, h, label)
END OpenRadioRoundButton;

PROCEDURE OpenReturnButton*(b: ReturnButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, return, x, y, w, h, label)
END OpenReturnButton;

PROCEDURE OpenRepeatButton*(b: RepeatButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, repeat, x, y, w, h, label)
END OpenRepeatButton;

PROCEDURE OpenToggleButton*(b: ToggleButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(b, toggle, x, y, w, h, label)
END OpenToggleButton;

(* Button *)

PROCEDURE (b: Button) Value*(): BOOLEAN;
BEGIN RETURN CValue(Fl.Live(b)) # 0
END Value;

(* Turns b on or off, without calling its Callback. Turning on a radio
   button this way leaves the others in its group as they are: see
   SetOnly. *)
PROCEDURE (b: Button) SetValue*(v: BOOLEAN);
  VAR changed: SYSTEM.INT32;
BEGIN
  IF v THEN changed := CSetValue(Fl.Live(b), 1) ELSE changed := CSetValue(Fl.Live(b), 0) END
END SetValue;

(* Turns b on, and every other radio button in its group off, as clicking
   it does; for a radio button. *)
PROCEDURE (b: Button) SetOnly*;
BEGIN CSetOnly(Fl.Live(b))
END SetOnly;

(* How b behaves when clicked: Normal, Toggle or Radio (Hidden is for
   XForms programs). Each type starts with its own kind. *)
PROCEDURE (b: Button) Kind*(): INTEGER;
BEGIN RETURN CType(Fl.Live(b))
END Kind;

PROCEDURE (b: Button) SetKind*(k: INTEGER);
BEGIN CSetType(Fl.Live(b), k)
END SetKind;

(* The key that clicks b, with the shift keys that must be held: key is
   a character's code or one of Fl's Key constants, state a set of Fl's
   Shift, Ctrl, Alt, Meta and Command. Key 0 is no shortcut. *)
PROCEDURE (b: Button) Shortcut*(VAR key: INTEGER; VAR state: SET);
  VAR s: INTEGER;
BEGIN
  s := CShortcut(Fl.Live(b));
  key := s MOD keyMask; state := SYSTEM.VAL(SET, s - key)
END Shortcut;

PROCEDURE (b: Button) SetShortcut*(key: INTEGER; state: SET);
BEGIN CSetShortcut(Fl.Live(b), key + ORD(state))
END SetShortcut;

(* The box drawn while b is on: a box type of Fl's. *)
PROCEDURE (b: Button) DownBox*(): INTEGER;
BEGIN RETURN CDownBox(Fl.Live(b))
END DownBox;

PROCEDURE (b: Button) SetDownBox*(t: INTEGER);
BEGIN CSetDownBox(Fl.Live(b), t)
END SetDownBox;

END FlButtons.
