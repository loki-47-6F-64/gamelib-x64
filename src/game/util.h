#ifndef GAME_UTIL_H
#define GAME_UTIL_H

#include "src/kernel/stdint.h"

// returns ascii representation of the value
char fromDigit(char val);

/*
 * str  -- array to be reversed
 * size -- size of the array
 */
void reverse(char *str, uint64_t size);

/* convert 'in' into a string
 *
 * out -- output for the string
 * in -- input for the string
 *
 * return:
 *  size of generated string
 */
uint64_t uint_to_string(char *out, uint64_t in);

/* convert 'in' into a string
 *
 * out -- output for the string
 * in -- input for the string
 *
 * return:
 *  size of generated string
 */
uint64_t int_to_string(char *out, int64_t in);

/* most significant hexadecimal digits are padded with zero's
 * convert 'in' into a string as an hexadecimal value
 *
 * out -- output for the string
 * in -- input for the string
 */
void uint_to_hex(char *out, uint64_t in);

/**
 * fills some memory with a value
 * params:
 *  out -- buffer for value
 *  val -- the value that buffer is filled with
 *  count -- the amount of bytes in buffer
 */
void fill(void *out, uint8_t val, uint64_t count);

/**
 * params:
 *  str -- null-terminated c-string
 * returns:
 *  the length of the string
 */
uint64_t strlen(const char *str);

/*
 * copy null-terminated string from 'in' to 'out'
 * 'out' will not be null-terminated
 */
uint64_t strcpy(char *out, const char *in);

#endif
