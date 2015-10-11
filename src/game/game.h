#ifndef KERNEL_GAME_H
#define KERNEL_GAME_H

#include "src/kernel/stdint.h"
#include "src/game/screen.h"


/**
 * writes data to the screen
 * params:
 *  scr -- the screen to print on.
 *    if NULL, then assume full screen
 *  buf -- a pointer to the data to be written
 *  count -- the amount if bytes in the buffer
 */
void write(screen_t *scr, const void *buf, uint64_t count, uint8_t color);

/**
 * prints a formatted string.
 * %c (use new color)
 * %n (new-line)
 * %h (uint64_t) in hex
 * %d (int64_t)
 * %u (uint64_t)
 * %s (c-string)
 * %% (print '%')
 *
 * format -- format string
 */
void writef(screen_t *scr, const char* format, ...);

#endif
