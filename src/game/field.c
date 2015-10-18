#include "src/kernel/kernel.h"
#include "src/game/game.h"
#include "src/game/util.h"

// /**
//  * initializes a field.
//  * params:
//  *  field -- the field to init
//  *  x -- x-origin
//  *  y -- y-origin
//  *  wdith
//  *  height
//  */
// void field_init(field_t *field, int32_t x, int32_t y) {
//   assert(field)
// 
//   assert(x >= 0 && y >= 0)
//   assert((x + FIELD_SIZE_X <= SCREEN_SIZE_X) && (y + FIELD_SIZE_Y <= SCREEN_SIZE_Y))
// 
// 
//   screen_init(&field->screen, x +1, y +1, FIELD_SIZE_X -1, FIELD_SIZE_Y -1);
//   fill(field->field, 0, sizeof(field->field));
// }
// 
// /**
//  * Checks wether it is possible to place the block
//  * params
//  *  field -- the playing field
//  *  block -- the block that might overlap some other blocks or exceed bounds
//  * returns:
//  *    0 on false
//  */
// int field_empty(field_t *field, block_t *block) {
//   assert(field && block);
// 
//   point_t block_point[BLOCK_POINTS];
//   block_to_points(&field->screen, block_point, block);
// 
//   for(int x = 0; x < BLOCK_POINTS; ++x) {
//     point_t *tmp = &block_point[x];
//     // if field occupied
//     if(field->field[tmp->y][tmp->x]) {
//       return 0;
//     }
//   }
// 
//   return 1;
// }
// 
// /**
//  * Draw field on screen
//  * params:
//  *  field
//  */
// void field_draw(field_t *field) {
//   assert(field);
// 
//   point_t bound_l = { field->screen.first.x -1, field->screen.first.y -1 };
//   point_t bound_r = { field->screen.last.x, field->screen.last.y };
// 
//   for(int x = bound_l.x; x <= bound_r.x; ++x) {
//     putChar(x, bound_l.y, '+', 0x7F);
//     putChar(x, bound_r.y, '+', 0x7F);
//   }
// 
//   for(int y = bound_l.y; y <= bound_r.y; ++y) {
//     putChar(bound_l.x, y, '+', 0x7F);
//     putChar(bound_r.x, y, '+', 0x7F);
//   }
// 
//   for(int y = 0; y < FIELD_SIZE_Y; ++y) {
//     for(int x = 0; x < FIELD_SIZE_X; ++x) {
//       // draw blocks
//       if(field->field[y][x]) {
//         putChar(field->screen.first.x + x, field->screen.first.y + y, '#', 0x07);
//       }
//     }
//   }
// }

/**
 * params:
 *  field -- the field
 *  block -- the block to draw
 */
void field_block_draw(field_t *field, block_t *block) {
  assert(field && block);

  screen_t *screen = &field->screen;
  point_t block_point[BLOCK_POINTS];
  block_to_points(screen, block_point, block);

  for(int x = 0; x < BLOCK_POINTS; ++x) {
    int8_t color = 0x27;

    point_t *tmp = &block_point[x];

    // if field occupied
    if(field->field[tmp->y][tmp->x]) {
      color = 0xC7; // red background
    }

    char b = '#';
    if(block->dealloc) {
      b = '-';
    }

    putChar(screen->first.x + tmp->x, screen->first.y + tmp->y, b, color);
  }
}

/**
 * merge the block with field.
 * params:
 *  field -- the field for merging
 *  block -- the block for merging
 */
void field_block_merge(field_t *field, block_t *block) {
  assert(field && block);

  point_t block_point[BLOCK_POINTS];
  block_to_points(&field->screen, block_point, block);

  for(int x = 0; x < BLOCK_POINTS; ++x) {
    field->field[block_point[x].y][block_point[x].x] = 1 - block->dealloc;
  }

}
