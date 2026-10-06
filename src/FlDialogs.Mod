MODULE FlDialogs; (* FLTK's common dialogs: messages, questions, input, colors and files *)

(* Each procedure shows a modal dialog and waits for the user, handling
   events meanwhile, so timers fire and windows are redrawn, but no other
   window takes input. A cancelled dialog is not an error: it comes back as
   FALSE, or a Choice of Escaped or Closed.

   Text is shown as it is, never taken as a printf format. The C++ part is
   FlDialogs.cpp. *)

IMPORT SYSTEM, GarbageCollectedHeap, Fl;

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

  (* what a native file chooser asks for (OpenNativeFileChooser) *)
  BrowseFile* = 0;
  BrowseDirectory* = 1;
  BrowseMultiFile* = 2;
  BrowseMultiDirectory* = 3;
  BrowseSaveFile* = 4;
  BrowseSaveDirectory* = 5;

  (* a native file chooser's options (NativeFileChooser.SetOptions) *)
  SaveAsConfirm* = {0};
  NewFolder* = {1};
  Preview* = {2};
  UseFilterExt* = {3};
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

  (* what NativeFileChooser.Show gives *)
  Chosen* = 0;
  Cancelled* = 1;
  Failed* = -1;  (* ErrorMessage says why *)

TYPE
  (* The desktop's own file chooser: zenity's, kdialog's or GTK's,
     whichever the program and FLTK's options allow and the system has,
     or else FLTK's. A resource the program owns: Close it when done, or
     the collector does. *)
  NativeFileChooser* = POINTER TO NativeFileChooserDesc;
  NativeFileChooserDesc* = RECORD
    h: SYSTEM.ADDRESS
  END;

VAR
  openChoosers-: INTEGER;  (* choosers opened and not yet closed or finalized *)

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

PROCEDURE ["C", "ofl_fnfc_new"] CFnfcNew(kind: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_fnfc_close"] CFnfcClose(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_fnfc_set_text"] CFnfcSetText(c: SYSTEM.ADDRESS; what: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fnfc_set_int"] CFnfcSetInt(c: SYSTEM.ADDRESS; what, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_fnfc_get_int"] CFnfcGetInt(c: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fnfc_show"] CFnfcShow(c: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fnfc_filename"] CFnfcFilename(c: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_fnfc_errmsg"] CFnfcErrmsg(c: SYSTEM.ADDRESS): SYSTEM.ADDRESS;

(* Copies the C string at a into s, truncated to fit; "" for none. *)
PROCEDURE FromC(a: SYSTEM.ADDRESS; VAR s: ARRAY OF CHAR);
  VAR i: LONGINT; c: CHAR;
BEGIN
  i := 0;
  IF a # 0 THEN
    SYSTEM.GET(a, c);
    WHILE (c # 0X) & (i < LEN(s) - 1) DO
      s[i] := c; INC(i); SYSTEM.GET(a + i, c)
    END
  END;
  s[i] := 0X
END FromC;

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

(* Native file choosers *)

PROCEDURE CloseChooser(c: NativeFileChooser);
BEGIN
  IF c.h # 0 THEN CFnfcClose(c.h); c.h := 0; DEC(openChoosers) END
END CloseChooser;

(* GC finalizer: a chooser lost without Close. *)
PROCEDURE FinalizeChooser(obj: SYSTEM.PTR);
BEGIN CloseChooser(SYSTEM.VAL(NativeFileChooser, obj))
END FinalizeChooser;

(* c's handle, halting if c is closed. *)
PROCEDURE Hd(c: NativeFileChooser): SYSTEM.ADDRESS;
BEGIN
  ASSERT(c # NIL, Fl.NilArgument); ASSERT(c.h # 0, Fl.ClosedResource);
  RETURN c.h
END Hd;

(* Opens c, a chooser asking for kind: BrowseFile and the rest. *)
PROCEDURE OpenNativeFileChooser*(c: NativeFileChooser; kind: INTEGER);
BEGIN
  ASSERT(c # NIL, Fl.NilArgument); ASSERT(c.h = 0, Fl.OpenedTwice);
  ASSERT((kind >= BrowseFile) & (kind <= BrowseSaveDirectory), Fl.IndexOutOfRange);
  c.h := CFnfcNew(kind); ASSERT(c.h # 0);  (* out of memory *)
  INC(openChoosers);
  GarbageCollectedHeap.RegisterFinalizer(c, FinalizeChooser)
END OpenNativeFileChooser;

(* Frees c; idempotent. *)
PROCEDURE (c: NativeFileChooser) Close*;
BEGIN CloseChooser(c)
END Close;

PROCEDURE (c: NativeFileChooser) IsOpen*(): BOOLEAN;
BEGIN RETURN c.h # 0
END IsOpen;

PROCEDURE (c: NativeFileChooser) SetKind*(kind: INTEGER);
BEGIN
  ASSERT((kind >= BrowseFile) & (kind <= BrowseSaveDirectory), Fl.IndexOutOfRange);
  CFnfcSetInt(Hd(c), 0, kind)
END SetKind;

PROCEDURE (c: NativeFileChooser) Kind*(): INTEGER;
BEGIN RETURN CFnfcGetInt(Hd(c), 0)
END Kind;

(* SaveAsConfirm and the rest; a chooser may ignore those it can't do. *)
PROCEDURE (c: NativeFileChooser) SetOptions*(options: SET);
BEGIN CFnfcSetInt(Hd(c), 1, SYSTEM.VAL(SYSTEM.INT32, options))
END SetOptions;

PROCEDURE (c: NativeFileChooser) Options*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CFnfcGetInt(Hd(c), 1))
END Options;

PROCEDURE SetText(c: NativeFileChooser; what: INTEGER; s-: ARRAY OF CHAR);
BEGIN ASSERT(CFnfcSetText(Hd(c), what, s) # 0)  (* out of memory *)
END SetText;

PROCEDURE (c: NativeFileChooser) SetTitle*(title-: ARRAY OF CHAR);
BEGIN SetText(c, 0, title)
END SetTitle;

(* The files offered: patterns, one a line ("*.txt"), or a name, a tab
   and a pattern ("Text" + 09X + "*.{txt,md}"), lines separated by
   0AX. *)
PROCEDURE (c: NativeFileChooser) SetFilter*(filter-: ARRAY OF CHAR);
BEGIN SetText(c, 1, filter)
END SetFilter;

(* The number of filters SetFilter gave; FilterValue, the one chosen,
   from 0. *)
PROCEDURE (c: NativeFileChooser) Filters*(): INTEGER;
BEGIN RETURN CFnfcGetInt(Hd(c), 3)
END Filters;

PROCEDURE (c: NativeFileChooser) SetFilterValue*(i: INTEGER);
BEGIN CFnfcSetInt(Hd(c), 2, i)
END SetFilterValue;

PROCEDURE (c: NativeFileChooser) FilterValue*(): INTEGER;
BEGIN RETURN CFnfcGetInt(Hd(c), 2)
END FilterValue;

(* Where the chooser starts. *)
PROCEDURE (c: NativeFileChooser) SetDirectory*(dir-: ARRAY OF CHAR);
BEGIN SetText(c, 2, dir)
END SetDirectory;

(* The file name offered to start with, for BrowseSaveFile. *)
PROCEDURE (c: NativeFileChooser) SetPresetFile*(name-: ARRAY OF CHAR);
BEGIN SetText(c, 3, name)
END SetPresetFile;

(* Shows c and waits for the user: Chosen, Cancelled, or Failed
   (ErrorMessage says why). *)
PROCEDURE (c: NativeFileChooser) Show*(): INTEGER;
  VAR r: INTEGER;
BEGIN
  r := CFnfcShow(Hd(c));
  IF r > 0 THEN RETURN Cancelled ELSIF r < 0 THEN RETURN Failed ELSE RETURN Chosen END
END Show;

(* The number of files chosen, by the last Show. *)
PROCEDURE (c: NativeFileChooser) Count*(): INTEGER;
BEGIN RETURN CFnfcGetInt(Hd(c), 4)
END Count;

(* File i chosen, 0 to Count() - 1, as an absolute path, truncated to
   fit. *)
PROCEDURE (c: NativeFileChooser) FileName*(i: INTEGER; VAR name: ARRAY OF CHAR);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Hd(c); ASSERT((i >= 0) & (i < CFnfcGetInt(h, 4)), Fl.IndexOutOfRange);
  FromC(CFnfcFilename(h, i), name)
END FileName;

PROCEDURE (c: NativeFileChooser) ErrorMessage*(VAR msg: ARRAY OF CHAR);
BEGIN FromC(CFnfcErrmsg(Hd(c)), msg)
END ErrorMessage;

END FlDialogs.
