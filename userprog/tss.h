#ifndef __USERPROG_TSS_H
#define __USERPROG_TSS_H

#include "../kernel/global.h"
#include "../lib/string.h"
#include "../thread/thread.h"

void update_tss_esp(struct task_struct* pthread);
void tss_init(void);
#endif