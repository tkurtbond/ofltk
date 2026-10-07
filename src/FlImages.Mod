MODULE FlImages; (* Images: loaded from files or memory, made from pixels, drawn offscreen; multi-labels *)

(* An Image is a picture FLTK can draw: loaded from a PNG, JPEG, GIF, BMP,
   XPM, PNM or SVG file (the format told by its contents), decoded from
   bytes in memory, or made from RGB pixels. It is a resource the program
   owns, as a TextBuffer is: Close it when done. A widget showing it as
   its label keeps it until the widget is deleted or shows another, so
   closing an image a widget shows is safe; so does a browser showing it
   on a line, and a menu showing it on an item. A MultiLabel puts text
   and images side by side, in a widget's label or a menu item. An image the program loses
   without closing is closed by the collector. Using a closed image halts
   (Fl.ClosedResource).

   An image is drawn in a Draw method, as the rest of FlDraw is; or into
   a Surface, an image being drawn offscreen.

   Bad data is not an error: a file that can't be read or decoded comes
   back as FALSE. An XPM file's colors should be written "#rrggbb": FLTK
   knows color names ("red") on X11 alone, and draws them gray under
   Wayland. The C++ part is FlImages.cpp. *)

IMPORT SYSTEM, GarbageCollectedHeap, Fl, FlBrowsers, FlMenus;

CONST
  (* what an image is (Image.Kind) *)
  RGB* = 0;     (* pixels, 1 to 4 bytes each: PNG, JPEG, BMP, PNM, SVG, and those made from pixels *)
  Pixmap* = 1;  (* a palette: GIF, XPM *)
  Other* = 2;

