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

.global block_rotate
.global block_mov
.global block_next

/**
 * puts random positions in the block
 * params:
 *  (block_t*) block -- the block that get initialized
 */
block_next:
  pushq %rbp
  movq %rsp, %rbp

  pushq %r15

  assert $0, %rdi, block_next_1, jne

  movq %rdi, %r15
  # block->dealloc might be non-zero, make sure it's 0
  movl $0, SIZE_OF_BLOCK_T-8(%r15)

  # get next random value and put it in rax
  call rand_next
  movq $0, %rdx

  movq $4, %r10
  div %r10

  movq block_next_switch(,%rdx,8), %r10

  call *%r10
.data # make sure it doesn't get mixed with instructions
block_next_switch:
  .quad block_square
  .quad block_pole
  .quad block_hook
  .quad block_stage
.text
  
  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret

/**
 * params:
 *  (block_t*) block -- the block to move
 *  (int32_t) x -- how much movement along x-axis
 *  (int32_t) y -- how much movement along y-axis
 */
block_mov:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, block_mov_1, jne

  addl %esi, (%rdi)  # origin.x + x
  addl %edx, 4(%rdi) # origin + y

  movq %rbp, %rsp
  popq %rbp

  ret

/**
 * (logically) rotates the block.
 * params:
 *  (block_t*) block -- the block to rotate
 */
block_rotate:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, block_rotate_1, jne

  cmpl $0, 8*BLOCK_POINTS+12(%rdi)
  je 1f # if block->rotate == 0


  # block->rotate = 0
  movl $0, 8*BLOCK_POINTS+12(%rdi)

  # block->mirror = 1 - block->mirror
  movq $1, %r10
  subl 8*BLOCK_POINTS+8(%rdi), %r10d
  movl %r10d, 8*BLOCK_POINTS+8(%rdi)

  jmp 2f
1: # else

  # block->rotate = 1
  movl $1, 8*BLOCK_POINTS+12(%rdi)
2: # endif

  movq %rbp, %rsp
  popq %rbp

  ret
