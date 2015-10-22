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

.global field_init
.global field_empty
.global field_draw
.global field_block_draw

/**
 * merge the block with field.
 * params:
 *  (field_t*) field -- the field for merging
 *  (block_t*) block -- the block for merging
 */
field_block_merge:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, field_empty_1, jne
  assert $0, %rsi, field_empty_2, jne

  # init block_points
  subq $8*BLOCK_POINTS, %rsp

  pushq %r15
  pushq %r14
 
  movq %rdi, %r15 # field
  movq %rsi, %r14 # block

  # rdi is already at the correct value: &field->screen
  lea -8*BLOCK_POINTS(%rbp), %rsi
  movq %r14, %rdx
  call block_to_points

  movq $0, %r11 # init counter

  movq $1, %rcx

  # norm is complement of block->dealloc
  subl SIZE_OF_BLOCK_T-4(%r14), %ecx # norm = 1 - block->dealloc
1: # while counter < BLOCK_POINTS
  lea -8*BLOCK_POINTS(%rbp, %r11, 8), %r10 # &block_point[counter]

  movq $0, %r8
  movq $0, %r9

  movl (%r10), %r9d  # x
  movl 4(%r10), %r8d # y

  movq $0, %rdx
  movq $FIELD_SIZE_X, %rax
  mul %r8
  addq %r9, %rax # rax = x + y*FIELD_SIZE_X

  # field->field
  movl %ecx, SIZE_OF_SCREEN_T(%r15, %rax, 4)

  incq %r11
  cmpq $BLOCK_POINTS, %r11
  jl 1b
# end loop

  movq %rbp, %rsp
  popq %rbp

  ret

/**
 * params:
 *  (field_t*) field -- the field
 *  (block_t*) block -- the block to draw
 */
field_block_draw:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, field_empty_1, jne
  assert $0, %rsi, field_empty_2, jne

  # init block_points
  subq $8*BLOCK_POINTS, %rsp

  pushq %r15
  pushq %r14
 
  movq %rdi, %r15 # field
  movq %rsi, %r14 # block

  # rdi is already at the correct value: &field->screen
  lea -8*BLOCK_POINTS(%rbp), %rsi
  movq %r14, %rdx
  call block_to_points

  movq $0, %r11 # init counter
1: # while counter < BLOCK_POINTS
  lea -8*BLOCK_POINTS(%rbp, %r11, 8), %r10 # &block_point[counter]

  movq $0, %r8
  movq $0, %r9

  movl (%r10), %r9d  # x
  movl 4(%r10), %r8d # y

  movq $0, %rdx
  movq $FIELD_SIZE_X, %rax
  mul %r8
  addq %r9, %rax # rax = x + y*FIELD_SIZE_X

  # field->field
  cmpl $0, SIZE_OF_SCREEN_T(%r15, %rax, 4)
  movq $0x27, %rcx
  je 2f # if field empty

  movq $0xC7, %rcx
2: # skip modifying color

  cmpl $0, SIZE_OF_BLOCK_T-4(%r14) # block->dealloc
  movq $'#', %rdx
  je 3f # if deallocation block

  movq $'-', %rdx
3: # skip modifying character

  movq $0, %rdi
  movq $0, %rsi

  movl (%r15), %edi
  movl 4(%r15), %esi

  addl (%r10), %edi
  addl 4(%r10), %esi

  # putChar(screen->first.x + tmp->x, screen->first.y + tmp->y, character, color)
  call putChar

  incq %r11
  cmpq $BLOCK_POINTS, %r11
  jl 1b
# end loop

  movq %rbp, %rsp
  popq %rbp

  ret

/**
 * Draw field on screen
 * params:
 *  (field_t*) field
 */
field_draw:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, field_draw_1, jne

  pushq %r15
  pushq %r14
  pushq %r13
  pushq %r12
  pushq %rbx

  movq %rdi, %r15
  movl (%rdi), %r14d  # screen.first.x
  movl 4(%rdi), %r13d # screen.first.y
  movl 8(%rdi), %r12d # screen.last.x
  movl 12(%rdi), %ebx # screen.last.y

  decq %r14 # first.x -1
  decq %r13 # first.y -1
1: # while counter > last.x
  cmpq %r12, %r14
  jg 2f

  # upper border
  movq %r14, %rdi # x
  movq %r13, %rsi # first.y
  movq $'+', %rdx
  movq $0x7F, %rcx
  call putChar

  # lower border
  movq %r14, %rdi # x
  movq %rbx, %rsi # last.y
  movq $'+', %rdx
  movq $0x7F, %rcx
  call putChar

  incq %r14
  jmp 1b

2: # end loop
  # restore first.x 
  movl (%r15), %r14d  # screen.first.x 
  decq %r14 # first.x -1

