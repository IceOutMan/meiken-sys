%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR

;构建gdt及其内部的描述符
GDT_BASE: 
	dd 0x00000000
	dd 0x00000000
CODE_DESC:
	dd 0x0000FFFF
	dd DESC_CODE_HIGH4
DATA_STACK_DESC:
	dd 0x0000FFFF
	dd DESC_DATA_HIGH4
VIDEO_DESC:
	dd 0x80000007	;limit=(0xbffff-0xb8000)/4K=0x7
	dd DESC_VIDEO_HIGH4	;此时dpl为0
GDT_SIZE equ $-GDT_BASE
GDT_LIMIT equ GDT_SIZE-1
times 60 dq 0	;此处预留30个描述符的空位,预留60个就超过512B，调整的地方就比较多了

;total_mem_bytes 用于保存内存容量，以字节为单位，此位置比较好记
;当前偏移 loader.bin 文件头 0x200字节，故total_mem_bytes 内存中的地址是 0xb00，将来在内存中引用此地址
total_mem_bytes dd 0

SELECTOR_CODE	equ (0x0001<<3) + TI_GDT + RPL0	;相当于 (CODE_DESC-GDT_BASE)/8 + TI_GDT + RPL0
SELECTOR_DATA	equ (0x0002<<3) + TI_GDT + RPL0	;同上
SELECTOR_VIDEO	equ (0x0003<<3) + TI_GDT + RPL0	;同上

;下面是 gdt 的指针，前2字节是 gdt 界限，后4字节是 gdt 起始地址
gdt_ptr dw GDT_LIMIT
	dd GDT_BASE

;人工对齐：total_mem_bytes(4)+gdt_ptr(6)+ards_buf(244)+ards_nr(2) 共256字节
ards_buf times 244 db 0
ards_nr dw 0	;用于记录ARDS结构体数量

jmp loader_start

loadermsg db '2 loader in real.'

loader_start:
;--------------------------------------------------------------------
; int 15h , eax = 0000E820h	edx = 534D4150h ('SMAP') 获取内存布局
	xor ebx, ebx	;第一次调用，ebx置为0
	mov edx, 0x534D4150	;edx只赋值一次，循环体中不会改变
	mov di, ards_buf	;ards结构缓冲区
.e820_mem_get_loop:
	mov eax, 0x0000e820	;执行 int 0x15后， eax值变为 0x534d4150,所以每次执行int前都要更新为子功能号
	mov ecx, 20		;ARDS地址范围描述符结构大小是20字节
	int 0x15
	jc .e820_failed_so_try_e801	;若cf位为1，则有错误发生，尝试0xe801子功能
	add di, cx		;使 di 增加20字节指向缓冲区中新的ARDS结构位置
	inc word [ards_nr]	;记录ARDS 数量
	cmp ebx, 0 		;若 ebx 为0 且 cf不为1，这说明 ards全部返回
	jnz .e820_mem_get_loop

	;在所有ards结构中，找出(base_add_low + length_low)的最大值，既内存的容量
	mov cx,[ards_nr]	;遍历每一个ARDS结构体，循环次数是ARDS的数量
	mov ebx, ards_buf
	xor edx, edx		;edx 为最大的内存容量，在此先清0
.find_max_mem_area:
	mov eax, [ebx]		;base_add_low
	add eax, [ebx + 8]	;length_low
	add ebx, 20		;指向缓冲区中下一个ARDS结构
	cmp edx, eax
	;冒泡排序找出最大，edx寄存器始终是最大的内存容量
	jge .next_ards
	mov edx, eax		;edx 为总内存大小
.next_ards:
	loop .find_max_mem_area
	jmp .mem_get_ok

;------------------------------------------------------------------------
;int 15h    ax = E801h 获取内存大小，最大支持4G
;在 ax 和 cx 值一样，以为KB我单位，bx 和 dx 值一样，以 64KB为单位
;在 ax 和 cx 寄存器中为低16MB ，在 bx 和 dx 寄存器中为 16MB 到 4GB

.e820_failed_so_try_e801:
	mov ax, 0xe801
	int 0x15
	jc .e801_failed_so_try88	;若当前 e801 方法失败，就尝试 0x88方法

;1 先算出低 15MB 的内存, ax 和 cx 中以 KB 为单位的内存数量，将其转换位 byte 为单位
	mov cx, 0x400	;cx 和 ax 值一样，cx用作乘数
	mul cx
	shl edx,16		;edx 低16位移动到高16位
	and eax,0x0000FFFF	;eax 保留低 16位
	or edx,eax		;edx 中的值 来自 eax和edx中各自 16位，16位乘积后是32位，高16在dx，低16在ax中
	add edx, 0x100000	;ax 只是15MB，故要加1MB
	mov esi, edx		;先把低于15MB的内存容量存入 esi寄存器备份		

