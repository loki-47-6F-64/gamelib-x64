#include "src/kernel/kernel.h"
#include "src/game/game.h"
#include "src/game/util.h"
#include "src/game/screen.h"

/**
 * You could prototype most high-level logic in C before
 * porting it to assembly. :p
 */

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
  const uint64_t stack[0];
} __attribute__((packed)) snapshot_t;

void print_snapshot(snapshot_t *snapshot) {
  screen_clear(&scr_full);

  screen_t scr_regs;
  screen_init(&scr_regs, 2, 9, 24, 15);

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

  uint64_t *vals = (uint64_t*)snapshot;
  const uint64_t size = sizeof(snapshot_t) / 8;

  char digit_buf[21];
  for(uint64_t x = 0; x < size; ++x) {
    writef(&scr_regs, "%s | 0x%h", regs[x], vals[x]);

    // new line
    cursor_inc(&scr_regs);
  }

  screen_t scr_addr;
  screen_t scr_stack;

  screen_init(&scr_addr, 30, 9, 3, 16);
  screen_init(&scr_stack, 33, 9, 46, 16);

  
  for(int32_t y = 0; y < (scr_addr.last.y - scr_addr.first.y); ++y) {
    writef(&scr_addr, "%u", y << 3);

    uint64_t stack_val = snapshot->stack[y];
    writef(&scr_stack, " | 0x%h | %u", stack_val, stack_val);

    // new line
    cursor_mov(&scr_addr, 0, 1);
    scr_addr.cursor.x = 0;

    cursor_mov(&scr_stack, 0, 1);
    scr_stack.cursor.x = 0;
  }
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
 * initializes any global vars
 */
void c_init() {
  // wait_for_debugger();
  screen_init(&scr_full, 0, 0, SCREEN_MAX_X, SCREEN_MAX_Y);

  PANIC;
 // write("Hello World!", 12, 0x0F);
}

void c_loop() {
}
