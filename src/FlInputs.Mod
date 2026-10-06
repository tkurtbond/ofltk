MODULE FlInputs; (* Text inputs and outputs: one line or many, numbers, secrets *)

(* Each type is FLTK's class of the same name, opened by its own Open
   procedure. An input's Callback runs, by default, when the user leaves
   it with its text changed (Fl.WhenRelease); Fl.WhenChanged runs it on
   every change, and Fl.WhenEnterKey when Enter is typed.

   The text is UTF-8, and FLTK copies what it is given. Positions in it
   are byte offsets, from 0.

   The C++ part is FlInputs.cpp. *)

IMPORT SYSTEM, Fl;

CONST
  (* the classes, as ofl_input_new numbers them *)
  input = 0; intInput = 1; floatInput = 2; multilineInput = 3;
  secretInput = 4; output = 5; multilineOutput = 6;

  keyMask = 10000H;  (* FL_KEY_MASK + 1: a shortcut's key is below it *)

TYPE
  (* one line of text *)
  Input* = POINTER TO InputDesc;
  InputDesc* = RECORD (Fl.WidgetDesc) END;

  (* one line, taking only what may be part of a whole number (IntInput)
     or a real one (FloatInput) *)
  IntInput* = POINTER TO IntInputDesc;
  IntInputDesc* = RECORD (InputDesc) END;

  FloatInput* = POINTER TO FloatInputDesc;
  FloatInputDesc* = RECORD (InputDesc) END;

  (* many lines; Enter types a new line *)
  MultilineInput* = POINTER TO MultilineInputDesc;
  MultilineInputDesc* = RECORD (InputDesc) END;

  (* one line, shown as dots *)
  SecretInput* = POINTER TO SecretInputDesc;
  SecretInputDesc* = RECORD (InputDesc) END;

  (* text the user may select and copy, but not change; one line or many *)
  Output* = POINTER TO OutputDesc;
  OutputDesc* = RECORD (InputDesc) END;

  MultilineOutput* = POINTER TO MultilineOutputDesc;
  MultilineOutputDesc* = RECORD (OutputDesc) END;

PROCEDURE ["C", "ofl_input_new"] CNew(class, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_input_value"] CValue(i: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_set_value"] CSetValue(i: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_input_ivalue"] CIValue(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_dvalue"] CDValue(i: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_input_set_ivalue"] CSetIValue(i: SYSTEM.ADDRESS; v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_set_dvalue"] CSetDValue(i: SYSTEM.ADDRESS; v: LONGREAL);
PROCEDURE ["C", "ofl_input_size"] CSize(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_maximum_size"] CMaximumSize(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_maximum_size"] CSetMaximumSize(i: SYSTEM.ADDRESS; m: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_insert_position"] CInsertPosition(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_mark"] CMark(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_position"] CSetPosition(i: SYSTEM.ADDRESS; p, m: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_replace"] CReplace(i: SYSTEM.ADDRESS; b, e: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_cut"] CCut(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_cut_range"] CCutRange(i: SYSTEM.ADDRESS; a, b: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_insert"] CInsert(i: SYSTEM.ADDRESS; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_undo"] CUndo(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_redo"] CRedo(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_readonly"] CReadonly(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_readonly"] CSetReadonly(i: SYSTEM.ADDRESS; r: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_wrap"] CWrap(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_wrap"] CSetWrap(i: SYSTEM.ADDRESS; w: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_tab_nav"] CTabNav(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_tab_nav"] CSetTabNav(i: SYSTEM.ADDRESS; t: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_shortcut"] CShortcut(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_shortcut"] CSetShortcut(i: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_textfont"] CTextFont(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_textfont"] CSetTextFont(i: SYSTEM.ADDRESS; f: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_textsize"] CTextSize(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_textsize"] CSetTextSize(i: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_textcolor"] CTextColor(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_textcolor"] CSetTextColor(i: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_cursor_color"] CCursorColor(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_cursor_color"] CSetCursorColor(i: SYSTEM.ADDRESS; c: SYSTEM.INT32);

PROCEDURE Open(i: Input; class, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(i, CNew(class, x, y, w, h, label, Fl.BeginOpen(i)))
END Open;

PROCEDURE Bool(b: BOOLEAN): SYSTEM.INT32;
BEGIN
  IF b THEN RETURN 1 END;
  RETURN 0
END Bool;

(* Opening each type. x, y are relative to the window, as FLTK's are; the
   label, shown beside the input, is copied. *)

PROCEDURE OpenInput*(i: Input; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, input, x, y, w, h, label)
END OpenInput;

PROCEDURE OpenIntInput*(i: IntInput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, intInput, x, y, w, h, label)
END OpenIntInput;

PROCEDURE OpenFloatInput*(i: FloatInput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, floatInput, x, y, w, h, label)
END OpenFloatInput;

PROCEDURE OpenMultilineInput*(i: MultilineInput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, multilineInput, x, y, w, h, label)
END OpenMultilineInput;

PROCEDURE OpenSecretInput*(i: SecretInput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, secretInput, x, y, w, h, label)
END OpenSecretInput;

PROCEDURE OpenOutput*(i: Output; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, output, x, y, w, h, label)
END OpenOutput;

PROCEDURE OpenMultilineOutput*(i: MultilineOutput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, multilineOutput, x, y, w, h, label)
END OpenMultilineOutput;

(* The text *)

(* The text, truncated to fit s; Length gives its whole length. *)
PROCEDURE (i: Input) Value*(VAR s: ARRAY OF CHAR);
BEGIN CValue(Fl.Live(i), s, SHORT(LEN(s)))
END Value;

(* Replaces the text, without calling the Callback, and clears Changed. *)
PROCEDURE (i: Input) SetValue*(s-: ARRAY OF CHAR);
BEGIN CSetValue(Fl.Live(i), s)
END SetValue;

(* The text as a number: 0 if it doesn't start with one. *)
PROCEDURE (i: Input) IntValue*(): INTEGER;
BEGIN RETURN CIValue(Fl.Live(i))
END IntValue;

PROCEDURE (i: Input) RealValue*(): LONGREAL;
BEGIN RETURN CDValue(Fl.Live(i))
END RealValue;

(* Sets the text to the number, as SetValue does. *)
PROCEDURE (i: Input) SetIntValue*(v: INTEGER);
BEGIN CSetIValue(Fl.Live(i), v)
END SetIntValue;

PROCEDURE (i: Input) SetRealValue*(v: LONGREAL);
BEGIN CSetDValue(Fl.Live(i), v)
END SetRealValue;

(* The length of the text, in bytes. *)
PROCEDURE (i: Input) Length*(): INTEGER;
BEGIN RETURN CSize(Fl.Live(i))
END Length;

(* The most bytes the user may type in; 32767 to start with. *)
PROCEDURE (i: Input) MaximumSize*(): INTEGER;
BEGIN RETURN CMaximumSize(Fl.Live(i))
END MaximumSize;

PROCEDURE (i: Input) SetMaximumSize*(m: INTEGER);
BEGIN CSetMaximumSize(Fl.Live(i), m)
END SetMaximumSize;

(* The cursor, and the selection, which runs from the cursor to the mark;
   none if they are the same. *)
PROCEDURE (i: Input) InsertPosition*(): INTEGER;
BEGIN RETURN CInsertPosition(Fl.Live(i))
END InsertPosition;

PROCEDURE (i: Input) Mark*(): INTEGER;
BEGIN RETURN CMark(Fl.Live(i))
END Mark;

(* Puts the cursor at p and the mark at m, so selecting p .. m. *)
PROCEDURE (i: Input) Select*(p, m: INTEGER);
BEGIN CSetPosition(Fl.Live(i), p, m)
END Select;

(* Edits. Each is undoable, and returns FALSE if nothing changed. *)

(* Replaces bytes b .. e - 1 with s, and puts the cursor after it. *)
PROCEDURE (i: Input) Replace*(b, e: INTEGER; s-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CReplace(Fl.Live(i), b, e, s) # 0
END Replace;

(* Deletes the selection, without copying it. *)
PROCEDURE (i: Input) Cut*(): BOOLEAN;
BEGIN RETURN CCut(Fl.Live(i)) # 0
END Cut;

(* Deletes bytes a .. b - 1. *)
PROCEDURE (i: Input) CutRange*(a, b: INTEGER): BOOLEAN;
BEGIN RETURN CCutRange(Fl.Live(i), a, b) # 0
END CutRange;

(* Replaces the selection with s, or inserts s at the cursor. *)
PROCEDURE (i: Input) Insert*(s-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CInsert(Fl.Live(i), s) # 0
END Insert;

PROCEDURE (i: Input) Undo*(): BOOLEAN;
BEGIN RETURN CUndo(Fl.Live(i)) # 0
END Undo;

PROCEDURE (i: Input) Redo*(): BOOLEAN;
BEGIN RETURN CRedo(Fl.Live(i)) # 0
END Redo;

(* Settings *)

(* A read-only input is an output: the user may select, not change. *)
PROCEDURE (i: Input) Readonly*(): BOOLEAN;
BEGIN RETURN CReadonly(Fl.Live(i)) # 0
END Readonly;

PROCEDURE (i: Input) SetReadonly*(r: BOOLEAN);
BEGIN CSetReadonly(Fl.Live(i), Bool(r))
END SetReadonly;

(* Whether a multiline input or output wraps its lines at its width. *)
PROCEDURE (i: Input) Wrap*(): BOOLEAN;
BEGIN RETURN CWrap(Fl.Live(i)) # 0
END Wrap;

PROCEDURE (i: Input) SetWrap*(w: BOOLEAN);
BEGIN CSetWrap(Fl.Live(i), Bool(w))
END SetWrap;

(* Whether Tab moves the focus to the next widget (TRUE to start with),
   rather than typing a tab, in a multiline input. *)
PROCEDURE (i: Input) TabNav*(): BOOLEAN;
BEGIN RETURN CTabNav(Fl.Live(i)) # 0
END TabNav;

PROCEDURE (i: Input) SetTabNav*(t: BOOLEAN);
BEGIN CSetTabNav(Fl.Live(i), Bool(t))
END SetTabNav;

(* The key that gives i the focus, as a button's shortcut is. *)
PROCEDURE (i: Input) Shortcut*(VAR key: INTEGER; VAR state: SET);
  VAR s: INTEGER;
BEGIN
  s := CShortcut(Fl.Live(i));
  key := s MOD keyMask; state := SYSTEM.VAL(SET, s - key)
END Shortcut;

PROCEDURE (i: Input) SetShortcut*(key: INTEGER; state: SET);
BEGIN CSetShortcut(Fl.Live(i), key + SYSTEM.VAL(INTEGER, state))
END SetShortcut;

(* The text's font, size and color, and the cursor's color. *)
PROCEDURE (i: Input) TextFont*(): INTEGER;
BEGIN RETURN CTextFont(Fl.Live(i))
END TextFont;

PROCEDURE (i: Input) SetTextFont*(f: INTEGER);
BEGIN CSetTextFont(Fl.Live(i), f)
END SetTextFont;

PROCEDURE (i: Input) TextSize*(): INTEGER;
BEGIN RETURN CTextSize(Fl.Live(i))
END TextSize;

PROCEDURE (i: Input) SetTextSize*(s: INTEGER);
BEGIN CSetTextSize(Fl.Live(i), s)
END SetTextSize;

PROCEDURE (i: Input) TextColor*(): INTEGER;
BEGIN RETURN CTextColor(Fl.Live(i))
END TextColor;

PROCEDURE (i: Input) SetTextColor*(c: INTEGER);
BEGIN CSetTextColor(Fl.Live(i), c)
END SetTextColor;

PROCEDURE (i: Input) CursorColor*(): INTEGER;
BEGIN RETURN CCursorColor(Fl.Live(i))
END CursorColor;

PROCEDURE (i: Input) SetCursorColor*(c: INTEGER);
BEGIN CSetCursorColor(Fl.Live(i), c)
END SetCursorColor;

END FlInputs.
