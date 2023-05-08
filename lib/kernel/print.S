TI_GDT 	equ 	0
RPL0 	equ 	0
SELECTOR_VIDEO	equ	(0x0003 << 3) + TI_GDT + RPL0

[bits 32]
section .data
	put_int_buffer dq 0	;定义8字节缓冲区	用于数字到字符的转换

section .text
;----------------------put_char-------------------
;功能描述：把栈中的 1 个字符写入光标所在处
;-------------------------------------------------

global put_char
put_char:
	pushad		;备份32位寄存器环境
	;需要保证 gs 中为正确的视频段选择子
	;为保险期间，每次打印都为 gs赋值
	mov ax, SELECTOR_VIDEO	;不能直接把立即数送入段寄存器
	mov gs, ax

;;;;;;;;;;;;;;;;;;获取当前光标位置;;;;;;;;;;;;;;;;;;;
	;先获得高8位
	mov dx, 0x03d4		;索引寄存器
	mov al, 0x0e		;用于提供光标位置的高8位
	out dx, al
	mov dx, 0x03d5		;通过读写数据端口 0x3d5 来获得或设置光标位置
	in al, dx		;得到了光标位置的高8位
	mov ah, al
	
	;获取低8位
	mov dx, 0x03d4
	mov al, 0x0f
	out dx, al
	mov dx, 0x03d5
	in al, dx

	;将光标存入 bx
	mov bx, ax
	;下面这行是在栈中获取待打印的字符
	mov ecx, [esp + 36]	;pushad 压入 4x8 = 32 字节, 加上主调用函数 4字节的返回地址，故esp+36字节
	
	cmp cl, 0xd		;CR 是 0x0d, LF是 0x0a
	jz .is_carriage_return	
	cmp cl,0xa
	jz .is_line_feed

	cmp cl, 0x8		;BS(backspace)的asc码是8
	jz .is_backspace
	jmp .put_other

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	.is_backspace:	;退格
;当backspace时，本质上只要将光标向前移动一个显存位置即可，后面再次输入的字符自然会覆盖此处的字符
;但是有可能在键入 backspace 后并不再键入新的字符，这时光标已经向前移动到待删除的字符位置，但字符还在
;这就显示的好怪异，所以此处添加了空格或空字符 0
		dec bx	
		shl bx,1	;光标左移1位等于乘2
				;表示光标对应显存中的偏移字节

		mov byte [gs:bx], 0x20	;将待删除的字节补为0或空格即可
		inc bx
		mov byte [gs:bx], 0x07		
		shr bx,1
		jmp .set_cursor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	.put_other:
		shl bx,1	;光标位置用2字节表示，将光标值乘2
				;表示对应显存中的偏移字节
		mov [gs:bx], cl		;ASCII 字符本身
		inc bx
		mov byte [gs:bx], 0x07	;字符属性
		shr bx, 1	;恢复老的光标
		inc bx		;下一个光标
		cmp bx, 2000	
		jl .set_cursor	;若光标值小于2000，表示未写到显存合规，设置新光标
				;超过屏幕字符，进行换行处理
				
	.is_line_feed:		;换行符 LF(\n)
	.is_carriage_return:	;回车符号CR(\r)
		;回车，只需要光标移动到行首部
		xor dx,	dx	;dx 是被除数的高16位，清0，用来存储余数
		mov ax, bx	;ax 是被除数的低16位
		mov si, 80	;由于是效仿Linux，Linux中\n表示下一行的行首
				;所以本系统中\n和\r都处理为\n的意思,也就是下一行行首
		div si		
		sub bx, dx	;光标值减去除以80的余数便是取整
	
	.is_carriage_return_end:	;回车符CR处理结束
		add bx, 80
		cmp bx, 2000
	.is_line_feed_end:		;若是LF(\n)，将光标+80便
		jl .set_cursor
