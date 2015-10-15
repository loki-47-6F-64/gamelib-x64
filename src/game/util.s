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

.global int_to_string
.global uint_to_string
.global reverse
.global fromDigit
.global strlen
.global strcpy

/* convert integer to a string
 *
 * (char*) out -- output for the string
 * (int64_t) in -- input for the string
 *
 * return:
 *  size of generated string
 */
int_to_string:
  # If the integer is greater than 0, than the output is equivelant to uint_to_string
  cmp $0, %rsi
  jge uint_to_string # if('in' >= 0) return uint_to_string('out', 'in')

  pushq %rbp
  movq %rbp, %rsp

  # 'in' is negative
  imul $-1, %rsi # make 'in' positive

  movb $'-', (%rdi)
  inc %rdi # *out++ = '-'

  call uint_to_string
  inc %rax

  movq %rbp, %rsp
  popq %rbp

  ret # return uint_to_string('out', 'in') +1

/* convert an integer to a string
 *
 * (char*) out -- output for the string
 * (uint64_t) in -- input for the string
 *
 * return:
 *  size of generated string
 */
uint_to_string:
  pushq %rbp
  movq %rsp, %rbp

  pushq %r15
  pushq %r14
  pushq %r13

  movq %rsi, %r15 # save 'in'
  movq %rdi, %r14 # save 'out'
  movq %rdi, %r13 # initialize 'out_p'

  cmpq $0, %r15
  jne 1f

  # 'in' is zero
  movq $0, %rdi
  call fromDigit
  movb %axl, (%r14)

  movq $1, %rax
  jmp 3f # return 1

1: # while 'in' >= 0
  cmp $0, %r15
  je 2f # break if ('in' == 0)

  # 'in' = 'in' / 10
  movq %r15, %rax
  movq $0, %rdx
  movq $10, %rcx
  div %rcx # divides %rcx by [%rdx:%rax]
  # result is put in %rax
  # remainder is put in %rdx

  movq %rax, %r15 # store result of division
  
  movb %dxl, %dil # put remainder in first param
  call fromDigit
  movq %rax, (%r13) # *out_p = fromDigit(n % 10)

  inc %r13 # '++out_p'

  jmp 1b # continue loop

2: # loop end   
  subq %r14, %r13 # size = 'out_p - out'

  movq %r14, %rdi
  movq %r13, %rsi
  call reverse # reverse('out', 'size')

  movq %r13, %rax # return 'size'

3: # preparation for return
  popq %r13
  popq %r14
  popq %r15

  movq %rbp, %rsp
  popq %rbp

  ret

/* copy null-terminated string from 'in' to 'out'
 * 'out' will not be null-terminated
 *
 * params:
 *  (char*) out -- the destination of the copy
 *  (char*) in  -- the source of the copy
 * return:
 *  the amount of characters copied
 */
strcpy:
  pushq %rbp
  movq %rsp, %rbp

  movq %rdi, %r11 # initialize 'out_p' with 'out'

1: # while (null character is not yet reached
  cmpb $0x00, (%rsi)
  je 2f # while(*in)

  movb (%rsi), %r10b # char tmp = *in
  movb %r10b, (%r11) # *out_p = tmp

  # next iteration
  inc %rsi
  inc %r11
  jmp 1b

2: # loop end
  movq %r11, %rax
  sub %rdi, %rax # store size in return value

  movq %rbp, %rsp
  popq %rbp

  ret # return ('out_p' - 'out')

/**
 * str -- needs to be null-terminated
 * return
 *  the size of the string
 */
strlen:
  pushq %rbp
  movq %rsp, %rbp

  movq $0, %rax # initialize 'size'
1: # while null character not reached
  cmpb $0, (%rdi)
  je 2f # while(*str)
  inc %rdi # ++'str'

  inc %rax #++'size'
  
  jmp 1b
2: # loop end

  movq %rbp, %rsp
  popq %rbp

  ret

/*
 * params:
 *   0. byte (digit)
 * returns (byte)
 *   ascii representation of the digit
 */
fromDigit:
  pushq %rbp
  movq %rsp, %rbp

  mov %dil, %al
  addb $'0', %al

  movq %rbp, %rsp
  popq %rbp

  ret # 'digit' + '0'

/*
 * str  -- array to be reversed
 * size -- size of the array
 */
reverse:
  pushq %rbp
  movq %rsp, %rbp

  movq %rdi, %r11
  addq %rsi, %r11
  dec %r11 # 'backward_it' = (array + size -1)
  
1: # while ('forward_t' < 'backward_it')
  cmp %rdi, %r11
  jl 2f # Don't loop if !('forward_t' < 'backward_it')

  # Swap (%r11) and (%rdi)
  movb (%r11), %r10b
  movb (%rdi), %r9b

  movb %r10b, (%rdi)
  movb %r9b, (%r11)

  dec %r11 # --'backward_it'
  inc %rdi # ++'array'

  jmp 1b

2: # loop end

  movq %rbp, %rsp
  popq %rbp

  ret
