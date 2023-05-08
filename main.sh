# 编译 C 程序, 生成目标文件
gcc -I lib/kernel/ -I device/ -m32 -c -fno-builtin -fno-stack-protector -o build/timer.o device/timer.c && 

gcc -I lib/kernel/ -I lib/ -I kernel/ -m32 -c -fno-builtin -fno-stack-protector -o build/main.o kernel/main.c &&
 
gcc -I lib/kernel -I lib/ -I kernel/ -m32 -c -fno-builtin -fno-stack-protector -o build/interrupt.o kernel/interrupt.c && 

gcc -I lib/kernel -I lib/ -I kernel/ -m32 -c -fno-builtin -fno-stack-protector -o build/init.o kernel/init.c && 


# 编译汇编程序，生成目标文件
nasm -f elf -o build/print.o  lib/kernel/print.S &&  

nasm -f elf -o build/kernel.o kernel/kernel.S && 

# 链接所有目标文件，在build目录下生成 kernel.bin
ld -m elf_i386 -Ttext 0xc0001500 -e main -o build/kernel.bin build/main.o build/init.o build/interrupt.o build/print.o build/kernel.o build/timer.o && 

# 将要 kernel.bin 用 dd 命令写入虚拟机磁盘
dd if=build/kernel.bin of=/root/software/debugger-bochs/bochs-2.6.2/hd60M.img bs=512 count=200 seek=9 conv=notrunc
