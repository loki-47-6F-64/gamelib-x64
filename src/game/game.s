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
.global game_draw
.global game_init
.global menu_init
.global new_highscore_init
.global highscore_init
.global game_loop
.global new_highscore

.global game_state

.global panic

.section .data

new_highscore: .skip 16
score: .skip SIZE_OF_SCORE_T*SCORE_SIZE
game: .skip SIZE_OF_GAME_T
game_state: .skip 8

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

  movq $19886, %rdi # 60Hz
  call setTimer

  movq $scr_full, %rdi
  movq $0, %rsi # x
  movq $0, %rdx # y
  movq $SCREEN_SIZE_X, %rcx # width
  movq $SCREEN_SIZE_Y, %r8 # height
  call screen_init

  movq $0, %rdi # default screen
  movq $0, %rsi # color black
  call screen_clear

  call menu_init
  
  movq %rbp, %rsp
  popq %rbp

  ret

gameLoop:
  jmp c_loop

game_loop:
  pushq %rbp
  movq %rsp, %rbp

  # init screen for info
  subq $SIZE_OF_SCREEN_T, %rsp
  movq %rsp, %rdi
  movq $0, %rsi
  movq $0, %rdx
  movq $SCREEN_SIZE_X, %rcx
  movq $2, %r8
  call screen_init

  call readKeyCode

  # --game.timer
  decq game+SIZE_OF_GAME_T-16

  cmpq $0, %rax
  je 8f # skip switch if no key found

  pushq %rax # save keycode temporarely
  movq $0, %rdi # default screen
  movq $0, %rsi # color black
  call screen_clear
  popq %rax

  cmpq $KEY_CODE_AU, %rax
  je 1f

  cmpq $KEY_CODE_AD, %rax
  je 2f

  cmpq $KEY_CODE_AL, %rax
  je 3f

  cmpq $KEY_CODE_AR, %rax
  je 4f

  cmpq $KEY_CODE_S, %rax
  je 5f

  cmpq $KEY_CODE_ENT, %rax
  je 6f

  jmp 7f
1: # KEY_CODE_AU
  movq game, %rdi # game.player
  movq $0, %rsi
  movq $-1, %rdx
  call block_mov

  jmp 7f
2: # KEY_CODE_AD
  movq game, %rdi # game.player
  movq $0, %rsi
  movq $1, %rdx
  call block_mov

  jmp 7f
3: # KEY_CODE_AL
  movq game, %rdi # game.player
  movq $-1, %rsi
  movq $0, %rdx
  call block_mov

  jmp 7f
4: # KEY_CODE_AR
  movq game, %rdi # game.player
  movq $1, %rsi
  movq $0, %rdx
  call block_mov

  jmp 7f
5: # KEY_CODE_S
  movq game, %rdi # game.player
  call block_rotate

  jmp 7f
6: # KEY_CODE_ENT

  # When the player is a deallocation block, the field doesn't need to be empty
  movq game, %r11 # game.player
  cmpl $0, SIZE_OF_BLOCK_T-4(%r11)
  jne 11f # skip next compare

  # make sure field is empty before proceding
  movq $GAME_FIELD+game, %rdi
  movq %r11, %rsi
  call field_empty

  cmpq $0, %rax
  je 7f
11:
  # ++game.score
  incq game+SIZE_OF_GAME_T-8

  movq $GAME_FIELD+game, %rdi
  movq game, %rsi # game.player
  call field_block_merge

  movq $game, %rdi
  call game_next
7: # end switch

  movq $game, %rdi
  call game_draw
8: # skip switch

  # if timer == 0, goto new highscore screen
  cmpq $0, SIZE_OF_GAME_T-16+game
  jne 9f

  # game.score
  movq game+SIZE_OF_GAME_T-8, %rdi
  call new_highscore_init

  jmp 10f # return
9: # endif
.data
game_loop_f:
  .ascii  "time left: %c%u%c seconds!%n"
  .string "your current score: %c%u"
