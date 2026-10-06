MODULE FlText; (* Text: buffers of text, and the widgets that show and edit them *)

(* A TextBuffer holds text, UTF-8 bytes; positions in it are byte offsets
   from 0, and should fall at the start of a character (NextChar,
   PrevChar and Align find them). FLTK brings a position outside the text
   into it.

   A buffer is a resource the program owns, as polibfyaml's documents are:
   Close it when done. Closing gives up the program's hold only: a buffer
   shown by a TextDisplay, as its text or its styles, lives on until no
   display shows it, and FLTK deletes it then. A buffer the program loses
   without closing is closed by the collector. Using a closed buffer halts
   (Fl.ClosedResource).

   A TextDisplay shows a buffer; a TextEditor lets the user edit it. A
   display keeps its buffer, so the buffer isn't collected while it is
   shown. A display's methods that work on its text halt without a buffer
   (Fl.ClosedResource).

   A buffer's Modified runs after every change; an extension may override
   it. The C++ part is FlText.cpp. *)

IMPORT SYSTEM, GarbageCollectedHeap, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* how a display wraps lines (TextDisplay.SetWrapMode) *)
  WrapNone* = 0;
  WrapAtColumn* = 1;
  WrapAtPixel* = 2;
  WrapAtBounds* = 3;

  (* the cursor's look (TextDisplay.SetCursorStyle) *)
  NormalCursor* = 0;
  CaretCursor* = 1;
  DimCursor* = 2;
  BlockCursor* = 3;
  HeavyCursor* = 4;
  SimpleCursor* = 5;

  (* a style's attributes (TextDisplay.AddStyle): a line kind, plus a background *)
  AttrBgcolor* = 1;
  AttrBgcolorExt* = 3;
  AttrUnderline* = 4;
  AttrGrammar* = 8;
  AttrSpelling* = 12;
  AttrStrikeThrough* = 16;
(* END generated constants *)

  (* the classes, as ofl_text_new numbers them *)
  display = 0; editor = 1;

  (* what ofl_buffer_pos finds *)
  lineStart = 0; lineEnd = 1; wordStart = 2; wordEnd = 3; nextChar = 4;
  prevChar = 5; align = 6;

  (* what ofl_text_get and ofl_text_set read or set *)
  textFont = 0; textSize = 1; textColor = 2; cursorStyle = 3;
  cursorColor = 4; lineNumberWidth = 5; lineNumberFont = 6;
  lineNumberSize = 7; lineNumberFg = 8; lineNumberBg = 9;
  scrollbarSize = 10; shortcut = 11; insertMode = 12; tabNav = 13;

TYPE
  TextBuffer* = POINTER TO TextBufferDesc;
  TextBufferDesc* = RECORD
    h: SYSTEM.ADDRESS  (* the C++ buffer, 0 once closed *)
  END;

  (* FLTK's Fl_Text_Display: shows a buffer, scrolled, wrapped or not,
     with styles if given them. *)
  TextDisplay* = POINTER TO TextDisplayDesc;
  TextDisplayDesc* = RECORD (Fl.WidgetDesc)
    buffer, styles: TextBuffer
  END;

  (* FLTK's Fl_Text_Editor: a display the user can type in, with FLTK's
     usual keys. *)
  TextEditor* = POINTER TO TextEditorDesc;
  TextEditorDesc* = RECORD (TextDisplayDesc) END;

  ModifiedProc = PROCEDURE (self: SYSTEM.ADDRESS; pos, inserted, deleted, restyled: SYSTEM.INT32);

VAR
  openBuffers-: INTEGER;  (* buffers made and not yet closed or finalized *)

PROCEDURE ["C", "ofl_text_register"] CRegister(modified: ModifiedProc);
PROCEDURE ["C", "ofl_buffer_new"] CBufferNew(self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_buffer_close"] CBufferClose(b: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_buffer_length"] CLength(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_set_text"] CSetText(b: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_buffer_text"] CText(b: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_buffer_text_range"] CTextRange(b: SYSTEM.ADDRESS; start, end: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_buffer_char_at"] CCharAt(b: SYSTEM.ADDRESS; pos: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_byte_at"] CByteAt(b: SYSTEM.ADDRESS; pos: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_insert"] CInsert(b: SYSTEM.ADDRESS; pos: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_buffer_remove"] CRemove(b: SYSTEM.ADDRESS; start, end: SYSTEM.INT32);
PROCEDURE ["C", "ofl_buffer_replace"] CReplace(b: SYSTEM.ADDRESS; start, end: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_buffer_undo"] CUndo(b: SYSTEM.ADDRESS; redo: SYSTEM.INT32; VAR pos: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_can_undo"] CCanUndo(b: SYSTEM.ADDRESS; redo: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_set_can_undo"] CSetCanUndo(b: SYSTEM.ADDRESS; on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_buffer_file"] CFile(b: SYSTEM.ADDRESS; what: SYSTEM.INT32; name: ARRAY OF CHAR; pos, end: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_tab_distance"] CTabDistance(b: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_set_tab_distance"] CSetTabDistance(b: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_buffer_select"] CSelect(b: SYSTEM.ADDRESS; start, end: SYSTEM.INT32);
PROCEDURE ["C", "ofl_buffer_unselect"] CUnselect(b: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_buffer_selection"] CSelection(b: SYSTEM.ADDRESS; VAR start, end: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_selection_text"] CSelectionText(b: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_buffer_remove_selection"] CRemoveSelection(b: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_buffer_replace_selection"] CReplaceSelection(b: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_buffer_pos"] CPos(b: SYSTEM.ADDRESS; what, pos: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_line_text"] CLineText(b: SYSTEM.ADDRESS; pos: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_buffer_count_lines"] CCountLines(b: SYSTEM.ADDRESS; start, end: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_skip_lines"] CSkipLines(b: SYSTEM.ADDRESS; start, n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_rewind_lines"] CRewindLines(b: SYSTEM.ADDRESS; start, n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_buffer_search"] CSearch(b: SYSTEM.ADDRESS; backward, start: SYSTEM.INT32; s: ARRAY OF CHAR; VAR found: SYSTEM.INT32; matchCase: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_text_new"] CNew(class, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_text_set_buffer"] CSetBuffer(d, b: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_text_set_style_buffer"] CSetStyleBuffer(d, b: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_text_add_style"] CAddStyle(d: SYSTEM.ADDRESS; color, font, size, attr, bgcolor: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_text_clear_styles"] CClearStyles(d: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_text_insert_position"] CInsertPosition(d: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_text_set_insert_position"] CSetInsertPosition(d: SYSTEM.ADDRESS; pos: SYSTEM.INT32);
PROCEDURE ["C", "ofl_text_show_insert_position"] CShowInsertPosition(d: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_text_insert"] CTextInsert(d: SYSTEM.ADDRESS; s: ARRAY OF CHAR; overstrike: SYSTEM.INT32);
PROCEDURE ["C", "ofl_text_move"] CMove(d: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_text_scroll"] CScroll(d: SYSTEM.ADDRESS; line, offset: SYSTEM.INT32);
PROCEDURE ["C", "ofl_text_position_to_xy"] CPositionToXY(d: SYSTEM.ADDRESS; pos: SYSTEM.INT32; VAR x, y: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_text_in_selection"] CInSelection(d: SYSTEM.ADDRESS; x, y: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_text_line"] CLine(d: SYSTEM.ADDRESS; what, pos, n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_text_wrap_mode"] CWrapMode(d: SYSTEM.ADDRESS; mode, margin: SYSTEM.INT32);
PROCEDURE ["C", "ofl_text_show_cursor"] CShowCursor(d: SYSTEM.ADDRESS; on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_text_get"] CGet(d: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_text_set"] CSet(d: SYSTEM.ADDRESS; what, v: SYSTEM.INT32);

PROCEDURE Int(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Int;

(* Buffers *)

PROCEDURE CloseHandle(b: TextBuffer);
BEGIN
  IF b.h # 0 THEN CBufferClose(b.h); b.h := 0; DEC(openBuffers) END
END CloseHandle;

(* GC finalizer: a buffer lost without Close. *)
PROCEDURE FinalizeBuffer(obj: SYSTEM.PTR);
BEGIN CloseHandle(SYSTEM.VAL(TextBuffer, obj))
END FinalizeBuffer;

(* Makes b a new, empty buffer. b may be an extension. *)
PROCEDURE OpenBuffer*(b: TextBuffer);
BEGIN
  ASSERT(b # NIL, Fl.NilArgument); ASSERT(b.h = 0, Fl.OpenedTwice);
  b.h := CBufferNew(SYSTEM.VAL(SYSTEM.ADDRESS, b)); INC(openBuffers);
  GarbageCollectedHeap.RegisterFinalizer(b, FinalizeBuffer)
END OpenBuffer;

(* b's handle, halting if b is closed. *)
PROCEDURE H(b: TextBuffer): SYSTEM.ADDRESS;
BEGIN
  ASSERT(b # NIL, Fl.NilArgument); ASSERT(b.h # 0, Fl.ClosedResource);
  RETURN b.h
END H;

(* Gives up the program's hold on b; idempotent. *)
PROCEDURE (b: TextBuffer) Close*;
BEGIN CloseHandle(b)
END Close;

PROCEDURE (b: TextBuffer) IsOpen*(): BOOLEAN;
BEGIN RETURN b.h # 0
END IsOpen;

(* Called after every change: inserted bytes were inserted and deleted
   deleted at pos, or restyled restyled. Does nothing; an extension may
   override it. *)
PROCEDURE (b: TextBuffer) Modified*(pos, inserted, deleted, restyled: INTEGER);
END Modified;

(* The length in bytes. *)
PROCEDURE (b: TextBuffer) Length*(): INTEGER;
BEGIN RETURN CLength(H(b))
END Length;

PROCEDURE (b: TextBuffer) SetText*(s-: ARRAY OF CHAR);
BEGIN CSetText(H(b), s)
END SetText;

(* The text, truncated to fit s. *)
PROCEDURE (b: TextBuffer) GetText*(VAR s: ARRAY OF CHAR);
BEGIN CText(H(b), s, SHORT(LEN(s)))
END GetText;

(* The text from start up to end, truncated to fit s. *)
PROCEDURE (b: TextBuffer) TextRange*(start, end: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN CTextRange(H(b), start, end, s, SHORT(LEN(s)))
END TextRange;

(* The character (Unicode) starting at pos; 0 outside the text. *)
PROCEDURE (b: TextBuffer) CharAt*(pos: INTEGER): INTEGER;
BEGIN RETURN CCharAt(H(b), pos)
END CharAt;

(* The byte at pos; 0X outside the text. *)
PROCEDURE (b: TextBuffer) ByteAt*(pos: INTEGER): CHAR;
BEGIN RETURN CHR(CByteAt(H(b), pos))
END ByteAt;

PROCEDURE (b: TextBuffer) Insert*(pos: INTEGER; s-: ARRAY OF CHAR);
BEGIN CInsert(H(b), pos, s)
END Insert;

PROCEDURE (b: TextBuffer) Append*(s-: ARRAY OF CHAR);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := H(b); CInsert(h, CLength(h), s)
END Append;

(* Removes the text from start up to end. *)
PROCEDURE (b: TextBuffer) Remove*(start, end: INTEGER);
BEGIN CRemove(H(b), start, end)
END Remove;

PROCEDURE (b: TextBuffer) Replace*(start, end: INTEGER; s-: ARRAY OF CHAR);
BEGIN CReplace(H(b), start, end, s)
END Replace;

(* Undoes the last change, giving where it leaves the cursor; FALSE if
   there is nothing to undo. *)
PROCEDURE (b: TextBuffer) Undo*(VAR pos: INTEGER): BOOLEAN;
  VAR p: SYSTEM.INT32; r: BOOLEAN;
BEGIN r := CUndo(H(b), 0, p) # 0; pos := p; RETURN r
END Undo;

PROCEDURE (b: TextBuffer) Redo*(VAR pos: INTEGER): BOOLEAN;
  VAR p: SYSTEM.INT32; r: BOOLEAN;
BEGIN r := CUndo(H(b), 1, p) # 0; pos := p; RETURN r
END Redo;

PROCEDURE (b: TextBuffer) CanUndo*(): BOOLEAN;
BEGIN RETURN CCanUndo(H(b), 0) # 0
END CanUndo;

PROCEDURE (b: TextBuffer) CanRedo*(): BOOLEAN;
BEGIN RETURN CCanUndo(H(b), 1) # 0
END CanRedo;

(* Whether changes are recorded for Undo, as they are to start with. *)
PROCEDURE (b: TextBuffer) SetUndoable*(on: BOOLEAN);
BEGIN CSetCanUndo(H(b), Int(on))
END SetUndoable;

(* Files: TRUE if it worked. A file's text that isn't UTF-8 is converted
   from the system's encoding, as FLTK does. *)

(* Replaces the text with the file's. *)
PROCEDURE (b: TextBuffer) LoadFile*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFile(H(b), 0, name, 0, 0) = 0
END LoadFile;

PROCEDURE (b: TextBuffer) AppendFile*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFile(H(b), 1, name, 0, 0) = 0
END AppendFile;

PROCEDURE (b: TextBuffer) InsertFile*(name-: ARRAY OF CHAR; pos: INTEGER): BOOLEAN;
BEGIN RETURN CFile(H(b), 2, name, pos, 0) = 0
END InsertFile;

PROCEDURE (b: TextBuffer) SaveFile*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFile(H(b), 3, name, 0, 0) = 0
END SaveFile;

(* Saves the text from start up to end. *)
PROCEDURE (b: TextBuffer) SaveRange*(name-: ARRAY OF CHAR; start, end: INTEGER): BOOLEAN;
BEGIN RETURN CFile(H(b), 4, name, start, end) = 0
END SaveRange;

(* Columns between tab stops; 8 to start with. *)
PROCEDURE (b: TextBuffer) TabDistance*(): INTEGER;
BEGIN RETURN CTabDistance(H(b))
END TabDistance;

PROCEDURE (b: TextBuffer) SetTabDistance*(n: INTEGER);
BEGIN CSetTabDistance(H(b), n)
END SetTabDistance;

(* The selection: the text from start up to end, which displays show. *)

PROCEDURE (b: TextBuffer) Select*(start, end: INTEGER);
BEGIN CSelect(H(b), start, end)
END Select;

PROCEDURE (b: TextBuffer) Unselect*;
BEGIN CUnselect(H(b))
END Unselect;

(* TRUE and the selection's start and end if text is selected. *)
PROCEDURE (b: TextBuffer) Selection*(VAR start, end: INTEGER): BOOLEAN;
  VAR s, e: SYSTEM.INT32; r: BOOLEAN;
BEGIN r := CSelection(H(b), s, e) # 0; start := s; end := e; RETURN r
END Selection;

PROCEDURE (b: TextBuffer) SelectionText*(VAR s: ARRAY OF CHAR);
BEGIN CSelectionText(H(b), s, SHORT(LEN(s)))
END SelectionText;

PROCEDURE (b: TextBuffer) RemoveSelection*;
BEGIN CRemoveSelection(H(b))
END RemoveSelection;

PROCEDURE (b: TextBuffer) ReplaceSelection*(s-: ARRAY OF CHAR);
BEGIN CReplaceSelection(H(b), s)
END ReplaceSelection;

(* Positions, lines and words. A line ends at a newline, not counted in
   it; words are separated by spaces, tabs and punctuation. *)

PROCEDURE (b: TextBuffer) LineStart*(pos: INTEGER): INTEGER;
BEGIN RETURN CPos(H(b), lineStart, pos)
END LineStart;

PROCEDURE (b: TextBuffer) LineEnd*(pos: INTEGER): INTEGER;
BEGIN RETURN CPos(H(b), lineEnd, pos)
END LineEnd;

PROCEDURE (b: TextBuffer) WordStart*(pos: INTEGER): INTEGER;
BEGIN RETURN CPos(H(b), wordStart, pos)
END WordStart;

PROCEDURE (b: TextBuffer) WordEnd*(pos: INTEGER): INTEGER;
BEGIN RETURN CPos(H(b), wordEnd, pos)
END WordEnd;

(* The position of the next character, or the previous one. *)
PROCEDURE (b: TextBuffer) NextChar*(pos: INTEGER): INTEGER;
BEGIN RETURN CPos(H(b), nextChar, pos)
END NextChar;

PROCEDURE (b: TextBuffer) PrevChar*(pos: INTEGER): INTEGER;
BEGIN RETURN CPos(H(b), prevChar, pos)
END PrevChar;

(* The start of the character pos is in. *)
PROCEDURE (b: TextBuffer) Align*(pos: INTEGER): INTEGER;
BEGIN RETURN CPos(H(b), align, pos)
END Align;

(* The line pos is in, truncated to fit s. *)
PROCEDURE (b: TextBuffer) LineText*(pos: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN CLineText(H(b), pos, s, SHORT(LEN(s)))
END LineText;

(* The newlines from start up to end. *)
PROCEDURE (b: TextBuffer) CountLines*(start, end: INTEGER): INTEGER;
BEGIN RETURN CCountLines(H(b), start, end)
END CountLines;

(* The start of the line n lines after start's, or before it. *)
PROCEDURE (b: TextBuffer) SkipLines*(start, n: INTEGER): INTEGER;
BEGIN RETURN CSkipLines(H(b), start, n)
END SkipLines;

PROCEDURE (b: TextBuffer) RewindLines*(start, n: INTEGER): INTEGER;
BEGIN RETURN CRewindLines(H(b), start, n)
END RewindLines;

(* TRUE and where s starts, searching from start forward, or backward,
   with or without matching case. *)
PROCEDURE (b: TextBuffer) SearchForward*(start: INTEGER; s-: ARRAY OF CHAR; matchCase: BOOLEAN; VAR found: INTEGER): BOOLEAN;
  VAR f: SYSTEM.INT32; r: BOOLEAN;
BEGIN r := CSearch(H(b), 0, start, s, f, Int(matchCase)) # 0; found := f; RETURN r
END SearchForward;

PROCEDURE (b: TextBuffer) SearchBackward*(start: INTEGER; s-: ARRAY OF CHAR; matchCase: BOOLEAN; VAR found: INTEGER): BOOLEAN;
  VAR f: SYSTEM.INT32; r: BOOLEAN;
BEGIN r := CSearch(H(b), 1, start, s, f, Int(matchCase)) # 0; found := f; RETURN r
END SearchBackward;

(* Displays and editors *)

PROCEDURE Open(d: TextDisplay; class, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(d, CNew(class, x, y, w, h, label, Fl.BeginOpen(d)))
END Open;

PROCEDURE OpenTextDisplay*(d: TextDisplay; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(d, display, x, y, w, h, label)
END OpenTextDisplay;

PROCEDURE OpenTextEditor*(d: TextEditor; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(d, editor, x, y, w, h, label)
END OpenTextEditor;

(* d's handle, halting if d has no buffer. *)
PROCEDURE B(d: TextDisplay): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN h := Fl.Live(d); ASSERT(d.buffer # NIL, Fl.ClosedResource); RETURN h
END B;

(* Shows b, which may be closed, or NIL for none. *)
PROCEDURE (d: TextDisplay) SetBuffer*(b: TextBuffer);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(d);
  IF b = NIL THEN CSetBuffer(h, 0) ELSE CSetBuffer(h, H(b)) END;
  d.buffer := b
END SetBuffer;

PROCEDURE (d: TextDisplay) Buffer*(): TextBuffer;
BEGIN RETURN d.buffer
END Buffer;

(* Styles: b holds a style for each byte of the text, a character from
   "A": "A" the first style added, "B" the second, and so on. The text is
   drawn in its style once b and at least one style are given; a
   character past the last style is taken as the last. NIL is no styles. *)
PROCEDURE (d: TextDisplay) SetStyleBuffer*(b: TextBuffer);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(d);
  IF b = NIL THEN CSetStyleBuffer(h, 0) ELSE CSetStyleBuffer(h, H(b)) END;
  d.styles := b
END SetStyleBuffer;

PROCEDURE (d: TextDisplay) StyleBuffer*(): TextBuffer;
BEGIN RETURN d.styles
END StyleBuffer;

(* Adds a style, and returns its character: a color, font and size of
   Fl's; attr, 0 or one of the Attr constants, plus AttrBgcolor or
   AttrBgcolorExt for bgcolor behind the text, or to the end of the line. *)
PROCEDURE (d: TextDisplay) AddStyle*(color, font, size, attr, bgcolor: INTEGER): CHAR;
  VAR i: INTEGER;
BEGIN
  i := CAddStyle(Fl.Live(d), color, font, size, attr, bgcolor);
  ASSERT(i >= 0);  (* out of memory *)
  RETURN CHR(ORD("A") + i)
END AddStyle;

PROCEDURE (d: TextDisplay) ClearStyles*;
BEGIN CClearStyles(Fl.Live(d))
END ClearStyles;

(* The cursor's position. *)
PROCEDURE (d: TextDisplay) InsertPosition*(): INTEGER;
BEGIN RETURN CInsertPosition(Fl.Live(d))
END InsertPosition;

PROCEDURE (d: TextDisplay) SetInsertPosition*(pos: INTEGER);
BEGIN CSetInsertPosition(B(d), pos)
END SetInsertPosition;

(* Scrolls to show the cursor. *)
PROCEDURE (d: TextDisplay) ShowInsertPosition*;
BEGIN CShowInsertPosition(B(d))
END ShowInsertPosition;

(* Inserts s at the cursor, as if typed, moving the cursor after it. *)
PROCEDURE (d: TextDisplay) Insert*(s-: ARRAY OF CHAR);
BEGIN CTextInsert(B(d), s, 0)
END Insert;

(* The same, typing over the text after the cursor. *)
PROCEDURE (d: TextDisplay) Overstrike*(s-: ARRAY OF CHAR);
BEGIN CTextInsert(B(d), s, 1)
END Overstrike;

(* Moves the cursor a character or a line as shown; FALSE if it can't. *)
PROCEDURE (d: TextDisplay) MoveRight*(): BOOLEAN;
BEGIN RETURN CMove(B(d), 0) # 0
END MoveRight;

PROCEDURE (d: TextDisplay) MoveLeft*(): BOOLEAN;
BEGIN RETURN CMove(B(d), 1) # 0
END MoveLeft;

PROCEDURE (d: TextDisplay) MoveUp*(): BOOLEAN;
BEGIN RETURN CMove(B(d), 2) # 0
END MoveUp;

PROCEDURE (d: TextDisplay) MoveDown*(): BOOLEAN;
BEGIN RETURN CMove(B(d), 3) # 0
END MoveDown;

PROCEDURE (d: TextDisplay) NextWord*;
VAR ok: BOOLEAN;
BEGIN ok := CMove(B(d), 4) # 0
END NextWord;

PROCEDURE (d: TextDisplay) PreviousWord*;
VAR ok: BOOLEAN;
BEGIN ok := CMove(B(d), 5) # 0
END PreviousWord;

(* Scrolls so that line (from 1) is at the top, and the text is offset
   pixels to the left. *)
PROCEDURE (d: TextDisplay) Scroll*(line, offset: INTEGER);
BEGIN CScroll(B(d), line, offset)
END Scroll;

(* TRUE and where pos is drawn, in the window's coordinates, if it is
   shown. *)
PROCEDURE (d: TextDisplay) PositionToXY*(pos: INTEGER; VAR x, y: INTEGER): BOOLEAN;
  VAR X, Y: SYSTEM.INT32; r: BOOLEAN;
BEGIN r := CPositionToXY(B(d), pos, X, Y) # 0; x := X; y := Y; RETURN r
END PositionToXY;

(* TRUE if x, y is over selected text. *)
PROCEDURE (d: TextDisplay) InSelection*(x, y: INTEGER): BOOLEAN;
BEGIN RETURN CInSelection(B(d), x, y) # 0
END InSelection;

(* Lines as shown, which wrapping may make several of one line of the
   buffer's. *)

PROCEDURE (d: TextDisplay) LineStart*(pos: INTEGER): INTEGER;
BEGIN RETURN CLine(B(d), 0, pos, 0)
END LineStart;

PROCEDURE (d: TextDisplay) LineEnd*(pos: INTEGER): INTEGER;
BEGIN RETURN CLine(B(d), 1, pos, 0)
END LineEnd;

PROCEDURE (d: TextDisplay) CountLines*(start, end: INTEGER): INTEGER;
BEGIN RETURN CLine(B(d), 2, start, end)
END CountLines;

PROCEDURE (d: TextDisplay) SkipLines*(start, n: INTEGER): INTEGER;
BEGIN RETURN CLine(B(d), 3, start, n)
END SkipLines;

PROCEDURE (d: TextDisplay) RewindLines*(start, n: INTEGER): INTEGER;
BEGIN RETURN CLine(B(d), 4, start, n)
END RewindLines;

(* Wrapping: WrapNone, as to start with; WrapAtColumn margin;
   WrapAtPixel margin; or WrapAtBounds, the display's width. *)
PROCEDURE (d: TextDisplay) SetWrapMode*(mode, margin: INTEGER);
BEGIN CWrapMode(Fl.Live(d), mode, margin)
END SetWrapMode;

PROCEDURE (d: TextDisplay) ShowCursor*(on: BOOLEAN);
BEGIN CShowCursor(Fl.Live(d), Int(on))
END ShowCursor;

PROCEDURE Get(d: TextDisplay; what: INTEGER): INTEGER;
BEGIN RETURN CGet(Fl.Live(d), what)
END Get;

PROCEDURE Set(d: TextDisplay; what, v: INTEGER);
BEGIN CSet(Fl.Live(d), what, v)
END Set;

(* The text's font, size and color, Fl's. *)
PROCEDURE (d: TextDisplay) TextFont*(): INTEGER;
BEGIN RETURN Get(d, textFont)
END TextFont;

PROCEDURE (d: TextDisplay) SetTextFont*(f: INTEGER);
BEGIN Set(d, textFont, f)
END SetTextFont;

PROCEDURE (d: TextDisplay) TextSize*(): INTEGER;
BEGIN RETURN Get(d, textSize)
END TextSize;

PROCEDURE (d: TextDisplay) SetTextSize*(s: INTEGER);
BEGIN Set(d, textSize, s)
END SetTextSize;

PROCEDURE (d: TextDisplay) TextColor*(): INTEGER;
BEGIN RETURN Get(d, textColor)
END TextColor;

PROCEDURE (d: TextDisplay) SetTextColor*(c: INTEGER);
BEGIN Set(d, textColor, c)
END SetTextColor;

(* The cursor's look: one of the Cursor constants, and a color. *)
PROCEDURE (d: TextDisplay) CursorStyle*(): INTEGER;
BEGIN RETURN Get(d, cursorStyle)
END CursorStyle;

PROCEDURE (d: TextDisplay) SetCursorStyle*(s: INTEGER);
BEGIN Set(d, cursorStyle, s)
END SetCursorStyle;

PROCEDURE (d: TextDisplay) CursorColor*(): INTEGER;
BEGIN RETURN Get(d, cursorColor)
END CursorColor;

PROCEDURE (d: TextDisplay) SetCursorColor*(c: INTEGER);
BEGIN Set(d, cursorColor, c)
END SetCursorColor;

(* Line numbers, in a column this wide on the left: 0, as to start with,
   for none. *)
PROCEDURE (d: TextDisplay) LineNumberWidth*(): INTEGER;
BEGIN RETURN Get(d, lineNumberWidth)
END LineNumberWidth;

PROCEDURE (d: TextDisplay) SetLineNumberWidth*(w: INTEGER);
BEGIN Set(d, lineNumberWidth, w)
END SetLineNumberWidth;

PROCEDURE (d: TextDisplay) SetLineNumberFont*(font, size: INTEGER);
BEGIN Set(d, lineNumberFont, font); Set(d, lineNumberSize, size)
END SetLineNumberFont;

PROCEDURE (d: TextDisplay) SetLineNumberColors*(fg, bg: INTEGER);
BEGIN Set(d, lineNumberFg, fg); Set(d, lineNumberBg, bg)
END SetLineNumberColors;

(* The scrollbars' width; 0 for Fl's. *)
PROCEDURE (d: TextDisplay) ScrollbarSize*(): INTEGER;
BEGIN RETURN Get(d, scrollbarSize)
END ScrollbarSize;

PROCEDURE (d: TextDisplay) SetScrollbarSize*(n: INTEGER);
BEGIN Set(d, scrollbarSize, n)
END SetScrollbarSize;

(* Editors *)

(* TRUE if typing inserts, as to start with; FALSE if it types over. *)
PROCEDURE (e: TextEditor) InsertMode*(): BOOLEAN;
BEGIN RETURN Get(e, insertMode) # 0
END InsertMode;

PROCEDURE (e: TextEditor) SetInsertMode*(on: BOOLEAN);
BEGIN Set(e, insertMode, Int(on))
END SetInsertMode;

(* TRUE if Tab moves the focus to the next widget; FALSE, as to start
   with, if it types a tab. *)
PROCEDURE (e: TextEditor) TabNav*(): BOOLEAN;
BEGIN RETURN Get(e, tabNav) # 0
END TabNav;

PROCEDURE (e: TextEditor) SetTabNav*(on: BOOLEAN);
BEGIN Set(e, tabNav, Int(on))
END SetTabNav;

(* The dispatcher the C++ part calls. *)
PROCEDURE ModifiedD(self: SYSTEM.ADDRESS; pos, inserted, deleted, restyled: SYSTEM.INT32);
  VAR b: TextBuffer;
BEGIN b := SYSTEM.VAL(TextBuffer, self); b.Modified(pos, inserted, deleted, restyled)
END ModifiedD;

BEGIN
  openBuffers := 0;
  CRegister(ModifiedD)
END FlText.