;2 再将16MB 以上的内存转换为byte为单位，寄存器 bx 和 dx 是以 64KB为单位的内存数量
	xor eax, eax
	mov ax,bx
	mov ecx, 0x10000	;0x10000 十进制为 64KB
	mul ecx			;32位乘法，默认的被成数是 eax，积为64位， 高32位存入 edx,低32位存eax
	add esi,eax		;由于此方法只能检测出 4G以内测内存，所以32位 eax 足够了
	mov edx,esi		;edx 为总内存大小
	jmp .mem_get_ok

;----------------------------------------------------------------------------------
; int 15h ah = 0x88 获取内存大小，只能获取 64MB之内
.e801_failed_so_try88:
	;int 15 后，ax存入的是以 KB 为单位的内存容量
	mov ah, 0x88
	int 0x15
	jc .error_hlt
	and eax, 0x0000FFFF
	;16位乘法，被乘数是ax，积为32位。积的高16位在dx中，积的低16位在 ax 中
	mov cx, 0x400
	mul cx
	shl edx, 16 		;把 dx移到高16位
	or edx, eax		;把积的低 16位 组合到 edx，为32位的积
	add edx, 0x100000	;0x88 子功能只会返回1MB以上的内存，故实际内存大小要加上1MB
	jmp .mem_get_ok

.error_hlt:
	hlt

.mem_get_ok:
	mov [total_mem_bytes], edx

;-----------------------------------------
;INT 0x10 功能号:0x13  功能描述：打印字符
;-----------------------------------------
;输入：
;AH 子功能号=13H
;BH = 页码
;BL = 属性(若AL=00H 或 01H)
;CX = 字符串长度
;(DH,DL) = 坐标（行，列）
;ES:BP = 字符串地址
;AL = 显示输出方式
; 0 ——字符串中只含显示字符，其显示属性在BL中，显示后光标位置不变
; 1 ——字符串中只含显示字符，其显示属性在BL中，显示后光标位置改变
; 2 ——字符串中含显示字符和显示属性。显示后，光标位置不变
; 3 ——字符串中含显示字符和显示属性。显示后，光标位置不变
;无返回值

	mov sp, LOADER_BASE_ADDR
	mov bp, loadermsg	;ES:BP = 字符串地址
	mov cx, 17		;CX = 字符串长度
	mov ax, 0x1301		;AH = 13，AL=01h
	mov bx, 0x001f		;页号为0，蓝底粉红字
	mov dx, 0x1800
	int 0x10		;10h 号中断

;--------------------------准备进入保护模式
;1 打开A20地址线
;2 加载GDT
;3 将CR0寄存器PE位置1

;---------------------打开A20
	in al,0x92
	or al,0000_0010B
	out 0x92,al
;---------------------加载GDT
	lgdt [gdt_ptr]
;---------------------CR0第0位置1
	mov eax, cr0
	or eax,0x00000001
	mov cr0, eax

	jmp  SELECTOR_CODE:p_mode_start	;刷新流水线

[bits 32]
p_mode_start:
	mov ax, SELECTOR_DATA
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov esp, LOADER_STACK_TOP
	mov ax, SELECTOR_VIDEO
	mov gs, ax
	
	mov byte [gs:160], 'p'

	;--------------------加载内核----------
	mov eax, KERNEL_START_SECTOR
	mov ebx, KERNEL_BIN_BASE_ADDR	;从磁盘读出后，写入到 ebx=0x70000 指定的地址 ， 0x10000 = 64K

	mov ecx, 200	;读入的扇区个数,100KB, 0x70000 ～ 0x8xxxx 的100KB内存
	call rd_disk_m_32
	
	;---------- 创建也目录 和 页表，初始化内存位图------------
	call setup_page	
	
	;要将描述符表地址及偏移量写入内存 gdt_ptr, 一会儿用新地址重新加载
	sgdt [gdt_ptr]
	
	;将 gdt 描述符中视频段描述符中的段基址+ 0xc0000000
	mov ebx,[gdt_ptr + 2]	;ebx = GDT_BASE
	or dword [ebx + 0x18 + 4], 0xc0000000	; VIDEO的段描述符是第三个描述符，每个描述符8字节， 0x18 = 24，+4后得到段描述符的高32位
						; VIDEO的段描述符的段基址就指内核所在的高地址
	add dword [gdt_ptr + 2], 0xc0000000		;将 GDT 的基地址加上 0xc0000000,使用其成为内核的高地址
	add esp, 0xc0000000			; 栈指针同样映射到内核地址
	
	; 页目录地址赋给 cr3
	mov eax, PAGE_DIR_TABLE_POS
	mov cr3, eax
	
	; 打开 cr0 的 PG 位（第31位）
	mov eax,cr0
	or eax, 0x80000000
	mov cr0, eax
	
	; 开启分页后 用 gdt新的地址重新加载
	lgdt [gdt_ptr]
	mov byte [gs:160], 'V' ;视频段描述符中的段基址已经被更新过了，用字符 V 表示 virtual addr
	;jmp $

	;--------------------- 初始化内核-----------------------------
	jmp SELECTOR_CODE:enter_kernel		;强制刷新流水线，更新 gdt


