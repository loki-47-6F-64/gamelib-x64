#include "src/kernel/kernel.h"
#include "src/game/game.h"
#include "src/game/util.h"
#include "src/game/screen.h"

/**
 * You could prototype most high-level logic in C before
 * porting it to assembly. :p
 */

game_t game;

uint64_t game_state;


/**
 * Convert points in block to real points
 * params:
 *  screen -- the screen the block is in
 *  in -- the points to put the result in
 *  out -- the block
 */
void block_to_points(screen_t *screen, point_t *in, block_t *out) {
  assert(screen && in && out);

  const int32_t max = BLOCK_POINTS -1;
  for(int x = 0; x < BLOCK_POINTS; ++x) {
    if(out->rotate) {
      // With rotation y-axis becomes x-axis and
      // the x-axis becomes the mirror of the y-axis
      in[x].x = max - out->point[x].y;
      in[x].y = out->point[x].x;
    }
    else {
      in[x].x = out->point[x].x;
      in[x].y = out->point[x].y;
    }

    // A second rotation inverts x-axis and y-axis again,
    // but it's mirrored relative to the original
    if(out->mirror) {
      //invert point
      in[x].x = max - in[x].x;
      in[x].y = max - in[x].y;
    }

    in[x].x += out->origin.x;
    in[x].y += out->origin.y;
    // Normalize result
    normalize(screen, &in[x]);
  }
}

/**
 * Checks wether it is possible to place the block
 * params
 *  field -- the playing field
 *  block -- the block that might overlap some other blocks or exceed bounds
 * returns:
 *    0 on false
 */
int field_empty(field_t *field, block_t *block) {
  assert(field && block);

  point_t block_point[BLOCK_POINTS];
  block_to_points(&field->screen, block_point, block);

  for(int x = 0; x < BLOCK_POINTS; ++x) {
    point_t *tmp = &block_point[x];
    // if field occupied
    if(field->field[tmp->y][tmp->x]) {
      return 0;
    }
  }

  return 1;
}

/**
 * writes data to the screen
 * params:
 *  buf -- a pointer to the data to be written
 *  count -- the amount if bytes in the buffer
 */
void write(screen_t *scr, const void *buf, uint64_t count, uint8_t color) {
  if(!scr) {
    scr = &scr_full;
  }

  const char *data = buf;

  for(uint64_t x = 0; x < count; ++x) {
    putChar(screen_x(scr), screen_y(scr), data[x], color);

    cursor_inc(scr);
  }
}


/**
 * initialize the game
 * params:
 *  game -- the game to initialize
 */
void game_init(game_t *game) {
  assert(game);

  fill(game, 0, sizeof(game_t));

  game->player = game->queue;

  field_init(&game->field, 10, 6);
  screen_init(&game->block_screen,
      FIELD_SIZE_X + game->field.screen.first.x  +2,
      4,
      5,
      BLOCK_POINTS *4 +1
  );

  game_block_reset(game);

  for(int x = 0; x < BLOCK_POINTS; ++x) {
    block_next(&game->queue[x]);
  }

  game->timer = 6 *TICKS_PER_SEC;
}

uint64_t seed = 973;
uint64_t rand_next() {
  // wiki https://en.wikipedia.org/wiki/Linear_congruential_generator
  // X<n+1> = (aX<n> + c) mod m
  // 0 <= X<0> < m
  // m and c are relatively prime
  // a - 1 is divisible by all primefactors of m
  // a - 1 is divisible by 4 if m is divisible by 4
  const uint64_t a = 1103515245;
  const uint64_t c = 12345;
  const uint64_t m = 1 << 31;

  seed = (a*seed + c) % m;

  return seed;
}