TYPE
  Image* = POINTER TO ImageDesc;
  ImageDesc* = RECORD
    h: SYSTEM.ADDRESS
  END;

  (* A label of two parts, drawn side by side (FLTK's Fl_Multi_Label):
     each nothing, text, an image, or another multi-label, for more parts.
     A resource, as an Image is: the widgets and menu items showing it
     keep it, and it keeps its parts. *)
  MultiLabel* = POINTER TO MultiLabelDesc;
  MultiLabelDesc* = RECORD
    h: SYSTEM.ADDRESS
  END;

  (* An image being drawn: between Begin and End, FlDraw's drawing goes
     into it, offscreen. *)
  Surface* = POINTER TO SurfaceDesc;
  SurfaceDesc* = RECORD
    h: SYSTEM.ADDRESS;
    below: Surface;  (* the surface begun before this one *)
    begun: BOOLEAN
  END;

VAR
  openImages-: INTEGER;    (* images made and not yet closed or finalized *)
  openSurfaces-: INTEGER;  (* the same, for surfaces *)
  openMultiLabels-: INTEGER;  (* the same, for multi-labels *)
  current: Surface;        (* the surface last begun and not ended *)

PROCEDURE ["C", "ofl_image_load"] CLoad(name: ARRAY OF CHAR): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_load_data"] CLoadData(data: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_xpm"] CXPM(lines: ARRAY OF ARRAY OF CHAR; n, stride: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_rgb"] CRGB(bits: ARRAY OF CHAR; w, h, d, ld: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_close"] CClose(i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_image_get"] CGet(i: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_image_copy"] CCopy(i: SYSTEM.ADDRESS; w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_scale"] CScale(i: SYSTEM.ADDRESS; w, h, proportional, expand: SYSTEM.INT32);
PROCEDURE ["C", "ofl_image_change"] CChange(i: SYSTEM.ADDRESS; what, c: SYSTEM.INT32; weight: LONGREAL);
PROCEDURE ["C", "ofl_image_draw"] CDraw(i: SYSTEM.ADDRESS; x, y, w, h, cx, cy: SYSTEM.INT32);
PROCEDURE ["C", "ofl_image_pixel"] CPixel(i: SYSTEM.ADDRESS; x, y: SYSTEM.INT32; VAR r, g, b, a: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_image_save_png"] CSavePNG(i: SYSTEM.ADDRESS; name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_image_copy_to_clipboard"] CCopyToClipboard(i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_take_pasted_image"] CTakePastedImage(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_multi_new"] CMultiNew(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_multi_close"] CMultiClose(m: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_multi_set"] CMultiSet(m: SYSTEM.ADDRESS; i, kind: SYSTEM.INT32; s: ARRAY OF CHAR; t: SYSTEM.INT32; p: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_multi_contains"] CMultiContains(m, n: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_multi_label"] CWidgetMultiLabel(w: SYSTEM.ADDRESS; m: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_menu_item_label"] CMenuItemLabel(m: SYSTEM.ADDRESS; i, kind: SYSTEM.INT32; p: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_browser_icon"] CBrowserIcon(b: SYSTEM.ADDRESS; line: SYSTEM.INT32; i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_image"] CWidgetImage(w: SYSTEM.ADDRESS; slot: SYSTEM.INT32; i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_icon"] CWindowIcon(w, i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_surface_new"] CSurfaceNew(w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_surface_close"] CSurfaceClose(s: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_surface_begin"] CSurfaceBegin(s: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_surface_end"] CSurfaceEnd;
PROCEDURE ["C", "ofl_surface_draw"] CSurfaceDraw(s, w: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_surface_image"] CSurfaceImage(s: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_read_image"] CReadImage(x, y, w, h, alpha: SYSTEM.INT32): SYSTEM.ADDRESS;

PROCEDURE Int(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Int;

(* Images *)

PROCEDURE CloseHandle(i: Image);
BEGIN
  IF i.h # 0 THEN CClose(i.h); i.h := 0; DEC(openImages) END
END CloseHandle;

(* GC finalizer: an image lost without Close. *)
PROCEDURE FinalizeImage(obj: SYSTEM.PTR);
BEGIN CloseHandle(SYSTEM.VAL(Image, obj))
END FinalizeImage;

(* Makes i the image h, if h isn't 0; TRUE if it is. *)
PROCEDURE Opened(i: Image; h: SYSTEM.ADDRESS): BOOLEAN;
BEGIN
  IF h = 0 THEN RETURN FALSE END;
  i.h := h; INC(openImages);
  GarbageCollectedHeap.RegisterFinalizer(i, FinalizeImage);
  RETURN TRUE
END Opened;

PROCEDURE New(i: Image);
BEGIN ASSERT(i # NIL, Fl.NilArgument); ASSERT(i.h = 0, Fl.OpenedTwice)
END New;

(* i's handle, halting if i is closed. *)
PROCEDURE Hd(i: Image): SYSTEM.ADDRESS;
BEGIN
  ASSERT(i # NIL, Fl.NilArgument); ASSERT(i.h # 0, Fl.ClosedResource);
  RETURN i.h
END Hd;

(* Makes i the image in file name; FALSE, and i not open, if the file
   can't be read, or isn't an image FLTK can decode. *)
PROCEDURE Load*(i: Image; name-: ARRAY OF CHAR): BOOLEAN;
BEGIN New(i); RETURN Opened(i, CLoad(name))
END Load;

(* Makes i the image in the first n bytes of data: a PNG, JPEG, GIF, BMP
   or SVG file's contents (FLTK reads XPM and PNM from files alone), which
   are decoded, not kept; FALSE, and i not open, if they can't be
   decoded. *)
PROCEDURE LoadData*(i: Image; data-: ARRAY OF CHAR; n: INTEGER): BOOLEAN;
BEGIN
  New(i); ASSERT((n >= 0) & (n <= LEN(data)), Fl.IndexOutOfRange);
  RETURN Opened(i, CLoadData(data, n))
END LoadData;

(* Makes i the pixmap in the first n of lines, which are copied: the
   strings of an XPM file, without their quotes. The first holds the
   width, height, number of colors and characters a pixel (1 or 2); one
   line a color follows, then one a row of pixels. FALSE, and i not open,
   if the lines don't match the first, or can't be decoded. *)
PROCEDURE OpenXPM*(i: Image; lines-: ARRAY OF ARRAY OF CHAR; n: INTEGER): BOOLEAN;
BEGIN
  New(i); ASSERT((n >= 0) & (n <= LEN(lines)), Fl.IndexOutOfRange);
  RETURN Opened(i, CXPM(lines, n, SHORT(LEN(lines, 1))))
END OpenXPM;

(* Makes i an image of w by h pixels, from bits, which are copied: d
   bytes a pixel (1 gray, 2 gray and alpha, 3 red, green and blue, 4 those
   and alpha), rows starting ld bytes apart, 0 for w * d. *)
PROCEDURE OpenRGB*(i: Image; bits-: ARRAY OF CHAR; w, h, d, ld: INTEGER);
  VAR row: INTEGER;
BEGIN
  New(i);
  ASSERT((w > 0) & (h > 0) & (d >= 1) & (d <= 4) & ((ld = 0) OR (ld >= w * d)), Fl.IndexOutOfRange);
  IF ld = 0 THEN row := w * d ELSE row := ld END;
  ASSERT(row * h <= LEN(bits), Fl.IndexOutOfRange);
  ASSERT(Opened(i, CRGB(bits, w, h, d, ld)))  (* out of memory *)
END OpenRGB;

(* Makes copy a copy of i's data, at w by h pixels: scaled, with FLTK's
   own scaling. *)
PROCEDURE (i: Image) Copy*(copy: Image; w, h: INTEGER);
  VAR s: SYSTEM.ADDRESS;
BEGIN
  s := Hd(i); New(copy); ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  ASSERT(Opened(copy, CCopy(s, w, h)))  (* out of memory *)
END Copy;

(* Gives up the program's hold on i; idempotent. Widgets showing i keep
   it. *)
PROCEDURE (i: Image) Close*;
BEGIN CloseHandle(i)
END Close;

PROCEDURE (i: Image) IsOpen*(): BOOLEAN;
BEGIN RETURN i.h # 0
END IsOpen;

(* The size i is drawn at: its data's, unless Scale changed it. *)
PROCEDURE (i: Image) W*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 0)
END W;

PROCEDURE (i: Image) H*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 1)
END H;

(* The size of i's data, in pixels. *)
PROCEDURE (i: Image) DataW*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 3)
END DataW;

PROCEDURE (i: Image) DataH*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 4)
END DataH;

(* Bytes a pixel, 1 to 4, as OpenRGB takes them; a Pixmap's as Pixel
   reads it, 4. *)
PROCEDURE (i: Image) Depth*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 2)
END Depth;

(* RGB, Pixmap or Other. *)
PROCEDURE (i: Image) Kind*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 5)
END Kind;

(* Draws i at w by h pixels from now on, its data unchanged; keeping its
   proportions if proportional, within w by h, and larger than its data
   only if expand. *)
PROCEDURE (i: Image) Scale*(w, h: INTEGER; proportional, expand: BOOLEAN);
BEGIN CScale(Hd(i), w, h, Int(proportional), Int(expand))
END Scale;

(* Blends i's pixels with color c, a color of Fl's: weight 1 leaves them,
   0 makes them c. *)
PROCEDURE (i: Image) ColorAverage*(c: INTEGER; weight: REAL);
BEGIN CChange(Hd(i), 0, c, weight)
END ColorAverage;

(* Makes i's pixels gray. *)
PROCEDURE (i: Image) Desaturate*;
BEGIN CChange(Hd(i), 1, 0, 0)
END Desaturate;

(* Makes i look inactive, as FLTK draws an inactive label image. *)
PROCEDURE (i: Image) Inactive*;
BEGIN CChange(Hd(i), 0, Fl.Gray, 0.33)
END Inactive;

(* Draws i with its top left at x, y, in a Draw method or on a Surface. *)
PROCEDURE (i: Image) Draw*(x, y: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := Hd(i); CDraw(h, x, y, CGet(h, 0), CGet(h, 1), 0, 0)
END Draw;

(* Draws the w by h part of i at cx, cy, at x, y. *)
PROCEDURE (i: Image) DrawPart*(x, y, w, h, cx, cy: INTEGER);
BEGIN CDraw(Hd(i), x, y, w, h, cx, cy)
END DrawPart;

(* i's handle, halting unless x, y is in its data. *)
PROCEDURE P(i: Image; x, y: INTEGER): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Hd(i);
  ASSERT((x >= 0) & (y >= 0) & (x < CGet(h, 3)) & (y < CGet(h, 4)), Fl.IndexOutOfRange);
  RETURN h
END P;

(* Pixel x, y of i's data, as Fl.RGB gives a color; gray, r = g = b. *)
PROCEDURE (i: Image) Pixel*(x, y: INTEGER): INTEGER;
  VAR r, g, b, a: SYSTEM.INT32;
BEGIN
  ASSERT(CPixel(P(i, x, y), x, y, r, g, b, a) # 0, Fl.ClosedResource);  (* no pixels to read *)
  RETURN Fl.RGB(r, g, b)
END Pixel;

(* Its alpha, 0 transparent to 255 opaque; 255 if i has none. *)
PROCEDURE (i: Image) Alpha*(x, y: INTEGER): INTEGER;
  VAR r, g, b, a: SYSTEM.INT32;
BEGIN
  ASSERT(CPixel(P(i, x, y), x, y, r, g, b, a) # 0, Fl.ClosedResource);
  RETURN a
END Alpha;

(* Writes i to file name as a PNG; FALSE if it couldn't. *)
PROCEDURE (i: Image) SavePNG*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CSavePNG(Hd(i), name) # 0
END SavePNG;

(* The clipboard *)

(* Puts i on the clipboard, as the window system's own image. *)
PROCEDURE (i: Image) CopyToClipboard*;
BEGIN CCopyToClipboard(Hd(i))
END CopyToClipboard;

(* In a Handle of an EvPaste that carries an image (Fl.PasteImage,
   Fl.EventIsImage), makes i that image, now the program's; FALSE, and i
   not open, if the event carries none. An image no Handle takes is
   freed after the event. *)
PROCEDURE TakePastedImage*(i: Image): BOOLEAN;
BEGIN New(i); RETURN Opened(i, CTakePastedImage())
END TakePastedImage;

(* Widgets and windows *)

PROCEDURE Handle(i: Image): SYSTEM.ADDRESS;
BEGIN IF i = NIL THEN RETURN 0 ELSE RETURN Hd(i) END
END Handle;

(* Shows i in w's label, as Fl.Widget.SetAlign places it; NIL for none.
   w keeps i until it shows another, or is deleted. *)
PROCEDURE SetImage*(w: Fl.Widget; i: Image);
BEGIN CWidgetImage(Fl.Live(w), 0, Handle(i))
END SetImage;

(* The same, for when w is inactive; with none, FLTK draws the image
   grayed. *)
PROCEDURE SetInactiveImage*(w: Fl.Widget; i: Image);
BEGIN CWidgetImage(Fl.Live(w), 1, Handle(i))
END SetInactiveImage;

(* The icon the window system shows for win, copied; NIL for none.
   Wayland has none, and ignores it. *)
PROCEDURE SetIcon*(win: Fl.Window; i: Image);
BEGIN CWindowIcon(Fl.Live(win), Handle(i))
END SetIcon;

(* Shows i at the left of b's line, which is 1 to b.Count(); NIL for
   none. The line is made as tall as the image. b keeps i while a line
   shows it. *)
PROCEDURE SetLineIcon*(b: FlBrowsers.Browser; line: INTEGER; i: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(b); ASSERT((line >= 1) & (line <= b.Count()), Fl.IndexOutOfRange);
  CBrowserIcon(h, line, Handle(i))
END SetLineIcon;

(* Multi-labels *)

PROCEDURE CloseMulti(m: MultiLabel);
BEGIN
  IF m.h # 0 THEN CMultiClose(m.h); m.h := 0; DEC(openMultiLabels) END
END CloseMulti;

(* GC finalizer: a multi-label lost without Close. *)
PROCEDURE FinalizeMulti(obj: SYSTEM.PTR);
BEGIN CloseMulti(SYSTEM.VAL(MultiLabel, obj))
END FinalizeMulti;

(* m's handle, halting if m is closed. *)
PROCEDURE Mh(m: MultiLabel): SYSTEM.ADDRESS;
BEGIN
  ASSERT(m # NIL, Fl.NilArgument); ASSERT(m.h # 0, Fl.ClosedResource);
  RETURN m.h
END Mh;

(* Opens m with both parts nothing. *)
PROCEDURE OpenMultiLabel*(m: MultiLabel);
BEGIN
  ASSERT(m # NIL, Fl.NilArgument); ASSERT(m.h = 0, Fl.OpenedTwice);
  m.h := CMultiNew(); INC(openMultiLabels);
  GarbageCollectedHeap.RegisterFinalizer(m, FinalizeMulti)
END OpenMultiLabel;

(* Gives up the program's hold on m; idempotent. What shows m keeps it. *)
PROCEDURE (m: MultiLabel) Close*;
BEGIN CloseMulti(m)
END Close;

PROCEDURE (m: MultiLabel) IsOpen*(): BOOLEAN;
BEGIN RETURN m.h # 0
END IsOpen;

PROCEDURE Part(m: MultiLabel; part: INTEGER): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN h := Mh(m); ASSERT((part = 0) OR (part = 1), Fl.IndexOutOfRange); RETURN h
END Part;

(* Part 0 is drawn first, at the left (or top, as the label is aligned),
   and part 1 after it. A change shows when what shows m is redrawn. *)

(* The part becomes text, copied, drawn as label type t (Fl.NormalLabel
   to Fl.EmbossedLabel); "" for nothing. *)
PROCEDURE (m: MultiLabel) SetText*(part: INTEGER; text-: ARRAY OF CHAR; t: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Part(m, part); ASSERT((t >= Fl.NormalLabel) & (t <= Fl.EmbossedLabel), Fl.Unsupported);
  IF text = "" THEN CMultiSet(h, part, 0, "", 0, 0) ELSE CMultiSet(h, part, 1, text, t, 0) END
END SetText;

(* The part becomes image i, which m keeps; NIL for nothing. *)
PROCEDURE (m: MultiLabel) SetImage*(part: INTEGER; i: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Part(m, part);
  IF i = NIL THEN CMultiSet(h, part, 0, "", 0, 0) ELSE CMultiSet(h, part, 2, "", 0, Hd(i)) END
END SetImage;

(* The part becomes multi-label n, which m keeps; NIL for nothing. n
   that is m, or holds it, would be drawn forever, and halts
   (Fl.Unsupported). *)
PROCEDURE (m: MultiLabel) SetMulti*(part: INTEGER; n: MultiLabel);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Part(m, part);
  IF n = NIL THEN CMultiSet(h, part, 0, "", 0, 0)
  ELSE ASSERT(CMultiContains(Mh(n), h) = 0, Fl.Unsupported); CMultiSet(h, part, 3, "", 0, n.h)
  END
END SetMulti;

(* w's label becomes m, which w keeps until it shows another label, or
   is deleted; NIL for no label. Fl.Widget.SetLabel gives it text again.
   Not for a window, whose label is its title (Fl.Unsupported). *)
PROCEDURE SetMultiLabel*(w: Fl.Widget; m: MultiLabel);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(w); ASSERT(~(w IS Fl.Window), Fl.Unsupported);
  IF m = NIL THEN CWidgetMultiLabel(h, 0) ELSE CWidgetMultiLabel(h, Mh(m)) END
END SetMultiLabel;

(* Menu items *)

(* Item i of menu m shows image i, which the menu keeps while the item
   shows it; NIL for its text again. The item keeps its text, which its
   path is made of (ItemPath, FindIndex and Insert of FlMenus.Menu), and
   ItemLabel gives. Removing the item, or SetItemLabel, lets i go. *)
PROCEDURE SetItemImage*(m: FlMenus.Menu; item: INTEGER; i: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(m); ASSERT(m.IsItem(item), Fl.IndexOutOfRange);
  IF i = NIL THEN CMenuItemLabel(h, item, 0, 0) ELSE CMenuItemLabel(h, item, 1, Hd(i)) END
END SetItemImage;

(* The same, for multi-label l. *)
PROCEDURE SetItemMultiLabel*(m: FlMenus.Menu; item: INTEGER; l: MultiLabel);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(m); ASSERT(m.IsItem(item), Fl.IndexOutOfRange);
  IF l = NIL THEN CMenuItemLabel(h, item, 0, 0) ELSE CMenuItemLabel(h, item, 2, Mh(l)) END
END SetItemMultiLabel;

(* Surfaces *)

PROCEDURE CloseSurface(s: Surface);
BEGIN
  IF s.h # 0 THEN CSurfaceClose(s.h); s.h := 0; DEC(openSurfaces) END
END CloseSurface;

PROCEDURE FinalizeSurface(obj: SYSTEM.PTR);
BEGIN CloseSurface(SYSTEM.VAL(Surface, obj))
END FinalizeSurface;

(* s's handle, halting if it is closed. *)
PROCEDURE S(s: Surface): SYSTEM.ADDRESS;
BEGIN
  ASSERT(s # NIL, Fl.NilArgument); ASSERT(s.h # 0, Fl.ClosedResource);
  RETURN s.h
END S;

(* Makes s a surface of w by h pixels, white. *)
PROCEDURE OpenSurface*(s: Surface; w, h: INTEGER);
BEGIN
  ASSERT(s # NIL, Fl.NilArgument); ASSERT(s.h = 0, Fl.OpenedTwice);
  ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  s.h := CSurfaceNew(w, h); s.begun := FALSE; INC(openSurfaces);
  GarbageCollectedHeap.RegisterFinalizer(s, FinalizeSurface)
END OpenSurface;

PROCEDURE (s: Surface) IsOpen*(): BOOLEAN;
BEGIN RETURN s.h # 0
END IsOpen;

(* Sends drawing to s, until End. Surfaces nest: End ends the last one
   begun, and drawing goes to the one before. *)
PROCEDURE (s: Surface) Begin*;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := S(s); ASSERT(~s.begun, Fl.OutOfOrder);
  CSurfaceBegin(h); s.begun := TRUE; s.below := current; current := s
END Begin;

(* Sends drawing back where it went before Begin. s must be the surface
   last begun. *)
PROCEDURE (s: Surface) End*;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := S(s); ASSERT(s.begun & (current = s), Fl.OutOfOrder);
  CSurfaceEnd; s.begun := FALSE; current := s.below; s.below := NIL
END End;

(* Ends s if it is begun, and frees it; idempotent. *)
PROCEDURE (s: Surface) Close*;
BEGIN
  IF s.begun THEN s.End END;
  CloseSurface(s)
END Close;

(* Draws w and its children, as FLTK would on the screen, with w's top
   left at x, y; between Begin and End. *)
PROCEDURE (s: Surface) DrawWidget*(w: Fl.Widget; x, y: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := S(s); ASSERT(s.begun, Fl.OutOfOrder); CSurfaceDraw(h, Fl.Live(w), x, y)
END DrawWidget;

(* Makes i an image of what has been drawn on s. *)
PROCEDURE (s: Surface) GetImage*(i: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := S(s); New(i); ASSERT(Opened(i, CSurfaceImage(h)))  (* out of memory *)
END GetImage;

(* Makes i an image of the w by h pixels at x, y of what is being drawn
   on: a Surface begun, or a window in its Draw. With alpha, 4 bytes a
   pixel, all opaque; else 3. FALSE, and i not open, if FLTK couldn't read
   them. *)
PROCEDURE ReadImage*(i: Image; x, y, w, h: INTEGER; alpha: BOOLEAN): BOOLEAN;
BEGIN
  New(i); ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  RETURN Opened(i, CReadImage(x, y, w, h, Int(alpha)))
END ReadImage;

END FlImages.
