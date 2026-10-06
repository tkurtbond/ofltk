MODULE FlDialogs; (* FLTK's common dialogs: messages, questions, input, colors and files *)

(* Each procedure shows a modal dialog and waits for the user, handling
   events meanwhile, so timers fire and windows are redrawn, but no other
   window takes input. A cancelled dialog is not an error: it comes back as
   FALSE, or a Choice of Escaped or Closed.

   Text is shown as it is, never taken as a printf format. The C++ part is
   FlDialogs.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* kinds of beep (Beep) *)
  BeepDefault* = 0;
  BeepMessage* = 1;
  BeepError* = 2;
  BeepQuestion* = 3;
  BeepPassword* = 4;
  BeepNotification* = 5;
(* END generated constants *)

  (* Choice when no button was pushed *)
  Escaped* = -1;  (* the Escape key *)
  Closed* = -2;   (* the window's close button *)

  (* how ChooseColor shows the color: FLTK has no names for these *)
  ColorDefault* = -1;  (* as last time *)
  ColorRGB* = 0;       (* red, green and blue from 0 to 1 *)
  ColorByte* = 1;      (* from 0 to 255 *)
  ColorHex* = 2;       (* as one hexadecimal number *)
  ColorHSV* = 3;       (* hue, saturation and value *)

PROCEDURE ["C", "ofl_dialog_message"] CMessage(alert: SYSTEM.INT32; text: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_dialog_choice"] CChoice(text, b0, b1, b2: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dialog_input"] CInput(password: SYSTEM.INT32; label: ARRAY OF CHAR; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dialog_title"] CTitle(dflt: SYSTEM.INT32; title: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_dialog_hotspot"] CHotspot(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dialog_set_hotspot"] CSetHotspot(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_dialog_font"] CFont(VAR font, size: SYSTEM.INT32);
PROCEDURE ["C", "ofl_dialog_set_font"] CSetFont(font, size: SYSTEM.INT32);
PROCEDURE ["C", "ofl_beep"] CBeep(kind: SYSTEM.INT32);
PROCEDURE ["C", "ofl_color_chooser"] CColorChooser(title: ARRAY OF CHAR; VAR r, g, b: SYSTEM.INT32; mode: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_show_colormap"] CShowColormap(old: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_chooser"] CFileChooser(dir: SYSTEM.INT32; title, pattern: ARRAY OF CHAR; VAR buf: ARRAY OF CHAR; n, relative: SYSTEM.INT32): SYSTEM.INT32;

PROCEDURE Int(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Int;

PROCEDURE Byte(n: INTEGER): INTEGER;
BEGIN
  IF n < 0 THEN RETURN 0 ELSIF n > 255 THEN RETURN 255 ELSE RETURN n END
END Byte;

(* Shows text, with a button to close it. *)
PROCEDURE Message*(text-: ARRAY OF CHAR);
BEGIN CMessage(0, text)
END Message;

(* The same, marked as a warning. *)
PROCEDURE Alert*(text-: ARRAY OF CHAR);
BEGIN CMessage(1, text)
END Alert;

(* Shows text, with up to three buttons, from the right: b0, b1, b2, an
   empty label being no button. b1 is pushed by Enter. Returns the button
   pushed, 0 to 2, or Escaped or Closed. *)
PROCEDURE Choice*(text-, b0-, b1-, b2-: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CChoice(text, b0, b1, b2)
END Choice;

(* Asks for a line of text, starting with value, the cursor after it;
   TRUE and the text in
   value (truncated to fit) if the user pushed OK, FALSE and value
   unchanged if Cancel. *)
PROCEDURE Input*(label-: ARRAY OF CHAR; VAR value: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CInput(0, label, value, SHORT(LEN(value))) # 0
END Input;

(* The same, the text hidden as it is typed. *)
PROCEDURE Password*(label-: ARRAY OF CHAR; VAR value: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CInput(1, label, value, SHORT(LEN(value))) # 0
END Password;

(* The window title of the next of these dialogs (Message to Password)
   only; SetDefaultTitle, of every one given none. "" is none. *)
PROCEDURE SetTitle*(title-: ARRAY OF CHAR);
BEGIN CTitle(0, title)
END SetTitle;

PROCEDURE SetDefaultTitle*(title-: ARRAY OF CHAR);
BEGIN CTitle(1, title)
END SetDefaultTitle;

(* TRUE if the dialogs are shown under the mouse, as to start with; else
   centred on the screen. *)
PROCEDURE Hotspot*(): BOOLEAN;
BEGIN RETURN CHotspot() # 0
END Hotspot;

PROCEDURE SetHotspot*(on: BOOLEAN);
BEGIN CSetHotspot(Int(on))
END SetHotspot;

(* The font and size of the dialogs' text: a font of Fl's; size 0 is
   FLTK's normal size. *)
PROCEDURE Font*(VAR font, size: INTEGER);
  VAR f, s: SYSTEM.INT32;
BEGIN CFont(f, s); font := f; size := s
END Font;

PROCEDURE SetFont*(font, size: INTEGER);
BEGIN CSetFont(font, size)
END SetFont;

(* Sounds the system's beep of this kind, one of the Beep constants. *)
PROCEDURE Beep*(kind: INTEGER);
BEGIN CBeep(kind)
END Beep;

(* Asks for a color, starting with r, g, b, each from 0 to 255 (others are
   brought into that range); mode is one of the Color constants. TRUE and
   the color in r, g, b if the user pushed OK. *)
PROCEDURE ChooseColor*(title-: ARRAY OF CHAR; VAR r, g, b: INTEGER; mode: INTEGER): BOOLEAN;
  VAR R, G, B: SYSTEM.INT32;
BEGIN
  R := Byte(r); G := Byte(g); B := Byte(b);
  IF CColorChooser(title, R, G, B, mode) # 0 THEN r := R; g := G; b := B; RETURN TRUE END;
  RETURN FALSE
END ChooseColor;

(* Pops up FLTK's colormap at the mouse, old marked, and returns the color
   picked: an index color of Fl's; old if none was. *)
PROCEDURE ChooseFromColormap*(old: INTEGER): INTEGER;
BEGIN RETURN CShowColormap(old)
END ChooseFromColormap;

(* FLTK's file chooser: asks for a file matching pattern ("*.txt", or
   several, each a name and a pattern in brackets, separated by tabs, as
   FLTK's Fl_File_Chooser::filter documents; "" is any), starting at path ("" for
   the one chosen last, or the current directory). TRUE and the file in
   path (truncated to fit), relative to the current directory if relative,
   if the user pushed OK. The file need not exist. *)
PROCEDURE ChooseFile*(title-, pattern-: ARRAY OF CHAR; VAR path: ARRAY OF CHAR; relative: BOOLEAN): BOOLEAN;
BEGIN RETURN CFileChooser(0, title, pattern, path, SHORT(LEN(path)), Int(relative)) # 0
END ChooseFile;

(* The same, for a directory. *)
PROCEDURE ChooseDirectory*(title-: ARRAY OF CHAR; VAR path: ARRAY OF CHAR; relative: BOOLEAN): BOOLEAN;
BEGIN RETURN CFileChooser(1, title, "", path, SHORT(LEN(path)), Int(relative)) # 0
END ChooseDirectory;

END FlDialogs.
