# abi x764 linux :: http://www.x86-64.org/documentation/abi.pdf
# Registers %rbp, %rbx, %r12 through %r15 belong to the caller
# These registers must be restored before returning
#
#
# The stack grows downwards from high addresses


# At the entry of a function, (%rsp + 8) is a multiple of 16

# args passing :: INTEGER
#   0 .. 5
#    rdi, rsi, rdx, rcx, r8d, r9d
#   n .. 6
#      push{l,q}

.att_syntax


.text

.global writef
# This MUST only be called from writef
# return:
#   the next arg from the stack
writef_next_arg:
  # There are 4 args put on the stack after the args.
  # Every value takes 8-bytes.
  movq 40(%rbp, %r13, 8), %rax
  inc %r13

  /*
    The 4th 'parameter' is actually the return address to the caller of 'writef'.
    This should be skipped for obvious reasons
  */
  cmp $4, %r13
  je writef_next_arg_if

  ret

writef_next_arg_if:
  inc %r13 # skip the 4th 'parameter'
  ret

# This MUST only be called from writef
# params:
#   0. (char) arg
writef_switch:
  cmpb $'d', %dil
  je writef_case_d

  cmpb $'u', %dil
  je writef_case_u

  cmpb $'h', %dil
  je writef_case_h

  cmpb $'s', %dil
  je writef_case_s

  cmpb $'%', %dil
  je writef_case_modulo

# writef_switch_default:
  movb $'%', (%r14)
  inc %r14 # *container++ = '%'

  movb (%r15), %r11b
  movb %r11b, (%r14) # *container = *format
  inc %r14

  ret

writef_case_d:
  call writef_next_arg

  movq %r14, %rdi
  movq %rax, %rsi
  call int_to_string
  addq %rax, %r14 # 'container_p' += int_to_string('container_p', 'arg')

  ret

writef_case_u:
  call writef_next_arg

  movq %r14, %rdi
  movq %rax, %rsi
  call uint_to_string
  addq %rax, %r14 # 'container_p' += uint_to_string('container_p', 'arg')

  ret

writef_case_h:
  call writef_next_arg

  movq %r14, %rdi
  movq %rax, %rsi
  call uint_to_hex
  addq %rax, %r14 # 'container_p' += uint_to_hex('container_p', 'arg')

  ret

writef_case_s:
  call writef_next_arg

  movq %r14, %rdi
  movq %rax, %rsi
  call strcpy
  addq %rax, %r14 # 'container_p' += strcpy('container_p', 'arg')

  ret

writef_case_modulo:
  movb $'%', (%r14)
  inc %r14 # *container++ = '%'

  ret

# prints a formatted string.
# %h (uint64_t) hex
# %d (int64_t)
# %u (uint64_t)
# %s (c-string)
# %% (print '%')

# params:
#   0. screen_t* (full screen is used if it is NULL)
#   1. char* (formatted string)
#   2 .. n any args required
writef:
  # Save all potential args to the stack
  pushq %r9
  pushq %r8
  pushq %rcx
  pushq %rdx

  pushq %r15 # 'format'
  pushq %r14 # 'container_p'
  pushq %r13 # the amount of args read
  pushq %r12 # storing the address to the screen

  pushq %rbp
  movq %rsp, %rbp
  sub $1024, %rsp # char container[1024]

  movq %rdi, %r12 # save 'screen_t*'
  movq %rsi, %r15 # save 'format'
  movq %rsp, %r14 # 'container_p' = 'container'
  movq $0, %r13 # the amount of args read is zero

writef_loop:
  cmpb $0, (%r15)
  je writef_loop_break # break if (!*format)

  cmpb $'%', (%r15)
  jne writef_else

# writef_if:
  inc %r15
  movb (%r15), %dil 
  call writef_switch # switch(*(++'format'))

  jmp writef_endif

writef_else:
  movb (%r15), %r11b
  movb %r11b, (%r14) # *container = *format
  inc %r14

writef_endif:
  inc %r15 # ++'format;
  
  jmp writef_loop
writef_loop_break:

  movb $0, (%r14) # Make sure 'container' is null-terminated

  movq %rsp, %rdi # first char in 'container' is at the address in the stack pointer
  call strlen

  movq $0x07, %rcx
  movq %rax, %rdx
  movq %rsp, %rsi # first char in 'container' is at the address in the stack pointer
  movq %r12, %rdi

  call write # write(screen_t*, container, strlen(container))

  # retore stack
  movq %rbp, %rsp
  popq %rbp

  popq %r12
  popq %r13
  popq %r14
  popq %r15

  add $32, %rsp # 8*5
  ret
