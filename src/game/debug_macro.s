.att_syntax

.ifndef GAME_DEBUG_H

.set SCREEN_SIZE_X, 80
.set SCREEN_SIZE_Y, 25

.set BLOCK_QUEUE_SIZE, 4

.set SIZE_OF_BLOCK_T, 52

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
