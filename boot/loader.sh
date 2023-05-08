nasm -I include/ -o loader.bin loader.S && dd if=loader.bin of=/root/software/debugger-bochs/bochs-2.6.2/hd60M.img bs=512 count=4 seek=2 conv=notrunc
