#ifndef KERNEL_H
#define KERNEL_H

#include "src/kernel/stdint.h"
int64_t readKeyCode();
void putChar(int8_t x, int8_t y, char ascii, int8_t color);

#endif
