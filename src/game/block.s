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
.global block_to_points
.global block_draw
.global block_square
.global block_pole
.global block_hook
.global block_stage

# (block_t*) block
block_square:
  pushq %rbp
  movq %rsp, %rbp

  lea 8(%rdi), %r11

  movl $1, (%r11)
  movl $1, 4(%r11)
  movl $2, 8(%r11)
  movl $2, 12(%r11)
  movl $1, 16(%r11)
  movl $2, 20(%r11)
  movl $2, 24(%r11)
  movl $1, 28(%r11)

  movq %rbp, %rsp
  popq %rbp

  ret

block_pole:
  pushq %rbp
  movq %rsp, %rbp

  lea 8(%rdi), %r11

  movl $1, (%r11)
  movl $0, 4(%r11)
  movl $1, 8(%r11)
  movl $1, 12(%r11)
  movl $1, 16(%r11)
  movl $2, 20(%r11)
  movl $1, 24(%r11)
  movl $3, 28(%r11)

  movq %rbp, %rsp
  popq %rbp

  ret

block_hook:
  pushq %rbp
  movq %rsp, %rbp

  lea 8(%rdi), %r11

  movl $0, (%r11)
  movl $1, 4(%r11)
  movl $1, 8(%r11)
  movl $1, 12(%r11)
  movl $1, 16(%r11)
  movl $0, 20(%r11)
  movl $2, 24(%r11)
  movl $0, 28(%r11)

  movq %rbp, %rsp
  popq %rbp

  ret

block_stage:
  pushq %rbp
  movq %rsp, %rbp

  lea 8(%rdi), %r11

  movl $3, (%r11)
  movl $3, 4(%r11)
  movl $2, 8(%r11)
  movl $3, 12(%r11)
  movl $1, 16(%r11)
  movl $3, 20(%r11)
  movl $2, 24(%r11)
  movl $2, 28(%r11)

  movq %rbp, %rsp
  popq %rbp

  ret

/**
 * params:
 *  (screen_t*) screen -- the block to draw
 *  (block_t*) block -- the screen to draw on
 */
block_draw:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, block_draw_1, jne
  assert $0, %rsi, block_draw_2, jne

  subq $8*BLOCK_POINTS, %rsp # init block_point

  pushq %r15
  pushq %r14
  pushq %r13

  movq %rdi, %r15 # screen
  movq %rsi, %r14 # block
  movq $0, %r13 # init counter

  movq %r15, %rdi # screen
  lea -8*BLOCK_POINTS(%rbp), %rsi
  movq %r14, %rdx # block
  call block_to_points


1: # while counter < BLOCK_POITS
  lea -8*BLOCK_POINTS(%rbp, %r13, 8), %r11 # &block_point[x]

  cmpq $0, SIZE_OF_BLOCK_T-8(%r14)
  movq $'#', %rdx
  je 2f

  movq $'-', %rdx
2: # endif

  movq $0x07, %rcx # color

  
  movq $0, %rdi
  movq $0, %rsi
  movl (%r15), %edi   # screen->first.x
  movl 4(%r15), %esi  # screen->first.y
  addl (%r11), %edi  # x += tmp->x
  addl 4(%r11), %esi # y += tmp->y

  call putChar

  inc %r13 # next iteration
  cmpq $BLOCK_POINTS, %r13
  jl 1b

# end loop
  popq %r13
  popq %r14
  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret

/**
 * Convert points in block to real points
 * params:
 *  (screen_t*) screen -- the screen the block is in
 *  (point_t*) in -- the points to put the result in, it should always be an array of four elements
 *  (block_t*) out -- the block
 */
block_to_points:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, block_to_points_1, jne
  assert $0, %rsi, block_to_points_2, jne
  assert $0, %rdx, block_to_points_3, jne

  pushq %r15
  pushq %r14
  pushq %r13
  pushq %r12

  movq %rdi, %r15 # scree
  movq %rsi, %r14 # in
  movq %rdx, %r13 # out

  movq $0, %r12 # counter
1: # while counter < BLOCK_POINTS  movq $0, 
  cmpl $0, SIZE_OF_BLOCK_T-8(%r13)
  je 2f

  # With rotation y-axis becomes x-axis and
  # the x-axis becomes the mirror of the y-axis
  movl 8(%r13, %r12, 8), %r10d # out->point[counter].x
  movl 12(%r13, %r12, 8), %r9d # out->point[counter].y

  movq $BLOCK_POINTS-1, %r8 # max
  subl %r9d, %r8d # max - y = the mirror of y
  movl %r8d, (%r14, %r12, 8) # point->x = y

  movl %r10d, 4(%r14, %r12, 8) # point->y = x

  jmp 3f
2: # else
  movl 8(%r13, %r12, 8), %r10d # out->point[counter].x
  movl 12(%r13, %r12, 8), %r9d # out->point[counter].y

  movl %r10d, (%r14, %r12, 8) # point->x = x
  movl %r9d, 4(%r14, %r12, 8) # point->y = y
3: # endif
  cmpl $0, SIZE_OF_BLOCK_T-12(%r13)
  je 4f
  
  # A second rotation inverts x-axis and y-axis again,
  # but it's mirrored relative to the original
  movl (%r14, %r12, 8), %r10d # point[counter].x
  movl 4(%r14, %r12, 8), %r9d # point[counter].y

  movq $BLOCK_POINTS-1, %r8 # max
  subl %r10d, %r8d # max - x = the mirror of x
  movl %r8d, (%r14, %r12, 8) # point->x = x

  movq $BLOCK_POINTS-1, %r8 # max
  subl %r9d, %r8d # max - y = the mirror of y
  movl %r8d, 4(%r14, %r12, 8) # point->y = y

  
4: # endif
  # Make sure the point is at the corret position
  movl (%r13), %r10d # origin->x
  movl 4(%r13), %r9d # origin->y

  addl %r10d, (%r14, %r12, 8) # point->x += x
  addl %r9d, 4(%r14, %r12, 8) # point->y += y

  # Normalize the result to the screen
  movq %r15, %rdi
  lea (%r14, %r12, 8), %rsi
  call normalize

  inc %r12 # next iteration

  cmpq $BLOCK_POINTS, %r12
  jl 1b

  popq %r12
  popq %r13
  popq %r14
  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret

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
  pushq %rdi
  call rand_next
  popq %rdi

  movq $0, %rdx
  movq $20, %r10
  div %r10

  # not a deallocation block by default
  movl $0, SIZE_OF_BLOCK_T-4(%rdi)
  cmpq $16, %rdx
  jle 1f # no deallocation block

  # the block is a deallocation block
  movl $1, SIZE_OF_BLOCK_T-4(%rdi)

1:
  movq $4, %r10
  movq %rdx, %rax
  incq %rax

  movq $0, %rdx
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
