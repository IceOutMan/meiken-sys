#include "stdio.h"
#include "../kernel/interrupt.h"
#include "../kernel/global.h"
#include "./string.h"
#include "./user/syscall.h"
#include "./kernel/print.h"
#include "./stdint.h"


#define va_start(ap, v) ap = (va_list)&v    //把ap指向第一个固定参数v
#define va_arg(ap, t) *((t*)(ap += 4))      //ap 指向下一个参数并返回其值
#define va_end(ap) ap = NULL                //清除ap

/* 将整型转换成字符 (integer to ascii) */
static void itoa(uint32_t value, char** buf_ptr_addr, uint8_t base){

    uint32_t m = value % base;      //求模，最想掉下来的是最低位
    uint32_t i = value / base;      //取整

    if(i){  //如果倍数不为 0，则递归调用
        itoa(i, buf_ptr_addr, base);
    }
    if(m < 10){ //如果余数是 0～9
        *((*buf_ptr_addr)++) = m + '0';     //将数字 0-9 转换为字符 ‘0' ~ '9'
    }else{
        *((*buf_ptr_addr)++) = m - 10 + 'A';    //将数字 A-F 转换为字符 ‘A'~'F'
    }
}

/* 将参数 ap 按照格式 format 输出到字符串 str，并返回替换后 str长度 */
uint32_t vsprintf(char* str, const char* format, va_list ap){
    char* buf_ptr = str;
    const char* index_ptr = format;
    char index_char = *index_ptr;
    int32_t arg_int;
    char* arg_str;
    while(index_char){
        if(index_char != '%'){
            *(buf_ptr++) = index_char;
            index_char = *(++index_ptr);
            continue;
        }
        index_char = *(++index_ptr);        //得到%后面的字符
        switch(index_char){
            case 's':
                arg_str = va_arg(ap, char*);
                strcpy(buf_ptr, arg_str);
                buf_ptr += strlen(arg_str);
                index_char = *(++index_ptr);
                break;
            case 'c':
                *(buf_ptr++) = va_arg(ap, char);
                index_char = *(++index_ptr);
                break;
            
            case 'd':
                arg_int = va_arg(ap, int);
                /* 若是负数，将其转正数后，在正数前面输出个负号码 '-' */
                if(arg_int < 0){
                    arg_int = 0 - arg_int;
                    *buf_ptr++ = '-';
                }
                itoa(arg_int, &buf_ptr, 10);
                index_char = *(++index_ptr);
                break;
            case 'x':
                arg_int = va_arg(ap, uint32_t);
                itoa(arg_int, &buf_ptr, 16); //转换成16进制
                index_char = *(++index_ptr);
                //跳过格式字符并更新 index_char
                break;
            
        }
    }
    return strlen(str);
}

/* 同 printf 不同的地方是，字符串不是写到终端，而是写到buf 中,返回字符串的长度 */
uint32_t sprintf(char* buf, const char* format, ...){
    va_list args;
    uint32_t retval;
    va_start(args, format);
    retval = vsprintf(buf, format, args);
    va_end(args);
    return retval;
}

/* 格式化输出字符串 */
uint32_t printf(const char* format, ...){
    va_list args;
    va_start(args, format);     //使 args 指向 format
    char buf[1024] = {0};       //用于存储拼接后的字符串
    vsprintf(buf, format, args);
    va_end(args);
    return write(1,buf,strlen(buf));
}