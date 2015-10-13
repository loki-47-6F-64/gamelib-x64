#include "src/kernel/kernel.h"
#include "src/game/game.h"
#include "src/game/util.h"
#include "src/game/screen.h"

/**
 * You could prototype most high-level logic in C before
 * porting it to assembly. :p
 */

game_t game;

typedef struct {
  uint64_t rax;
  uint64_t rbx;
  uint64_t rcx;
  uint64_t rdx;
  uint64_t rsi;
  uint64_t rdi;
  uint64_t rbp;
  uint64_t rsp;
  uint64_t r8;
  uint64_t r9;
  uint64_t r10;
  uint64_t r11;
  uint64_t r12;
  uint64_t r13;
  uint64_t r14;
  uint64_t r15;
  const char *message;
  const uint64_t stack[0];
} __attribute__((packed)) snapshot_t;

void print_snapshot(snapshot_t *snapshot) {
  screen_clear(NULL, 0x90);

  writef(NULL, "%c"
      "This is a snapshot of the state of the game.%n"
      "The game send the following message:%n"
      "%s", 0x9F, snapshot->message);

  char *regs[] = {
    "rax",
    "rbx",
    "rcx",
    "rdx",
    "rsi",
    "rdi",
    "rbp",
    "rsp",
    "r8 ",
    "r9 ",
    "r10",
    "r11",
    "r12",
    "r13",
    "r14",
    "r15"
  };

  screen_t scr_regs;
  screen_init(&scr_regs, 2, 8, 24, 17);

  uint64_t *vals = (uint64_t*)snapshot;
  const uint64_t size = sizeof(regs) / 8;

  screen_clear(&scr_regs, 0x10);
  writef(&scr_regs, "%cThe registers:%n", 0x1F);
  for(uint64_t x = 0; x < size; ++x) {
    writef(&scr_regs, "%c%s | 0x%h", 0x1F, regs[x], vals[x]);
  }

  screen_t scr_msg;
  screen_t scr_addr;
  screen_t scr_stack;

  screen_init(&scr_msg, 29, 8, 50, 1);
  screen_init(&scr_addr, 29, 9, 4, 16);
  screen_init(&scr_stack, 33, 9, 46, 16);

  screen_clear(&scr_msg, 0x10); 
  screen_clear(&scr_addr, 0x10); 
  screen_clear(&scr_stack, 0x10); 
  writef(&scr_msg, "%cThe stack | (Hex and Integer)", 0x1F);
  for(int32_t y = 0; y < (scr_addr.last.y - scr_addr.first.y); ++y) {
    writef(&scr_addr, "%c%u", 0x1F, y << 3);

    uint64_t stack_val = snapshot->stack[y];
    writef(&scr_stack, "%c | 0x%h | %u%n", 0x1F, stack_val, stack_val);

    // new line
    cursor_mov(&scr_addr, 0, 1);
    scr_addr.cursor.x = 0;
  }
}

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
  block_to_points(&scr_full, block_point, block);

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
  field_init(&game->field, 10, 1);

  for(int x = 0; x < BLOCK_POINTS; ++x) {
    block_next(&game->queue[x]);
  }
}

uint64_t init = 0;

uint64_t seed = 1234;
uint64_t rand_next() {
  uint64_t res = seed * seed;

  // shave of the first two and last two digits
  uint64_t div = 100;

  // less than 8 digits
  if(res < 10000000) {
    div = 10;
  }

  // less than 7 digits
  if(res < 1000000) {
    div = 1;
  }


  res = (res / div) % 1000;

  seed = res;
  return res;
}

/**
 * initializes any global vars
 */
void c_init() {
  // 60HZ
  setTimer(19886);

  screen_init(&scr_full, 0, 0, SCREEN_SIZE_X, SCREEN_SIZE_Y);
  screen_clear(NULL, 0x00);

  game_init(&game);
  game.player->origin.x = 0;
  game.player->origin.y = 0;

  init = 1;
}

void c_loop() {
  if(!init) return;

  int64_t ascii = readKeyCode();

  if(ascii) {
    screen_clear(NULL, 0x00);
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
    }

    game_draw(&game);
  }
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


  // point_t l = { x, y };
  // point_t r = { x + FIELD_SIZE_X, y +  FIELD_SIZE_Y};

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
        putChar(x, y, '#', 0x07);
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

  for(int x = 0; x < BLOCK_QUEUE_SIZE; ++x) {
    block_draw(&game->queue[x]);
  }

  field_block_draw(&game->field, game->player);
}

/**
 * params:
 *  block -- the block to draw
 */
void block_draw(block_t *block) {
  assert(block);

  return;
  point_t block_point[BLOCK_POINTS];
  block_to_points(&scr_full, block_point, block);

  for(int x = 0; x < BLOCK_POINTS; ++x) {
    point_t *tmp = &block_point[x];

    putChar(tmp->x, tmp->y, '#', 0x07);
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

    putChar(screen->first.x + tmp->x, screen->first.y + tmp->y, '#', color);
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

  uint64_t type = rand_next() % 4;
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

