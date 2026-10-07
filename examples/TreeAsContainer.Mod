MODULE TreeAsContainer; (* FLTK's examples/tree-as-container.cxx: widgets in a tree's items *)

(* Each item under "FLTK Widgets" shows a row of inputs, a group the
   item holds (TreeItem.SetWidget), in place of its label. *)

IMPORT Fl, FlInputs, FlBrowsers, OutStr;

CONST
  MaxRows = 20000;
  MaxFields = 5;
  FieldWidth = 70;
  FieldHeight = 30;

TYPE
  MyData = POINTER TO RECORD (Fl.GroupDesc)
    fields: ARRAY MaxFields OF FlInputs.Input
  END;

VAR
  win: Fl.DoubleWindow;
  tree: FlBrowsers.Tree;
  item: FlBrowsers.TreeItem;
  data: MyData;
  s: ARRAY 80 OF CHAR;
  t, c: INTEGER;

PROCEDURE OpenMyData(d: MyData; x, y, w, h: INTEGER);
  VAR t: INTEGER; colors: ARRAY MaxFields OF INTEGER;
BEGIN
  colors[0] := Fl.RGB(0FFH, 0FFH, 0DDH); colors[1] := Fl.RGB(0FFH, 0DDH, 0DDH);
  colors[2] := Fl.RGB(0DDH, 0FFH, 0FFH); colors[3] := Fl.RGB(0DDH, 0FFH, 0DDH);
  colors[4] := Fl.RGB(0DDH, 0DDH, 0FFH);
  Fl.OpenGroup(d, x, y, w, h, "");
  FOR t := 0 TO MaxFields - 1 DO
    NEW(d.fields[t]); FlInputs.OpenInput(d.fields[t], x + t * FieldWidth, y, FieldWidth, h, "");
    d.fields[t].SetColor(colors[t])
  END;
  d.End
END OpenMyData;

PROCEDURE (d: MyData) SetData(col: INTEGER; val: ARRAY OF CHAR);
BEGIN
  IF (col >= 0) & (col < MaxFields) THEN d.fields[col].SetValue(val) END
END SetData;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 450, 400, "Tree As FLTK Widget Container");
  (* Create the tree *)
  NEW(tree); FlBrowsers.OpenTree(tree, 10, 10, win.W() - 20, win.H() - 20, "");
  tree.SetShowRoot(FALSE);                 (* don't show root of tree *)
  (* Add some regular text nodes *)
  item := tree.Add("Foo/Bar/001");
  item := tree.Add("Foo/Bar/002");
  item := tree.Add("Foo/Bla/Aaa");
  item := tree.Add("Foo/Bla/Bbb");
  (* Add items to the 'Data' node *)
  FOR t := 0 TO MaxRows - 1 DO
    (* Add item to tree *)
    s := "FLTK Widgets/"; OutStr.Int(t, 0, s);
    item := tree.Add(s);
    (* Make the item show an FLTK widget (MyData), which joins the tree *)
    NEW(data); OpenMyData(data, 0, 0, FieldWidth * MaxFields, FieldHeight);
    item.SetWidget(data);
    (* Initialize widget data *)
    FOR c := 0 TO MaxFields - 1 DO
      s := ""; OutStr.Int(t, 0, s); OutStr.Char("-", s); OutStr.Int(c, 0, s);
      data.SetData(c, s)
    END
  END;
  win.End;
  win.SetResizable(win);
  win.ShowArgs;
  Fl.Run
END TreeAsContainer.
