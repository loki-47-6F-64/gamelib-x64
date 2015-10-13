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

#define KEY_CODE_W 0x11
#define KEY_CODE_S 0x1F
#define KEY_CODE_A 0x1E
#define KEY_CODE_D 0x20

#define KEY_CODE_ENT 0x1C

#define KEY_CODE_AU 72
#define KEY_CODE_AD 80
#define KEY_CODE_AL 75
#define KEY_CODE_AR 77

#define TICKS_PER_SEC 60 // Hz

#include "src/kernel/stdint.h"
int64_t readKeyCode();
void putChar(int8_t x, int8_t y, char ascii, int8_t color);
void setTimer(int16_t reloadValue);

/*
 * Simply hlt's the processor until the debugger nops the instructions
 */
void wait_for_debugger();

#endif
