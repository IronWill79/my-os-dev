# Makefile

.PHONY: all clean boot

NASM := nasm -f elf64

BUILD_DIR := build
SRC_DIR := src

SRC := $(wildcard $(SRC_DIR)/*.s)
OBJS := $(patsubst $(SRC_DIR)/%.s, $(BUILD_DIR)/%.o, $(SRC))
BOOT_IMAGE := $(BUILD_DIR)/boot_image

all: $(BOOT_IMAGE)

boot: $(BOOT_IMAGE)
	qemu-system-x86_64 -no-reboot -drive file=$<,format=raw,index=0,media=disk

$(BOOT_IMAGE): $(BUILD_DIR)/linked.o
	objcopy -O binary $< $@

$(BUILD_DIR)/linked.o: $(OBJS)
	ld -T linker.ld -o $@ $^

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(dir $@)
	$(NASM) $< -o $@

clean:
	$(RM) -r $(BUILD_DIR)
