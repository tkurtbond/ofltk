MODULE ProgressSimple; (* FLTK's examples/progress-simple.cxx: a progress bar during a long job *)

IMPORT OutStr, Platform, Fl, FlButtons, FlValuators;

VAR
  win: Fl.Window;
  butt: FlButtons.Button;

(* Shows a progress bar while "the work" runs, a millisecond at a time,
   letting FLTK redraw between. *)
PROCEDURE ButtCB(butt: Fl.Widget);
  VAR progress: FlValuators.Progress; t: INTEGER; percent: ARRAY 10 OF CHAR; ok: BOOLEAN;
BEGIN
  butt.Deactivate;  (* so it can't be pushed again *)
  ok := Fl.Check();  (* let FLTK gray it out *)
  win.Begin;
  NEW(progress); FlValuators.OpenProgress(progress, 10, 50, 200, 30, "");
  progress.SetBounds(0.0D0, 1.0D0);
  progress.SetColor(Fl.RGB(88H, 88H, 88H));  (* the background *)
  progress.SetSelectionColor(Fl.RGB(44H, 44H, 0FFH));  (* the bar *)
  progress.SetLabelColor(Fl.White);  (* the percentage *)
  win.End;
  FOR t := 1 TO 500 DO
    progress.SetValue(t / 500.0D0);
    percent := ""; OutStr.Int(t * 100 DIV 500, 0, percent); OutStr.Char("%", percent);
    progress.SetLabel(percent);
    ok := Fl.Check();
    Platform.Delay(1)  (* the compute-intensive part *)
  END;
  progress.Delete;  (* inside a callback, FLTK deletes it when its event loop next runs *)
  butt.Activate;
  win.Redraw
END ButtCB;

BEGIN
  NEW(win); Fl.OpenWindow(win, 220, 90, "");
  NEW(butt); FlButtons.OpenButton(butt, 10, 10, 100, 25, "Press");
  butt.action := ButtCB;
  win.End;
  win.SetResizable(win);
  win.Show;
  Fl.Run
END ProgressSimple.
