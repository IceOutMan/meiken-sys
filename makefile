# BUILD_DIR = ./build
# ENTRY_PONT = 0xc0001500
# AS = nasm
# CC = gcc
# LD = ld
# LIB = -I lib/ -I lib/kernel/ -I lib/user/ -I lib/kernel/ -I device/
# ASFLAGS = -f elf
# CFLAGS = -Wall $(LIB) -m32 -c -fno-builtin -fno-stack-protector -W -Wstrict-prototypes -Wmissing-prototypes
# LDFLAGS = -m elf_i386 -Ttext $(ENTRY_PONT) -e main -Map $(BUILD_DIR)/kernel.map
# OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o $(BUILD_DIR)/timer.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/print.o $(BUILD_DIR)/debug.o $(BUILD_DIR)/memory.o $(BUILD_DIR)/bitmap.o $(BUILD_DIR)/string.o

# ######### C 代码编译 #####################
# # $< 表示依赖的第一个， $@ 表示目标文件
# $(BUILD_DIR)/main.o : kernel/main.c lib/kernel/print.h lib/stdint.h kernel/init.h
# 	$(CC) $(CFLAGS) $< -o $@

# $(BUILD_DIR)/init.o : kernel/init.c kernel/init.h kernel/memory.h lib/kernel/print.h lib/stdint.h kernel/interrupt.h device/timer.h
# 	$(CC) $(CFLAGS) $< -o $@

# $(BUILD_DIR)/bitmap.o : lib/kernel/bitmap.c lib/kernel/bitmap.h 
# 	$(CC) $(CFLAGS) $< -o $@

# $(BUILD_DIR)/memory.o : kernel/memory.c kernel/memory.h lib/kernel/bitmap.h lib/stdint.h lib/kernel/print.h
# 	$(CC) $(CFLAGS) $< -o $@

# $(BUILD_DIR)/string.o : lib/string.c lib/string.h kernel/global.h
# 	$(CC) $(CFLAGS) $< -o $@

# $(BUILD_DIR)/interrupt.o : kernel/interrupt.c kernel/interrupt.h lib/stdint.h kernel/global.h lib/kernel/io.h lib/kernel/print.h
# 	$(CC) $(CFLAGS) $< -o $@

# $(BUILD_DIR)/timer.o : device/timer.c device/timer.h lib/stdint.h lib/kernel/io.h lib/kernel/print.h
# 	$(CC) $(CFLAGS) $< -o $@

# $(BUILD_DIR)/debug.o : kernel/debug.c kernel/debug.h lib/kernel/print.h lib/stdint.h kernel/interrupt.h
# 	$(CC) $(CFLAGS) $< -o $@

# ########## 汇编代码 ###################
# $(BUILD_DIR)/kernel.o : kernel/kernel.S
# 	$(AS) $(ASFLAGS) $< -o $@
# $(BUILD_DIR)/print.o : lib/kernel/print.S
# 	$(AS) $(ASFLAGS) $< -o $@


# ######### 链接所有目标文件 #################
# $(BUILD_DIR)/kernel.bin : $(OBJS)
# 	$(LD) $(LDFLAGS) $^ -o $@


# .PHONY : mk_dir hd clean all

# mk_dir:
# 	if [ ! -d $(BUILD_DIR) ]; then mkdir $(BUILD_DIR);fi

# hd:
# 	dd if=$(BUILD_DIR)/kernel.bin of=/root/software/debugger-bochs/bochs-2.6.2/hd60M.img bs=512 count=200 seek=9 conv=notrunc
	
# clean:
# 	cd $(BUILD_DIR) && rm -rf ./*

# build: $(BUILD_DIR)/kernel.bin

# all: mk_dir build hd



