MODULE TextEditorWithDynamicColors; (* FLTK's examples/texteditor-with-dynamic-colors.cxx: digits colored as they are typed *)

IMPORT OutStr, Fl, FlText;

TYPE
  (* The text, which restyles what is inserted into it. *)
  ColoredBuffer = POINTER TO RECORD (FlText.TextBufferDesc)
    styles: FlText.TextBuffer
  END;

VAR
  win: Fl.Window;
  med: FlText.TextEditor;
  tbuff: ColoredBuffer;            (* the text *)
  sbuff: FlText.TextBuffer;        (* its styles *)
  s: ARRAY 300 OF CHAR;
  ch: CHAR;

(* After each change: an "A" for each character inserted, then the style
   of each: B (green) for 0 to 4, C (red) for 5 to 9, else A (black). *)
PROCEDURE (b: ColoredBuffer) Modified*(pos, inserted, deleted, restyled: INTEGER);
  VAR style: POINTER TO ARRAY OF CHAR; i: INTEGER; c: CHAR;
BEGIN
  IF (inserted = 0) & (deleted = 0) THEN RETURN END;
  IF inserted > 0 THEN
    NEW(style, inserted + 1);
    FOR i := 0 TO inserted - 1 DO style[i] := "A" END;
    style[inserted] := 0X;
    b.styles.Insert(pos, style^)
  END;
  IF deleted > 0 THEN
    b.styles.Remove(pos, pos + deleted);
    RETURN                         (* deleting changes no character's color *)
  END;
  FOR i := pos TO pos + inserted - 1 DO
    c := b.ByteAt(i);
    IF (c >= "0") & (c <= "4") THEN b.styles.Replace(i, i + 1, "B")
    ELSIF (c >= "5") & (c <= "9") THEN b.styles.Replace(i, i + 1, "C")
    ELSE b.styles.Replace(i, i + 1, "A")
    END
  END
END Modified;

BEGIN
  NEW(win); Fl.OpenWindow(win, 720, 480, "Text Editor With Dynamic Coloring");
  NEW(med); FlText.OpenTextEditor(med, 10, 10, win.W() - 20, win.H() - 20, "");
  NEW(sbuff); FlText.OpenBuffer(sbuff);
  NEW(tbuff); FlText.OpenBuffer(tbuff); tbuff.styles := sbuff;
  med.SetBuffer(tbuff);
  ch := med.AddStyle(Fl.Black, Fl.Courier, 14, 0, 0);       (* A: black *)
  ch := med.AddStyle(Fl.DarkGreen, Fl.Courier, 14, 0, 0);   (* B: green *)
  ch := med.AddStyle(Fl.Red, Fl.Courier, 14, 0, 0);         (* C: red *)
  med.SetStyleBuffer(sbuff);
  s := "In this editor, digits 0-4 are shown in green, 5-9 shown in red."; OutStr.Ln(s);
  OutStr.String("So here's some numbers 0123456789.", s); OutStr.Ln(s);
  OutStr.String("Coloring is handled automatically by the add_modify_callback().", s); OutStr.Ln(s);
  OutStr.Ln(s);
  OutStr.String("You can type here to test. ", s);
  tbuff.SetText(s);
  win.SetResizable(med);
  win.End;
  win.Show;
  Fl.Run
END TextEditorWithDynamicColors.
