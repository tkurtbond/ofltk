MODULE AddFdAndPopen; (* FLTK's examples/howto-add_fd-and-popen.cxx: a slow command's output, shown as it comes *)

(* It pings this host, which needs no network: a line every 2 seconds,
   ten times. Each is added to the browser when the pipe has it, so the
   window takes events meanwhile. *)

IMPORT Err, Fl, FlBrowsers, Pipe;

CONST
  PingCmd = "ping -i 2 -c 10 localhost";  (* a slow command *)

TYPE
  (* Adds each line of the command's output to brow. *)
  Watch = POINTER TO RECORD (Fl.FdWatchDesc)
    pipe: Pipe.Pipe;
    brow: FlBrowsers.MultiBrowser
  END;

VAR
  win: Fl.Window;
  brow: FlBrowsers.MultiBrowser;
  watch: Watch;

PROCEDURE (w: Watch) Ready*;
  VAR s: ARRAY 1024 OF CHAR; status: INTEGER;
BEGIN
  IF ~w.pipe.ReadLine(s) THEN                (* the command ended? *)
    Fl.UnwatchFd(w);                          (* stop watching *)
    status := w.pipe.Close();
    w.brow.Add(""); w.brow.Add("<<DONE>>");   (* say it finished *)
    RETURN
  END;
  w.brow.Add(s)                               (* a line read: add it *)
END Ready;

BEGIN
  NEW(win); Fl.OpenWindow(win, 600, 600, "");
  NEW(brow); FlBrowsers.OpenMultiBrowser(brow, 10, 10, 580, 580, "");
  NEW(watch); NEW(watch.pipe); watch.brow := brow;
  IF ~Pipe.Open(watch.pipe, PingCmd) THEN     (* start the command *)
    Err.String("popen failed"); Err.Ln;
    HALT(1)
  END;
  Fl.WatchFd(watch, watch.pipe.Fd(), Fl.FdRead);   (* call Ready when it has output *)
  win.End;
  win.SetResizable(brow);
  win.ShowArgs;
  Fl.Run
END AddFdAndPopen.
