MODULE WizardSimple; (* FLTK's examples/wizard-simple.cxx: three pages, with Back, Next and Finish *)

IMPORT Fl, FlButtons, FlInputs, FlLayout;

VAR
  win: Fl.Window;
  wiz: FlLayout.Wizard;

PROCEDURE Back(w: Fl.Widget);
BEGIN wiz.Prev
END Back;

PROCEDURE Next(w: Fl.Widget);
BEGIN wiz.Next
END Next;

PROCEDURE Done(w: Fl.Widget);
BEGIN win.Hide
END Done;

PROCEDURE Button(x: INTEGER; label: ARRAY OF CHAR; action: PROCEDURE (w: Fl.Widget));
  VAR b: FlButtons.Button;
BEGIN NEW(b); FlButtons.OpenButton(b, x, 265, 100, 25, label); b.action := action
END Button;

(* A page: its buttons first, then its text under title. *)
PROCEDURE Page(title, text: ARRAY OF CHAR; back: BOOLEAN; last: BOOLEAN);
  VAR g: Fl.Group; out: FlInputs.MultilineOutput;
BEGIN
  NEW(g); Fl.OpenGroup(g, 0, 0, 400, 300, "");
  IF last THEN Button(290, "Finish", Done) ELSE Button(290, "Next @->", Next) END;
  IF back THEN Button(180, "@<- Back", Back) END;
  NEW(out); FlInputs.OpenMultilineOutput(out, 10, 30, 400 - 20, 300 - 80, title);
  out.SetLabelSize(20);
  out.SetAlign(Fl.AlignTop + Fl.AlignLeft);
  out.SetValue(text);
  g.End
END Page;

BEGIN
  NEW(win); Fl.OpenWindow(win, 400, 300, "Example Wizard");
  NEW(wiz); FlLayout.OpenWizard(wiz, 0, 0, 400, 300, "");
  Page("Welcome", "This is First page", FALSE, FALSE);
  Page("Terms And Conditions", "This is the Second page", TRUE, FALSE);
  Page("Finish", "This is the Last page", TRUE, TRUE);
  wiz.End;
  win.End;
  win.Show;
  Fl.Run
END WizardSimple.
