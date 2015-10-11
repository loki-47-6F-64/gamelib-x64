#ifndef KERNEL_H
#define KERNEL_H

#define _CONST_TO_STRING_HELPER( x ) # x
#define CONST_TO_STRING( x ) _CONST_TO_STRING_HELPER( x )

/**
 * prints state to screen and halts execution
 */
#define PANIC( x ) \
  __asm__ volatile(\
      "pushq %0\n"\
      "jmp panic"\
      : : "r"  ( x ))

#ifdef NDEBUG
  #define assert( x )\
    if(!(x)) {\
      PANIC( __FILE__ ":" CONST_TO_STRING(__LINE__));\
    }
#else
  #define assert( x ) do {} while(0);
#endif



#include "src/kernel/stdint.h"
int64_t readKeyCode();
void putChar(int8_t x, int8_t y, char ascii, int8_t color);

/*
 * Simply hlt's the processor until the debugger nops the instructions
 */
void wait_for_debugger();

#endif
