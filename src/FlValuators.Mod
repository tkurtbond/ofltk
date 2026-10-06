MODULE FlValuators; (* Sliders, scrollbars, counters, dials, rollers, spinners, progress *)

(* A valuator has a real value between two bounds, which the user changes
   by dragging, clicking or typing. Each type is FLTK's class of the same
   name, opened by its own Open procedure. Its Callback runs, by default,
   whenever the user changes the value (Fl.WhenChanged); setting it from
   the program doesn't run it.

   Spinner, a field with arrows, is a group in FLTK, and Progress, a bar,
   a plain widget: neither is a Valuator, but each has a value and bounds
   of its own.

   The C++ part is FlValuators.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* kinds of valuator (Valuator.SetKind): of a roller, scrollbar or other valuator *)
  Vertical* = 0;
  Horizontal* = 1;

  (* of a slider or value slider *)
  VertSlider* = 0;
  HorSlider* = 1;
  VertFillSlider* = 2;
  HorFillSlider* = 3;
  VertNiceSlider* = 4;
  HorNiceSlider* = 5;

  (* of a dial *)
  NormalDial* = 0;
  LineDial* = 1;
  FillDial* = 2;

  (* of a counter *)
  NormalCounter* = 0;
  SimpleCounter* = 1;

  (* of a spinner (Spinner.SetKind): whole numbers, or real ones *)
  IntSpinner* = 2;
  FloatSpinner* = 1;
(* END generated constants *)

  (* the classes, as ofl_valuator_new numbers them *)
  slider = 0; valueSlider = 1; scrollbar = 2; counter = 3; dial = 4;
  roller = 5; adjuster = 6; valueInput = 7; valueOutput = 8;

