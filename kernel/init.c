#include "init.h"

/* 负责初始化所有模块 */
void init_all(){
    put_str("init_all\n");
    idt_init(); //初始化中断

    timer_init();   //初始化 PIT 时钟计数器

    mem_init();     //内存池初始化

    thread_init();  //初始化线程

    console_init(); //控制台初始化，最好在放开中断之前

    keyboard_init();    //初始化键盘

    tss_init(); //初始化 tss

    syscall_init();   // 初始化系统调用

    ide_init();     //初始化磁盘

    filesys_init(); //初始化文件系统
    
}