#ifndef GAME_SCREEN_H
#define GAME_SCREEN_H

#include "src/kernel/stdint.h"

#define SCREEN_SIZE_X 80
#define SCREEN_SIZE_Y 25

typedef struct {
  int32_t x;
  int32_t y;
} point_t;

/**
 * params:
 *  first -- the left upper corner of the screen
 *  last  -- the right lower corner
 *  cursor -- the coordinates of the cursor
 */
typedef struct {
  point_t first;
  point_t last;
  point_t cursor;
} screen_t;

// screen_t scr_full;

/**
 * Makes the entire screen black
 * params:
 *  -- screen on NULL it is the entire screen
 *  -- color the background color
 */
void screen_clear(screen_t *screen, int8_t color);

/**
 * increment cursor position
 * params:
 *  screen
 *
 * return:
 *  1  on overflow of x
 *  -1 on overflow of y
 *  0 otherwise
 */
int cursor_inc(screen_t* screen);

/**
 * move cursor position to (x,y) relative to it's current position.
 * If the cursor goes out of bounds, it will emerge from the other side.
 * params:
 *  screen
 *  x
 *  y
 * return:
 *  non-zero on overflow of x or y
 */
int64_t cursor_mov(screen_t *screen, int32_t x, int32_t y);

/**
 * initializes a screen
 * params:
 *  scr -- the screen to initialize
 *  x -- the x-origin
 *  y -- the y-origin
 *  width -- width of the screen
 *  height -- height of the screen
 */
void screen_init(screen_t *scr, int32_t x, int32_t y, int32_t width, int32_t height);

/*
 * params:
 *  scr -- the screen
 * returns:
 *  absolute x coordinate
 */
int32_t screen_x(screen_t *scr);

/*
 * params:
 *  scr -- the screen
 * returns:
 *  absolute y coordinate
 */
int32_t screen_y(screen_t *scr);

/*
 * Makes sure the point is within boundaries of the screen
 * params:
 *  screen -- the screen to use for normalization
 *  p -- the point to normalize
 *
 * return:
 *  non-zero on overflow of boundaries of (x or y)
 */
int32_t normalize(screen_t *screen, point_t *p);

#endif
