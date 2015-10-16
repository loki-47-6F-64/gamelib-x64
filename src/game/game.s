/*
This file is part of gamelib-x64.

Copyright (C) 2014 Tim Hegeman

gamelib-x64 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

gamelib-x64 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with gamelib-x64. If not, see <http://www.gnu.org/licenses/>.
*/


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

.file "src/game/game.s"

.include "src/game/debug_macro.s"

.global gameInit
.global gameLoop
.global write
.global wait_for_debugger
.global game_block_reset
.global game_next

.global panic

.section .data

.section .text

/*
  Simple infinite loop
  The debugger should nop the instructions
*/
wait_for_debugger:
  hlt
  jmp wait_for_debugger
  ret

gameInit:
  pushq %rbp
  movq %rsp, %rbp

  call c_init

  movq %rbp, %rsp
  popq %rbp

  ret

gameLoop:
  jmp c_loop

/**
 * writes data to the screen
 * params:
 *  (screen_t*) screen -- the screen to write on. Could be NULL
 *  (void*) in -- a pointer to the data to be written
 *  (uint64_t) count -- the amount if bytes in the buffer
 *  (int8_t) color
 */
write:
  pushq %rbp
  movq %rsp, %rbp

  pushq %r15
  pushq %r14
  pushq %r13
  pushq %r12
  pushq %rbx

  cmpq $0, %rdi
  jne 1f # omit default screen

  # default screen
  movq $scr_full, %rdi
1:

  movq %rdi, %r15 # screen
  movq %rsi, %r14 # in
  movq %rdx, %r13 # count
  movq %rcx, %r12 # color

2: # while count > 0
  cmpq $0, %r13 
  jng 3f # break if count <= 0

  movq %r15, %rdi
  call screen_x
  movq %rax, %rbx # tmp store x-coordinate

  movq %r15, %rdi
  call screen_y

  movq %rbx, %rdi # x-coordinate
  movq %rax, %rsi # y-coordiante
  movzb (%r14), %rdx # *in
  movq %r12, %rcx # color
  call putChar

  movq %r15, %rdi
  call cursor_inc

  inc %r14 # next *in
  dec %r13 # next iteration

  jmp 2b
3: # end loop

  popq %rbx
  popq %r12
  popq %r13
  popq %r14
  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret

/**
 * Handles the drawing part of the game
 * params:
 *  (game_t*) game -- the game to draw
 */
game_draw:

/**
 * A block has been placed, it is time for a new block.
 * Oh... and the timer needs to be reset, I guess..
 * params:
 *  (game_t*) game
 */
game_next:
  pushq %rbp
  movq %rsp, %rbp

  assert $0, %rdi, game_draw_1, jne

  pushq %r15
  pushq %r14

  movq %rdi, %r15 # game
  movq (%rdi), %r14 # game->player
  
  # rdi already contains correct value
  call game_block_reset

  movq %r14, %rdi # game->player
  call block_next # place pseudo-random block in queue

  addq $SIZE_OF_BLOCK_T, %r14 # player = next block

  # game->queue + BLOCK_QUEUE_SIZE
  lea (SIZE_OF_BLOCK_T*BLOCK_QUEUE_SIZE)+8(%r15), %r11
  cmpq %r11, %r14
  jb 1f

  lea 8(%r15), %r14 # game->player = start of queue

1: # proper value for game->player
  movq %r14, (%r15) # store new game->player
  
  # reset timer
  movq $6*TICKS_PER_SEC, SIZE_OF_GAME_T-16(%r15)

  popq %r14
  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret

/**
 * reset the origin of all blocks in the queue
 * params:
 *  (game_t*) game
 */
game_block_reset:
  pushq %rbp
  movq %rsp, %rbp

  movq $0, %r11 # init counter

  # r10 = block_t*
  lea 8(%rdi), %r10 # game_t->queue

1: # while x < BLOCK_QUEUE_SIZE
  cmpq $BLOCK_QUEUE_SIZE, %r11
  jnl 2f

  movq $0, 40(%r10) # init flags (mirror and rotate)

  lea (,%r11,4), %r9 # r9 = counter *4

  movl $0, (%r10)
  movl %r9d, 4(%r10) # block_t->origin = { 0, counter*4 }

  addq $SIZE_OF_BLOCK_T, %r10
  inc %r11

  jmp 1b # next iteration
2: # end loop

  movq %rbp, %rsp
  popq %rbp

  ret

/*
  Something unrecoverable happened
  We must print as much as possible on the screen before halting
*/
panic:
  pushq %r15
  pushq %r14
  pushq %r13
  pushq %r12
  pushq %r11
  pushq %r10
  pushq %r9
  pushq %r8

  # push rsp with original value
  movq %rsp, %r15
  addq $64, %r15
  pushq %r15

  pushq %rbp
  pushq %rdi
  pushq %rsi
  pushq %rdx
  pushq %rcx
  pushq %rbx
  pushq %rax

  movq %rsp, %rdi
  call print_snapshot
panic_hlt:
  hlt
  jmp panic_hlt
