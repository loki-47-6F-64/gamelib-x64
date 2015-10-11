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

  screen_init(&scr_msg, 29, 8, 49, 1);
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
  screen_init(&scr_full, 0, 0, SCREEN_SIZE_X, SCREEN_SIZE_Y);

  assert(0, "W-W-What is h-happening?");
 // write("Hello World!", 12, 0x0F);
}

void c_loop() {
}
