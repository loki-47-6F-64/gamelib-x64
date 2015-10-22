# all symbols are in dummy kernel
file out/kernel_symbols

# the tcp port opened by qemu. (make qemu-debug)
target remote :1234


# nop the 'wait for debugger'
set *((char*) wait_for_debugger)    = 0x90
set *((char*) wait_for_debugger +1) = 0x90
set *((char*) wait_for_debugger +2) = 0x90
set *((char*) wait_for_debugger +3) = 0x90
set *((char*) wait_for_debugger +4) = 0x90
set *((char*) wait_for_debugger +5) = 0x90