enter_kernel:
	call kernel_init
	mov esp, 0xc009f000
	jmp KERNEL_ENTRY_POINT				;使用地址 0x1500访问测试
	

;------------------------- 将 kernel.bin 中的 segment 拷贝到编译的地址
kernel_init:
	xor eax, eax
	xor ebx, ebx	; ebx 用来记录程序头表地址
	xor ecx, ecx	; ecx 记录程序头表中的 program header 数量
	xor edx, edx	; edx 记录 program header 尺寸， 即 e_phentsize

	mov dx, [KERNEL_BIN_BASE_ADDR + 42]		;偏移文件42字节处 属性 e_phentsize  表示 program header 每条记录的字节大小
	mov ebx, [KERNEL_BIN_BASE_ADDR + 28]	;偏移文件28字节处 属性 e_phoff		表示 program header 在文件中的偏移量
											;其实该值是 0x34 不过还是谨慎一点，这里来读取实际值
	
	add ebx, KERNEL_BIN_BASE_ADDR			; ebx = 0x70000 + e_phoff = program header 在内存中的位置
	mov cx, [KERNEL_BIN_BASE_ADDR + 44]		;偏移文件44字节处 属性 e_phnum  表示 program header 中记录的条数
	
	
.each_segment:
	cmp byte [ebx + 0], PT_NULL		;若 p_type 等于 PT_NULL， 说明此 program header未使用，ebx指针累加一条记录的大小，继续遍历下一条
	je .PTNULL

	;为函数 memcpy 压入参数，参数是从右往左依次压入
	;函数原型类似 memcpy(dst, src, size)
	push dword [ebx + 16]		;段的字节大小 p_filesz ，program header 中偏移 16字节的地方是 p_filesz, 压入函数 memcpy 的地方个参数：size
	mov eax, [ebx + 4]			;eax = p_offset ，该段距离程序起始位置的偏移 距程序头偏移量为4字节的是 p_offset
	add eax, KERNEL_BIN_BASE_ADDR		;eax = 0x70000 + p_offset ,加上kernel.bin 别加载到的物理地址, eax 为该段的物理起始地址
	push eax							;压入函数 memcpy 的第一个参数：源地址
	push dword [ebx + 8]				;压入函数 memcpy 的第二个参数：目的地址， p_vaddr,本段在内存中起始虚拟地址
										;偏移程序头 8 字节的位置是 p_vaddr 这就是目的地址
	call mem_cpy
	add esp, 12							;清理栈中国呢压入的三个参数
	
.PTNULL:
	add ebx, edx						;edx e_phentsize  表示 program header 每条记录的字节大小
										;在此 ebx 指向下一个 program header
	loop .each_segment
	ret

;---------------- 逐 字节拷贝 mem_cpy( dst, src, size) ------------------
; 输入：栈中三个参数 (dst, src, size)
; 输出：无
;-----------------------------------------------------------------------
mem_cpy:
	cld
	push ebp
	mov ebp, esp
	push ecx		; rep 指令用到了 ecx, 但 ecx 对外层段的循环还有用，故先入栈备份

	mov edi, [ebp + 8]		;dst
	mov esi, [ebp + 12]		;src
	mov ecx, [ebp + 16]		;size
	rep movsb				;逐字节拷贝

	;恢复环境
	pop ecx
	pop ebp
	ret

;---------------------------创建页目录 和 页表--------------------------------
setup_page:
	;先把页目录占用的空间逐字节清0
	mov ecx, 4096		;0x1000 = 4096 = 4K,页目录占一页 -1024条记录，每条记录 4B，共占4KB
	mov esi, 0
.clear_page_dir:
	mov byte [PAGE_DIR_TABLE_POS + esi], 0
	inc esi
	loop .clear_page_dir

