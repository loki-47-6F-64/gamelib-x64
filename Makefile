TARGET = amd64-elf-

# include local Makefile. Copy local.mk.template and adapt
include local.mk

PREFIX=/usr
COMPPATH=$(PREFIX)/bin
CC = $(COMPPATH)/$(TARGET)gcc
CXX = $(COMPPATH)/$(TARGET)g++
AS = $(COMPPATH)/$(TARGET)as
AR = $(COMPPATH)/$(TARGET)ar
NM = $(COMPPATH)/$(TARGET)nm
LD = $(COMPPATH)/$(TARGET)ld
OBJDUMP = $(COMPPATH)/$(TARGET)objdump
OBJCOPY = $(COMPPATH)/$(TARGET)objcopy
RANLIB = $(COMPPATH)/$(TARGET)ranlib
STRIP = $(COMPPATH)/$(TARGET)strip

ifeq ($(DEBUG),1)
	NDEBUG   := -O1 -g
	PASS_MACRO_CC := -DNDEBUG=1
	PASS_MACRO_AS := --defsym NDEBUG=1
else
	NRELEASE := -O3
endif


obj_boot   = out/boot.o
obj_kernel = out/kernel.o
obj_game   = out/game.o out/main.o

ASFLAGS = -g $(PASS_MACRO_AS)
CFLAGS  = $(PASS_MACRO_CC) -I$(PWD) -std=c11 -m64 -nostdlib -c -fno-omit-frame-pointer -ffreestanding -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -mno-sse3 $(NDEBUG) $(NRELEASE) -Wall -Wextra -W


all: out/kernel_symbols out/bootloader out/kernel Makefile
	
out/bootloader: out/boot.o src/bootloader/link_boot.ld | HD_img
	$(LD) -nostdlib -T src/bootloader/link_boot.ld -o $@ out/boot.o
	dd if=out/bootloader of=HD_img conv=notrunc

out/kernel: $(obj_kernel) $(obj_game) src/kernel/link_kernel.ld | HD_img
	$(LD) -nostdlib -T src/kernel/link_kernel.ld -o $@ $(obj_kernel) $(obj_game)
	dd if=out/kernel of=HD_img bs=512 seek=17 conv=notrunc

# GDB needs a specific format in order to read the symbols,
# unfortunately the kernel will not boot properly with that format, thus
# a dummy kernel is required
out/kernel_symbols: $(obj_kernel) $(obj_game) src/kernel/link_kernel_symbols.ld 
	$(LD) -nostdlib -T src/kernel/link_kernel_symbols.ld -o $@ $(obj_kernel) $(obj_game)

out/boot.o: src/bootloader/*.s | out
	$(AS) src/bootloader/*.s -o $@

out/kernel.o: src/kernel/*.s | out
	$(AS) $(ASFLAGS) src/kernel/*.s -o $@

out/game.o: src/game/*.s | out
	$(AS) $(ASFLAGS) src/game/*.s -o $@

out/main.o: src/game/main.c | out
	$(CC) $(CFLAGS) src/game/main.c -o $@ 

out/block.o: src/game/block.c | out
	$(CC) $(CFLAGS) src/game/block.c -o $@ 

out/field.o: src/game/field.c | out
	$(CC) $(CFLAGS) src/game/field.c -o $@ 

out/panic.o: src/game/panic.c | out
	$(CC) $(CFLAGS) src/game/panic.c -o $@ 

out/util.o: src/game/util.c | out
	$(CC) $(CFLAGS) src/game/util.c -o $@ 

out/screen.o: src/game/screen.c | out
	$(CC) $(CFLAGS) src/game/screen.c -o $@

HD_img:
	dd if=/dev/zero of=$@ count=512

qemu-debug: all
	qemu-system-x86_64 -s HD_img

qemu: all
	qemu-system-x86_64 HD_img

kvm: all
	qemu-system-x86_64 -enable-kvm -cpu host HD_img

bochs: all
	bochs

out:
	mkdir out

clean:
	rm -f HD_img
	rm -rf out

.PHONY: clean all kvm qemu 