.text

  # game.timer / TICKS_PER_SEC +1
  movq $0, %rdx
  movq game+SIZE_OF_GAME_T-16, %rax
  movq $TICKS_PER_SEC, %r11
  div %r11
  inc %rax

  movq %rsp, %rdi # info screen
  movq $game_loop_f, %rsi # format string
  movq $0xCF, %rdx # color
  movq %rax, %rcx # game.timer / TICKS_PER_SEC +1
  movq $0x07, %r8 # color
  movq $0x2F, %r9 # color
  pushq game+SIZE_OF_GAME_T-8 # game.score
  call writef

10: # return
  movq %rbp, %rsp
  popq %rbp

  ret

# initialize the menu
menu_init:
  pushq %rbp
  movq %rsp, %rbp
 
  subq $SIZE_OF_SCREEN_T, %rsp
  movq %rsp, %rdi # screen_t*
  movq $20, %rsi  # x
  movq $5, %rdx   # y
  movq $40, %rcx  # width
  movq $15, %r8   # height
  call screen_init

  movq $0, %rdi
  movq $0x00, %rsi
  call screen_clear

.data
menu_init_f:
  .ascii  "Please select the %capplication%c to run.%n%n%n"
  .ascii  "[1] :: %cGame%c%n%n"
  .string "[2] :: %cHighscore"
.text
  movq %rsp, %rdi
  movq $menu_init_f, %rsi  
  movq $0xCF, %rdx
  movq $0x07, %rcx
  movq $0x4F, %r8
  movq $0x07, %r9
  pushq $0x4F
  call writef

  movq $STATE_MENU, game_state

  movq %rbp, %rsp
  popq %rbp

  ret

# initialize the game
game_init:
  pushq %rbp
  movq %rsp, %rbp
  
  pushq %r15

  movq $game, %rdi
  movq $0, %rsi
  movq $SIZE_OF_GAME_T, %rdx
  call fill # fill(&game, 0, sizeof(game_t)

  movq $game+8, game # game.player = &game.queue[0]
  
  .set GAME_FIELD, SIZE_OF_BLOCK_T*BLOCK_QUEUE_SIZE+8

  # &game.field
  movq $GAME_FIELD+game, %rdi
  movq $10, %rsi
  movq $6, %rdx
  call field_init

# init the screen of the field
  movq $GAME_FIELD+SIZE_OF_FIELD_T+game, %rdi

  # game.field.screen.first.x
  movq $0, %rsi
  movl GAME_FIELD+game, %esi
  lea FIELD_SIZE_X+2(%rsi), %rsi # FIELD_SIZE_X + x + 2

  movq $4, %rdx
  movq $5, %rcx
  movq $BLOCK_POINTS*4+1, %r8
  call screen_init # finally

  movq $game, %rdi
  call game_block_reset

  movq $0, %r15 # init counter

1: # while counter < BLOCK_POINTS

  lea game+8(%r15), %rdi
  call block_next

  addq $SIZE_OF_BLOCK_T, %r15
  cmpq $SIZE_OF_BLOCK_T*BLOCK_POINTS, %r15
  jl 1b # next iteration if counter < BLOCK_POINTS
# end loop

  movq $6*TICKS_PER_SEC, SIZE_OF_GAME_T-16+game
  movq $STATE_GAME, game_state

  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret


# initialize highscore mode
highscore_init:
  pushq %rbp
  movq %rsp, %rbp

  subq $SIZE_OF_SCREEN_T, %rsp
  pushq %r15

  movq $0, %rdi    # default screen_t*
  movq $0x00, %rsi # color
  call screen_clear

  lea -SIZE_OF_SCREEN_T(%rbp), %rdi # screen_t*

  movq $20, %rsi          # x
  movq $5, %rdx           # y
  movq $45, %rcx          # width
  movq $SCORE_SIZE+2, %r8 # height
  call screen_init

.data
hall_of_shame: .string "-- Hall of Shame --%n%n"
score_f: .string "%s | %u%n"
.text
  lea -SIZE_OF_SCREEN_T(%rbp), %rdi # screen_t*
  movq $hall_of_shame, %rsi
  call writef

  movq $0, %r15 # init counter