;开始创建 页目录项 （PDE）	
.create_pde:	;创建 Page Directory Entry
	mov eax, PAGE_DIR_TABLE_POS
	add eax, 0x1000			;此时 eax = 0x101000 (1M + 4K) 第一个页表的起始地址
	mov ebx, eax			; ebx = 0x101000 作为基址使用
	
	;下面将页目录 0 和 0xc00 都存为第一个页表的地址，每个页表表示4MB内存
	;0xc03fffff 一下地址和  0x003fffff 以下的 4M地址都指向相同的页表，这是为将地址映射为内核地址作准备
	or eax, PG_US_U | PG_RW_W | PG_P	;页目录项的属性RW和P位为1,US为1,表示用户属性,所有特权级别都可以访问.
	mov [PAGE_DIR_TABLE_POS + 0x0], eax	;一个页表项占 4B
	mov [PAGE_DIR_TABLE_POS + 0xc00], eax	;0xc00 表示第 768个页表占用的也目录

	; 0xc0000000 ~ 0xffffffff  1G  内核
	; 0x00000000 ~ 0xbfffffff  3G  用户

	sub eax, 0x1000		; eax = 0x100000, 页目录起始地址 
	mov [PAGE_DIR_TABLE_POS + 4092], eax  	;最后一个页目录项 指向-> 页目录起始地址 0x100000
	
;下面创建页表项 （PTE）
	mov ecx, 256				;1M低端内存 / 每页大小 4K = 256 页
	mov esi, 0
	mov edx, PG_US_U | PG_RW_W | PG_P	;属性 为（7） 1_1_1 US=1, RW=1, P=1
	
.create_pte:	;创建 Page Table Entry
	mov [ebx + esi * 4], edx	;ebx = 0x101000	，也就是第一个页表的起始地址
	add edx, 4096
	inc esi
	loop .create_pte
	
;创建内核其他页表的 PDE
	mov eax,PAGE_DIR_TABLE_POS	;eax = 0x100000
	add eax, 0x2000			;eax = 0x102000	,第二个页表的起始地址
	or eax, PG_US_U | PG_RW_W | PG_P	;也目录项的属性 US ，RW 和 P位都是1
	mov ebx, PAGE_DIR_TABLE_POS		;ebx = 0x100000
	mov ecx, 254
	mov esi, 769
.create_kernel_pde:
	mov [ebx + esi * 4], eax
	inc esi
	add eax, 0x1000	
	loop .create_kernel_pde
	
	ret



;------------------------------------------
;功能：读取硬盘 n 个扇区
; rd_risk_m_16
; exa = LBA扇区号
; bx = 将数据写入的内存地址
; cx = 读入的扇区数
;------------------------------------------
rd_disk_m_32:
	mov esi,eax	;备份 eax
	mov di,cx	;备份 cx

;读写硬盘
;第一步：设置要读取的扇区数
	mov dx,0x1f2
	mov al,cl
	out dx,al	;读取的扇区数

	mov eax,esi	;恢复ax

;第二步：将LBA地址存入 0x1f3 ~ 0x1f6
	;LBA地址 7~0 位写入端口 0x1f3
	mov dx,0x1f3
	out dx,al
	
	;LBA地址 15~8 位写入端口 0x1f4
	mov cl,8
	shr eax,cl
	mov dx,0x1f4
	out dx,al
	
	;将LBA地址 23~16 位写入端口0x1f5
	shr eax,cl
	mov dx,0x1f5
	out dx,al

	shr eax,cl
	and al,0x0f	;LBA第24~27位
	or al,0xe0	;设置7~4位为1110，表示LBA模式
	mov dx,0x1f6
	out dx,al

;第三步：向0x1f7端口写入读命令，0x20
	mov dx,0x1f7
	mov al,0x20
	out dx,al

;第四步：检测硬盘状态
	 .not_ready:
		;同一端，写时表示写入命令字，读时表示读入硬盘状态
		nop
		in al,dx
		and al,0x88	;第4位为1表示硬盘控制器已准备好准备数据传输，第7位为1表示硬盘忙
		cmp al,0x08
		jnz .not_ready	;若没准备好，继续等待
	
;第五步：从0x1f0 端口读数据
	mov ax,di
	mov dx,256
	mul dx
	mov cx,ax
	;di 为要读取的扇区数，一个扇区有512字节，每次读入一个字（2B）共需要 di*512 /2次，所以 di * 256
	mov dx,0x1f0
	
	 .go_on_read:
		in ax,dx
		mov [ebx],ax
		add ebx,2
		loop .go_on_read
	ret
