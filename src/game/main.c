#include "src/kernel/kernel.h"


/**
 * You could prototype most high-level logic in C before
 * porting it to assembly. :p
 */

void CLoop() {
  int64_t ascii = readKeyCode();

  if(!ascii) {
    putChar(0, 0, 'N', 0x0F);
  }
  else {
    putChar(0, 0, 'Y', 0x0F);
  }
}
