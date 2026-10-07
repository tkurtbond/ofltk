MODULE MenuWithImages; (* FLTK's examples/howto-menu-with-images.cxx: menu items with images *)

(* A menu bar, a pop-up menu (the right button, on the window) and a
   choice, each with the same items: File's show an image and their
   text, a multi-label; Edit's show text; Images' show only an image.
   An item showing an image still has its text, which its action reads
   (FlMenus.Menu.ItemLabel), as FLTK's reads its user data. *)

IMPORT OutStr, Fl, FlMenus, FlImages, FlDialogs;

VAR
  win: Fl.DoubleWindow;
  box: Fl.Box;
  menubar: FlMenus.MenuBar;
  menubutt: FlMenus.MenuButton;
  choice: FlMenus.Choice;
  document, folder, redx: FlImages.Image;
  help: ARRAY 64 OF CHAR;
  ok: BOOLEAN;

(* The icon of a document. *)
PROCEDURE Document(i: FlImages.Image);
  VAR x: ARRAY 15, 14 OF CHAR;
BEGIN
  x[0] := "13 11 3 1";
  x[1] := "   c None";
  x[2] := "x  c #d8d8f8";
  x[3] := "@  c #202060";
  x[4] := " @@@@@@@@@   ";
  x[5] := " @xxxxxxx@   ";
  x[6] := " @xxxxxxx@   ";
  x[7] := " @xxxxxxx@   ";
  x[8] := " @xxxxxxx@   ";
  x[9] := " @xxxxxxx@   ";
  x[10] := " @xxxxxxx@   ";
  x[11] := " @xxxxxxx@   ";
  x[12] := " @xxxxxxx@   ";
  x[13] := " @xxxxxxx@   ";
  x[14] := " @@@@@@@@@   ";
  ASSERT(FlImages.OpenXPM(i, x, 15))
END Document;

(* The icon of a folder. *)
PROCEDURE Folder(i: FlImages.Image);
  VAR x: ARRAY 15, 14 OF CHAR;
BEGIN
  x[0] := "13 11 3 1";
  x[1] := "   c None";
  x[2] := "x  c #d8d833";
  x[3] := "@  c #808011";
  x[4] := "             ";
  x[5] := "     @@@@    ";
  x[6] := "    @xxxx@   ";
  x[7] := "@@@@@xxxx@@  ";
  x[8] := "@xxxxxxxxx@  ";
  x[9] := "@xxxxxxxxx@  ";
  x[10] := "@xxxxxxxxx@  ";
  x[11] := "@xxxxxxxxx@  ";
  x[12] := "@xxxxxxxxx@  ";
  x[13] := "@xxxxxxxxx@  ";
  x[14] := "@@@@@@@@@@@  ";
  ASSERT(FlImages.OpenXPM(i, x, 15))
END Folder;

(* The icon of a red X. *)
PROCEDURE RedX(i: FlImages.Image);
  VAR x: ARRAY 17, 14 OF CHAR;
BEGIN
  x[0] := "13 11 5 1";
  x[1] := "   c None";
  x[2] := "+  c #222222";
  x[3] := "x  c #555555";
  x[4] := "-  c #882222";
  x[5] := "@  c #ffffff";
  x[6] := "   x+++x     ";
  x[7] := "  ++---++    ";
  x[8] := " ++-----++   ";
  x[9] := "++-@@-@@-++  ";
  x[10] := "++--@@@--++  ";
  x[11] := "++---@---++  ";
  x[12] := "++--@@@--++  ";
  x[13] := "++-@@-@@-++  ";
  x[14] := " ++-----++   ";
  x[15] := "  ++---++    ";
  x[16] := "   x+++x     ";
  ASSERT(FlImages.OpenXPM(i, x, 17))
END RedX;

(* Every item's action: Quit hides the window, and the others say what
   they would do. *)
PROCEDURE MenuCb(w: Fl.Widget);
  VAR m: FlMenus.Menu; name: ARRAY 32 OF CHAR; s: ARRAY 64 OF CHAR;
BEGIN
  m := w(FlMenus.Menu);
  m.ItemLabel(m.Value(), name);
  IF name = "Quit" THEN
    win.Hide
  ELSE
    s := "'"; OutStr.String(name, s); OutStr.String("' would happen here", s);
    FlDialogs.Message(s)
  END
END MenuCb;

(* Adds an item that shows image i beside its text, a multi-label. *)
PROCEDURE AddItemToMenu(menu: FlMenus.Menu; label: ARRAY OF CHAR; key: INTEGER; i: FlImages.Image;
                        flags: SET);
  VAR n: INTEGER; ml: FlImages.MultiLabel; name: ARRAY 32 OF CHAR;
BEGIN
  n := menu.Add(label, key, Fl.Command, MenuCb, flags);
  menu.ItemLabel(n, name);
  NEW(ml); FlImages.OpenMultiLabel(ml);
  ml.SetImage(0, i);                       (* the image at the left *)
  ml.SetText(1, name, Fl.NormalLabel);     (* the text at the right *)
  FlImages.SetItemMultiLabel(menu, n, ml);
  ml.Close                                 (* the item keeps it *)
END AddItemToMenu;

(* Adds an item that shows only image i. *)
PROCEDURE AddImageItem(menu: FlMenus.Menu; label: ARRAY OF CHAR; i: FlImages.Image);
BEGIN FlImages.SetItemImage(menu, menu.Add(label, 0, {}, MenuCb, {}), i)
END AddImageItem;

PROCEDURE CreateMenuItems(menu: FlMenus.Menu);
  VAR n: INTEGER;
BEGIN
  (* Items with labels and images, multi-labels *)
  AddItemToMenu(menu, "File/New", ORD("n"), document, {});
  AddItemToMenu(menu, "File/Open", ORD("o"), folder, FlMenus.MenuDivider);
  AddItemToMenu(menu, "File/Quit", ORD("q"), redx, {});

  (* Items with just labels *)
  n := menu.Add("Edit/Copy", ORD("c"), Fl.Command, MenuCb, {});
  n := menu.Add("Edit/Paste", ORD("v"), Fl.Command, MenuCb, {});

  (* Items with just images *)
  AddImageItem(menu, "Images/One", document);
  AddImageItem(menu, "Images/Two", folder);
  AddImageItem(menu, "Images/Three", redx)
END CreateMenuItems;

BEGIN
  NEW(document); Document(document);
  NEW(folder); Folder(folder);
  NEW(redx); RedX(redx);
  NEW(win); Fl.OpenDoubleWindow(win, 400, 400, "Menu items with images");
  help := "Right click on window background"; OutStr.Ln(help); OutStr.String("for popup menu", help);
  win.SetTooltip(help);

  (* Help message *)
  NEW(box); Fl.OpenBox(box, 100, 100, 200, 200, help);
  box.SetAlign(Fl.AlignCenter + Fl.AlignInside);

  (* Menu bar *)
  NEW(menubar); FlMenus.OpenMenuBar(menubar, 0, 0, win.W(), 25, "");
  CreateMenuItems(menubar);

  (* Right click context menu *)
  NEW(menubutt); FlMenus.OpenMenuButton(menubutt, 0, 25, win.W(), win.H() - 25, "");
  CreateMenuItems(menubutt);
  menubutt.SetKind(FlMenus.Popup3);

  (* Chooser menu *)
  NEW(choice); FlMenus.OpenChoice(choice, 140, 50, 200, 25, "Choice");
  CreateMenuItems(choice);
  ok := choice.SetValue(1);

  win.End;
  win.SetResizable(win);
  win.Show;
  Fl.Run
END MenuWithImages.
