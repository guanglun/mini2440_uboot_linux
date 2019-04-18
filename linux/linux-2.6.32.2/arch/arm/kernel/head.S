/*
 *  linux/arch/arm/kernel/head.S
 *
 *  Copyright (C) 1994-2002 Russell King
 *  Copyright (c) 2003 ARM Limited
 *  All Rights Reserved
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 *  Kernel startup code for all 32-bit CPUs
 */
#include <linux/linkage.h>
#include <linux/init.h>

#include <asm/assembler.h>
#include <asm/domain.h>
#include <asm/ptrace.h>
#include <asm/asm-offsets.h>
#include <asm/memory.h>
#include <asm/thread_info.h>
#include <asm/system.h>

#if (PHYS_OFFSET & 0x001fffff)
#error "PHYS_OFFSET must be at an even 2MiB boundary!"
#endif

/*
PAGE_OFFSET			0xC0000000 	页表偏移地址
PHYS_OFFSET			0x30000000 	物理内存偏移地址
TEXT_OFFSET			0x00008000
KERNEL_RAM_VADDR	0xC0008000 	内核虚拟映射地址
KERNEL_RAM_PADDR  	0x30008000 	内核物理（RAM）地址
*/

#define KERNEL_RAM_VADDR	(PAGE_OFFSET + TEXT_OFFSET)
#define KERNEL_RAM_PADDR	(PHYS_OFFSET + TEXT_OFFSET)


/*
 * swapper_pg_dir is the virtual address of the initial page table.
 * We place the page tables 16K below KERNEL_RAM_VADDR.  Therefore, we must
 * make sure that KERNEL_RAM_VADDR is correctly set.  Currently, we expect
 * the least significant 16 bits to be 0x8000, but we could probably
 * relax this restriction to KERNEL_RAM_VADDR >= PAGE_OFFSET + 0x4000.
 */

 /*
 swapper_pg_dir是初始化页表的虚拟地址
 我们把页表放在KERNEL_RAM_VADDR下面,因此我们必须保证KERNEL_RAM_VADDR设置得正确。
 当前我们要求最低有效的16位数值位0x8000,
 但我们可能放宽此限制为KERNEL_RAM_VADDR >= PAGE_OFFSET + 0x4000
 */

#if (KERNEL_RAM_VADDR & 0xffff) != 0x8000
#error KERNEL_RAM_VADDR must start at 0xXXXX8000
#endif

/*

    .equ 虽然数据段主要用于定义变量数据，但是也可以在这里声明静态数据符号。
    .equ 命令用于把常量值设置为可以在文本段中使用的符号
*/
	.globl	swapper_pg_dir
	.equ	swapper_pg_dir, KERNEL_RAM_VADDR - 0x4000
//定义rgtbl 宏 功能是将KERNEL_RAM_PADDR - 0x4000复制给rd寄存器
	.macro	pgtbl, rd
	ldr	\rd, =(KERNEL_RAM_PADDR - 0x4000)
	.endm

/*CONFIG_XIP_KERNEL未设置
*#define KERNEL_START	KERNEL_RAM_VADDR
*#define KERNEL_END		_end
*/

//XIP片上执行
#ifdef CONFIG_XIP_KERNEL
#define KERNEL_START	XIP_VIRT_ADDR(CONFIG_XIP_PHYS_ADDR)
#define KERNEL_END	_edata_loc
#else
#define KERNEL_START	KERNEL_RAM_VADDR
#define KERNEL_END	_end
#endif

/*
 * Kernel startup entry point.
 * ---------------------------
 *
 * This is normally called from the decompressor code.  The requirements
 * are: MMU = off, D-cache = off, I-cache = dont care, r0 = 0,

 * 0xc0008000, you call this at __pa(0xc0008000).
 *
 * See linux/arch/arm/tools/mach-types for the complete list of machine
 * numbers for r1.
 *
 * We're trying to keep crap to a minimum; DO NOT add any machine specific
 * crap here - that's what the boot loader (or in extreme, well justified
 * circumstances, zImage) is for.
 */
 /**
 内核运行入口
 MCR指令将ARM处理器的寄存器中的数据传送到协处理器的寄存器中。如果协处理器不能成功地执行该操作，将产生未定义的指令异常中断。
 MRC指令将协处理器的寄存器中数值传送到ARM处理器的寄存器中。如果协处理器不能成功地执行该操作，将产生未定义的指令异常中断。
 **/
	.section ".text.head", "ax"
