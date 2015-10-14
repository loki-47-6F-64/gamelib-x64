#include "src/game/screen.h"
#include "src/kernel/kernel.h"

// /*
//  * Makes sure the point is within boundaries of the screen
//  * params:
//  *  screen -- the screen to use for normalization
//  *  p -- the point to normalize
//  *
//  * return:
//  *  non-zero on overflow of boundaries of (x or y)
//  */
// int32_t normalize(screen_t *screen, point_t *p) {
//   assert(screen && p)
// 
//   const int32_t bound_x = screen->last.x - screen->first.x;
//   const int32_t bound_y = screen->last.y - screen->first.y;
// 
//   assert(bound_x <= SCREEN_SIZE_X && bound_y <= SCREEN_SIZE_Y);
// 
//   uint32_t result = 1;
//   // Make sure the screen remains inside the bounds of the screen
//   while(p->x >= bound_x) {
//     p->x -= bound_x;
// 
//     result = 1;
//   }
//   while(p->x < 0) {
//     p->x += bound_x;
// 
//     result = 1;
//   }
// 
//   while(p->y >= bound_y) {
//     p->y -= bound_y;
// 
//     result = 1;
//   }
//   while(p->y < 0) {
//     p->y += bound_y;
// 
//     result = 1;
//   }
// 
//   return result;
// }
// 
// /**
//  * move screen position to (x,y) relative to it's current position.
//  * If the screen goes out of bounds, it will emerge from the other side.
//  * params:
//  *  screen
//  *  x
//  *  y
//  * return:
//  *  non-zero on overflow of x or y
//  */
// int64_t cursor_mov(screen_t *screen, int32_t x, int32_t y) {
//   assert(screen);
// 
//   point_t *cursor = &screen->cursor;
// 
//   cursor->x += x;
//   cursor->y += y;
// 
//   return normalize(screen, cursor);
// }
//
// /**
//  * increment screen position
//  * params:
//  *  screen
//  *
//  * return:
//  *  1  on overflow of x
//  *  -1 on overflow of y
//  *  0 otherwise
//  */
// int cursor_inc(screen_t *screen) {
//   assert(screen)
// 
//   const int32_t bound_x = screen->last.x - screen->first.x;
//   const int32_t bound_y = screen->last.y - screen->first.y;
// 
//   assert(bound_x <= SCREEN_SIZE_X && bound_y <= SCREEN_SIZE_Y);
// 
//   point_t *cursor = &screen->cursor;
// 
//   ++cursor->x;
// 
//   if(cursor->x >= bound_x) {
//     cursor->x = 0;
// 
//     ++cursor->y;
// 
//     if(cursor->y >= bound_y) {
//       cursor->y = 0;
// 
//       return -1;
//     }
// 
//     return 1;
//   }
// 
// 
//   return 0;
// }
//
// /**
//  * Makes the entire screen black
//  * params:
//  *  -- screen on NULL it is the entire screen
//  *  -- color the background color
//  */
// void screen_clear(screen_t *screen, int8_t color) {
//   if(!screen) {
//     screen = &scr_full;
//   }
// 
//   screen->cursor.x = 0;
//   screen->cursor.y = 0;
// 
//   do {
//     putChar(screen_x(screen), screen_y(screen), ' ', color);
//   } while(cursor_inc(screen) >= 0);
// }

/*
 * params:
 *  scr -- the screen
 * returns:
 *  absolute x coordinate
 */
int32_t screen_x(screen_t *scr) {
  assert(scr)
  assert(scr->cursor.x + scr->first.x <= SCREEN_SIZE_X);

  return scr->cursor.x + scr->first.x;
}

/*
 * params:
 *  scr -- the screen
 * returns:
 *  absolute y coordinate
 */
int32_t screen_y(screen_t *scr) {
  assert(scr)
  assert(scr->cursor.y + scr->first.y <= SCREEN_SIZE_Y);
  return scr->cursor.y + scr->first.y;
}

/**
 * initializes a screen
 * params:
 *  scr -- the screen to initialize
 *  x -- the x-origin
 *  y -- the y-origin
 *  width -- width of the screen
 *  height -- height of the screen
 */
void screen_init(screen_t *scr, int32_t x, int32_t y, int32_t width, int32_t height) {
  assert(scr)
  assert(x >= 0 && y >= 0)
  assert(width > 0 && height > 0)
  assert((x + width <= SCREEN_SIZE_X) && (y + height <= SCREEN_SIZE_Y))

  point_t c = {0};
  point_t f = {x, y};
  point_t l = {x + width, y + height};

  scr->first  = f;
  scr->last   = l;
  scr->cursor = c;
}
