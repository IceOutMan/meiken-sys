#ifndef __DEVICE_TIMER_H
#define __DEVICE_TIMER_H
#include "../lib/kernel/io.h"
#include "../lib/kernel/print.h"
#include "../thread/thread.h"

void timer_init(void);
void mtime_sleep(uint32_t m_seconds);
#endif