3: # while counter > last.y
  cmpq %rbx, %r13
  jg 4f

  # left border
  movq %r14, %rdi # first.x
  movq %r13, %rsi # y
  movq $'+', %rdx
  movq $0x7F, %rcx
  call putChar

  # right border
  movq %r12, %rdi # last.x
  movq %r13, %rsi # y
  movq $'+', %rdx
  movq $0x7F, %rcx
  call putChar
 
  incq %r13
  jmp 3b
4: # end loop
  # restore screen.first.y
  movl 4(%r15), %r13d # screen.first.y
  incq %r14 # screen.first.x

  # last.x and last.y no longer has any use
  movq $0, %r12 # y
5: # while counter_y < FIELD_SIZE_Y
  cmpq $FIELD_SIZE_Y, %r12
  jnl 8f

  movq $0, %rbx # init counter_x
6: # inner while counter_x < FIELD_SIZE_X
  cmpq $FIELD_SIZE_X, %rbx
  jnl 7f

  movq $FIELD_SIZE_X, %rax
  mul %r12

  lea (%rax, %rbx), %r11
  cmpl $0, SIZE_OF_SCREEN_T(%r15, %r11, 4)
  je 10f # skip putChar

  # get actual coordinates on screen
  lea (%r14, %rbx), %rdi # field->screen.first.x + x
  lea (%r13, %r12), %rsi # field->screen.first.y + y
  movq $'#', %rdx
  movq $0x07, %rcx
  call putChar
  
10: # skip putChar
  incq %rbx
  jmp 6b
7: # end inner loop
  incq %r12
  jmp 5b
8: # end loop
  popq %rbx
  popq %r12
  popq %r13
  popq %r14
  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret


/**
 * Checks wether it is possible to place the block
 * params
 *  (field_t*) field -- the playing field
 *  (block_t*) block -- the block that might overlap some other blocks or exceed bounds
 * returns:
 *    0 on false
 */
field_empty:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, field_empty_1, jne
  assert $0, %rsi, field_empty_2, jne

  # init block_points
  subq $8*BLOCK_POINTS, %rsp

  pushq %r15
  pushq %r14
 
  movq %rdi, %r15 # field
  movq %rsi, %r14 # block

  # rdi is already at the correct value: &field->screen
  lea -8*BLOCK_POINTS(%rbp), %rsi
  movq %r14, %rdx
  call block_to_points

  movq $0, %r11 # init counter
1: # while counter < BLOCK_POINTS
  lea -8*BLOCK_POINTS(%rbp, %r11, 8), %r10 # &block_point[counter]

  movq $0, %r8
  movq $0, %r9

  movl (%r10), %r9d  # x
  movl 4(%r10), %r8d # y

  movq $0, %rdx
  movq $FIELD_SIZE_X, %rax
  mul %r8
  addq %r9, %rax # rax = x + y*FIELD_SIZE_X

  # field->field
  cmpl $0, SIZE_OF_SCREEN_T(%r15, %rax, 4)
  jne 8f # if field not empty

  incq %r11
  cmpq $BLOCK_POINTS, %r11
  jl 1b
# end loop

# return true
  movq $1, %rax # not false
9: # return
  popq %r14
  popq %r15

  movq %rbp, %rsp
  popq %rbp  

  ret

8: # return false
  movq $0, %rax
  jmp 9f



/**
 * initializes a field.
 * params:
 *  (field_t*) field -- the field to init
 *  (int32_t) x -- x-origin
 *  (int32_t) y -- y-origin
 *  (int32_t) wdith
 *  (int32_t) height
 */
field_init:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, field_init_1, jne
  assert $0, %rsi, field_init_2, jge
  assert $0, %rdx, field_init_3, jge

  lea FIELD_SIZE_X(%rsi), %r11 # x + FIELD_SIZE_X
  lea FIELD_SIZE_Y(%rdx), %r10 # x + FIELD_SIZE_Y

  assert $SCREEN_SIZE_X, %r11, field_init_4, jle
  assert $SCREEN_SIZE_Y, %r10, field_init_5, jle

  pushq %r15
  movq %rdi, %r15

  # initialize the screen of the field
  # rdi is already at the correct value: &field->screen
  incq %rsi
  incq %rdx
  movq $FIELD_SIZE_X-1, %rcx
  movq $FIELD_SIZE_Y-1, %r8
  call screen_init

  # nullify the entire field
  # field->field
  lea SIZE_OF_SCREEN_T(%r15), %rdi
  movq $0, %rsi
  movq $SIZE_OF_FIELD_T-SIZE_OF_SCREEN_T, %rdx # sizeof(field->field)
  call fill

  popq %r15
  
  movq %rbp, %rsp
  popq %rbp  

  ret
