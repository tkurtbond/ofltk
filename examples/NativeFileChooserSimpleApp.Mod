MODULE NativeFileChooserSimpleApp; (* FLTK's examples/nativefilechooser-simple-app.cxx: File/Open, Save and Save As with the native file chooser *)

IMPORT Args, Files, Out, OutStr, Fl, FlMenus, FlDialogs, FlText;

TYPE
  Application = POINTER TO RECORD (Fl.WindowDesc)
    fc: FlDialogs.NativeFileChooser
  END;

VAR
  app: Application;
  ok: BOOLEAN;

PROCEDURE Exist(filename: ARRAY OF CHAR): BOOLEAN;
  VAR f: Files.File;
BEGIN
  f := Files.Old(filename);
  IF f # NIL THEN Files.Close(f) END;
  RETURN f # NIL
END Exist;

PROCEDURE (a: Application) Open(filename: ARRAY OF CHAR);
BEGIN Out.String("Open '"); Out.String(filename); Out.Char("'"); Out.Ln
END Open;

(* Creates the file if it doesn't exist. Written through a text buffer,
   whose SaveFile returns FALSE if it can't be, where poc's Files halts;
   but not why, so the message doesn't say, as FLTK's does. *)
PROCEDURE (a: Application) Save(filename: ARRAY OF CHAR);
  VAR b: FlText.TextBuffer; s: ARRAY 1100 OF CHAR;
BEGIN
  Out.String("Saving '"); Out.String(filename); Out.Char("'"); Out.Ln;
  IF ~Exist(filename) THEN
    NEW(b); FlText.OpenBuffer(b);
    s := "Hello world."; OutStr.Ln(s); b.SetText(s);
    IF ~b.SaveFile(filename) THEN
      s := "Error: "; OutStr.String(filename, s); OutStr.String(": can't be written", s);
      FlDialogs.Message(s)
    END;
    b.Close
  ELSE
    (* An existing file is left as it is: a real application would ask
       whether to overwrite it, and then save. *)
  END
END Save;

(* Shows the chooser as title, of kind, and gives the file chosen to
   Open or Save. *)
PROCEDURE (a: Application) Choose(title: ARRAY OF CHAR; kind: INTEGER; save: BOOLEAN);
  VAR name: ARRAY 1024 OF CHAR;
BEGIN
  a.fc.SetTitle(title);
  a.fc.SetKind(kind);
  IF a.fc.Show() = FlDialogs.Chosen THEN  (* not cancelled, and no error *)
    a.fc.FileName(0, name);
    a.fc.SetPresetFile(name);
    IF save THEN a.Save(name) ELSE a.Open(name) END
  END
END Choose;

PROCEDURE OpenCb(w: Fl.Widget);
BEGIN app.Choose("Open", FlDialogs.BrowseFile, FALSE)  (* only files that exist *)
END OpenCb;

PROCEDURE SaveAsCb(w: Fl.Widget);
BEGIN app.Choose("Save As", FlDialogs.BrowseSaveFile, TRUE)  (* a file that may not exist yet *)
END SaveAsCb;

PROCEDURE SaveCb(w: Fl.Widget);
  VAR name: ARRAY 1024 OF CHAR;
BEGIN
  IF app.fc.Count() = 0 THEN SaveAsCb(w)
  ELSE app.fc.FileName(0, name); app.Save(name)
  END
END SaveCb;

PROCEDURE QuitCb(w: Fl.Widget);
BEGIN app.Hide
END QuitCb;

(* $HOME/untitled.txt. *)
PROCEDURE UntitledDefault(VAR filename: ARRAY OF CHAR);
BEGIN
  IF ~Args.getEnv("HOME", filename) & ~Args.getEnv("HOME_PATH", filename) THEN COPY(".", filename) END;
  OutStr.String("/untitled.txt", filename)
END UntitledDefault;

PROCEDURE OpenApplication(a: Application);
  VAR menu: FlMenus.MenuBar; box: Fl.Box; s: ARRAY 400 OF CHAR; i: INTEGER;
BEGIN
  Fl.OpenWindow(a, 400, 200, "Native File Chooser Example");
  NEW(menu); FlMenus.OpenMenuBar(menu, 0, 0, 400, 25, "");
  i := menu.Add("&File/&Open", ORD("o"), Fl.Command, OpenCb, {});
  i := menu.Add("&File/&Save", ORD("s"), Fl.Command, SaveCb, {});
  i := menu.Add("&File/&Save As", 0, {}, SaveAsCb, {});
  i := menu.Add("&File/&Quit", ORD("q"), Fl.Command, QuitCb, {});
  NEW(box); Fl.OpenBox(box, 20, 25 + 20, a.W() - 40, a.H() - 40 - 25, "");
  box.SetColor(45);
  box.SetBoxType(Fl.FlatBox);
  box.SetAlign(Fl.AlignCenter + Fl.AlignInside + Fl.AlignWrap);
  s := "This demo shows an example of implementing common 'File' menu operations like:"; OutStr.Ln(s);
  OutStr.String("    File/Open, File/Save, File/Save As", s); OutStr.Ln(s);
  OutStr.String("..using the Fl_Native_File_Chooser widget.", s); OutStr.Ln(s); OutStr.Ln(s);
  OutStr.String("Note 'Save' and 'Save As' really *does* create files! ", s);
  OutStr.String("This is to show how behavior differs when files exist vs. do not.", s);
  box.SetLabel(s);
  box.SetLabelSize(12);
  NEW(a.fc); FlDialogs.OpenNativeFileChooser(a.fc, FlDialogs.BrowseFile);
  s := "Text?*.txt"; s[4] := 09X; OutStr.Ln(s); a.fc.SetFilter(s);
  UntitledDefault(s); a.fc.SetPresetFile(s);
  a.End
END OpenApplication;

BEGIN
  ok := Fl.SetScheme("gtk+");
  NEW(app); OpenApplication(app);
  app.Show;
  Fl.Run;
  app.fc.Close
END NativeFileChooserSimpleApp.
