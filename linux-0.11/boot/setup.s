.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

SETUPLEN = 2				! nr of setup-sectors
BOOTSEG  = 0x07c0			! original address of boot-sector
INITSEG  = 0x9000			! we move boot here - out of the way
SETUPSEG = 0x9020			! setup starts here
SYSSEG   = 0x1000			! system loaded at 0x10000 (65536).

entry _start
_start:
	mov	ax,#SETUPSEG
	mov	es,ax

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#29
	mov	bx,#0x0007		! page 0, attribute 7 (normal)
	mov	bp,#msg1
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

	mov    ax,#INITSEG    
	mov    ds,ax 		!设置ds=0x9000
	mov    ah,#0x03     !读入光标位置
	xor    bh,bh
	int    0x10         !调用0x10中断
	mov    [0],dx       !将光标位置写入0x90000.

	!读入内存大小位置
	mov    ah,#0x88
	int    0x15
	mov    [2],ax

	!从0x41处拷贝16个字节（磁盘参数表）
	mov    ax,#0x0000
	mov    ds,ax
	lds    si,[4*0x41]
	mov    ax,#INITSEG
	mov    es,ax
	mov    di,#0x0080
	mov    cx,#0x10
	rep            !重复16次
	movsb

    !堆栈栈寄存器ss和堆栈顶寄存器sp 0x9000 至 0x9ff00
    mov ax,#INITSEG
	mov	ss,ax
	mov	sp,#0xFF00

    !设置附加数据段寄存器ES的值指向SETUPSEG，以便可以正常显示字符串数据
	mov ax, #SETUPSEG
	mov	es,ax


Print_Cursor:

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh			! 页号bh=0
	int	0x10
	
	mov	cx,#11
	mov	bx,#0x0007		! page 0, attribute 7 (normal) 页号BH=0 属性BL=7正常显示
	mov	bp,#Cursor		! ES:BP要显示的字符串地址
	mov	ax,#0x1301		! write string, move cursor AH=13显示字符串 AL=01光标跟随移动
	int	0x10
	mov ax, #0			!set bp = 0x0000
	mov bp, ax			
	call print_hex
	call print_nl

Print_Memory:

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh			! 页号bh=0
	int	0x10
	
	mov	cx,#12
	mov	bx,#0x0007		! page 0, attribute 7 (normal) 页号BH=0 属性BL=7正常显示
	mov	bp,#Memory		! ES:BP要显示的字符串地址
	mov	ax,#0x1301		! write string, move cursor AH=13显示字符串 AL=01光标跟随移动
	int	0x10
	mov ax, #2			!set bp = 0x0002
	mov bp, ax
	call print_hex
	
	!显示扩展内存最后的单位"KB"
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh			! 页号bh=0
	int	0x10

	mov	cx,#2
	mov	bx,#0x0007		! page 0, attribute 7 (normal) 页号BH=0 属性BL=7正常显示
	mov	bp,#KB		    ! ES:BP要显示的字符串地址
	mov	ax,#0x1301		! write string, move cursor AH=13显示字符串 AL=01光标跟随移动
	int	0x10
	call print_nl



Print_Cyl_hd0:

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh			! 页号bh=0
	int	0x10
	
	mov	cx,#9
	mov	bx,#0x0007		! page 0, attribute 7 (normal) 页号BH=0 属性BL=7正常显示
	mov	bp,#Cyl_hd0		! ES:BP要显示的字符串地址
	mov	ax,#0x1301		! write string, move cursor AH=13显示字符串 AL=01光标跟随移动
	int	0x10
	mov ax, #0x0080	    !set bp = 0x0004
	mov bp, ax
	call print_hex
	call print_nl

!死循环
dead_loop:
	jmp dead_loop

!以16进制方式打印栈顶的16位数
print_hex:
	mov    cx,#4        ! 4个十六进制数字
	mov    dx,(bp)      ! 将(bp)所指的值放入dx中，如果bp是指向栈顶的话
print_digit:
	rol    dx,#4        ! 循环以使低4比特用上 !! 取dx的高4比特移到低4比特处。
	mov    ax,#0xe0f    ! ah = 请求的功能值，al = 半字节(4个比特)掩码。
	and    al,dl        ! 取dl的低4比特值。
	add    al,#0x30     ! 给al数字加上十六进制0x30
	cmp    al,#0x3a
	jl    outp          !是一个不大于十的数字
	add    al,#0x07      !是a～f，要多加7
outp: 
	int    0x10
	loop    print_digit
	ret
!这里用到了一个loop指令，每次执行loop指令，cx减1，然后判断cx是否等于0。如果不为0则转移到loop指令后的标号处，实现循环；如果为0顺序执行。另外还有一个非常相似的指令：rep指令，每次执行rep指令，cx减1，然后判断cx是否等于0，如果不为0则继续执行rep指令后的串操作指令，直到cx为0，实现重复。
!打印回车换行
print_nl:
	mov    ax,#0xe0d     ! CR
	int    0x10
	mov    al,#0xa       ! LF
	int    0x10
	ret

msg1:
	.byte 13,10
	.ascii "Now we are in SETUP ..."
	.byte 13,10,13,10

Cursor:
	.ascii "Cursor POS:"	!0x90000 2bytes
Memory:
	.ascii "Memory SIZE:"	!0x90002 2bytes
Cyl_hd0:
	.ascii "Cyls_hd0:"		!0x90004 2bytes
KB:
	.ascii "KB"

.text
endtext:
.data
enddata:
.bss
endbss:
