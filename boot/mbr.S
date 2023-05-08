;引导主程序
;---------------------------------------------------------------------
%include "boot.inc"
SECTION MBR vstart=0x7c00
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov fs,ax
	mov sp,0x7c00
	mov ax,0xb800
	mov gs,ax
	

;清屏利用 0x06号功能，上卷全部行，则可清屏
;--------------------------------------------------------------------
;INT 0x10 功能号：0x06	功能描述：上卷窗口
;--------------------------------------------------------------------
;输入：
;AH	功能号=0x06
;AL=	上卷的行数（如果为0，表示全部）
;BH=	上卷行属性
;(CL,CH) = 窗口左上角(X,Y)位置
;(DL,DH) = 窗口右下角(X,Y)位置
;无返回值

	mov ax, 0x0600
	mov bx, 0x0700
	mov cx, 0	;左上角(0,0)
	mov dx, 0x184f	;右下角(80,25)
			;VGA文本模式中，一行只能容纳80个字符，共25行
			;下标从0开始，所以0x18=24, 0x4f=79
	int 0x10	;int 0x10

;;;;;;;;;;;;;;;;; 下面三行代码获取光标位置;;;;;;;;;;
	mov ah, 3	;输入： 3号子功能是获取光标位置，需要放入ax寄存器高8位
	mov bh, 0	;bx 寄存器高8位存储的是待获取光标的页号码
	int 0x10	;输出： ch=光标开始行，cl=光标结束行
			;	dh=光标所在行号，dl=光标所在列号
;;;;;;;;;;;;;;;;;; 获取光标结束;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;; 打印字符串 ;;;;;;;;;;;;;;;;;;;;;;;
	;依然使用 10中断，这次调用13号功能打印字符串
	mov ax, message
	mov bp, ax	;es:bp 为串首地址，es此时同cs一致，开头已为段寄存次初始化过

	mov cx, 5	;光标位置要用到dx寄存器中内容，cx中的光标位置可以忽略
			;cx为串长度，不包括结束符号0的字符个数
	mov ax, 0x1301	;字功能号13显示字符串及属性，要存入ah寄存器
			;al设置写字符方式 al=01:显示字符串，光标跟随移动
	mov dx, 0x0707	;把获取得到的行号和列号修改一下验证输出中断会读取dx中的行和列信息
	mov bx, 0x0002	;bh存储要显示的页号，此处是第0页，bl中是字符属性，属性黑底绿字(bl = 02h)
	int 0x10	;执行BIOS 0x10号中断
;;;;;;;;;;;;;;;;;;打印字符串结束;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;操作显存输出GLF字符;;;;;;;;;;;;;;
	mov byte [gs:0x00],'G'
	mov byte [gs:0x01],0xA4	;A  背景色 绿色 闪烁 ，4 前景色 红色

	mov byte [gs:0x02],'L'
	mov byte [gs:0x03],0xA4

	mov byte [gs:0x04],'F'
	mov byte [gs:0x05],0xA4 
;;;;;;;;;;;;;;;;;操作显存输出GLF字符;;;;;;;;;;;;;;;;;;;

	mov eax,LOADER_START_SECTOR	;起始扇区lba地址
	mov bx,LOADER_BASE_ADDR		;写入的地址
	mov cx,4			;待读入的扇区数
	call rd_disk_m_16		;在实模式下读入磁盘中loader程序

	jmp LOADER_BASE_ADDR + 0x300		;开始执行loader程序

;------------------------------------------
;功能：读取硬盘 n 个扇区
; rd_risk_m_16
; exa = LBA扇区号
; bx = 将数据写入的内存地址
; cx = 读入的扇区数
;------------------------------------------
rd_disk_m_16:
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
	mov [bx],ax
	add bx,2
	loop .go_on_read
	ret
	
	
;	jmp $	;使程序悬停此处
	
	message db "1 MBR"
	times 510-($-$$) db 0
	db 0x55,0xaa
	