ENTRY(stext)
	setmode	PSR_F_BIT | PSR_I_BIT | SVC_MODE, r9 @ ensure svc mode
						@ and irqs disabled
	mrc	p15, 0, r9, c0, c0		@ get processor id			//获取处理器ID			r9 = cpuid
	bl	__lookup_processor_type		@ r5=procinfo r9=cpuid 	//处理器类型是否支持

	beq	__error_p			@ yes, error 'p'
	bl	__lookup_machine_type		@ r5=machinfo			//机器（板子）类型是否支持
	movs	r8, r5				@ invalid machine (r5=0)?							r8 = machinfo
	beq	__error_a			@ yes, error 'a'
	bl	__vet_atags				//确定r2 atags指针的有效性   无参数？？？

	//r8 = machinfo 
	//r9 = cpuid 
	//r10 = procinfo
	bl	__create_page_tables

	/*
	 * The following calls CPU specific code in a position independent
	 * manner.  See arch/arm/mm/proc-*.S for details.  r10 = base of
	 * xxx_proc_info structure selected by __lookup_machine_type
	 * above.  On return, the CPU will be ready for the MMU to be
	 * turned on, and r0 will hold the CPU control register value.
	 */
	ldr	r13, __switch_data		@ address to jump to after      r13 = __mmap_switched(虚拟地址)
						@ mmu has been enabled
	adr	lr, BSYM(__enable_mmu)		@ return (PIC) address
 ARM(	add	pc, r10, #PROCINFO_INITFUNC	)
 THUMB(	add	r12, r10, #PROCINFO_INITFUNC	)
 THUMB(	mov	pc, r12				)
ENDPROC(stext)

#if defined(CONFIG_SMP)
ENTRY(secondary_startup)
	/*
	 * Common entry point for secondary CPUs.
	 *
	 * Ensure that we're in SVC mode, and IRQs are disabled.  Lookup
	 * the processor type - there is no need to check the machine type
	 * as it has already been validated by the primary processor.
	 */
	setmode	PSR_F_BIT | PSR_I_BIT | SVC_MODE, r9
	mrc	p15, 0, r9, c0, c0		@ get processor id
	bl	__lookup_processor_type
	movs	r10, r5				@ invalid processor?
	moveq	r0, #'p'			@ yes, error 'p'
	beq	__error

	/*
	 * Use the page tables supplied from  __cpu_up.
	 */
	adr	r4, __secondary_data
	ldmia	r4, {r5, r7, r12}		@ address to jump to after
	sub	r4, r4, r5			@ mmu has been enabled
	ldr	r4, [r7, r4]			@ get secondary_data.pgdir
	adr	lr, BSYM(__enable_mmu)		@ return address
	mov	r13, r12			@ __secondary_switched address
 ARM(	add	pc, r10, #PROCINFO_INITFUNC	) @ initialise processor
						  @ (return control reg)
 THUMB(	add	r12, r10, #PROCINFO_INITFUNC	)
 THUMB(	mov	pc, r12				)
ENDPROC(secondary_startup)

	/*
	 * r6  = &secondary_data
	 */
ENTRY(__secondary_switched)
	ldr	sp, [r7, #4]			@ get secondary_data.stack
	mov	fp, #0
	b	secondary_start_kernel
ENDPROC(__secondary_switched)

	.type	__secondary_data, %object
__secondary_data:
	.long	.
	.long	secondary_data
	.long	__secondary_switched
#endif /* defined(CONFIG_SMP) */



/*
 * Setup common bits before finally enabling the MMU.  Essentially
 * this is just loading the page table pointer and domain access
 * registers.
 */
__enable_mmu:
#ifdef CONFIG_ALIGNMENT_TRAP
	orr	r0, r0, #CR_A			//执行
#else
	bic	r0, r0, #CR_A
#endif
#ifdef CONFIG_CPU_DCACHE_DISABLE
	bic	r0, r0, #CR_C			//未执行
#endif
#ifdef CONFIG_CPU_BPREDICT_DISABLE
	bic	r0, r0, #CR_Z			//未执行
#endif
#ifdef CONFIG_CPU_ICACHE_DISABLE
	bic	r0, r0, #CR_I			//未执行
#endif
	mov	r5, #(domain_val(DOMAIN_USER, DOMAIN_MANAGER) | \
		      domain_val(DOMAIN_KERNEL, DOMAIN_MANAGER) | \
		      domain_val(DOMAIN_TABLE, DOMAIN_MANAGER) | \
		      domain_val(DOMAIN_IO, DOMAIN_CLIENT))	

//MRC：协处理器寄存器到ARM处理器寄存器的数据传送指令(读出协处理器寄存器)。
//MCR：ARM处理器寄存器到协处理器寄存器的数据传送指令(写入协处理器寄存器)。

	//c3 DOMAIN ACCESS CONTROL REGISTER
	mcr	p15, 0, r5, c3, c0, 0		@ load domain access register
	//r4 = 30004000 放进协处理器c2
	mcr	p15, 0, r4, c2, c0, 0		@ load page table pointer

	b	__turn_mmu_on
ENDPROC(__enable_mmu)

/*
 * Enable the MMU.  This completely changes the structure of the visible
 * memory space.  You will not be able to trace execution through this.
 * If you have an enquiry about this, *please* check the linux-arm-kernel
 * mailing list archives BEFORE sending another post to the list.
 *
 *  r0  = cp#15 control register
 *  r13 = *virtual* address to jump to upon completion
 *
 * other registers depend on the function called upon completion
 */
	.align	5
__turn_mmu_on:
	mov	r0, r0
	mcr	p15, 0, r0, c1, c0, 0		@ write control reg
	mrc	p15, 0, r3, c0, c0, 0		@ read id reg
	mov	r3, r3
	mov	r3, r13
	mov	pc, r3
ENDPROC(__turn_mmu_on)


/*
 * Setup the initial page tables.  We only setup the barest
 * amount which are required to get the kernel running, which
 * generally means mapping in the kernel code.
 *
 * r8  = machinfo
 * r9  = cpuid
 * r10 = procinfo
 *
 * Returns:
 *  r0, r3, r6, r7 corrupted
 *  r4 = physical page table address
 */
 //创建页表
__create_page_tables:
/* 
*宏定义 *.macro pgtbl, rd *ldr \rd, =(KERNEL_RAM_PADDR - 0x4000) *.endm * 
*分析：内存为 4G = 4*1024 MB；需要4096个表单表示，每一页表单为4bytes；因此需要16K内存，即0x4000； 
*根据 =(KERNEL_RAM_PADDR - 0x4000)得，页表存放于-内核在内存中的物理地址之前。 
*/

//定义rgtbl 宏 功能是将KERNEL_RAM_PADDR - 0x4000复制给rd寄存器
	pgtbl	r4				@ page table address       //r4 = 30004000

	/*
	 * Clear the 16K level 1 swapper page table
	 */
	 /* * 按16个bytes一次，将页表清空 */
	mov	r0, r4		//r0 = 30004000
	mov	r3, #0		//r3 = 0
	add	r6, r0, #0x4000 //r6 = 30008000
	//将30004000-30008000 的空间置0
1:	str	r3, [r0], #4
	str	r3, [r0], #4
	str	r3, [r0], #4
	str	r3, [r0], #4
	teq	r0, r6
	bne	1b

/* *r10 = proc_info_list类型结构体的基地址 *PROCINFO_MM_MMUFLAGS 8 /* offsetof(struct proc_info_list, __cpu_mm_mmu_flags) @ */
	ldr	r7, [r10, #PROCINFO_MM_MMUFLAGS] @ mm_mmuflags   r7 = 00000C1E __cpu_mm_mmu_flags

	/*
	 * Create identity mapping for first MB of kernel to
	 * cater for the MMU enable.  This identity mapping
	 * will be removed by paging_init().  We use our current program
	 * counter to determine corresponding section base address.
	 */

	 /*
	 
	 为第一个MB内核创建标识映射，以满足MMU启用。 此标识映射将通过paging_init（）删除。 我们使用当前的程序计数器来确定相应的部分基址。

	 */

/* 
*下面代码建立kernel对应的section页表项。 * 
*1. 通过PC值的高12位(右移20位)，得到kernel的section，并存储在r6中。 
*2. 获取32bit的页表表单值 
*3. 将页表表单值存放在页表内存区中。 * 
*注意点： *a. lsr 20 因为虚拟地址分区中，后20位为相对地址，前12位为段地址 
*b. lsl 2 因为每一个页表项为4字节，所以需要左移2位 
*/

/*页表将4GB的地址空间分成若干个1MB的段(section)，因此页表包含4096个页表项(section entry)。
每个页表项是32bits(4 bytes)，因而页表占用4096*4=16k的内存空间。下面的代码是将这16k的页表清0。
*/

	mov	r6, pc   //r6= 3000xxxx 通过pc值的高12位(右移20位),得到kernel的section,并存储到r6中.因为当前是通过运行时地址得到的kernel的section,因而是物理地址. 
	mov	r6, r6, lsr #20			@ start of kernel section  r6 = 00000300
	orr	r3, r7, r6, lsl #20		@ flags + kernel base   r3 = 30000C1E = r7 | (r6 << 20); flags + kernel base,得到页表中需要设置的值. 
	str	r3, [r4, r6, lsl #2]		@ identity mapping  //设置页表: mem[r4 + r6 * 4] = r3   r4 = 30004000
														//         mem(30004000 + 300 << 2) = 30000C1E
														//         mem(30004000 + 300 * 4)  = 30000C1E
														//			mem(30004C00) = 30000C1E
														//这里,因为页表的每一项是32 bits(4 bytes),所以要乘以4(<<2). 

	/*
	 * Now setup the pagetables for our kernel direct
	 * mapped region.
	 */
/* 
* 下面的 add r0, r4, #(KERNEL_START & 0xff000000) >> 18 涉及到一个立即数的概念： 
* 关于arm汇编立即数，可以参考下面网站：http://blog.csdn.net/a99778800/article/details/6759825 * 
* 下面这段代码就是存储kernel物理地址。建立页表，虚拟地址和物理地址之间建立连接。 
* 即：将内核中所有的物理地址（1M为单位）都存放到了页表中，与虚拟地址一一对应。 */	 

//KERNEL_START = 0xC0008000
//这样分开写是由于arm的立即数只能是8位表示。
	add	r0, r4,  #(KERNEL_START & 0xff000000) >> 18     //r0 = 30007000 R4 =30004000
	str	r3, [r0, #(KERNEL_START & 0x00f00000) >> 18]!
	ldr	r6, =(KERNEL_END - 1)
	add	r0, r0, #4
	add	r6, r4, r6, lsr #18
1:	cmp	r0, r6
	add	r3, r3, #1 << 20
	strls	r3, [r0], #4
	bls	1b

/*
运行到此 段表在内存中如下：

J-Link>mem32 30007000 10
30007000 = 30000C1E 30100C1E 30200C1E 30300C1E 
30007010 = 30400C1E 00000000 00000000 00000000 
30007020 = 00000000 00000000 00000000 00000000 
30007030 = 00000000 00000000 00000000 00000000 
J-Link>h
PC: (R15) = 300080D8, CPSR = 200000D3 (SVC mode, ARM FIQ dis. IRQ dis.)
Current:
     R0 =30007014, R1 =000007CF, R2 =00000000, R3 =30500C1E
     R4 =30004000, R5 =00000000, R6 =30007013, R7 =00000C1E
     R8 =3001EF70, R9 =41129200, R10=3001EF3C, R11=00000020, R12=306EFD84
     R13=3049D990, R14=30008028, SPSR=00000010
USR: R8 =3001EF70, R9 =41129200, R10=3001EF3C, R11=00000020, R12=306EFD84
     R13=00000000, R14=00000000
FIQ: R8 =00000000, R9 =00000000, R10=00000000, R11=00000000, R12=00000000
     R13=00000000, R14=00000000, SPSR=00000010
IRQ: R13=00000000, R14=00000000, SPSR=00000010
SVC: R13=3049D990, R14=30008028, SPSR=00000010
ABT: R13=00000000, R14=00000000, SPSR=00000010
UND: R13=00000000, R14=00000000, SPSR=00000010


*/


/* 
* XIP介绍: 
* XIP是指 (EXECUTE IN PLACE) 是指直接从存放代码的位置上启动运行。 
* 非XIP方式是指在运行之前需对代码进行重定位。该类型的内核以非压缩方式存放在Flash中，启动时由Bootloader加载到内存后运行。 * 
* 如果是XIP技术的内核，上面的映射只能映射内核代码和只读数据部分 
* 这里我们再映射一些RAM来作为.data and .bss空间。 
*/

#ifdef CONFIG_XIP_KERNEL XIP 未定义
	/*
	 * Map some ram to cover our .data and .bss areas.
	 */
	orr	r3, r7, #(KERNEL_RAM_PADDR & 0xff000000)
	.if	(KERNEL_RAM_PADDR & 0x00f00000)
	orr	r3, r3, #(KERNEL_RAM_PADDR & 0x00f00000)
	.endif
	//这样分开写是由于arm的立即数只能是8位表示。
	add	r0, r4,  #(KERNEL_RAM_VADDR & 0xff000000) >> 18
	str	r3, [r0, #(KERNEL_RAM_VADDR & 0x00f00000) >> 18]!
	ldr	r6, =(_end - 1)
	add	r0, r0, #4
	add	r6, r4, r6, lsr #18
1:	cmp	r0, r6
	add	r3, r3, #1 << 20
	strls	r3, [r0], #4
	bls	1b
#endif

	/*
	 * Then map first 1MB of ram in case it contains our boot params.
	 * 然后映射第一个1MB的RAM，以防它包含我们的引导参数。
	 */
/* 
* 下面的代码用来设置RAM中大小为1M虚拟地址的页表。之所以要设置这个页表项的原因是该区域存储着boot params。 
* 因此需要为它建立map，这样开启MMU后就可以访问 
*/	 

//这样分开写是由于arm的立即数只能是8位表示。

/*
*下面的代码用来设置RAM中起始地址为0x30000000、大小为1M虚拟地址的页表，之所以要设置这个页表项的原因是该区域起始地址为0x30000100存
*储着boot params。因此需要为它建立map，这样开启MMU后就可以访问这些参数了。
*/
	add	r0, r4, #PAGE_OFFSET >> 18
	orr	r6, r7, #(PHYS_OFFSET & 0xff000000)
	.if	(PHYS_OFFSET & 0x00f00000)
	orr	r6, r6, #(PHYS_OFFSET & 0x00f00000)
	.endif
	str	r6, [r0]


#ifdef CONFIG_DEBUG_LL
	ldr	r7, [r10, #PROCINFO_IO_MMUFLAGS] @ io_mmuflags
	/*
	 * Map in IO space for serial debugging.
	 * This allows debug messages to be output
	 * via a serial console before paging_init.
	 */
	ldr	r3, [r8, #MACHINFO_PGOFFIO]
	add	r0, r4, r3
	rsb	r3, r3, #0x4000			@ PTRS_PER_PGD*sizeof(long)
	cmp	r3, #0x0800			@ limit to 512MB
	movhi	r3, #0x0800
	add	r6, r0, r3
	ldr	r3, [r8, #MACHINFO_PHYSIO]
	orr	r3, r3, r7
1:	str	r3, [r0], #4
	add	r3, r3, #1 << 20
	teq	r0, r6
	bne	1b
#if defined(CONFIG_ARCH_NETWINDER) || defined(CONFIG_ARCH_CATS)
	/*
	 * If we're using the NetWinder or CATS, we also need to map
	 * in the 16550-type serial port for the debug messages
	 */
	add	r0, r4, #0xff000000 >> 18
	orr	r3, r7, #0x7c000000
	str	r3, [r0]
#endif
#ifdef CONFIG_ARCH_RPC
	/*
	 * Map in screen at 0x02000000 & SCREEN2_BASE
	 * Similar reasons here - for debug.  This is
	 * only for Acorn RiscPC architectures.
	 */
	add	r0, r4, #0x02000000 >> 18
	orr	r3, r7, #0x02000000
	str	r3, [r0]
	add	r0, r4, #0xd8000000 >> 18
	str	r3, [r0]
#endif
#endif
	mov	pc, lr
ENDPROC(__create_page_tables)
	.ltorg

#include "head-common.S"
