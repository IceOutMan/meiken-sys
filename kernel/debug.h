#ifndef _KERNEL_DEBUG_H
#define __KERNEL_DEBUG_H
#include "../lib/kernel/print.h"
#include "./interrupt.h"
void panic_spin(char* filename, int line, const char* func, const char* condition);

/*********************** _VA_ARGS_ ************************
 *  _VA_ARGS__ 是预处理起所支持的专用标识符。
 *  代表所有与生路好相对应的参数。
 *  "..." 表示定义的宏其参数可变
**/
#define PANIC(...) panic_spin(__FILE__, __LINE__, __func__, __VA_ARGS__)
/************************************************************/

#ifdef NDEBUG  
    #define ASSERT(CONDITION) ((void)0)
#else
//符号#让编译器将宏的参数转化为字符串字面常量
#define ASSERT(CONDITION) if(CONDITION){} else{PANIC(#CONDITION);}

#endif /* __NDEBUG */

#endif /* __KERNEL_DEBUG_H */