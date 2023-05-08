#ifndef __USERPROG_SYSCALLINIT_H
#define __USERPROG_SYSCALLINIT_H
#include "../lib/stdint.h"
#include "../thread/thread.h"
#include "../lib/user/syscall.h"
#include "../device/console.h"
void syscall_init(void);
uint32_t sys_getpid(void);
#endif