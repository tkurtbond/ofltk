MODULE Pipe; (* For the examples: a command's output, read as it comes (popen) *)

(* Running a command isn't FLTK's, so it isn't pofltk's: this is the
   examples' own, as test/Probe is the tests'. A Pipe reads the standard
   output of a command run by the shell; its Fd is for Fl.WatchFd. Its
   C++ part is Pipe.cpp. *)

IMPORT SYSTEM;

TYPE
  Pipe* = POINTER TO PipeDesc;
  PipeDesc* = RECORD
    h: SYSTEM.ADDRESS   (* the FILE *, or 0 *)
  END;

PROCEDURE ["C", "ofl_pipe_open"] COpen(cmd: ARRAY OF CHAR): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_pipe_fd"] CFd(h: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_pipe_read_line"] CReadLine(h: SYSTEM.ADDRESS; VAR s: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_pipe_close"] CClose(h: SYSTEM.ADDRESS): SYSTEM.INT32;

(* Runs cmd, with sh -c, for p to read its output; FALSE if it can't. *)
PROCEDURE Open*(p: Pipe; cmd-: ARRAY OF CHAR): BOOLEAN;
BEGIN
  ASSERT((p # NIL) & (p.h = 0));
  p.h := COpen(cmd);
  RETURN p.h # 0
END Open;

PROCEDURE (p: Pipe) IsOpen*(): BOOLEAN;
BEGIN RETURN p.h # 0
END IsOpen;

(* The descriptor of the command's output. *)
PROCEDURE (p: Pipe) Fd*(): INTEGER;
BEGIN ASSERT(p.h # 0); RETURN CFd(p.h)
END Fd;

(* The next line, with its line feed, cut to fit s (fgets); FALSE at the
   end of the output. It waits for a line, or the end. *)
PROCEDURE (p: Pipe) ReadLine*(VAR s: ARRAY OF CHAR): BOOLEAN;
BEGIN ASSERT(p.h # 0); RETURN CReadLine(p.h, s, SHORT(LEN(s))) # 0
END ReadLine;

(* Waits for the command to end; its exit status, or -1. Idempotent. *)
PROCEDURE (p: Pipe) Close*(): INTEGER;
  VAR r: INTEGER;
BEGIN
  r := -1;
  IF p.h # 0 THEN r := CClose(p.h); p.h := 0 END;
  RETURN r
END Close;

END Pipe.
