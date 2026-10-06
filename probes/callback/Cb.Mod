MODULE Cb;
  IMPORT SYSTEM, Out;
  TYPE
    Callback = PROCEDURE (w, data: SYSTEM.ADDRESS);
    Obj = POINTER TO ObjDesc;
    ObjDesc = RECORD n: LONGINT; name: ARRAY 16 OF CHAR END;
  VAR o: Obj;

  PROCEDURE ["C", "invoke"] Invoke(cb: Callback; w, data: SYSTEM.ADDRESS);

  PROCEDURE Handler(w, data: SYSTEM.ADDRESS);
    VAR p: Obj;
  BEGIN
    p := SYSTEM.VAL(Obj, data);
    Out.String("callback w="); Out.Int(w, 0); Out.String(" n="); Out.Int(p.n, 0);
    Out.String(" "); Out.String(p.name); Out.Ln
  END Handler;
BEGIN
  NEW(o); o.n := 42; o.name := "hello";
  Invoke(Handler, 7, SYSTEM.VAL(SYSTEM.ADDRESS, o))
END Cb.
