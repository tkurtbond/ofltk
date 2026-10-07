MODULE TreeCustomDrawItems; (* FLTK's examples/tree-custom-draw-items.cxx: items that draw themselves *)

(* MyTimeItem extends FlBrowsers.TreeItem, and draws its label, three
   colored boxes, and the date and time (local or GMT), which a timer
   keeps up to date. Items are added two ways: made and added at a path
   (Tree.AddItem), or put in an existing item's place (TreeItem.Replace). *)

IMPORT Platform, Out, Fl, FlDraw, FlMenus, FlBrowsers;

TYPE
  MyTimeItem = POINTER TO RECORD (FlBrowsers.TreeItemDesc)
    timeFormat: ARRAY 8 OF CHAR    (* "Local" or "GMT" *)
  END;

  Tm = RECORD year, mon, mday, hour, min, sec: INTEGER END;   (* as struct tm: mon 0 .. 11, year since 1900 *)

  Timer = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  win: Fl.DoubleWindow;
  tree: FlBrowsers.Tree;
  item: FlBrowsers.TreeItem;
  scheme: FlMenus.SchemeChoice;
  timer: Timer;
  ok: BOOLEAN;

(* The local time now, from Platform's clock: the year modulo 100. *)
PROCEDURE LocalTime(VAR tm: Tm);
  VAR t, d: LONGINT;
BEGIN
  Platform.GetClock(t, d);
  tm.year := SHORT(d DIV 200H); tm.mon := SHORT(d DIV 20H MOD 10H) - 1; tm.mday := SHORT(d MOD 20H);
  tm.hour := SHORT(t DIV 1000H); tm.min := SHORT(t DIV 40H MOD 40H); tm.sec := SHORT(t MOD 40H)
END LocalTime;

(* GMT now, from the seconds since 1970: the civil date of a day number,
   by Howard Hinnant's days_from_civil, inverted. *)
PROCEDURE GmTime(VAR tm: Tm);
  VAR sec, usec, days, z, era, doe, yoe, doy, mp, y, m: LONGINT;
BEGIN
  Platform.GetTimeOfDay(sec, usec);
  days := sec DIV 86400; sec := sec MOD 86400;
  z := days + 719468; era := z DIV 146097; doe := z - era * 146097;
  yoe := (doe - doe DIV 1460 + doe DIV 36524 - doe DIV 146096) DIV 365;
  y := yoe + era * 400; doy := doe - (365 * yoe + yoe DIV 4 - yoe DIV 100);
  mp := (5 * doy + 2) DIV 153;
  tm.mday := SHORT(doy - (153 * mp + 2) DIV 5 + 1);
  IF mp < 10 THEN m := mp + 3 ELSE m := mp - 9 END;
  IF m <= 2 THEN INC(y) END;
  tm.year := SHORT(y - 1900); tm.mon := SHORT(m - 1);
  tm.hour := SHORT(sec DIV 3600); tm.min := SHORT(sec DIV 60 MOD 60); tm.sec := SHORT(sec MOD 60)
END GmTime;

(* Appends n as two digits, as "%02d". *)
PROCEDURE Two(n: INTEGER; VAR s: ARRAY OF CHAR; VAR i: INTEGER);
BEGIN
  s[i] := CHR(ORD("0") + n DIV 10 MOD 10); s[i + 1] := CHR(ORD("0") + n MOD 10);
  INC(i, 2); s[i] := 0X
END Two;

PROCEDURE Three(prefix: ARRAY OF CHAR; a: INTEGER; sep: CHAR; b, c: INTEGER; VAR s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  COPY(prefix, s); i := 0; WHILE s[i] # 0X DO INC(i) END;
  Two(a, s, i); s[i] := sep; INC(i); Two(b, s, i); s[i] := sep; INC(i); Two(c, s, i)
END Three;

(* Handle custom drawing of the item. Fl_Tree has already drawn
   everything to the left of the label area, including any user icon,
   collapse buttons and connector lines. All we're responsible for is
   drawing the label area of the item and its background, in the colors
   Fl_Tree hints at (DrawFgColor, DrawBgColor), and only if render. The
   result is the right-most X of what we draw, for the horizontal
   scrollbar. *)
PROCEDURE (i: MyTimeItem) DrawContent*(render: BOOLEAN): INTEGER;
  VAR fg, bg, x, y, w, h, dx, dw, lw, lh, lw2, lh2, box: INTEGER;
    label, s: ARRAY 80 OF CHAR; tm: Tm;
BEGIN
  fg := i.DrawFgColor(); bg := i.DrawBgColor();
  (* Show the date and time as two small strings, one on top of the
     other, in a single item. Our item's label dimensions: *)
  i.LabelXYWH(x, y, w, h);
  box := tree.SelectBox();
  (* Render background *)
  IF render THEN
    IF i.IsSelected() THEN                    (* selected? use selectbox() style *)
      FlDraw.DrawBox(box, x, y, w, h, bg)
    ELSE                                      (* not selected? use plain filled rectangle *)
      FlDraw.SetColor(bg); FlDraw.RectF(x, y, w, h)
    END
  END;
  (* Render the label *)
  i.GetLabel(label);
  dx := Fl.BoxDX(box) + 1; dw := Fl.BoxDW(box) + 2;
  IF render THEN
    FlDraw.SetColor(fg);
    FlDraw.TextAligned(label, x + dx, y, w - dw, h, Fl.AlignLeft)
  END;
  lw := 0; lh := 0; FlDraw.Measure(label, lw, lh);
  INC(x, lw + 8);
  (* Draw some red/grn/blu boxes *)
  IF render THEN
    FlDraw.SetColor(Fl.Red); FlDraw.RectF(x + 0, y + 2, 10, h - 4);
    FlDraw.SetColor(Fl.Green); FlDraw.RectF(x + 10, y + 2, 10, h - 4);
    FlDraw.SetColor(Fl.Blue); FlDraw.RectF(x + 20, y + 2, 10, h - 4)
  END;
  INC(x, 35);
  (* Render the date and time, one over the other *)
  FlDraw.SetFont(i.LabelFont(), 8);           (* small font *)
  FlDraw.SetColor(fg);
  IF i.timeFormat = "Local" THEN LocalTime(tm) ELSE GmTime(tm) END;
  Three("Date: ", tm.mon + 1, "/", tm.mday, tm.year MOD 100, s);
  lw := 0; lh := 0; FlDraw.Measure(s, lw, lh);   (* get box around text (including white space) *)
  IF render THEN FlDraw.TextAligned(s, x, y + 4, w, h, Fl.AlignLeft + Fl.AlignTop) END;
  Three("Time: ", tm.hour, ":", tm.min, tm.sec, s);
  IF render THEN FlDraw.TextAligned(s, x, y + h DIV 2, w, h DIV 2, Fl.AlignLeft + Fl.AlignTop) END;
  lw2 := 0; lh2 := 0; FlDraw.Measure(s, lw2, lh2);
  IF lw > lw2 THEN INC(x, lw) ELSE INC(x, lw2) END;
  RETURN x                                    (* right most edge of what we've rendered *)
END DrawContent;

PROCEDURE NewTimeItem(format: ARRAY OF CHAR): MyTimeItem;
  VAR i: MyTimeItem;
BEGIN NEW(i); COPY(format, i.timeFormat); RETURN i
END NewTimeItem;

(* Prints the tree, as Fl_Tree::show_self does for debugging, but without
   the items' addresses. *)
PROCEDURE ShowSelf(i: FlBrowsers.TreeItem; indent: ARRAY OF CHAR);
  VAR label: ARRAY 80 OF CHAR; i2: ARRAY 80 OF CHAR; t: INTEGER;
BEGIN
  i.GetLabel(label);
  Out.String(indent); Out.Char("-"); Out.String(label); Out.String(" (");
  Out.Int(i.Children(), 0); Out.String(" children, depth="); Out.Int(i.Depth(), 0); Out.Char(")"); Out.Ln;
  COPY(indent, i2); t := 0; WHILE i2[t] # 0X DO INC(t) END;
  i2[t] := " "; i2[t + 1] := "|"; i2[t + 2] := 0X;
  FOR t := 0 TO i.Children() - 1 DO ShowSelf(i.Child(t), i2) END
END ShowSelf;

(* Keeps the time in the tree up to date. *)
PROCEDURE (t: Timer) Fire*;
BEGIN
  tree.Redraw;
  Fl.RepeatTimeout(t, 0.2D0)
END Fire;

PROCEDURE AddTimeItem(path, format: ARRAY OF CHAR);
  VAR i: MyTimeItem;
BEGIN
  i := NewTimeItem(format);                   (* create custom item *)
  IF tree.AddItem(path, i, format) THEN i.SetLabelSize(20) END
END AddTimeItem;

PROCEDURE ReplaceTimeItem(path, format: ARRAY OF CHAR);
  VAR item: FlBrowsers.TreeItem; i: MyTimeItem;
BEGIN
  item := tree.Add(path);
  i := NewTimeItem(format);                   (* create custom item *)
  item.Replace(i, format);                    (* replace normal item with custom *)
  i.SetLabelSize(20)
END ReplaceTimeItem;

BEGIN
  ok := Fl.SetScheme("gtk+");                 (* default scheme: can be overridden by command line *)
  NEW(win); Fl.OpenDoubleWindow(win, 350, 450, "Tree Custom Draw Items");
  (* Create the tree *)
  NEW(tree); FlBrowsers.OpenTree(tree, 0, 0, win.W(), win.H() - 50, "");
  tree.SetShowRoot(FALSE);                    (* don't show root of tree *)
  tree.SetSelectMode(FlBrowsers.TreeSelectMulti);   (* multiselect *)

  (* Add some items *)
  item := tree.Add("Flintstones/Fred");
  item := tree.Add("Flintstones/Wilma");
  item := tree.Add("Flintstones/Pebbles");
  (* 'Add' approach *)
  AddTimeItem("Time Add Item/Local", "Local");
  AddTimeItem("Time Add Item/GMT", "GMT");
  (* 'Replace' approach *)
  ReplaceTimeItem("Time Replace Item/Local Time", "Local");
  ReplaceTimeItem("Time Replace Item/GMT Time", "GMT");
  item := tree.Add("Superjail/Warden");
  item := tree.Add("Superjail/Jared");
  item := tree.Add("Superjail/Alice");
  item := tree.Add("Superjail/Jailbot");

  ShowSelf(tree.Root(), "");

  (* Start with some items closed *)
  item := tree.Find("Superjail"); item.Close;
  (* Optional: set a "special" selection color (light blue) *)
  tree.SetSelectionColor(Fl.RGB(0CCH, 0EEH, 0FFH));
  (* Optional: set a "special" box type for the selection box *)
  tree.SetSelectBox(Fl.ThinUpBox);
  (* Create the scheme choice box *)
  NEW(scheme); FlMenus.OpenSchemeChoice(scheme, (win.W() - 130) DIV 2, win.H() - 40, 130, 30, "Scheme: ");
  (* Set up a timer to keep time in tree updated *)
  NEW(timer); Fl.AddTimeout(timer, 0.2D0);
  win.End;
  win.SetResizable(tree);
  win.SizeRange(300, 350, 0, 0);
  win.ShowArgs;
  Fl.Run
END TreeCustomDrawItems.
