MODULE TextOverImageButton; (* FLTK's examples/howto-text-over-image-button.cxx: buttons with an image behind their text *)

IMPORT Fl, FlButtons, FlImages;

VAR
  gradient: FlImages.Image;
  win: Fl.Window;
  but1, but2: FlButtons.Button;

(* The gradient behind each button's label: the strings of an XPM. *)
PROCEDURE Gradient(i: FlImages.Image);
  VAR g: ARRAY 47, 136 OF CHAR;
BEGIN
  g[0] := "135 20 26 1";
  g[1] := "a      c #e0e0e0";
  g[2] := "b  c #dcdcdc";
  g[3] := "c  c #d8d8d8";
  g[4] := "d  c #d4d4d4";
  g[5] := "e  c #d2d2d2";
  g[6] := "f      c #d0d0d0";
  g[7] := "g  c #cccccc";
  g[8] := "h  c #c8c8c8";
  g[9] := "i  c #c4c4c4";
  g[10] := "j  c #c2c2c2";
  g[11] := "k      c #c0c0c0";
  g[12] := "l  c #bcbcbc";
  g[13] := "m  c #b8b8b8";
  g[14] := "n  c #b4b4b4";
  g[15] := "o  c #b2b2b2";
  g[16] := "p      c #b0b0b0";
  g[17] := "q  c #acacac";
  g[18] := "r  c #a8a8a8";
  g[19] := "s  c #a4a4a4";
  g[20] := "t  c #a2a2a2";
  g[21] := "u      c #a0a0a0";
  g[22] := "v  c #9c9c9c";
  g[23] := "w  c #989898";
  g[24] := "x  c #949494";
  g[25] := "y  c #929292";
  g[26] := "z      c #909090";
  g[27] := "aaaaaaaaabbbbbbbbcccccccddddddeeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrssss";
  g[28] := "aaaaaabbbbbbbbcccccccddddddeeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssst";
  g[29] := "aaabbbbbbbbcccccccddddddeeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssstt";
  g[30] := "bbbbbbbbcccccccddddddeeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrssssssssstttt";
  g[31] := "bbbbbcccccccddddddeeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttu";
  g[32] := "bbcccccccddddddeeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuu";
  g[33] := "ccccccddddddeeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuu";
  g[34] := "cccddddddeeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvv";
  g[35] := "ddddddeeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvv";
  g[36] := "dddeeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvw";
  g[37] := "eeeeeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvwwww";
  g[38] := "eeefffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvwwwwwww";
  g[39] := "fffffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvwwwwwwwwxx";
  g[40] := "ffffgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvwwwwwwwwxxxxx";
  g[41] := "fgggggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvwwwwwwwwxxxxxxyy";
  g[42] := "gggggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvwwwwwwwwxxxxxxyyyyy";
  g[43] := "ggghhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvwwwwwwwwxxxxxxyyyyyyyy";
  g[44] := "hhhhhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvwwwwwwwwxxxxxxyyyyyyyyzzz";
  g[45] := "hhhhiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvwwwwwwwwxxxxxxyyyyyyyyzzzzzz";
  g[46] := "hiiiiiiijjjjjjjkkkkkkkklllllllmmmmmmmnnnnnnnnnoooooooppppppppqqqqqqrrrrrrrsssssssssttttttuuuuuuuuvvvvvvvwwwwwwwwxxxxxxyyyyyyyyzzzzzzzzz";
  ASSERT(FlImages.OpenXPM(i, g, 47))
END Gradient;

BEGIN
  NEW(gradient); Gradient(gradient);
  NEW(win); Fl.OpenWindow(win, 160, 75, "test");
  NEW(but1); FlButtons.OpenButton(but1, 10, 10, 140, 25, "Button 1");  (* a regular button *)
  FlImages.SetImage(but1, gradient);                                    (* given an image *)
  but1.SetAlign(Fl.AlignImageBackdrop + but1.Align());                  (* behind its label *)
  NEW(but2); FlButtons.OpenButton(but2, 10, 40, 140, 25, "Button 2");  (* another *)
  FlImages.SetImage(but2, gradient);                                    (* the same image *)
  but2.SetAlign(Fl.AlignImageBackdrop + but2.Align());
  win.End;
  win.Show;
  Fl.Run
END TextOverImageButton.
