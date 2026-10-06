#include <stdint.h>
typedef void (*cb_t)(intptr_t, intptr_t);
void invoke(cb_t cb, intptr_t w, intptr_t d) { cb(w, d); }
