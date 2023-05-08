/************ 机器模式 *************
 *  b -- 输出寄存器 QImode 名称，即寄存器中的最低 8位:[a-d]l
 *  w -- 输出寄存器 HImode 名称，既寄存器中的2字节的部分,如 [a-d]x
 * 
 * HImode  
 *      "Half - Integer" 模式，表示一个2字节的整数
 * QImode
 *      "Quarter-Integer" 模式，表示一个1字节的整数
 * 
 * ********************************/

#ifndef __LIB_IO_H
#define __LIB_IO_H
#include "stdint.h"

/*向端口 port 写入一个字节 */
static inline void outb(uint16_t port,uint8_t data){

    /**************************************************
     * 
     * 端口指定 N 表示 0 ～ 255， d 表示用 dx存储端口
     * %b0 表示对应 al， %w1 表示对应 dx
     * 
     * **************************************************/
    
    asm volatile ("outb %b0, %w1": : "a" (data),"Nd" (port));
}

/* 将 addr处起始的 word_cnt 个字写入端口 port */
static inline void outsw(uint16_t port, const void* addr, uint32_t word_cnt){
    /****************************************************
     * 
     * +表示此限制既做输入，又做输出.
     * outsw是把 ds:esi 处的16位的内容写入port端口
     * 我们在设置段描述符时，已经将 ds, es, ss 段的选择子设置为相同的内容，此时不用担心数据错乱
     * ***************************************************/
    
    asm volatile ( "cld; rep outsw" : "+S" (addr), "+c" (word_cnt) : "d" (port));
}

/* 将从端口 port 读入的一个字符返回  */
static inline uint8_t inb(uint16_t port){
    uint8_t data;
    asm volatile("inb %w1, %b0" : "=a" (data) : "Nd" (port));
    return data;
}

/* 将从端口 port读入的 word_cnt 个字写入 addr */
static inline void insw(uint16_t port, void* addr, uint32_t word_cnt){
    /**************************************************
     * insw 是将从端口 port 处读入的 16位内容写入 es:edi 指向的内存
     * 我们在设置段描述符时，已经将 ds,es,ss段的选择子都设置为相同的值了，此时不用担心数据错乱
     * ***********************************************/
    asm volatile ("cld; rep insw" : "+D" (addr), "+c" (word_cnt) : "d" (port) : "memory" );
}


#endif