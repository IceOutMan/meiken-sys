#ifndef __KERNEL_INIT_H
#define __KERNEL_INIT_H
#include "../lib/kernel/print.h"
#include "./interrupt.h"
#include "../device/timer.h"
#include "./memory.h"
#include "../thread/thread.h"
#include "../device/console.h"
#include "../device/keyboard.h"
#include "../userprog/tss.h"
#include "../userprog/syscall-init.h" 
#include "../device/ide.h"
#include "../fs/fs.h"
void init_all(void);

#endif