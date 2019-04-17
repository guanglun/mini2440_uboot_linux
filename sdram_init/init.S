@******************************************************************************
@ File：init.S
@ 功能：初始化sdram
@****************************************************************************** 
 
.text
.global _start
_start:
	// 关看门狗
	ldr r0,=0x53000000
	mov r1,#0
	str r1,[r0]
	
	// 屏蔽中断
	mov	r1, #0xffffffff
	ldr	r0, =0x4A000008
	str	r1, [r0]
	
	ldr	r1, =0x3ff
	ldr	r0, =0x4A00001C
	str	r1, [r0]
	
	// 初始化内存
	MOV R0,#0x48000000
	ADRL R1,mem_cfg_val
							@STR [R1],[R0],#4
	MOV R4,#0
1:	
	LDR R3,[R1],#4
	STR R3,[R0],#4
	ADD R4,R4,#1
	CMP R4,#13
	BNE 1b
 
loop:
	b loop
	
.align 4
mem_cfg_val:
    @ 存储控制器13个寄存器的设置值
    .long   0x22011110      @ BWSCON
    .long   0x00000700      @ BANKCON0
    .long   0x00000700      @ BANKCON1
    .long   0x00000700      @ BANKCON2
    .long   0x00000700      @ BANKCON3  
    .long   0x00000700      @ BANKCON4
    .long   0x00000700      @ BANKCON5
    .long   0x00018005      @ BANKCON6
    .long   0x00018005      @ BANKCON7
    .long   0x008C07A3      @ REFRESH
    .long   0x000000B1      @ BANKSIZE
    .long   0x00000030      @ MRSRB6
    .long   0x00000030      @ MRSRB7