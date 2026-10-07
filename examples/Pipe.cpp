// The C++ part of the examples' Pipe module: popen, and reading from it.

#include <stdint.h>
#include <stdio.h>
#include <sys/wait.h>

extern "C" {

intptr_t ofl_pipe_open(const char *cmd) {
  return reinterpret_cast<intptr_t>(popen(cmd, "r"));
}

int32_t ofl_pipe_fd(intptr_t f) {
  return fileno(reinterpret_cast<FILE *>(f));
}

// 1 if a line was read into s, n bytes.
int32_t ofl_pipe_read_line(intptr_t f, char *s, int32_t n) {
  if (fgets(s, n, reinterpret_cast<FILE *>(f)) != 0) return 1;
  s[0] = 0;
  return 0;
}

int32_t ofl_pipe_close(intptr_t f) {
  int r = pclose(reinterpret_cast<FILE *>(f));
  return r != -1 && WIFEXITED(r) ? WEXITSTATUS(r) : -1;
}

}  // extern "C"
