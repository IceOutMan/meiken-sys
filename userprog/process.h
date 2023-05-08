#ifndef __USERPROG_PROCESS_H
#define __USERPROG_PROCESS_H

#include "../kernel/global.h"
#include "../thread/thread.h"
#include "../thread/sync.h"
#include "../kernel/interrupt.h"
#include "../device/console.h"
#include "tss.h"

#define USER_STACK3_VADDR (0xc0000000 - 0x1000)
#define USER_VADDR_START 0x8048000
#define default_prio 31

void process_execute(void* filename, char* name);
void start_process(void* filename_);
void process_activate(struct task_struct* p_thread);
void page_dir_activate(struct task_struct* p_thread);
uint32_t* create_page_dir(void);
void create_user_vaddr_bitmap(struct task_struct* user_prog);

#endif