MODULE TextEditorSimple; (* FLTK's examples/texteditor-simple.cxx: a text editor and its buffer *)

IMPORT OutStr, Fl, FlText;

VAR
  win: Fl.DoubleWindow;
  buff: FlText.TextBuffer;
  edit: FlText.TextEditor;
  text: ARRAY 512 OF CHAR;
  i: INTEGER;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 640, 480, "Simple Fl_Text_Editor");
  NEW(buff); FlText.OpenBuffer(buff);
  NEW(edit); FlText.OpenTextEditor(edit, 20, 20, 640 - 40, 480 - 40, "");
  edit.SetBuffer(buff);
  win.End;
  win.SetResizable(edit);
  win.Show;
  text := "";
  FOR i := 0 TO 23 DO OutStr.String("line ", text); OutStr.Int(i, 0, text); OutStr.Ln(text) END;
  buff.SetText(text);
  buff.Close;  (* the editor keeps the buffer while it shows it *)
  Fl.Run
END TextEditorSimple.
