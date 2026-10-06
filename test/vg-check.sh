#!/bin/sh
# vg-check.sh LOG: succeed unless a loss record in the valgrind log LOG
# (from --leak-check=full --show-leak-kinds=all) is memory that ofltk
# allocated: a record whose allocator - the first frame after malloc,
# calloc, realloc or operator new - is ofltk's C++ part (ofl_ functions,
# the ofl namespace) or one of its Oberon modules (Fl, FlDraw, ...). Each
# one found is printed.
#
# FLTK's display stack leaks by design: a program that deletes every
# widget it made still shows about 390 KB "definitely lost" and thousands
# of records, all allocated by fontconfig and Pango's font cache, and under
# Wayland by GTK's window decorations (libdecor). Confirmed live,
# 2026-10-06, on a C++ program, both backends: PLAN.md, Phase 0. Their
# allocators are in those libraries or in libfltk, so they pass; a widget
# that ofltk made and never deleted is allocated by an ofl_ function, so it
# doesn't. (polibfyaml's test/vg-reachable.sh checks by allocator too.)
awk '
  / bytes in [0-9,]+ blocks are .* in loss record / { inrec = 1; seen = 0; rec = $0; next }
  inrec && /(at|by) 0x/ {
    if ($0 ~ /: (malloc|calloc|realloc) \(/ || $0 ~ /: operator new/) next
    if (!seen) {
      seen = 1
      if ($0 ~ /: (ofl_|ofl::|Fl[A-Za-z]*\.)/) { print rec; print; bad = 1 }
    }
    next
  }
  inrec && /^==[0-9]+== *$/ { inrec = 0 }
  END { exit bad }
' "$1"