void c_game_loop() {
  int64_t ascii = readKeyCode();

  screen_t scr_timer;
  screen_init(&scr_timer, 0, 0, SCREEN_SIZE_X, 1);

  --game.timer;
  if(ascii) {
    screen_clear(NULL, 0x00);

    cursor_mov(&scr_full, 25, 0);
    writef(NULL, "KeyCode of key presses: %h", ascii);
    switch(ascii) {
      case KEY_CODE_AU:
        block_mov(game.player, 0, -1);
        break;
      case KEY_CODE_AD:
        block_mov(game.player, 0, 1);
        break;
      case KEY_CODE_AL:
        block_mov(game.player, -1, 0);
        break;
      case KEY_CODE_AR:
        block_mov(game.player, 1, 0);
        break;
      case KEY_CODE_S:
        block_rotate(game.player);
        break;
      case KEY_CODE_ENT:
        if( game.player->dealloc ||
            field_empty(&game.field, game.player)
        ) {
          field_block_merge(&game.field, game.player);

          game_next(&game); 
        }
        break;
    }

    game_draw(&game);
  }

  if(game.timer == 0) {
    screen_clear(NULL, 0x00);
    writef(NULL, "The application crashed...%nWhy did you abandon it? You monster!");
    while(1);
  }

  writef(&scr_timer, "Time left: %c%u%c seconds!", 0xC7, game.timer / TICKS_PER_SEC +1, 0x07);
}

void c_menu_init() {
  screen_t middle;
  screen_init(&middle, 20, 5, 40, 15);

  screen_clear(NULL, 0x00);

  writef(&middle,
      "Please select the %capplication%c to run.%n%n%n"
      "[1] :: %cGame%c%n%n"
      "[2] :: %cHighscore",
      0xCF, 0x07, 0x4F, 0x07, 0x4F
  );

}

void c_menu_loop() {
  uint64_t ascii = readKeyCode();

  seed = (seed +1) % (1 << 31);
  screen_t middle;
  screen_init(&middle, 25, 5, 25, 15);

  if(ascii) {
    switch(ascii) {
      case KEY_CODE_1:
        game_init(&game);
        game_state = STATE_GAME;
        break;
    };
  }
}

void c_loop() {
  if(game_state == STATE_GAME) {
    c_game_loop();
  }
  else if(game_state == STATE_MENU) {
    c_menu_loop();
  }

}

/**
 * initializes any global vars
 */
void c_init() {
  // 60HZ
  setTimer(19886);

  screen_init(&scr_full, 0, 0, SCREEN_SIZE_X, SCREEN_SIZE_Y);
  screen_clear(NULL, 0x00);

  c_menu_init();
}


/**
 * A block has been placed, it is time for a new block.
 * Oh... and the timer needs to be reset, I guess..
 */
void game_next(game_t *game) {
  assert(game);

  game_block_reset(game);
  block_next(game->player);

  // next block in queue
  ++game->player;
  if(game->player >= (game->queue + BLOCK_QUEUE_SIZE)) {
    game->player = game->queue;
  }

  game->timer = 6 * TICKS_PER_SEC;
}


/**
 * initializes a field.
 * params:
 *  field -- the field to init
 *  x -- x-origin
 *  y -- y-origin
 *  wdith
 *  height
 */
void field_init(field_t *field, int32_t x, int32_t y) {
  assert(field)

  assert(x >= 0 && y >= 0)
  assert((x + FIELD_SIZE_X <= SCREEN_SIZE_X) && (y + FIELD_SIZE_Y <= SCREEN_SIZE_Y))


  screen_init(&field->screen, x +1, y +1, FIELD_SIZE_X -1, FIELD_SIZE_Y -1);
  fill(field->field, 0, sizeof(field->field));
}

/**
 * params:
 *  block -- the block to move
 *  x -- how much movement along x-axis
 *  y -- how much movement along y-axis
 */
void block_mov(block_t *block, int32_t x, int32_t y) {
  assert(block);

  block->origin.x += x;
  block->origin.y += y;
}

/**
 * (logically) rotates the block.
 * params:
 *  block -- the block to rotate
 */
void block_rotate(block_t *block) {
  assert(block);

  if(block->rotate) {
    // complement mirror
    block->mirror = 1 - block->mirror;

    block->rotate = 0;
  }
  else {
    block->rotate = 1;
  }
}

/**
 * Draw field on screen
 * params:
 *  field
 */