BUILD_DIR = ./build
ENTRY_PONT = 0xc0001500
AS = nasm
CC = gcc
LD = ld
LIB = -I lib/ -I lib/kernel/ -I lib/user/ -I lib/kernel/ -I device/
ASFLAGS = -f elf
CFLAGS = -Wall $(LIB) -m32 -c -fno-builtin -fno-stack-protector -W -Wstrict-prototypes -Wmissing-prototypes
LDFLAGS = -m elf_i386 -Ttext $(ENTRY_PONT) -e main -Map $(BUILD_DIR)/kernel.map
OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o \
$(BUILD_DIR)/list.o $(BUILD_DIR)/timer.o $(BUILD_DIR)/kernel.o \
$(BUILD_DIR)/print.o $(BUILD_DIR)/debug.o $(BUILD_DIR)/memory.o \
$(BUILD_DIR)/bitmap.o $(BUILD_DIR)/string.o $(BUILD_DIR)/thread.o \
$(BUILD_DIR)/switch.o $(BUILD_DIR)/sync.o $(BUILD_DIR)/console.o \
$(BUILD_DIR)/keyboard.o $(BUILD_DIR)/ioqueue.o $(BUILD_DIR)/tss.o \
$(BUILD_DIR)/process.o $(BUILD_DIR)/syscall.o $(BUILD_DIR)/syscall-init.o \
$(BUILD_DIR)/stdio.o $(BUILD_DIR)/stdio-kernel.o $(BUILD_DIR)/ide.o	$(BUILD_DIR)/fs.o \
$(BUILD_DIR)/file.o $(BUILD_DIR)/inode.o $(BUILD_DIR)/dir.o $(BUILD_DIR)/fork.o

######### C 代码编译 #####################
# $< 表示依赖的第一个， $@ 表示目标文件
$(BUILD_DIR)/main.o : kernel/main.c \
lib/kernel/print.h thread/thread.h lib/stdint.h kernel/init.h kernel/memory.h \
thread/thread.h device/console.h device/ioqueue.h  device/keyboard.h userprog/process.h \
userprog/syscall-init.h lib/user/syscall.h lib/stdio.h fs/fs.h fs/dir.h userprog/fork.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/ide.o : device/ide.c device/ide.h  \
lib/stdint.h thread/sync.h lib/kernel/list.h lib/kernel/bitmap.h lib/kernel/stdio-kernel.h lib/stdio.h device/timer.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/stdio-kernel.o : lib/kernel/stdio-kernel.c lib/kernel/stdio-kernel.h  \
lib/stdint.h lib/kernel/print.h device/console.h kernel/global.h lib/stdio.h 
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/init.o : kernel/init.c kernel/init.h  \
kernel/memory.h lib/kernel/print.h lib/stdint.h kernel/interrupt.h device/timer.h \
thread/thread.h device/console.h device/keyboard.h userprog/tss.h userprog/syscall-init.h device/ide.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/bitmap.o : lib/kernel/bitmap.c lib/kernel/bitmap.h \
lib/kernel/print.h lib/stdint.h kernel/interrupt.h lib/stdint.h kernel/debug.h kernel/global.h lib/string.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/memory.o : kernel/memory.c kernel/memory.h \
lib/kernel/print.h lib/stdint.h lib/kernel/bitmap.h thread/sync.h \
lib/string.h device/console.h kernel/interrupt.h kernel/global.h lib/kernel/list.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/string.o : lib/string.c lib/string.h kernel/global.h lib/stdint.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/interrupt.o : kernel/interrupt.c kernel/interrupt.h \
lib/stdint.h kernel/global.h lib/kernel/io.h lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/timer.o : device/timer.c device/timer.h \
lib/stdint.h lib/kernel/io.h lib/kernel/print.h thread/thread.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/debug.o : kernel/debug.c kernel/debug.h \
lib/kernel/print.h lib/stdint.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/thread.o : thread/thread.c thread/thread.h \
kernel/memory.h lib/stdint.h kernel/global.h lib/string.h lib/stdint.h lib/kernel/list.h userprog/process.h lib/kernel/bitmap.h 
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/list.o : lib/kernel/list.c lib/kernel/list.h \
kernel/interrupt.h kernel/global.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/sync.o : thread/sync.c thread/sync.h \
lib/kernel/list.h lib/stdint.h thread/thread.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/console.o : device/console.c device/console.h \
lib/kernel/print.h  lib/stdint.h thread/sync.h thread/thread.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/keyboard.o : device/keyboard.c device/keyboard.h \
kernel/global.h lib/kernel/print.h kernel/interrupt.h lib/kernel/io.h device/ioqueue.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/ioqueue.o : device/ioqueue.c device/ioqueue.h \
lib/stdint.h  thread/thread.h thread/sync.h kernel/interrupt.h kernel/global.h lib/kernel/print.h  kernel/debug.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/tss.o : userprog/tss.c userprog/tss.h \
lib/string.h kernel/global.h thread/thread.h lib/stdint.h lib/kernel/list.h 
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/process.o : userprog/process.c userprog/process.h \
thread/thread.h lib/stdint.h lib/kernel/list.h kernel/global.h kernel/debug.h \
kernel/memory.h lib/kernel/bitmap.h userprog/tss.h kernel/interrupt.h \
lib/string.h
	$(CC) $(CFLAGS) $< -o $@


