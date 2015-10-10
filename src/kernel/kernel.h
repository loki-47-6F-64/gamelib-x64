#ifndef KERNEL_H
#define KERNEL_H

/**
 * prints state to screen and halts execution
 */
#define PANIC __asm__ volatile("jmp panic")

#include "src/kernel/stdint.h"
int64_t readKeyCode();
void putChar(int8_t x, int8_t y, char ascii, int8_t color);

/*
 * Simply hlt's the processor until the debugger nops the instructions
 */
void wait_for_debugger();

#endif