TYPE
  (* FLTK's Fl_Valuator: never opened itself *)
  Valuator* = POINTER TO ValuatorDesc;
  ValuatorDesc* = RECORD (Fl.WidgetDesc) END;

  (* a knob in a trough; vertical to start with (SetKind) *)
  Slider* = POINTER TO SliderDesc;
  SliderDesc* = RECORD (ValuatorDesc) END;

  (* a slider that shows its value *)
  ValueSlider* = POINTER TO ValueSliderDesc;
  ValueSliderDesc* = RECORD (SliderDesc) END;

  (* a slider with arrows at its ends, for scrolling: its value is a
     whole number, the first line shown (ScrollValue) *)
  Scrollbar* = POINTER TO ScrollbarDesc;
  ScrollbarDesc* = RECORD (SliderDesc) END;

  (* the value, between arrows that step it *)
  Counter* = POINTER TO CounterDesc;
  CounterDesc* = RECORD (ValuatorDesc) END;

  Dial* = POINTER TO DialDesc;
  DialDesc* = RECORD (ValuatorDesc) END;

  (* a wheel seen edge on, dragged up and down, or across *)
  Roller* = POINTER TO RollerDesc;
  RollerDesc* = RECORD (ValuatorDesc) END;

  (* three buttons, each dragged to change the value by a step of its own *)
  Adjuster* = POINTER TO AdjusterDesc;
  AdjusterDesc* = RECORD (ValuatorDesc) END;

  (* the value, typed in, or dragged; and shown only, or dragged *)
  ValueInput* = POINTER TO ValueInputDesc;
  ValueInputDesc* = RECORD (ValuatorDesc) END;

  ValueOutput* = POINTER TO ValueOutputDesc;
  ValueOutputDesc* = RECORD (ValuatorDesc) END;

  (* a number typed in, or stepped by its up and down arrows *)
  Spinner* = POINTER TO SpinnerDesc;
  SpinnerDesc* = RECORD (Fl.GroupDesc) END;

  (* a bar filled in proportion to its value *)
  Progress* = POINTER TO ProgressDesc;
  ProgressDesc* = RECORD (Fl.WidgetDesc) END;

PROCEDURE ["C", "ofl_valuator_new"] CNew(class, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_spinner_new"] CSpinnerNew(x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_progress_new"] CProgressNew(x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_valuator_value"] CValue(v: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_valuator_set_value"] CSetValue(v: SYSTEM.ADDRESS; x: LONGREAL);
PROCEDURE ["C", "ofl_valuator_minimum"] CMinimum(v: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_valuator_maximum"] CMaximum(v: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_valuator_bounds"] CBounds(v: SYSTEM.ADDRESS; a, b: LONGREAL);
PROCEDURE ["C", "ofl_valuator_step"] CStep(v: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_valuator_set_step"] CSetStep(v: SYSTEM.ADDRESS; s: LONGREAL);
PROCEDURE ["C", "ofl_valuator_precision"] CPrecision(v: SYSTEM.ADDRESS; digits: SYSTEM.INT32);
PROCEDURE ["C", "ofl_valuator_round"] CRound(v: SYSTEM.ADDRESS; x: LONGREAL): LONGREAL;
PROCEDURE ["C", "ofl_valuator_clamp"] CClamp(v: SYSTEM.ADDRESS; x: LONGREAL): LONGREAL;
PROCEDURE ["C", "ofl_valuator_increment"] CIncrement(v: SYSTEM.ADDRESS; x: LONGREAL; n: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_valuator_format"] CFormat(v: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_valuator_type"] CType(v: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_valuator_set_type"] CSetType(v: SYSTEM.ADDRESS; t: SYSTEM.INT32);
PROCEDURE ["C", "ofl_valuator_soft"] CSoft(v: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_valuator_set_soft"] CSetSoft(v: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_valuator_textfont"] CTextFont(v: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_valuator_set_textfont"] CSetTextFont(v: SYSTEM.ADDRESS; f: SYSTEM.INT32);
PROCEDURE ["C", "ofl_valuator_textsize"] CTextSize(v: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_valuator_set_textsize"] CSetTextSize(v: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_valuator_textcolor"] CTextColor(v: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_valuator_set_textcolor"] CSetTextColor(v: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_slider_size"] CSliderSize(s: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_slider_set_size"] CSetSliderSize(s: SYSTEM.ADDRESS; v: LONGREAL);
PROCEDURE ["C", "ofl_slider_box"] CSliderBox(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_slider_set_box"] CSetSliderBox(s: SYSTEM.ADDRESS; b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_slider_scrollvalue"] CScrollValue(s: SYSTEM.ADDRESS; pos, size, first, total: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_scrollbar_linesize"] CLinesize(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_scrollbar_set_linesize"] CSetLinesize(s: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_counter_lstep"] CLStep(c: SYSTEM.ADDRESS; s: LONGREAL);
PROCEDURE ["C", "ofl_dial_angle1"] CAngle1(d: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dial_angle2"] CAngle2(d: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dial_angles"] CAngles(d: SYSTEM.ADDRESS; a, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_spinner_value"] CSpValue(s: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_spinner_set_value"] CSpSetValue(s: SYSTEM.ADDRESS; v: LONGREAL);
PROCEDURE ["C", "ofl_spinner_minimum"] CSpMinimum(s: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_spinner_maximum"] CSpMaximum(s: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_spinner_range"] CSpRange(s: SYSTEM.ADDRESS; a, b: LONGREAL);
PROCEDURE ["C", "ofl_spinner_step"] CSpStep(s: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_spinner_set_step"] CSpSetStep(s: SYSTEM.ADDRESS; v: LONGREAL);
PROCEDURE ["C", "ofl_spinner_wrap"] CSpWrap(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_spinner_set_wrap"] CSpSetWrap(s: SYSTEM.ADDRESS; w: SYSTEM.INT32);
PROCEDURE ["C", "ofl_spinner_type"] CSpType(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_spinner_set_type"] CSpSetType(s: SYSTEM.ADDRESS; t: SYSTEM.INT32);
PROCEDURE ["C", "ofl_spinner_color"] CSpColor(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_spinner_set_color"] CSpSetColor(s: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_spinner_selection_color"] CSpSelectionColor(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_spinner_set_selection_color"] CSpSetSelectionColor(s: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_spinner_textfont"] CSpTextFont(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_spinner_set_textfont"] CSpSetTextFont(s: SYSTEM.ADDRESS; f: SYSTEM.INT32);
PROCEDURE ["C", "ofl_spinner_textsize"] CSpTextSize(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_spinner_set_textsize"] CSpSetTextSize(s: SYSTEM.ADDRESS; z: SYSTEM.INT32);
PROCEDURE ["C", "ofl_spinner_textcolor"] CSpTextColor(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_spinner_set_textcolor"] CSpSetTextColor(s: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_progress_value"] CPrValue(p: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_progress_minimum"] CPrMinimum(p: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_progress_maximum"] CPrMaximum(p: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_progress_set_value"] CPrSetValue(p: SYSTEM.ADDRESS; v: LONGREAL);
PROCEDURE ["C", "ofl_progress_set_minimum"] CPrSetMinimum(p: SYSTEM.ADDRESS; v: LONGREAL);
PROCEDURE ["C", "ofl_progress_set_maximum"] CPrSetMaximum(p: SYSTEM.ADDRESS; v: LONGREAL);

PROCEDURE Open(v: Valuator; class, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(v, CNew(class, x, y, w, h, label, Fl.BeginOpen(v)))
END Open;

PROCEDURE Bool(b: BOOLEAN): SYSTEM.INT32;
BEGIN
  IF b THEN RETURN 1 END;
  RETURN 0
END Bool;

(* Opening each type. x, y are relative to the window, as FLTK's are; the
   label is copied. *)

PROCEDURE OpenSlider*(v: Slider; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(v, slider, x, y, w, h, label)
END OpenSlider;

PROCEDURE OpenValueSlider*(v: ValueSlider; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(v, valueSlider, x, y, w, h, label)
END OpenValueSlider;

PROCEDURE OpenScrollbar*(v: Scrollbar; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(v, scrollbar, x, y, w, h, label)
END OpenScrollbar;

PROCEDURE OpenCounter*(v: Counter; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(v, counter, x, y, w, h, label)
END OpenCounter;

PROCEDURE OpenDial*(v: Dial; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(v, dial, x, y, w, h, label)
END OpenDial;

PROCEDURE OpenRoller*(v: Roller; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(v, roller, x, y, w, h, label)
END OpenRoller;

PROCEDURE OpenAdjuster*(v: Adjuster; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(v, adjuster, x, y, w, h, label)
END OpenAdjuster;

PROCEDURE OpenValueInput*(v: ValueInput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(v, valueInput, x, y, w, h, label)
END OpenValueInput;

PROCEDURE OpenValueOutput*(v: ValueOutput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(v, valueOutput, x, y, w, h, label)
END OpenValueOutput;

PROCEDURE OpenSpinner*(s: Spinner; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(s, CSpinnerNew(x, y, w, h, label, Fl.BeginOpen(s)))
END OpenSpinner;

PROCEDURE OpenProgress*(p: Progress; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(p, CProgressNew(x, y, w, h, label, Fl.BeginOpen(p)))
END OpenProgress;

(* Valuator *)

PROCEDURE (v: Valuator) Value*(): LONGREAL;
BEGIN RETURN CValue(Fl.Live(v))
END Value;

(* Sets the value, as it is: unrounded and unclamped (Round, Clamp). It
   doesn't run the Callback, and clears Changed. *)
PROCEDURE (v: Valuator) SetValue*(x: LONGREAL);
BEGIN CSetValue(Fl.Live(v), x)
END SetValue;

(* The bounds: the value at the top or left, and at the bottom or right.
   The minimum may be the greater. 0 and 1 to start with. *)
PROCEDURE (v: Valuator) Minimum*(): LONGREAL;
BEGIN RETURN CMinimum(Fl.Live(v))
END Minimum;

PROCEDURE (v: Valuator) Maximum*(): LONGREAL;
BEGIN RETURN CMaximum(Fl.Live(v))
END Maximum;

PROCEDURE (v: Valuator) SetBounds*(min, max: LONGREAL);
BEGIN CBounds(Fl.Live(v), min, max)
END SetBounds;

(* The value moves in steps of this; 0, to start with, for none. *)
PROCEDURE (v: Valuator) Step*(): LONGREAL;
BEGIN RETURN CStep(Fl.Live(v))
END Step;

PROCEDURE (v: Valuator) SetStep*(s: LONGREAL);
BEGIN CSetStep(Fl.Live(v), s)
END SetStep;

(* Sets the step to 10 to the power -digits: 0 for whole numbers. *)
PROCEDURE (v: Valuator) SetPrecision*(digits: INTEGER);
BEGIN CPrecision(Fl.Live(v), digits)
END SetPrecision;

(* x to the nearest step; x within the bounds; and x rounded, plus n
   steps (n hundredths of the range if there is no step), unclamped. *)
PROCEDURE (v: Valuator) Round*(x: LONGREAL): LONGREAL;
BEGIN RETURN CRound(Fl.Live(v), x)
END Round;

PROCEDURE (v: Valuator) Clamp*(x: LONGREAL): LONGREAL;
BEGIN RETURN CClamp(Fl.Live(v), x)
END Clamp;

PROCEDURE (v: Valuator) Increment*(x: LONGREAL; n: INTEGER): LONGREAL;
BEGIN RETURN CIncrement(Fl.Live(v), x, n)
END Increment;

(* The value as v shows it, to the step's digits, truncated to fit s. *)
PROCEDURE (v: Valuator) Format*(VAR s: ARRAY OF CHAR);
BEGIN CFormat(Fl.Live(v), s, SHORT(LEN(s)))
END Format;

(* How v is drawn: Vertical or Horizontal, for a roller or scrollbar;
   VertSlider, HorFillSlider or another slider kind, for a slider;
   NormalDial, LineDial or FillDial; NormalCounter or SimpleCounter. *)
PROCEDURE (v: Valuator) Kind*(): INTEGER;
BEGIN RETURN CType(Fl.Live(v))
END Kind;

PROCEDURE (v: Valuator) SetKind*(k: INTEGER);
BEGIN CSetType(Fl.Live(v), k)
END SetKind;

(* Slider *)

(* The knob's length, as a fraction of the trough's, from 0 to 1. *)
PROCEDURE (s: Slider) SliderSize*(): LONGREAL;
BEGIN RETURN CSliderSize(Fl.Live(s))
END SliderSize;

PROCEDURE (s: Slider) SetSliderSize*(v: LONGREAL);
BEGIN CSetSliderSize(Fl.Live(s), v)
END SetSliderSize;

(* The knob's box type. *)
PROCEDURE (s: Slider) SliderBox*(): INTEGER;
BEGIN RETURN CSliderBox(Fl.Live(s))
END SliderBox;

PROCEDURE (s: Slider) SetSliderBox*(b: INTEGER);
BEGIN CSetSliderBox(Fl.Live(s), b)
END SetSliderBox;

(* Sets the bounds, knob and value for scrolling: of total lines, from
   first, size are shown, from pos. *)
PROCEDURE (s: Slider) ScrollValue*(pos, size, first, total: INTEGER);
  VAR r: SYSTEM.INT32;
BEGIN r := CScrollValue(Fl.Live(s), pos, size, first, total)
END ScrollValue;

(* ValueSlider: the shown value's font, size and color *)

PROCEDURE (v: ValueSlider) TextFont*(): INTEGER;
BEGIN RETURN CTextFont(Fl.Live(v))
END TextFont;

PROCEDURE (v: ValueSlider) SetTextFont*(f: INTEGER);
BEGIN CSetTextFont(Fl.Live(v), f)
END SetTextFont;

PROCEDURE (v: ValueSlider) TextSize*(): INTEGER;
BEGIN RETURN CTextSize(Fl.Live(v))
END TextSize;

PROCEDURE (v: ValueSlider) SetTextSize*(s: INTEGER);
BEGIN CSetTextSize(Fl.Live(v), s)
END SetTextSize;

PROCEDURE (v: ValueSlider) TextColor*(): INTEGER;
BEGIN RETURN CTextColor(Fl.Live(v))
END TextColor;

PROCEDURE (v: ValueSlider) SetTextColor*(c: INTEGER);
BEGIN CSetTextColor(Fl.Live(v), c)
END SetTextColor;

(* Scrollbar *)

(* How many lines an arrow scrolls by; 16 to start with. *)
PROCEDURE (s: Scrollbar) Linesize*(): INTEGER;
BEGIN RETURN CLinesize(Fl.Live(s))
END Linesize;

PROCEDURE (s: Scrollbar) SetLinesize*(n: INTEGER);
BEGIN CSetLinesize(Fl.Live(s), n)
END SetLinesize;

(* Counter *)

(* The step of the outer, fast arrows; the inner ones step by Step. *)
PROCEDURE (c: Counter) SetLargeStep*(s: LONGREAL);
BEGIN CLStep(Fl.Live(c), s)
END SetLargeStep;

PROCEDURE (c: Counter) TextFont*(): INTEGER;
BEGIN RETURN CTextFont(Fl.Live(c))
END TextFont;

PROCEDURE (c: Counter) SetTextFont*(f: INTEGER);
BEGIN CSetTextFont(Fl.Live(c), f)
END SetTextFont;

PROCEDURE (c: Counter) TextSize*(): INTEGER;
BEGIN RETURN CTextSize(Fl.Live(c))
END TextSize;

PROCEDURE (c: Counter) SetTextSize*(s: INTEGER);
BEGIN CSetTextSize(Fl.Live(c), s)
END SetTextSize;

PROCEDURE (c: Counter) TextColor*(): INTEGER;
BEGIN RETURN CTextColor(Fl.Live(c))
END TextColor;

PROCEDURE (c: Counter) SetTextColor*(col: INTEGER);
BEGIN CSetTextColor(Fl.Live(c), col)
END SetTextColor;

(* Dial *)

(* The angles of the minimum and maximum, in degrees clockwise from six
   o'clock; 45 and 315 to start with. *)
PROCEDURE (d: Dial) Angle1*(): INTEGER;
BEGIN RETURN CAngle1(Fl.Live(d))
END Angle1;

PROCEDURE (d: Dial) Angle2*(): INTEGER;
BEGIN RETURN CAngle2(Fl.Live(d))
END Angle2;

PROCEDURE (d: Dial) SetAngles*(a1, a2: INTEGER);
BEGIN CAngles(Fl.Live(d), a1, a2)
END SetAngles;

(* Adjuster *)

(* Whether the user may go past the bounds; TRUE to start with. *)
PROCEDURE (a: Adjuster) Soft*(): BOOLEAN;
BEGIN RETURN CSoft(Fl.Live(a)) # 0
END Soft;

PROCEDURE (a: Adjuster) SetSoft*(s: BOOLEAN);
BEGIN CSetSoft(Fl.Live(a), Bool(s))
END SetSoft;

(* ValueInput *)

PROCEDURE (v: ValueInput) Soft*(): BOOLEAN;
BEGIN RETURN CSoft(Fl.Live(v)) # 0
END Soft;

PROCEDURE (v: ValueInput) SetSoft*(s: BOOLEAN);
BEGIN CSetSoft(Fl.Live(v), Bool(s))
END SetSoft;

PROCEDURE (v: ValueInput) TextFont*(): INTEGER;
BEGIN RETURN CTextFont(Fl.Live(v))
END TextFont;

PROCEDURE (v: ValueInput) SetTextFont*(f: INTEGER);
BEGIN CSetTextFont(Fl.Live(v), f)
END SetTextFont;

PROCEDURE (v: ValueInput) TextSize*(): INTEGER;
BEGIN RETURN CTextSize(Fl.Live(v))
END TextSize;

PROCEDURE (v: ValueInput) SetTextSize*(s: INTEGER);
BEGIN CSetTextSize(Fl.Live(v), s)
END SetTextSize;

PROCEDURE (v: ValueInput) TextColor*(): INTEGER;
BEGIN RETURN CTextColor(Fl.Live(v))
END TextColor;

PROCEDURE (v: ValueInput) SetTextColor*(c: INTEGER);
BEGIN CSetTextColor(Fl.Live(v), c)
END SetTextColor;

(* ValueOutput *)

PROCEDURE (v: ValueOutput) Soft*(): BOOLEAN;
BEGIN RETURN CSoft(Fl.Live(v)) # 0
END Soft;

PROCEDURE (v: ValueOutput) SetSoft*(s: BOOLEAN);
BEGIN CSetSoft(Fl.Live(v), Bool(s))
END SetSoft;

PROCEDURE (v: ValueOutput) TextFont*(): INTEGER;
BEGIN RETURN CTextFont(Fl.Live(v))
END TextFont;

PROCEDURE (v: ValueOutput) SetTextFont*(f: INTEGER);
BEGIN CSetTextFont(Fl.Live(v), f)
END SetTextFont;

PROCEDURE (v: ValueOutput) TextSize*(): INTEGER;
BEGIN RETURN CTextSize(Fl.Live(v))
END TextSize;

PROCEDURE (v: ValueOutput) SetTextSize*(s: INTEGER);
BEGIN CSetTextSize(Fl.Live(v), s)
END SetTextSize;

PROCEDURE (v: ValueOutput) TextColor*(): INTEGER;
BEGIN RETURN CTextColor(Fl.Live(v))
END TextColor;

PROCEDURE (v: ValueOutput) SetTextColor*(c: INTEGER);
BEGIN CSetTextColor(Fl.Live(v), c)
END SetTextColor;

(* Spinner. Its Color, SelectionColor and the text's are its field's. *)

PROCEDURE (s: Spinner) Value*(): LONGREAL;
BEGIN RETURN CSpValue(Fl.Live(s))
END Value;

(* Sets the value, without running the Callback. A value that isn't
   whole needs Kind FloatSpinner. *)
PROCEDURE (s: Spinner) SetValue*(v: LONGREAL);
BEGIN CSpSetValue(Fl.Live(s), v)
END SetValue;

(* The bounds, 1 and 100 to start with. *)
PROCEDURE (s: Spinner) Minimum*(): LONGREAL;
BEGIN RETURN CSpMinimum(Fl.Live(s))
END Minimum;

PROCEDURE (s: Spinner) Maximum*(): LONGREAL;
BEGIN RETURN CSpMaximum(Fl.Live(s))
END Maximum;

PROCEDURE (s: Spinner) SetBounds*(min, max: LONGREAL);
BEGIN CSpRange(Fl.Live(s), min, max)
END SetBounds;

(* What the arrows add and subtract; 1 to start with. *)
PROCEDURE (s: Spinner) Step*(): LONGREAL;
BEGIN RETURN CSpStep(Fl.Live(s))
END Step;

PROCEDURE (s: Spinner) SetStep*(v: LONGREAL);
BEGIN CSpSetStep(Fl.Live(s), v)
END SetStep;

(* Whether stepping past a bound goes to the other; TRUE to start with. *)
PROCEDURE (s: Spinner) Wrap*(): BOOLEAN;
BEGIN RETURN CSpWrap(Fl.Live(s)) # 0
END Wrap;

PROCEDURE (s: Spinner) SetWrap*(w: BOOLEAN);
BEGIN CSpSetWrap(Fl.Live(s), Bool(w))
END SetWrap;

(* IntSpinner, to start with, or FloatSpinner. *)
PROCEDURE (s: Spinner) Kind*(): INTEGER;
BEGIN RETURN CSpType(Fl.Live(s))
END Kind;

PROCEDURE (s: Spinner) SetKind*(k: INTEGER);
BEGIN CSpSetType(Fl.Live(s), k)
END SetKind;

PROCEDURE (s: Spinner) Color*(): INTEGER;
BEGIN RETURN CSpColor(Fl.Live(s))
END Color;

PROCEDURE (s: Spinner) SetColor*(c: INTEGER);
BEGIN CSpSetColor(Fl.Live(s), c)
END SetColor;

PROCEDURE (s: Spinner) SelectionColor*(): INTEGER;
BEGIN RETURN CSpSelectionColor(Fl.Live(s))
END SelectionColor;

PROCEDURE (s: Spinner) SetSelectionColor*(c: INTEGER);
BEGIN CSpSetSelectionColor(Fl.Live(s), c)
END SetSelectionColor;

PROCEDURE (s: Spinner) TextFont*(): INTEGER;
BEGIN RETURN CSpTextFont(Fl.Live(s))
END TextFont;

PROCEDURE (s: Spinner) SetTextFont*(f: INTEGER);
BEGIN CSpSetTextFont(Fl.Live(s), f)
END SetTextFont;

PROCEDURE (s: Spinner) TextSize*(): INTEGER;
BEGIN RETURN CSpTextSize(Fl.Live(s))
END TextSize;

PROCEDURE (s: Spinner) SetTextSize*(z: INTEGER);
BEGIN CSpSetTextSize(Fl.Live(s), z)
END SetTextSize;

PROCEDURE (s: Spinner) TextColor*(): INTEGER;
BEGIN RETURN CSpTextColor(Fl.Live(s))
END TextColor;

PROCEDURE (s: Spinner) SetTextColor*(c: INTEGER);
BEGIN CSpSetTextColor(Fl.Live(s), c)
END SetTextColor;

(* Progress. FLTK keeps its values as REALs, so they are rounded to
   about 7 digits. *)

PROCEDURE (p: Progress) Value*(): LONGREAL;
BEGIN RETURN CPrValue(Fl.Live(p))
END Value;

PROCEDURE (p: Progress) SetValue*(v: LONGREAL);
BEGIN CPrSetValue(Fl.Live(p), v)
END SetValue;

(* The bounds, 0 and 100 to start with. *)
PROCEDURE (p: Progress) Minimum*(): LONGREAL;
BEGIN RETURN CPrMinimum(Fl.Live(p))
END Minimum;

PROCEDURE (p: Progress) Maximum*(): LONGREAL;
BEGIN RETURN CPrMaximum(Fl.Live(p))
END Maximum;

PROCEDURE (p: Progress) SetBounds*(min, max: LONGREAL);
BEGIN CPrSetMinimum(Fl.Live(p), min); CPrSetMaximum(Fl.Live(p), max)
END SetBounds;

END FlValuators.
