MODULE TextDisplayWithColors; (* FLTK's examples/textdisplay-with-colors.cxx: a text display with a color for each line *)

IMPORT OutStr, Fl, FlText;

VAR
  win: Fl.Window;
  disp: FlText.TextDisplay;
  tbuff, sbuff: FlText.TextBuffer;  (* the text, and its styles *)
  text, styles: ARRAY 100 OF CHAR;
  ch: CHAR;
  i: INTEGER;

(* Appends line to s, and a line feed. *)
PROCEDURE Line(line: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
BEGIN OutStr.String(line, s); OutStr.Ln(s)
END Line;

BEGIN
  NEW(win); Fl.OpenWindow(win, 640, 480, "Simple Text Display With Colors");
  NEW(disp); FlText.OpenTextDisplay(disp, 20, 20, 640 - 40, 480 - 40, "");
  NEW(tbuff); FlText.OpenBuffer(tbuff);  (* the text *)
  NEW(sbuff); FlText.OpenBuffer(sbuff);  (* its styles *)
  disp.SetBuffer(tbuff);
  (* The styles, A to D *)
  ch := disp.AddStyle(Fl.Red, Fl.Courier, 18, 0, 0);         (* A: red *)
  ch := disp.AddStyle(Fl.DarkYellow, Fl.Courier, 18, 0, 0);  (* B: yellow *)
  ch := disp.AddStyle(Fl.DarkGreen, Fl.Courier, 18, 0, 0);   (* C: green *)
  ch := disp.AddStyle(Fl.Blue, Fl.Courier, 18, 0, 0);        (* D: blue *)
  disp.SetStyleBuffer(sbuff);
  text := "";
  Line("Red Line 1", text); Line("Yel Line 2", text); Line("Grn Line 3", text); Line("Blu Line 4", text);
  Line("Red Line 5", text); Line("Yel Line 6", text); Line("Grn Line 7", text); Line("Blu Line 8", text);
  styles := "";
  FOR i := 0 TO 1 DO
    Line("AAAAAAAAAA", styles); Line("BBBBBBBBBB", styles); Line("CCCCCCCCCC", styles); Line("DDDDDDDDDD", styles)
  END;
  tbuff.SetText(text);
  sbuff.SetText(styles);
  win.SetResizable(disp);
  win.End;
  win.Show;
  Fl.Run
END TextDisplayWithColors.
