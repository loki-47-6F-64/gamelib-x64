#include "src/kernel/kernel.h"
#include "src/game/game.h"
#include "src/game/util.h"
#include "src/game/screen.h"

/**
 * You could prototype most high-level logic in C before
 * porting it to assembly. :p
 */

// new_highscore_t new_highscore;
// score_t score[SCORE_SIZE];
// game_t game;
// 
// uint64_t game_state;

void highscore_init();
void menu_init();
/**
 * If it fits in the highscore, prepare the new highscore
 * params:
 *  score -- the new highscore
 */
void new_highscore_init(uint64_t new_score);

void highscore_loop();
void menu_loop();
void new_highscore_loop();
void game_loop();

// /**
//  * writes data to the screen
//  * params:
//  *  buf -- a pointer to the data to be written
//  *  count -- the amount if bytes in the buffer
//  */
// void write(screen_t *scr, const void *buf, uint64_t count, uint8_t color) {
//   if(!scr) {
//     scr = &scr_full;
//   }
// 
//   const char *data = buf;
// 
//   for(uint64_t x = 0; x < count; ++x) {
//     putChar(screen_x(scr), screen_y(scr), data[x], color);
// 
//     cursor_inc(scr);
//   }
// }
// 
// 
// /**
//  * If it fits in the highscore, prepare the new highscore
//  * params:
//  *  score -- the new highscore
//  */
// void new_highscore_init(uint64_t new_score) {
//   screen_clear(NULL, 0x00);
// 
//   int x;
//   for(x = 0; x < SCORE_SIZE; ++x) {
//     if(new_score > score[x].score) {
//       break; // new highscore, and there is a spot
//     }
//   }
// 
//   if(x == SCORE_SIZE) {
//     highscore_init();
//     return; // no new highscore
//   }
// 
//   // Insert new highscore
//   for(int y = SCORE_SIZE -1; y > x; --y) {
//     score[y] = score[y -1];
//   }
// 
//   // prepare initial values of the name
//   char *name = score[x].name;
//   name[0] = 'A';
//   name[1] = 'A';
//   name[2] = 'A';
//   name[3] = '\0';
// 
//   score[x].score = new_score;
// 
//   new_highscore.score = &score[x];
//   new_highscore.name_p = name;
// 
//   game_state = STATE_NEW_HIGHSCORE;
// }
// 
// /**
//  * initialize the game
//  */
// void game_init() {
//   fill(&game, 0, sizeof(game_t));
// 
//   game.player = game.queue;
// 
//   field_init(&game.field, 10, 6);
//   screen_init(&game.block_screen,
//       FIELD_SIZE_X + game.field.screen.first.x  +2,
//       4,
//       5,
//       BLOCK_POINTS *4 +1
//   );
// 
//   game_block_reset(&game);
// 
//   for(int x = 0; x < BLOCK_POINTS; ++x) {
//     block_next(&game.queue[x]);
//   }
// 
//   game.timer = 6 *TICKS_PER_SEC;
// 
//   game_state = STATE_GAME;
// }
// 
// uint64_t seed = 973;
// uint64_t rand_next() {
//   // wiki https://en.wikipedia.org/wiki/Linear_congruential_generator
//   // X<n+1> = (aX<n> + c) mod m
//   // 0 <= X<0> < m
//   // m and c are relatively prime
//   // a - 1 is divisible by all primefactors of m
//   // a - 1 is divisible by 4 if m is divisible by 4
//   const uint64_t a = 1103515245;
//   const uint64_t c = 12345;
//   const uint64_t m = 1 << 31;
// 
//   seed = (a*seed + c) % m;
// 
//   return seed / 3;
// }
// 
// void game_loop() {
//   int64_t ascii = readKeyCode();
// 
//   screen_t scr_info;
//   screen_init(&scr_info, 0, 0, SCREEN_SIZE_X, 2);
// 
//   --game.timer;
//   if(ascii) {
//     screen_clear(NULL, 0x00);
// 
//     switch(ascii) {
//       case KEY_CODE_AU:
//         block_mov(game.player, 0, -1);
//         break;
//       case KEY_CODE_AD:
//         block_mov(game.player, 0, 1);
//         break;
//       case KEY_CODE_AL:
//         block_mov(game.player, -1, 0);
//         break;
//       case KEY_CODE_AR:
//         block_mov(game.player, 1, 0);
//         break;
//       case KEY_CODE_S:
//         block_rotate(game.player);
//         break;
//       case KEY_CODE_ENT:
//         if( game.player->dealloc ||
//             field_empty(&game.field, game.player)
//         ) {
//           ++game.score;
//           field_block_merge(&game.field, game.player);
// 
//           game_next(&game); 
//         }
//         break;
//     }
// 
//     game_draw(&game);
//   }
// 
//   if(game.timer == 0) {
// //    screen_clear(NULL, 0x00);
// //    writef(NULL, "The application crashed...%nWhy did you abandon it? You monster!");
// 
//     new_highscore_init(game.score);
// 
//     return;
//   }
// 
//   writef(&scr_info,
//       "Time left: %c%u%c seconds!%n"
//       "Your current score: %c%u",
//       0xCF, game.timer / TICKS_PER_SEC +1, 0x07, 0x2F, game.score);
// }
// 
// void menu_init() {
//   screen_t middle;
//   screen_init(&middle, 20, 5, 40, 15);
// 
//   screen_clear(NULL, 0x00);
// 
//   writef(NULL, "sizeof(game_t) == %d", sizeof(field_t));
// 
//   writef(&middle,
//       "Please select the %capplication%c to run.%n%n%n"
//       "[1] :: %cGame%c%n%n"
//       "[2] :: %cHighscore",
//       0xCF, 0x07, 0x4F, 0x07, 0x4F
//   );
// 
//   game_state = STATE_MENU;
// }
// 
// void highscore_init() {
//   screen_clear(NULL, 0x00);
// 
//   screen_t scr_score;
//   screen_init(&scr_score, 20, 5, 45, SCORE_SIZE + 2);
// 
//   writef(&scr_score, "-- Hall of Shame --%n%n");
//   for(int x = 0; x < SCORE_SIZE; ++x) {
//     // Printed all scores
//     if(!score[x].score) {
//       break;
//     }
// 
//     writef(&scr_score, "%s | %u%n", score[x].name, score[x].score);
//   }
// 
//   game_state = STATE_HIGHSCORE;
// }
// 
// void menu_loop() {
//   uint64_t ascii = readKeyCode();
// 
//   seed = (seed +1) % (1 << 31);
// 
//   if(ascii) {
//     switch(ascii) {
//       case KEY_CODE_1:
//         game_init();
//         break;
//       case KEY_CODE_2:
//         highscore_init();
//         break;
//     };
//   }
// }
// 
// void new_highscore_loop() {
//   uint64_t ascii = readKeyCode();
// 
//   screen_t scr_score;
//   screen_init(&scr_score, 20, 10, 45, 2);
// 
// //  screen_clear(&scr_score, 0x00);
//   if(ascii) {
//     switch(ascii) {
//       case KEY_CODE_AU:
//         ++*new_highscore.name_p;
//         break;
//       case KEY_CODE_AD:
//         --*new_highscore.name_p;
//         break;
//       case KEY_CODE_ENT:
//         ++new_highscore.name_p;
// 
//         // Name entered
//         if(!*new_highscore.name_p) {
//           highscore_init();
//           return;
//         }
//         break;
//     }
//   }
// 
//   writef(&scr_score,
//       "Your score: %c%u%c%n"
//       "Your name:  %c%s",
//       0x2F, new_highscore.score->score, 0x07, 0xC7, new_highscore.score->name
//   );
// }
// 
// void highscore_loop() {
//   uint64_t ascii = readKeyCode();
// 
//   if(ascii == KEY_CODE_ENT) {
//     menu_init();
//   }
// }
// 
// void c_loop() {
//   switch(game_state) {
//     case STATE_MENU:
//       menu_loop();
//       break;
//     case STATE_GAME:
//       game_loop();
//       break;
//     case STATE_HIGHSCORE:
//       highscore_loop();
//       break;
//     case STATE_NEW_HIGHSCORE:
//       new_highscore_loop();
//       break;
//   }
// }
// 
// /**
//  * initializes any global vars
//  */
// void c_init() {
//   // 60HZ
//   setTimer(19886);
// 
//   screen_init(&scr_full, 0, 0, SCREEN_SIZE_X, SCREEN_SIZE_Y);
//   screen_clear(NULL, 0x00);
// 
//   menu_init();
// }
// 
// 
// /**
//  * A block has been placed, it is time for a new block.
//  * Oh... and the timer needs to be reset, I guess..
//  * params:
//  *  game
//  */
// void game_next(game_t *game) {
//   assert(game);
// 
//   game_block_reset(game);
//   block_next(game->player);
// 
//   // next block in queue
//   ++game->player;
//   if(game->player >= (game->queue + BLOCK_QUEUE_SIZE)) {
//     game->player = game->queue;
//   }
// 
//   game->timer = 6 * TICKS_PER_SEC;
// }
// 
// /**
//  * params:
//  *  game -- the game to draw
//  */
// void game_draw(game_t *game) {
//   field_draw(&game->field);
// 
//   screen_clear(&game->block_screen, 0x30);
//   for(int x = 0; x < BLOCK_QUEUE_SIZE; ++x) {
//     if(game->player != (game->queue + x)) {
//       block_draw(&game->block_screen, &game->queue[x]);
//     }
//   }
// 
//   field_block_draw(&game->field, game->player);
// }
// 
// /**
//  * reset the origin of all blocks in the queue
//  * params:
//  *  game -- the game
//  */
// void _game_block_reset(game_t *game) {
//   for(int x = 0; x < BLOCK_QUEUE_SIZE; ++x) {
//     block_t *tmp_block = &game->queue[x];
// 
//     tmp_block->mirror = 0;
//     tmp_block->rotate = 0;
// 
//     point_t *tmp_p = &tmp_block->origin;
// 
//     tmp_p->x = 0;
//     tmp_p->y = (x << 2); // x *4
//   }
// }
