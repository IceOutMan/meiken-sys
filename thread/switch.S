[bits 32]
section .text
global switch_to
switch_to:
    ;栈中此处是返回地址
    push esi
    push edi
    push ebx
    push ebp

    mov eax, [esp + 20]     ;得到栈中的参数 cur
    mov [eax], esp          ;保存栈顶指针esp，task_struct的 self_kstack 字段，所以直接往 thread开头楚存4字节即可

    ;------------- 以上是备份当前线程的环境，下面是恢复下一个线程的环境 -----------
    mov eax, [esp + 24]     ;得到栈中的参数 next   
    mov esp, [eax]          ; pcb 的第一个成员是是 self_kstack 成员
    ; 它用来记录 0级栈顶指针，被换上 cpu时用来恢复 0级栈
    ; 0 级栈中保存了进程或线程所有信息，包括3级栈指针
    pop ebp 
    pop ebx
    pop edi
    pop esi
    ret     ;返回到上面 switch_to 下面那句注视的返回地址    
            ;未由中断进入，第一次执行时会返回到 kernel_thread