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
