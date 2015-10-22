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

.data

seed: .quad 973

.text

.global rand_next

rand_next:
  pushq %rbp
  movq %rsp, %rbp

  # wiki https://en.wikipedia.org/wiki/Linear_congruential_generator
  # X<n+1> = (aX<n> + c) mod m
  # 0 <= X<0> < m
  # m and c are relatively prime
  # a - 1 is divisible by all primefactors of m
  # a - 1 is divisible by 4 if m is divisible by 4

  movq seed, %rax
  movq $1103515245, %r11 # a
  movq $12345, %r10      # c
  movq $(1<<31), %r9     # m

  # seed = (a*seed + c) % m
  mul %r11
  addq %r10, %rax

  movq $0, %rdx  
  div %r9

  movq %rdx, %rax
  movq %rdx, seed

  movq $0, %rdx
  movq $3, %r11
  div %r11 # return seed / 3

  movq %rbp, %rsp
  popq %rbp

  ret
