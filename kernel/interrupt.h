#ifndef __KERNEL_INTERRUPT_H
#define __KERNEL_INTERRUPT_H
#include "../lib/stdint.h"
#include "./global.h"
#include "../lib/kernel/io.h"
#include "../lib/kernel/print.h"

typedef void* intr_handler;
void idt_init(void);

/* 
 * 定义中断的两种状态
 * INTR_OFF 值为0 表示关中断
 * INTR_ON  值为1 表示开中断
 */ 
enum intr_status{//中断状态
    INTR_OFF,   //中断关闭
    INTR_ON     //中断打开
};

//操作中断的四个方法
enum intr_status intr_get_status(void);
enum intr_status intr_set_status(enum intr_status);
enum intr_status intr_enable(void);
enum intr_status intr_disable(void);
void register_handler(uint8_t vector_no, intr_handler function);

#endif