1: # while counter < SCORE_SIZE
  lea score(%r15), %rdx # score_t*

  movq 4(%rdx), %rcx

  cmpq $0, %rcx
  je 2f # break if score == 0
  
  lea -SIZE_OF_SCREEN_T(%rbp), %rdi # screen_t*
  movq $score_f, %rsi
  call writef

  addq $SIZE_OF_SCORE_T, %r15
  cmpq $SIZE_OF_SCORE_T*SCORE_SIZE, %r15
  jl 1b
2: # end loop
  movq $STATE_HIGHSCORE, game_state

  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret


/**
 * If it fits in the highscore, prepare the new highscore
 * params:
 *  (uint64_t) new_score -- the new highscore
 */
new_highscore_init:
  pushq %rbp
  movq %rsp, %rbp

  # First clear screen
  pushq %rdi
  movq $0, %rdi # screen
  movq $0, %rsi # color black
  call screen_clear
  popq %rdi

  # First, aquire the correct position for the new score
  movq $0, %r11 # init counter
1: # while counter < SCORE_SIZE
  cmpq score+4(%r11), %rdi
  jg 2f # break if new_score > score[counter].score
  
  addq $SIZE_OF_SCORE_T, %r11
  cmpq $SCORE_SIZE*SIZE_OF_SCORE_T, %r11
  jl 1b
2: # end loop
  
  cmpq $SCORE_SIZE*SIZE_OF_SCORE_T, %r11
  jne 3f # don't return yet

  # no new highscore to the highscore
  call highscore_init
  jmp 9f # return
3: # endif
  movq $(SCORE_SIZE-1)*SIZE_OF_SCORE_T, %r10 # init counter_y
4: # while counter_y > counter_x
  cmpq %r11, %r10
  jng 5f

  lea score(%r10), %r9    # score[counter_y]
  lea score-SIZE_OF_SCORE_T(%r10), %r8 # score[counter_y -1]

  # score[counter_y] = score[counter_y -1]
  movl (%r8), %esi # tmp
  movl %esi, (%r9)

  movq 4(%r8), %rsi # tmp
  movq %rsi, 4(%r9)

  subq $SIZE_OF_SCORE_T, %r10
  jmp 4b # next iteration
5: # end loop

  lea score(%r11), %r10 # &score[counter]

  movq $0x00414141, (%r10) # .string "AAA"
  movq %rdi, 4(%r10) # init score[counter]

  movq %r10, new_highscore
  movq %r10, new_highscore+8

  movq $STATE_NEW_HIGHSCORE, game_state
9: # return
  movq %rbp, %rsp
  popq %rbp

  ret


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
  pushq %rbp
  movq %rsp, %rbp

  pushq %r15
  pushq %r14
  pushq %r13

  movq %rdi, %r15   # game
  movq (%rdi), %r14 # game->player
  
  # load &game->field
  lea (SIZE_OF_BLOCK_T*BLOCK_QUEUE_SIZE)+8(%rdi), %rdi
  call field_draw

  # Make sure the background has the proper color
  # load &game->block_screen
  lea (SIZE_OF_BLOCK_T*BLOCK_QUEUE_SIZE)+SIZE_OF_FIELD_T+8(%r15), %rdi
  movq $0x30, %rsi # background color for the screen
  call screen_clear

  movq $0, %r13 # counter
1: # while counter < BLOCK_QUEUE_SIZE
  lea 8(%r15, %r13), %r11
  cmpq %r11, %r14
  je 2f # skip drawing block if it is the player

  # load &game->block_screen
  lea (SIZE_OF_BLOCK_T*BLOCK_QUEUE_SIZE)+SIZE_OF_FIELD_T+8(%r15), %rdi
  lea 8(%r15, %r13), %rsi
  call block_draw

2: # decide next iteration
  addq $SIZE_OF_BLOCK_T, %r13

  cmpq $SIZE_OF_BLOCK_T*BLOCK_QUEUE_SIZE, %r13
  jl 1b
# end loop

  # Finally, we can draw the field
  # load &game->field
  lea (SIZE_OF_BLOCK_T*BLOCK_QUEUE_SIZE)+8(%r15), %rdi
  movq %r14, %rsi # game->player
  call field_block_draw

  popq %r13
  popq %r14
  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret

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
