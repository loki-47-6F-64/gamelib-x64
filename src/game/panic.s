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

.global panic
.global print_snapshot

.data
# each reg-name occupies 4 bytes
regs:
  .string "rax"
  .string "rbx"
  .string "rcx"
  .string "rdx"
  .string "rsi"
  .string "rdi"
  .string "rbp"
  .string "rsp"
  .string "r8 "
  .string "r9 "
  .string "r10"
  .string "r11"
  .string "r12"
  .string "r13"
  .string "r14"
  .string "r15"
.text

# (snapshot_t*) snapshot
print_snapshot:
  pushq %rbp
  movq %rsp, %rbp

  subq $SIZE_OF_SCREEN_T*4, %rsp

  pushq %r15
  pushq %r14

  movq %rdi, %r15

  movq $0, %rdi # default screen
  movq $0x90, %rsi
  call screen_clear

.data
message_f:
  .ascii  "%cThis is a snapshot of the game. %n"
  .ascii  "The game send the following message:%n"
  .string "%s"
.text
  movq $0, %rdi # default screen
  movq $message_f, %rsi
  movq $0x9F, %rdx
  movq SIZE_OF_SNAPSHOT_T-8(%r15), %rcx
  call writef

/* Initialize all four screens */

  lea -SIZE_OF_SCREEN_T(%rbp), %rdi
  movq $2, %rsi
  movq $8, %rdx
  movq $24, %rcx
  movq $17, %r8
  call screen_init

  lea -SIZE_OF_SCREEN_T*2(%rbp), %rdi
  movq $29, %rsi
  movq $8, %rdx
  movq $50, %rcx
  movq $1, %r8
  call screen_init
 
  lea -SIZE_OF_SCREEN_T*3(%rbp), %rdi
  movq $29, %rsi
  movq $9, %rdx
  movq $4, %rcx
  movq $16, %r8
  call screen_init

  lea -SIZE_OF_SCREEN_T*4(%rbp), %rdi
  movq $33, %rsi
  movq $9, %rdx
  movq $46, %rcx
  movq $16, %r8
  call screen_init

/* End initialization of the screens */

/* clear all four screens */

  lea -SIZE_OF_SCREEN_T(%rbp), %rdi
  movq $0x10, %rsi
  call screen_clear

  lea -SIZE_OF_SCREEN_T*2(%rbp), %rdi
  movq $0x10, %rsi
  call screen_clear

  lea -SIZE_OF_SCREEN_T*3(%rbp), %rdi
  movq $0x10, %rsi
  call screen_clear

  lea -SIZE_OF_SCREEN_T*4(%rbp), %rdi
  movq $0x10, %rsi
  call screen_clear

/* End clear all four screens */

.data
regs_head_f:
  .string "%cThe registers:%n"
regs_f:
  .string "%c%s | 0x%h"
.text

  lea -SIZE_OF_SCREEN_T(%rbp), %rdi
  movq $regs_head_f, %rsi
  movq $0x1F, %rdx
  call writef

  # 16 is the number of registers
  movq $0, %r14 # counter
1: # while counter < number of registers
  lea -SIZE_OF_SCREEN_T(%rbp), %rdi
  movq $regs_f, %rsi
  movq $0x1F, %rdx
  lea regs(,%r14, 4), %rcx
  movq (%r15, %r14, 8), %r8
  call writef

  incq %r14
  # 16 is the number of registers
  cmpq $16, %r14
  jl 1b
# end loop

.data
stack_head_f:
  .string "%cThe stack | (Hex and Integer)"
stack_addr_f:
  .string "%c%u%n"
stack_hex_f:
  .string "%c | 0x%h | %u%n"
.text
  
  lea -SIZE_OF_SCREEN_T*2(%rbp), %rdi
  movq $stack_head_f, %rsi
  movq $0x1F, %rdx
  call writef

  movq $0, %r14
2: # while counter < 16
  lea -SIZE_OF_SCREEN_T*3(%rbp), %rdi
  movq $stack_addr_f, %rsi
  movq $0x1F, %rdx
  lea (,%r14,8), %rcx
  call writef

  lea -SIZE_OF_SCREEN_T*4(%rbp), %rdi
  movq $stack_hex_f, %rsi
  movq $0x1F, %rdx
  movq SIZE_OF_SNAPSHOT_T(%r15, %r14, 8), %rcx
  movq SIZE_OF_SNAPSHOT_T(%r15, %r14, 8), %r8
  call writef

  incq %r14

  cmpq $16, %r14
  jl 2b
# end loop
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
