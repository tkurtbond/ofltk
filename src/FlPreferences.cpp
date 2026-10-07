// The C++ part of FlPreferences: Fl_Preferences. See pofltk.h for the
// conventions.
//
// Only a database's root is an Fl_Preferences kept here. Deleting it
// deletes every group's node, and delete_group and clear delete nodes,
// so an Fl_Preferences kept for a group could outlive its node
// (Fl_Preferences::~Fl_Preferences, Node::remove). A group is instead
// its root and its path from the root ("" the root itself, "a/b" a
// group b in a); FlPreferences checks it with ofl_prefs_exists before
// every other call, and each call makes it a short-lived Fl_Preferences.

#include "pofltk.h"

#include <FL/Fl_Preferences.H>
#include <string.h>

#include <new>

namespace {

Fl_Preferences *root(intptr_t r) { return reinterpret_cast<Fl_Preferences *>(r); }

// Calls f with the group path of root r: the root itself, or a group
// object made for the call. The group exists (ofl_prefs_exists), so
// Fl_Preferences(parent, path) finds it rather than making it.
template <typename F>
auto in(intptr_t r, const char *path, F f) -> decltype(f(*root(r))) {
  if (!*path) return f(*root(r));
  Fl_Preferences g(root(r), path);
  return f(g);
}

}  // namespace

extern "C" {

// kind: 0 the user's, 1 the system's, 2 in memory alone, 3 in the
// directory dir. Floating point is always written in the C locale.
// 0 if out of memory.
intptr_t ofl_prefs_open(int32_t kind, const char *dir, const char *vendor,
                        const char *application) {
  Fl_Preferences *p;
  switch (kind) {
    case 0:
      p = new (std::nothrow)
          Fl_Preferences(Fl_Preferences::USER_L, vendor, application);
      break;
    case 1:
      p = new (std::nothrow)
          Fl_Preferences(Fl_Preferences::SYSTEM_L, vendor, application);
      break;
    case 2:
      p = new (std::nothrow)
          Fl_Preferences(Fl_Preferences::MEMORY, vendor, application);
      break;
    default:
      p = new (std::nothrow) Fl_Preferences(
          dir, vendor, application, Fl_Preferences::C_LOCALE);
  }
  return reinterpret_cast<intptr_t>(p);
}

// Writes the database if it changed, and frees it with every group.
void ofl_prefs_close(intptr_t r) { delete root(r); }

int32_t ofl_prefs_exists(intptr_t r, const char *path) {
  return !*path || root(r)->group_exists(path);
}

// Makes group name in path's group; 0 if FLTK can't.
int32_t ofl_prefs_add_group(intptr_t r, const char *path, const char *name) {
  return in(r, path, [name](Fl_Preferences &p) -> int32_t {
    Fl_Preferences g(p, name);
    return p.group_exists(name);
  });
}

// what: 0 groups, 1 entries.
int32_t ofl_prefs_count(intptr_t r, const char *path, int32_t what) {
  return in(r, path, [what](Fl_Preferences &p) -> int32_t {
    return what ? p.entries() : p.groups();
  });
}

// The name of group or entry i; the node's own copy, valid until it
// changes.
intptr_t ofl_prefs_name(intptr_t r, const char *path, int32_t what,
                        int32_t i) {
  return in(r, path, [what, i](Fl_Preferences &p) -> intptr_t {
    return reinterpret_cast<intptr_t>(what ? p.entry(i) : p.group(i));
  });
}

int32_t ofl_prefs_has(intptr_t r, const char *path, int32_t what,
                      const char *name) {
  return in(r, path, [what, name](Fl_Preferences &p) -> int32_t {
    return what ? p.entry_exists(name) : p.group_exists(name);
  });
}

// what: 0 group name, 1 entry name, 2 every group, 3 every entry, 4
// both. 1 if something was deleted, or (2 to 4) always.
int32_t ofl_prefs_delete(intptr_t r, const char *path, int32_t what,
                         const char *name) {
  return in(r, path, [what, name](Fl_Preferences &p) -> int32_t {
    switch (what) {
      case 0: return p.delete_group(name);
      case 1: return p.delete_entry(name);
      case 2: return p.delete_all_groups();
      case 3: return p.delete_all_entries();
      default: return p.clear();
    }
  });
}

int32_t ofl_prefs_set_int(intptr_t r, const char *path, const char *name,
                          int32_t v) {
  return in(r, path, [name, v](Fl_Preferences &p) -> int32_t {
    return p.set(name, static_cast<int>(v));
  });
}

int32_t ofl_prefs_set_real(intptr_t r, const char *path, const char *name,
                           double v) {
  return in(r, path, [name, v](Fl_Preferences &p) -> int32_t {
    return p.set(name, v);
  });
}

int32_t ofl_prefs_set_text(intptr_t r, const char *path, const char *name,
                           const char *v) {
  return in(r, path, [name, v](Fl_Preferences &p) -> int32_t {
    return p.set(name, v);
  });
}

// The get functions give the default when the entry is missing, and
// return whether it was found.
int32_t ofl_prefs_get_int(intptr_t r, const char *path, const char *name,
                          int32_t def, int32_t *v) {
  return in(r, path, [name, def, v](Fl_Preferences &p) -> int32_t {
    int x;
    int32_t found = p.get(name, x, static_cast<int>(def));
    *v = x;
    return found;
  });
}

int32_t ofl_prefs_get_real(intptr_t r, const char *path, const char *name,
                           double def, double *v) {
  return in(r, path, [name, def, v](Fl_Preferences &p) -> int32_t {
    return p.get(name, *v, def);
  });
}

// Copies at most n - 1 bytes into text, and a 0.
int32_t ofl_prefs_get_text(intptr_t r, const char *path, const char *name,
                           const char *def, char *text, int32_t n) {
  return in(r, path, [name, def, text, n](Fl_Preferences &p) -> int32_t {
    return p.get(name, text, def, n);
  });
}

// The length of the entry's text; 0 if missing.
int32_t ofl_prefs_size(intptr_t r, const char *path, const char *name) {
  return in(r, path, [name](Fl_Preferences &p) -> int32_t {
    return p.size(name);
  });
}

// 0 written or unchanged, -1 if the file can't be written.
int32_t ofl_prefs_flush(intptr_t r) { return root(r)->flush(); }

// The file's name, cut to n - 1 bytes; "" in memory.
void ofl_prefs_filename(intptr_t r, char *buf, int32_t n) {
  buf[0] = 0;
  if (root(r)->filename(buf, n) == Fl_Preferences::MEMORY) buf[0] = 0;
}

}  // extern "C"
