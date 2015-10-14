# abi x764 linux :: http://www.x86-64.org/documentation/abi.pdf
# Registers %rbp, %rbx, %r12 through %r15 belong to the caller
# These registers must be restored before returning
#
#
# The stack grows downwards from high addresses


# At the entry of a function, (%rsp + 8) is a multiple of 16

# args passing :: INTEGER
#   0 .. 5
#    rdi, rsi, rdx, rcx, r8, r9
#   n .. 6
#      push{l,q}
.att_syntax

.include "src/game/debug_macro.s"

.text

.global normalize
.global cursor_mov
.global cursor_inc
.global screen_clear

/**
 * Makes the entire screen black
 * params:
 *  (screen_t*) screen -- on NULL it is the entire screen
 *  (int8_t) color -- the background color
 */
screen_clear:
  pushq %rbp
  movq %rsp, %rbp

  pushq %r15
  pushq %r14
  pushq %r13

  movq %rdi, %r15 # screen
  movq %rsi, %r14 # color

  cmpq $0, %rdi # if screen == NULL, then use default screen
  jne 1f

  # use default screen instead
  movq $scr_full, %r15
1:
  # reset cursor for the screen
  movq $0, 16(%r15)

2: # do
  movq %r15, %rdi
  call screen_x # get screen x-coordinate
  movq %rax, %r13 # store x-coordinate

  movq %r15, %rdi
  call screen_y # get y-coordinate

  movq %rax, %rsi # y
  movq %r13, %rdi # x
  movq $' ', %rdx
  movq %r14, %rcx # color
  call putChar

  movq %r15, %rdi
  call cursor_inc

  cmp $0, %rax
  jge 2b # while(cursor_inc(screen) >= 0)

  popq %r13
  popq %r14
  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret
/**
 * increment screen position
 * params:
 *  (screen_t*) screen
 *
 * return:
 *  1  on overflow of x
 *  -1 on overflow of y
 *  0 otherwise
 */
cursor_inc:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, cursor_mov_1, jne

  movl (%rdi), %r11d  # screen->first.x
  movl 8(%rdi), %r10d # screen->last.x
  movl 4(%rdi), %r9d  # screen->first.y
  movl 12(%rdi), %r8d # screen->last.y

  subl %r11d, %r10d # bound_x
  subl %r9d, %r8d   # bound_y

  assert $SCREEN_SIZE_X, %r10d, cursor_mov_bound_1, jle
  assert $SCREEN_SIZE_Y, %r8d, cursor_mov_bound_1, jle

  movq $0, %rax # result = 0

  incl 16(%rdi)
  cmpl 16(%rdi), %r10d
  jg 1f

# if cursor->x >= bound_x
  movq $1, %rax # result = 1
  movl $0, 16(%rdi) # reset x-coordinate
  
  incl 20(%rdi)
  cmpl 20(%rdi), %r8d
  jg 1f
# if cursor->y >= bound_y
  movq $-1, %rax # result = -1
  movl $0, 20(%rdi) # reset y-coordinate
1: # endif
  
  movq %rbp, %rsp
  popq %rbp

  ret

/**
 * move screen position to (x,y) relative to it's current position.
 * If the screen goes out of bounds, it will emerge from the other side.
 * params:
 *  (screen_t*) screen
 *  (int32_t) x
 *  (int32_t) y
 * return:
 *  non-zero on overflow of x or y
 */
cursor_mov:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, cursor_mov_1, jne

  lea 16(%rdi), %r11 # &screen->cursor

  # Add x and y to the cursor
  addl %esi, (%r11)  # x
  addl %edx, 4(%r11) # y

  movq %r11, %rsi
  call normalize # normalize(screen, cursor)
  
  movq %rbp, %rsp
  popq %rbp

  ret
/*
 * Makes sure the point is within boundaries of the screen
 * params:
 *  (screen_t*) screen -- the screen to use for normalization
 *  (point_t *) p -- the point to normalize
 *
 * return:
 *  non-zero on overflow of boundaries of (x or y)
 */
normalize:
  pushq %rbp
  movq %rsp, %rbp

  # assert not NULL
  assert $0, %rdi, normalize_1, jne
  assert $0, %rdi, normalize_2, jne


  movl (%rdi), %r11d  # screen->first.x
  movl 8(%rdi), %r10d # screen->last.x
  movl 4(%rdi), %r9d  # screen->first.y
  movl 12(%rdi), %r8d # screen->last.y

  subl %r11d, %r10d # bound_x
  subl %r9d, %r8d   # bound_y

  assert $SCREEN_SIZE_X, %r10d, normalize_bound_1, jle
  assert $SCREEN_SIZE_Y, %r8d, normalize_bound_1, jle

  movq $0, %rax # result = 0

  movl (%esi), %r11d # p->x
  movl 4(%esi), %r9d # p->y

# First two loops normalize the x-value
# Last two loops normalize the y-value
1: # while p->x >= bound_x
  cmpl %r10d, %r11d
  jl 2f

  subl %r10d, %r11d # p->x -= bound_x
  movq $1, %rax # result = 1

  jmp 1b
2: # while p->x < 0
  cmpl $0, %r11d
  jge 3f

  addl %r10d, %r11d # p->x += bound_x
  movq $1, %rax # result = 1

  jmp 2b
3: # while p->y >= bound_y
  cmpl %r8d, %r9d
  jl 4f
  
  subl %r8d, %r9d # p->y -= bound_y
  movq $1, %rax # result = 1
  jmp 3b
4: # while p->y < 0
  cmpl $0, %r9d
  jge 5f

  addl %r8d, %r9d # p->y += bound_y
  movq $1, %rax # result = 1
  jmp 4b
5:
  
  # store normalized values
  movl %r11d, (%rsi)
  movl %r9d, 4(%rsi)

  movq %rbp, %rsp
  popq %rbp

  ret
