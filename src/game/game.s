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
