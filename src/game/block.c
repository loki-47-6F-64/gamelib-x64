#include "src/kernel/kernel.h"
#include "src/game/game.h"
#include "src/game/util.h"

// /**
//  * Convert points in block to real points
//  * params:
//  *  screen -- the screen the block is in
//  *  in -- the points to put the result in
//  *  out -- the block
//  */
// void block_to_points(screen_t *screen, point_t *in, block_t *out) {
//   assert(screen && in && out);
// 
//   const int32_t max = BLOCK_POINTS -1;
//   for(int x = 0; x < BLOCK_POINTS; ++x) {
//     if(out->rotate) {
//       // With rotation y-axis becomes x-axis and
//       // the x-axis becomes the mirror of the y-axis
//       in[x].x = max - out->point[x].y;
//       in[x].y = out->point[x].x;
//     }
//     else {
//       in[x].x = out->point[x].x;
//       in[x].y = out->point[x].y;
//     }
// 
//     // A second rotation inverts x-axis and y-axis again,
//     // but it's mirrored relative to the original
//     if(out->mirror) {
//       //invert point
//       in[x].x = max - in[x].x;
//       in[x].y = max - in[x].y;
//     }
// 
//     in[x].x += out->origin.x;
//     in[x].y += out->origin.y;
//     // Normalize result
//     normalize(screen, &in[x]);
//   }
// }
// 
// 
// /**
//  * params:
//  *  block  -- the block to draw
//  *  screen -- the screen to draw on
//  */
// void block_draw(screen_t *screen, block_t *block) {
//   assert(screen && block);
// 
//   point_t block_point[BLOCK_POINTS];
//   block_to_points(screen, block_point, block);
// 
//   for(int x = 0; x < BLOCK_POINTS; ++x) {
//     point_t *tmp = &block_point[x];
// 
//     char b = '#';
//     if(block->dealloc) {
//       b = '-';
//     }
// 
//     putChar(screen->first.x + tmp->x, screen->first.y + tmp->y, b, 0x07);
//   }
// }
// 
// void block_square(block_t *block) {
//   point_t *p = block->point;
// 
//   p[0].x = 1;
//   p[0].y = 1;
// 
//   p[1].x = 2;
//   p[1].y = 2;
// 
//   p[2].x = 1;
//   p[2].y = 2;
// 
//   p[3].x = 2;
//   p[3].y = 1;
// }
// 
// void block_pole(block_t *block) {
//   point_t *p = block->point;
// 
//   p[0].x = 1;
//   p[0].y = 0;
// 
//   p[1].x = 1;
//   p[1].y = 1;
// 
//   p[2].x = 1;
//   p[2].y = 2;
// 
//   p[3].x = 1;
//   p[3].y = 3;
// 
// }
// 
// void block_hook(block_t *block) {
//   point_t *p = block->point;
// 
//   p[0].x = 0;
//   p[0].y = 1;
// 
//   p[1].x = 1;
//   p[1].y = 1;
// 
//   p[2].x = 1;
//   p[2].y = 0;
// 
//   p[3].x = 2;
//   p[3].y = 0;
// }
// 
// void block_stage(block_t *block) {
//   point_t *p = block->point;
// 
//   p[0].x = 3;
//   p[0].y = 3;
// 
//   p[1].x = 2;
//   p[1].y = 3;
// 
//   p[2].x = 1;
//   p[2].y = 3;
// 
//   p[3].x = 2;
//   p[3].y = 2;
// }
// 
// /**
//  * puts random positions in the block
//  * params:
//  *  block -- the block that get initialized
//  */
// void block_next(block_t *block) {
//   assert(block);
// 
//   block->dealloc = 0;
//   uint64_t type = rand_next() % 20;
//   if(type > 16) {
//     // Deallocation block
//     block->dealloc = 1;
//   }
// 
//   type = (type +1) % 4;
//   switch(type) {
//     case 0:
//       block_square(block);
//       break;
//     case 1:
//       block_pole(block);
//       break;
//     case 2:
//       block_hook(block);
//       break;
//     case 3:
//       block_stage(block);
//       break;
//   }
// }
// 
// /**
//  * params:
//  *  block -- the block to move
//  *  x -- how much movement along x-axis
//  *  y -- how much movement along y-axis
//  */
// void block_mov(block_t *block, int32_t x, int32_t y) {
//   assert(block);
// 
//   block->origin.x += x;
//   block->origin.y += y;
// }
// 
// /**
//  * (logically) rotates the block.
//  * params:
//  *  block -- the block to rotate
//  */
// void block_rotate(block_t *block) {
//   assert(block);
// 
//   if(block->rotate) {
//     // complement mirror
//     block->mirror = 1 - block->mirror;
// 
//     block->rotate = 0;
//   }
//   else {
//     block->rotate = 1;
//   }
// }
// 
// 
