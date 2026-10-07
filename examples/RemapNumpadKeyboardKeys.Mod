MODULE RemapNumpadKeyboardKeys; (* FLTK's examples/howto-remap-numpad-keyboard-keys.cxx: keypad keys typing digits whatever NumLock is *)

(* With NumLock off, FLTK makes the keypad's keys arrows, Home, End and
   the rest. The event dispatch sees each key first, and while the check
   button is on, makes a keypad key type the character on it, as
   Fl.EventOriginalKey says, before NumLock. *)

IMPORT OutStr, Fl, FlInputs, FlButtons;

VAR
  win: Fl.DoubleWindow;
  input: FlInputs.Input;
  checkbut: FlButtons.CheckButton;
  tip: ARRAY 128 OF CHAR;

PROCEDURE MyHandler(e: INTEGER; w: Fl.Window): BOOLEAN;
  VAR keycode: INTEGER; buf: ARRAY 2 OF CHAR;
BEGIN
  IF ~checkbut.Value() THEN RETURN Fl.HandleDefault(e) END;   (* remapping off *)
  IF (e = Fl.EvKeyDown) OR (e = Fl.EvKeyUp) THEN               (* a key: remap it? *)
    keycode := Fl.EventOriginalKey();                           (* the key before NumLock *)
    IF (keycode >= Fl.KeyKP) & (keycode <= Fl.KeyKPLast) THEN   (* a keypad key *)
      buf[0] := CHR(keycode - Fl.KeyKP); buf[1] := 0X;          (* its character *)
      Fl.SetEventText(buf);
      Fl.SetEventKey(keycode)                                   (* some inputs need it too *)
    END
  END;
  RETURN Fl.HandleDefault(e)                                    (* FLTK delivers it *)
END MyHandler;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 400, 150, "Keyboard Translation Test");
  NEW(input); FlInputs.OpenInput(input, 100, 10, 200, 25, "Input:");
  NEW(checkbut); FlButtons.OpenCheckButton(checkbut, 100, 40, 280, 25, "Force numeric keypad to type numbers");
  checkbut.SetLabelSize(12);
  checkbut.SetValue(TRUE);
  win.End;
  win.SetResizable(win);
  win.ShowArgs;
  tip := "Turn NumLock OFF, then type into Input:"; OutStr.Ln(tip);
  OutStr.String("using numeric keypad to test translation", tip);
  win.SetTooltip(tip);
  Fl.SetEventDispatch(MyHandler);   (* every event comes to MyHandler first *)
  Fl.Run
END RemapNumpadKeyboardKeys.
