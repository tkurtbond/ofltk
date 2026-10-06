MODULE FlPreferences; (* Fl_Preferences: a program's settings, kept between runs *)

(* A database of settings is a tree of groups, each holding entries: a
   name and an integer, real or text. The database is read when opened,
   and written when flushed or closed, to a file named after the vendor
   and application in the user's or the system's settings directory, or
   in a directory of the program's choosing, or nowhere (Memory).

   A database is a resource the program owns, as a TextBuffer is: Close
   it when done, which writes it. One the program loses without closing
   is closed by the collector. A group is a Preferences too, reached
   through its database; closing it is optional. Using a closed database,
   a group of one, or a group deleted (DeleteGroup and the rest) halts
   (Fl.ClosedResource).

   Reals are written in the C locale, whatever the program's. Bad data
   is not an error: an entry missing or unreadable gives the default.
   The C++ part is FlPreferences.cpp. *)

IMPORT SYSTEM, GarbageCollectedHeap, Fl;

CONST
  (* where a database is kept (Open) *)
  User* = 0;    (* the user's settings *)
  System* = 1;  (* the system's settings, for every user *)
  Memory* = 2;  (* nowhere: it lasts until closed *)

TYPE
  Path = POINTER TO ARRAY OF CHAR;

  Preferences* = POINTER TO PreferencesDesc;
  PreferencesDesc* = RECORD
    h: SYSTEM.ADDRESS;  (* a database's handle; 0 in a group, or closed *)
    root: Preferences;  (* the database: itself, or a group's; NIL closed *)
    path: Path          (* from the database: "" itself, "a/b" a group *)
  END;

VAR
  openDatabases-: INTEGER;  (* databases opened and not yet closed or finalized *)
  none: Path;               (* "", the path of every database *)

PROCEDURE ["C", "ofl_prefs_open"] COpen(kind: SYSTEM.INT32; dir, vendor, application: ARRAY OF CHAR): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_prefs_close"] CClose(r: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_prefs_exists"] CExists(r: SYSTEM.ADDRESS; path: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_add_group"] CAddGroup(r: SYSTEM.ADDRESS; path, name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_count"] CCount(r: SYSTEM.ADDRESS; path: ARRAY OF CHAR; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_name"] CName(r: SYSTEM.ADDRESS; path: ARRAY OF CHAR; what, i: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_prefs_has"] CHas(r: SYSTEM.ADDRESS; path: ARRAY OF CHAR; what: SYSTEM.INT32; name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_delete"] CDelete(r: SYSTEM.ADDRESS; path: ARRAY OF CHAR; what: SYSTEM.INT32; name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_set_int"] CSetInt(r: SYSTEM.ADDRESS; path, name: ARRAY OF CHAR; v: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_set_real"] CSetReal(r: SYSTEM.ADDRESS; path, name: ARRAY OF CHAR; v: LONGREAL): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_set_text"] CSetText(r: SYSTEM.ADDRESS; path, name, v: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_get_int"] CGetInt(r: SYSTEM.ADDRESS; path, name: ARRAY OF CHAR; def: SYSTEM.INT32; VAR v: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_get_real"] CGetReal(r: SYSTEM.ADDRESS; path, name: ARRAY OF CHAR; def: LONGREAL; VAR v: LONGREAL): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_get_text"] CGetText(r: SYSTEM.ADDRESS; path, name, def: ARRAY OF CHAR; VAR text: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_size"] CSize(r: SYSTEM.ADDRESS; path, name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_flush"] CFlush(r: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_prefs_filename"] CFilename(r: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);

PROCEDURE Length(s-: ARRAY OF CHAR): INTEGER;
  VAR n: INTEGER;
BEGIN
  n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END;
  RETURN n
END Length;

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

(* Databases *)

PROCEDURE CloseHandle(p: Preferences);
BEGIN
  IF p.h # 0 THEN CClose(p.h); p.h := 0; DEC(openDatabases) END
END CloseHandle;

(* GC finalizer: a database lost without Close. *)
PROCEDURE Finalize(obj: SYSTEM.PTR);
BEGIN CloseHandle(SYSTEM.VAL(Preferences, obj))
END Finalize;

PROCEDURE New(p: Preferences);
BEGIN ASSERT(p # NIL, Fl.NilArgument); ASSERT(p.root = NIL, Fl.OpenedTwice)
END New;

PROCEDURE Opened(p: Preferences; h: SYSTEM.ADDRESS);
BEGIN
  ASSERT(h # 0);  (* out of memory *)
  p.h := h; p.root := p; p.path := none; INC(openDatabases);
  GarbageCollectedHeap.RegisterFinalizer(p, Finalize)
END Opened;

(* p's database's handle, halting if p is closed or deleted. *)
PROCEDURE Hd(p: Preferences): SYSTEM.ADDRESS;
BEGIN
  ASSERT(p # NIL, Fl.NilArgument);
  ASSERT((p.root # NIL) & (p.root.h # 0), Fl.ClosedResource);
  ASSERT(CExists(p.root.h, p.path^) # 0, Fl.ClosedResource);
  RETURN p.root.h
END Hd;

(* Opens p as the database for application, from vendor (a domain name
   is best, as "org.example"), kept where: User, System or Memory. An
   unreadable or missing file gives an empty database. *)
PROCEDURE Open*(p: Preferences; where: INTEGER; vendor-, application-: ARRAY OF CHAR);
BEGIN
  New(p); ASSERT((where >= User) & (where <= Memory), Fl.IndexOutOfRange);
  Opened(p, COpen(where, "", vendor, application))
END Open;

(* The same, kept in the directory dir, as "application.prefs". *)
PROCEDURE OpenFile*(p: Preferences; dir-, vendor-, application-: ARRAY OF CHAR);
BEGIN New(p); Opened(p, COpen(3, dir, vendor, application))
END OpenFile;

(* Opens g as p's group name, making it if it isn't there. name may be a
   path, "a/b", through groups made as needed; it must not be "". *)
PROCEDURE (p: Preferences) Group*(g: Preferences; name-: ARRAY OF CHAR);
  VAR r: SYSTEM.ADDRESS; m, n, i: INTEGER;
BEGIN
  r := Hd(p); New(g); n := Length(name);
  ASSERT(n > 0, Fl.IndexOutOfRange);
  ASSERT(CAddGroup(r, p.path^, name) # 0);  (* out of memory *)
  m := Length(p.path^);
  IF m = 0 THEN NEW(g.path, n + 1)
  ELSE
    NEW(g.path, m + 1 + n + 1);
    FOR i := 0 TO m - 1 DO g.path[i] := p.path[i] END;
    g.path[m] := "/"; INC(m)
  END;
  FOR i := 0 TO n - 1 DO g.path[m + i] := name[i] END;
  g.path[m + n] := 0X; g.root := p.root
END Group;

(* Closes p: a database is written if it changed, and freed, and its
   groups are closed with it; a group is only forgotten. Idempotent. *)
PROCEDURE (p: Preferences) Close*;
BEGIN
  IF p.root = p THEN CloseHandle(p) END;
  p.root := NIL
END Close;

(* Whether p is open: not closed, nor its database, nor deleted. *)
PROCEDURE (p: Preferences) IsOpen*(): BOOLEAN;
BEGIN
  RETURN (p.root # NIL) & (p.root.h # 0) & (CExists(p.root.h, p.path^) # 0)
END IsOpen;

(* p's path from its database, as "a/b"; "" for the database itself. *)
PROCEDURE (p: Preferences) Path*(VAR path: ARRAY OF CHAR);
  VAR r: SYSTEM.ADDRESS;
BEGIN r := Hd(p); COPY(p.path^, path)
END Path;

(* Writes p's database to its file if it changed; FALSE if it can't be
   written. *)
PROCEDURE (p: Preferences) Flush*(): BOOLEAN;
BEGIN RETURN CFlush(Hd(p)) = 0
END Flush;

(* The name of p's database's file; "" for Memory. *)
PROCEDURE (p: Preferences) FileName*(VAR name: ARRAY OF CHAR);
BEGIN CFilename(Hd(p), name, SHORT(LEN(name)))
END FileName;

(* Groups *)

PROCEDURE (p: Preferences) Groups*(): INTEGER;
BEGIN RETURN CCount(Hd(p), p.path^, 0)
END Groups;

(* The name of p's group i, 0 to Groups() - 1. *)
PROCEDURE (p: Preferences) GroupName*(i: INTEGER; VAR name: ARRAY OF CHAR);
  VAR r: SYSTEM.ADDRESS;
BEGIN
  r := Hd(p); ASSERT((i >= 0) & (i < CCount(r, p.path^, 0)), Fl.IndexOutOfRange);
  FromC(CName(r, p.path^, 0, i), name)
END GroupName;

(* Whether p has the group name, which may be a path. *)
PROCEDURE (p: Preferences) HasGroup*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CHas(Hd(p), p.path^, 0, name) # 0
END HasGroup;

(* Deletes p's group name, with its groups and entries; FALSE if there
   was none. *)
PROCEDURE (p: Preferences) DeleteGroup*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CDelete(Hd(p), p.path^, 0, name) # 0
END DeleteGroup;

PROCEDURE (p: Preferences) DeleteGroups*;
BEGIN IF CDelete(Hd(p), p.path^, 2, "") = 0 THEN END
END DeleteGroups;

(* Deletes every group and entry of p. *)
PROCEDURE (p: Preferences) Clear*;
BEGIN IF CDelete(Hd(p), p.path^, 4, "") = 0 THEN END
END Clear;

(* Entries *)

PROCEDURE (p: Preferences) Entries*(): INTEGER;
BEGIN RETURN CCount(Hd(p), p.path^, 1)
END Entries;

(* The name of p's entry i, 0 to Entries() - 1. *)
PROCEDURE (p: Preferences) EntryName*(i: INTEGER; VAR name: ARRAY OF CHAR);
  VAR r: SYSTEM.ADDRESS;
BEGIN
  r := Hd(p); ASSERT((i >= 0) & (i < CCount(r, p.path^, 1)), Fl.IndexOutOfRange);
  FromC(CName(r, p.path^, 1, i), name)
END EntryName;

PROCEDURE (p: Preferences) HasEntry*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CHas(Hd(p), p.path^, 1, name) # 0
END HasEntry;

(* FALSE if there was none. *)
PROCEDURE (p: Preferences) DeleteEntry*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CDelete(Hd(p), p.path^, 1, name) # 0
END DeleteEntry;

PROCEDURE (p: Preferences) DeleteEntries*;
BEGIN IF CDelete(Hd(p), p.path^, 3, "") = 0 THEN END
END DeleteEntries;

PROCEDURE (p: Preferences) SetInt*(name-: ARRAY OF CHAR; v: INTEGER);
BEGIN ASSERT(CSetInt(Hd(p), p.path^, name, v) # 0)  (* out of memory *)
END SetInt;

PROCEDURE (p: Preferences) SetReal*(name-: ARRAY OF CHAR; v: LONGREAL);
BEGIN ASSERT(CSetReal(Hd(p), p.path^, name, v) # 0)  (* out of memory *)
END SetReal;

(* v up to its 0X. *)
PROCEDURE (p: Preferences) SetText*(name-, v-: ARRAY OF CHAR);
BEGIN ASSERT(CSetText(Hd(p), p.path^, name, v) # 0)  (* out of memory *)
END SetText;

(* Entry name as an integer; default if it is missing. Text that isn't
   a number gives what C's atoi gives. *)
PROCEDURE (p: Preferences) Int*(name-: ARRAY OF CHAR; default: INTEGER): INTEGER;
  VAR v: SYSTEM.INT32;
BEGIN
  IF CGetInt(Hd(p), p.path^, name, default, v) = 0 THEN END;
  RETURN v
END Int;

PROCEDURE (p: Preferences) Real*(name-: ARRAY OF CHAR; default: LONGREAL): LONGREAL;
  VAR v: LONGREAL;
BEGIN
  IF CGetReal(Hd(p), p.path^, name, default, v) = 0 THEN END;
  RETURN v
END Real;

(* Entry name's text, truncated to fit; default if it is missing. *)
PROCEDURE (p: Preferences) GetText*(name-, default-: ARRAY OF CHAR; VAR text: ARRAY OF CHAR);
BEGIN
  IF CGetText(Hd(p), p.path^, name, default, text, SHORT(LEN(text))) = 0 THEN END
END GetText;

(* The length of entry name's text, untruncated; 0 if it is missing. *)
PROCEDURE (p: Preferences) TextLength*(name-: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CSize(Hd(p), p.path^, name)
END TextLength;

BEGIN
  NEW(none, 1); none[0] := 0X
END FlPreferences.
