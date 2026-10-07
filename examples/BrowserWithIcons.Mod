MODULE BrowserWithIcons; (* FLTK's examples/howto-browser-with-icons.cxx: icons on a browser's lines *)

IMPORT Fl, FlBrowsers, FlMenus, FlImages;

VAR
  w: Fl.DoubleWindow;
  b: FlBrowsers.MultiBrowser;
  choice: FlMenus.Choice;
  bigIcon, medIcon, smlIcon: FlImages.Image;
  n: INTEGER;
  ok: BOOLEAN;

(* The large icon: a face, 50 by 34. *)
PROCEDURE Big(i: FlImages.Image);
  VAR x: ARRAY 39, 51 OF CHAR;
BEGIN
  x[0] := "50 34 4 1";
  x[1] := "  c #000000";
  x[2] := "o c #ff9900";
  x[3] := "@ c #ffffff";
  x[4] := "# c None";
  x[5] := "##################################################";
  x[6] := "###      ##############################       ####";
  x[7] := "### ooooo  ###########################  ooooo ####";
  x[8] := "### oo  oo  #########################  oo  oo ####";
  x[9] := "### oo   oo  #######################  oo   oo ####";
  x[10] := "### oo    oo  #####################  oo    oo ####";
  x[11] := "### oo     oo  ###################  oo     oo ####";
  x[12] := "### oo      oo                     oo      oo ####";
  x[13] := "### oo       oo  ooooooooooooooo  oo       oo ####";
  x[14] := "### oo        ooooooooooooooooooooo        oo ####";
  x[15] := "### oo     ooooooooooooooooooooooooooo    ooo ####";
  x[16] := "#### oo   ooooooo ooooooooooooo ooooooo   oo #####";
  x[17] := "####  oo oooooooo ooooooooooooo oooooooo oo  #####";
  x[18] := "##### oo oooooooo ooooooooooooo oooooooo oo ######";
  x[19] := "#####  o ooooooooooooooooooooooooooooooo o  ######";
  x[20] := "###### ooooooooooooooooooooooooooooooooooo #######";
  x[21] := "##### ooooooooo     ooooooooo     ooooooooo ######";
  x[22] := "##### oooooooo  @@@  ooooooo  @@@  oooooooo ######";
  x[23] := "##### oooooooo @@@@@ ooooooo @@@@@ oooooooo ######";
  x[24] := "##### oooooooo @@@@@ ooooooo @@@@@ oooooooo ######";
  x[25] := "##### oooooooo  @@@  ooooooo  @@@  oooooooo ######";
  x[26] := "##### ooooooooo     ooooooooo     ooooooooo ######";
  x[27] := "###### oooooooooooooo       oooooooooooooo #######";
  x[28] := "###### oooooooo@@@@@@@     @@@@@@@oooooooo #######";
  x[29] := "###### ooooooo@@@@@@@@@   @@@@@@@@@ooooooo #######";
  x[30] := "####### ooooo@@@@@@@@@@@ @@@@@@@@@@@ooooo ########";
  x[31] := "######### oo@@@@@@@@@@@@ @@@@@@@@@@@@oo ##########";
  x[32] := "########## o@@@@@@ @@@@@ @@@@@ @@@@@@o ###########";
  x[33] := "########### @@@@@@@     @     @@@@@@@ ############";
  x[34] := "############  @@@@@@@@@@@@@@@@@@@@@  #############";
  x[35] := "##############  @@@@@@@@@@@@@@@@@  ###############";
  x[36] := "################    @@@@@@@@@    #################";
  x[37] := "####################         #####################";
  x[38] := "##################################################";
  ASSERT(FlImages.OpenXPM(i, x, 39))
END Big;

(* The medium icon: an X in a box, 14 by 14. *)
PROCEDURE Medium(i: FlImages.Image);
  VAR x: ARRAY 17, 15 OF CHAR;
BEGIN
  x[0] := "14 14 2 1";
  x[1] := "# c #000000";
  x[2] := "  c #ffffff";
  x[3] := "##############";
  x[4] := "##############";
  x[5] := "##          ##";
  x[6] := "##  ##  ##  ##";
  x[7] := "##  ##  ##  ##";
  x[8] := "##   ####   ##";
  x[9] := "##    ##    ##";
  x[10] := "##    ##    ##";
  x[11] := "##   ####   ##";
  x[12] := "##  ##  ##  ##";
  x[13] := "##  ##  ##  ##";
  x[14] := "##          ##";
  x[15] := "##############";
  x[16] := "##############";
  ASSERT(FlImages.OpenXPM(i, x, 17))
END Medium;

(* The small icon: an arrow, 9 by 11. *)
PROCEDURE Small(i: FlImages.Image);
  VAR x: ARRAY 17, 13 OF CHAR;
BEGIN
  x[0] := "9 11 5 1";
  x[1] := ".  c None";
  x[2] := "@  c #000000";
  x[3] := "+  c #808080";
  x[4] := "r  c #802020";
  x[5] := "#  c #ff8080";
  x[6] := ".........";
  x[7] := ".........";
  x[8] := "@+.......";
  x[9] := "@@@+.....";
  x[10] := "@@r@@+...";
  x[11] := "@@##r@@+.";
  x[12] := "@@####r@@";
  x[13] := "@@##r@@+.";
  x[14] := "@@r@@+...";
  x[15] := "@@@+.....";
  x[16] := "@+.......";
  ASSERT(FlImages.OpenXPM(i, x, 17))
END Small;

(* Gives lines 3, 4 and 5 the icon chosen, or none. The browser makes
   the lines as tall as their icons. *)
PROCEDURE ChoiceCb(w: Fl.Widget);
  VAR i: FlImages.Image;
BEGIN
  CASE choice.Value() OF
  | 0: i := NIL
  | 1: i := smlIcon
  | 2: i := medIcon
  | 3: i := bigIcon
  END;
  FlImages.SetLineIcon(b, 3, i);
  FlImages.SetLineIcon(b, 4, i);
  FlImages.SetLineIcon(b, 5, i)
END ChoiceCb;

BEGIN
  NEW(w); Fl.OpenDoubleWindow(w, 400, 300, "");

  (* The browser, with its icons (which could be PNGs or JPEGs too) *)
  NEW(bigIcon); Big(bigIcon);
  NEW(medIcon); Medium(medIcon);
  NEW(smlIcon); Small(smlIcon);
  NEW(b); FlBrowsers.OpenMultiBrowser(b, 10, 40, w.W() - 20, w.H() - 50, "");
  b.SetTextFont(Fl.Courier);
  b.SetTextSize(14);
  b.Add("One"); b.Add("Two"); b.Add("Three"); b.Add("Four");
  b.Add("Five"); b.Add("Six"); b.Add("Seven");

  (* A chooser for the icons *)
  NEW(choice); FlMenus.OpenChoice(choice, 60, 10, 140, 25, "Icon:");
  n := choice.Add("None", 0, {}, NIL, {});
  n := choice.Add("Small", 0, {}, NIL, {});
  n := choice.Add("Medium", 0, {}, NIL, {});
  n := choice.Add("Large", 0, {}, NIL, {});
  choice.action := ChoiceCb;
  ok := choice.TakeFocus();
  ok := choice.SetValue(1); choice.DoCallback;

  w.End;
  w.Show;
  Fl.Run
END BrowserWithIcons.
