#include "src/game/util.h"

/**
 * fills some memory with a value
 * params:
 *  out -- buffer for value
 *  val -- the value that buffer is filled with
 *  count -- the amount of bytes in buffer
 */
void fill(void *out, uint8_t val, uint64_t count) {
  uint8_t *_out = out;

  for(uint64_t x = 0; x < count; ++x) {
    _out[x] = val;
  }
}


// returns ascii representation of the value
char fromDigit(char val) {
  return val + '0';
}

/*
 * str  -- array to be reversed
 * size -- size of the array
 */
void reverse(char *str, uint64_t size) {
  char *backward_it = str + size -1;
  while(str < backward_it) {
    char tmp = *backward_it;
    *backward_it = *str;
    *str = tmp;

    ++str;
    --backward_it;
  }
}

/* convert 'in' into a string
 *
 * out -- output for the string
 * in -- input for the string
 *
 * return:
 *  size of generated string
 */
uint64_t int_to_string(char *out, int64_t in) {
  if(in >= 0) {
    return uint_to_string(out, in); 
  }

  in = (~in) + 1; // get positive value
  *out = '-';


  return uint_to_string(out +1, in) +1;
}

/* convert 'in' into a string
 *
 * out -- output for the string
 * in -- input for the string
 *
 * return:
 *  size of generated string
 */
uint64_t uint_to_string(char *out, uint64_t in) {
  if(in == 0) {
    *out = fromDigit(in);

    return 1;
  }

  char *out_p = out;
  while(in) {
    *out_p++ = fromDigit(in % 10);
    in /= 10;
  }

  uint64_t size = out_p - out;
  reverse(out, size);
  return size;
}

const char _bits[16] = {
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
};

/* convert 'in' into a string as a hexadecimal value
 *
 * out -- output for the string
 * in -- input for the string
 */
void uint_to_hex(char *out, uint64_t in) {
  fill(out, '0', 16);

  char *out_p = out;
  while(in) {
    *out_p++ = _bits[in % 16];
    in /= 16;
  }


  reverse(out, 16);
}


/**
 * str -- needs to be null-terminated
 * return
 *  the size of the string
 */
uint64_t strlen(const char *str) {
  uint64_t size = 0;
  while(*str++) {
    ++size;
  }

  return size;
}

/* copy null-terminated string from 'in' to 'out'
 * 'out' will not be null-terminated
 *
 * params:
 *  out -- the destination of the copy
 *  in  -- the source of the copy
 * return:
 *  the amount of characters copied
 */
uint64_t strcpy(char *out, const char *in) {
  char *out_p = out;
  while(*in) {
    *out_p++ = *in++;
  }

  return out_p - out;
}