$(BUILD_DIR)/syscall.o : lib/user/syscall.c lib/user/syscall.h \
lib/stdint.h thread/thread.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/syscall-init.o : userprog/syscall-init.c userprog/syscall-init.h \
lib/stdint.h thread/thread.h lib/user/syscall.h device/console.h fs/fs.h userprog/fork.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/stdio.o : lib/stdio.c lib/stdio.h \
kernel/interrupt.h kernel/global.h lib/string.h \
lib/user/syscall.h lib/kernel/print.h lib/stdint.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/fs.o : fs/fs.c fs/fs.h \
fs/file.h fs/super_block.h fs/inode.h fs/inode.h fs/dir.h lib/kernel/list.h lib/kernel/stdio-kernel.h \
lib/stdint.h lib/string.h device/ide.h kernel/global.h kernel/debug.h kernel/memory.h device/console.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/inode.o : fs/inode.c fs/inode.h \
fs/fs.h fs/file.h kernel/global.h kernel/memory.h kernel/interrupt.h lib/kernel/list.h lib/kernel/stdio-kernel.h lib/string.h \
fs/super_block.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/file.o : fs/file.c fs/file.h \
fs/fs.h fs/super_block.h fs/inode.h lib/kernel/stdio-kernel.h kernel/memory.h kernel/debug.h kernel/interrupt.h \
lib/string.h thread/thread.h kernel/global.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/dir.o : fs/dir.c fs/dir.h \
lib/stdint.h fs/inode.h fs/file.h fs/fs.h lib/kernel/stdio-kernel.h kernel/global.h kernel/memory.h \
lib/string.h kernel/interrupt.h fs/super_block.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/fork.o : userprog/fork.c userprog/fork.h \
userprog/process.h kernel/memory.h kernel/debug.h thread/thread.h lib/string.h fs/file.h 
	$(CC) $(CFLAGS) $< -o $@


########## 汇编代码 ###################
$(BUILD_DIR)/kernel.o : kernel/kernel.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD_DIR)/print.o : lib/kernel/print.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD_DIR)/switch.o : thread/switch.S
	$(AS) $(ASFLAGS) $< -o $@


######### 链接所有目标文件 #################
$(BUILD_DIR)/kernel.bin : $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@


.PHONY : mk_dir hd clean all

mk_dir:
	if [ ! -d $(BUILD_DIR) ]; then mkdir $(BUILD_DIR);fi

hd:
	dd if=$(BUILD_DIR)/kernel.bin of=/root/software/debugger-bochs/bochs-2.6.2/hd60M.img bs=512 count=200 seek=9 conv=notrunc
	
clean:
	cd $(BUILD_DIR) && rm -rf ./*

build: $(BUILD_DIR)/kernel.bin

all: mk_dir build hd