;屏幕范围是 0~24 ,滚屏的原理是讲屏幕的第 1~24行搬运到 0~23行，再将24行用空格填充

	.roll_screen:	;超出屏幕大小
		cld
		mov ecx, 960		;2000 - 80 = 1920 个字符需要搬运，共 1920 * 2 = 3840字节
					;一次搬运4字节， 共3840/4=960 次
		mov esi, 0xc00b80a0	;第1行行首
		mov edi, 0xc00b8000	;第0行行首
		rep movsd
	;最后一行填充为空白
		mov ebx, 3840
		mov ecx, 80
	.cls:
		mov word [gs:ebx], 0x0720	;0x0720是黑底白字的空格
		add ebx, 2
		loop .cls
		mov bx, 1920		;光标重置为1920，最后一行的首字符
	
	.set_cursor:
		;将光标设为bx值
		;1.设置高8位
		mov dx, 0x03d4	;索引寄存器
		mov al, 0x0e
		out dx,al
		mov dx, 0x03d5	;通过读写数据端口 0x03d5来获得或设置光标位置
		mov al, bh
		out dx, al
		
		;2.设置低8位
		mov dx, 0x03d4
		mov al, 0x0f
		out dx, al
		mov dx, 0x03d5
		mov al, bl
		out dx, al
	
	.put_char_done:
		popad
		ret
		
;------------------------------
; set_cursor :设置光标位置
;------------------------------
global set_cursor:
set_cursor:
	push eax
	push edx
	push ebx

	mov ebx,[esp+16]	;从栈中获取光标位置数据
	;将光标设为bx值
	;1.设置高8位
	mov dx, 0x03d4	;索引寄存器
	mov al, 0x0e
	out dx,al
	mov dx, 0x03d5	;通过读写数据端口 0x03d5来获得或设置光标位置
	mov al, bh
	out dx, al
		
	;2.设置低8位
	mov dx, 0x03d4
	mov al, 0x0f
	out dx, al
	mov dx, 0x03d5
	mov al, bl
	out dx, al

	pop ebx
	pop edx
	pop eax
	ret


;-----------------------------------------------
;put_str 通过 put_char 来打印以 0位结尾的字符串
;----------------------------------------------
global put_str
put_str:
;由于本函数中只用到了 ebx 和 ecx，只备份这两个寄存器
	push ebx
	push ecx
	xor ecx,ecx	;准备用ecx存储参数，清空
	mov ebx, [esp+12]	;从栈中得到待打印的字符串地址
	
	.goon:
		mov cl, [ebx]
		cmp cl, 0	;如果处理到了字符串尾，跳到结束处返回
		jz .str_over
		push ecx	;为put_char函数传递参数
		call put_char
		add esp, 4	;回收参数所占的栈空间
		inc ebx		;使 ebx指向下一个字符
		jmp .goon
	.str_over:
		pop ecx
		pop ebx
	ret
		
;------------将小端字节序的数字变成对应的ASCII后，倒置-----------
;输入：栈中参数为待打印的数字
;输出：在屏幕是哪个打印十六进制数字，并不会打印前缀0x
;如打印十进制 15 时，只会直接打印 f，不会是 0xf
;----------------------------------------------------------------
global put_int
put_int:
	pushad
	mov ebp, esp
	mov eax, [ebp + 4*9] 	; call 的返回地址占4字节 + pushad 的8个4字节
	mov edx, eax	;edx = eax = 要处理的数字
	mov edi, 7	;指定在 put_int_buffer 中初始的偏移量
	mov ecx, 8	;在32位数字中，16进制数字的位数是8个
	mov ebx, put_int_buffer		; ebx = 缓冲区的地址

;将32位数字按照十六进制的形式从低位到高位逐个处理
;共处理8个十六进制数字

	.16based_4bits:
		and edx, 0x0000000F	; 一个十六进制占4个bit
		cmp edx, 9		; 数字 0-9 和 a-f 需要分别处理
		jg .is_A2F		
		add edx, '0'
		jmp .store
	.is_A2F:
		sub edx, 10		;A~F减10所得到的差，再加上字符A的ASCII码，便是A—F对应的ASCII码
		add edx, 'A'
	
	.store:
		mov [ebx+edi], dl	;此时dl中因该是数字对应的字符的ASCII码
		dec edi
		shr eax, 4
		mov edx, eax
		loop .16based_4bits

	;现在 put_int_buffer 中已全是字符，打印之前把高位连续的字符去掉
	;比如 000123 变成 123
	.ready_to_print:
		inc edi		;此时 edi 退减为 -1 0xffffffff , +1 使为0
	.skip_prefix_0:
		cmp edi, 8
		je .full0
	.go_on_skip:
		mov cl, [put_int_buffer + edi]
		inc edi
		cmp cl, '0'
		je .skip_prefix_0
		dec edi
		jmp .put_each_num

	.full0:
		mov cl, '0'
	.put_each_num:
		push ecx
		call put_char
		add esp, 4
		inc edi
		mov cl, [put_int_buffer+edi]
		cmp edi, 8
		jl .put_each_num
		popad
	ret



















