#ifndef KERNEL_GAME_H
#define KERNEL_GAME_H

#include "src/kernel/stdint.h"
#include "src/game/screen.h"

#define BLOCK_POINTS 4

#define FIELD_SIZE_X 40
#define FIELD_SIZE_Y 20

#define BLOCK_QUEUE_SIZE 4

typedef struct {
  screen_t screen;

  int32_t field[FIELD_SIZE_Y][FIELD_SIZE_X];
} field_t;

typedef struct {
  point_t origin;

  point_t point[BLOCK_POINTS];

  // either 1 or 0
  int32_t mirror;
  int32_t rotate;
} block_t;

typedef struct {
  block_t *player;
  block_t queue[BLOCK_QUEUE_SIZE];

  field_t field;
} game_t;

extern game_t game;
/**
 * Convert points in block to real points
 * params:
 *  screen -- the screen the block is in.
 *  in -- the points to put the result in
 *  out -- the block
 */
void block_to_points(screen_t *screen, point_t *in, block_t *out);

/**
 * (logically) rotates the block.
 * params:
 *  block -- the block to rotate
 */
void block_rotate(block_t *block);

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

/**
 * Draw field on screen
 * params:
 *  field
 */
void field_draw(field_t *field);

/**
 * initializes a field.
 * params:
 *  field -- the field to init
 *  x -- x-origin
 *  y -- y-origin
 */
void field_init(field_t *field, int32_t x, int32_t y); 

/**
 * Checks wether it is possible to place the block
 * params
 *  field -- the playing field
 *  block -- the block that might overlap some other blocks or exceed bounds
 * returns:
 *    0 on false
 */
int field_empty(field_t *field, block_t *block);

/**
 * params:
 *  game -- the game to draw
 */
void game_draw(game_t *game);


/**
 * initialize the game
 * params:
 *  game -- the game to initialize
 */
void game_init(game_t *game);

/**
 * like block_draw, but with color background on special purposes
 * params:
 *  field -- to know where to put the red background
 *  block -- the block to draw
 */
void field_block_draw(field_t *field, block_t *block);

/**
 * params:
 *  block -- the block to draw
 */
void block_draw(block_t *block);

/**
 * params:
 *  block -- the block to move
 *  x -- how much movement along x-axis
 *  y -- how much movement along y-axis
 */
void block_mov(block_t *block, int32_t x, int32_t y);

/**
 * puts random positions in the block
 * params:
 *  block -- the block that get initialized
 */
void block_next(block_t *block);

#endif