void field_draw(field_t *field) {
  assert(field);

  point_t bound_l = { field->screen.first.x -1, field->screen.first.y -1 };
  point_t bound_r = { field->screen.last.x, field->screen.last.y };

  for(int x = bound_l.x; x <= bound_r.x; ++x) {
    putChar(x, bound_l.y, '+', 0x7F);
    putChar(x, bound_r.y, '+', 0x7F);
  }

  for(int y = bound_l.y; y <= bound_r.y; ++y) {
    putChar(bound_l.x, y, '+', 0x7F);
    putChar(bound_r.x, y, '+', 0x7F);
  }

  for(int y = 0; y < FIELD_SIZE_Y; ++y) {
    for(int x = 0; x < FIELD_SIZE_X; ++x) {
      // draw blocks
      if(field->field[y][x]) {
        putChar(field->screen.first.x + x, field->screen.first.y + y, '#', 0x07);
      }
    }
  }
}

/**
 * params:
 *  game -- the game to draw
 */
void game_draw(game_t *game) {
  field_draw(&game->field);

  screen_clear(&game->block_screen, 0x30);
  for(int x = 0; x < BLOCK_QUEUE_SIZE; ++x) {
    if(game->player != (game->queue + x)) {
      block_draw(&game->block_screen, &game->queue[x]);
    }
  }

  field_block_draw(&game->field, game->player);
}

/**
 * params:
 *  block  -- the block to draw
 *  screen -- the screen to draw on
 */
void block_draw(screen_t *screen, block_t *block) {
  assert(screen && block);

  point_t block_point[BLOCK_POINTS];
  block_to_points(screen, block_point, block);

  for(int x = 0; x < BLOCK_POINTS; ++x) {
    point_t *tmp = &block_point[x];

    char b = '#';
    if(block->dealloc) {
      b = '-';
    }

    putChar(screen->first.x + tmp->x, screen->first.y + tmp->y, b, 0x07);
  }
}

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

void block_square(block_t *block) {
  point_t *p = block->point;

  p[0].x = 1;
  p[0].y = 1;

  p[1].x = 2;
  p[1].y = 2;

  p[2].x = 1;
  p[2].y = 2;

  p[3].x = 2;
  p[3].y = 1;
}

void block_pole(block_t *block) {
  point_t *p = block->point;

  p[0].x = 1;
  p[0].y = 0;

  p[1].x = 1;
  p[1].y = 1;

  p[2].x = 1;
  p[2].y = 2;

  p[3].x = 1;
  p[3].y = 3;

}

void block_hook(block_t *block) {
  point_t *p = block->point;

  p[0].x = 0;
  p[0].y = 1;

  p[1].x = 1;
  p[1].y = 1;

  p[2].x = 1;
  p[2].y = 0;

  p[3].x = 2;
  p[3].y = 0;
}

void block_stage(block_t *block) {
  point_t *p = block->point;

  p[0].x = 3;
  p[0].y = 3;

  p[1].x = 2;
  p[1].y = 3;

  p[2].x = 1;
  p[2].y = 3;

  p[3].x = 2;
  p[3].y = 2;
}

/**
 * puts random positions in the block
 * params:
 *  block -- the block that get initialized
 */
void block_next(block_t *block) {
  assert(block);

  block->dealloc = 0;
  uint64_t type = rand_next() % 20;
  if(type > 16) {
    // Deallocation block
    block->dealloc = 1;
  }

  type = (type +1) % 4;
  switch(type) {
    case 0:
      block_square(block);
      break;
    case 1:
      block_pole(block);
      break;
    case 2:
      block_hook(block);
      break;
    case 3:
      block_stage(block);
      break;
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

/**
 * reset the origin of all blocks in the queue
 * params:
 *  game -- the game
 */
void game_block_reset(game_t *game) {
  for(int x = 0; x < BLOCK_QUEUE_SIZE; ++x) {
    block_t *tmp_block = &game->queue[x];

    tmp_block->mirror = 0;
    tmp_block->rotate = 0;

    point_t *tmp_p = &tmp_block->origin;

    tmp_p->x = 0;
    tmp_p->y = (x << 2); // x *4
  }
}
