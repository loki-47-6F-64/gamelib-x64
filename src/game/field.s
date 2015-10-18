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
