# Makefile

.PHONY: all clean boot

GNUA := i686-elf-as
CC := i686-elf-gcc
CFLAGS := -std=gnu99 -ffreestanding -O2 -Wall -Wextra

C++ := i686-elf-g++
CPPFLAGS := -ffreestanding -O2 -Wall -Wextra -fno-exceptions -fno-rtti

LINKER := i686-elf-gcc
GCC_LINKER_FLAGS := -ffreestanding -O2 -nostdlib
LINKER_FLAGS := -lgcc

BUILD_DIR := build
SRC_DIR := src

SRC := $(wildcard $(SRC_DIR)/*)
OBJS := $(patsubst $(SRC_DIR)/%, $(BUILD_DIR)/%.o, $(SRC))
BOOT_IMAGE := $(BUILD_DIR)/myos.bin
ISO_IMAGE := $(BUILD_DIR)/myos.iso

all: $(ISO_IMAGE)

boot: $(ISO_IMAGE)
	qemu-system-i386 -no-reboot -cdrom $<

$(ISO_IMAGE): $(BOOT_IMAGE)
	mkdir -p isodir/boot/grub
	cp $< isodir/boot/myos.bin
	cp grub/grub.cfg isodir/boot/grub/grub.cfg
	grub-mkrescue -o build/myos.iso isodir

$(BOOT_IMAGE): $(OBJS)
	$(CC) -T linker.ld -o myos.bin $(GCC_LINKER_FLAGS) $^ $(LINKER_FLAGS)

$(BUILD_DIR)/%.s.o: $(SRC_DIR)/%.s
	@mkdir -p $(dir $@)
	$(GNUA) $< -o $@

$(BUILD_DIR)/%.c.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) -c $< -o $@ $(CFLAGS)

clean:
	$(RM) -r $(BUILD_DIR)
