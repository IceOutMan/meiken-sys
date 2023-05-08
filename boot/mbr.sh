nasm -I include/ -o mbr.bin mbr.S && dd if=mbr.bin of=/root/software/debugger-bochs/bochs-2.6.2/hd60M.img bs=512 count=1 conv=notrunc
