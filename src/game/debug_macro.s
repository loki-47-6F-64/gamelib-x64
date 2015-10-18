.att_syntax

.ifndef GAME_DEBUG_H

.set TICKS_PER_SEC, 60 # Hz

.set KEY_CODE_W, 0x11 
.set KEY_CODE_S, 0x1F
.set KEY_CODE_A, 0x1E
.set KEY_CODE_D, 0x20

.set KEY_CODE_1, 2
.set KEY_CODE_2, 3
.set KEY_CODE_3, 4

.set KEY_CODE_ENT, 0x1C

.set KEY_CODE_AU, 72
.set KEY_CODE_AD, 80
.set KEY_CODE_AL, 75
.set KEY_CODE_AR, 77


.set BLOCK_POINTS, 4

.set SCREEN_SIZE_X, 80
.set SCREEN_SIZE_Y, 25

.set FIELD_SIZE_X, 12
.set FIELD_SIZE_Y, 12

.set BLOCK_QUEUE_SIZE, 4
.set SCORE_SIZE, 10

.set STATE_MENU, 0
.set STATE_GAME, 1
.set STATE_HIGHSCORE, 2
.set STATE_NEW_HIGHSCORE, 3

.set SIZE_OF_GAME_T, 856
.set SIZE_OF_BLOCK_T, 52
.set SIZE_OF_FIELD_T, 600
.set SIZE_OF_SCORE_T, 12
.set SIZE_OF_SCREEN_T, 24
.set SIZE_OF_SNAPSHOT_T, 17*8

.set GAME_DEBUG_H, $1

  .if NDEBUG == 1
    .macro assert op1, op2, assert_message, jmp_on=je
      cmp \op1, \op2
      \jmp_on 2f
      pushq $1f
      jmp panic

      .data
      # This does not get inserted inside the code, instead it will be read
      # Thus disassembling the subroutine doesn't result in bogus data
      1: .string "\assert_message" # \assert_message
      .text
    2:
    .endm
  
  .else
    .macro assert op1, op2, assert_message jmp_on=je
    .endm
  .endif
.endif
