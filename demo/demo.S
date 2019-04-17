@ .section .bss
@ .global _word_bss
@ _word_bss:
@ .word	0x40000000
@ .section .data
@ _word_data:
@ .word	0x12345678

.section .text
.global _start
_start:     
@ .align	4
@      mov     r0,#0x01
@ .align	4
@.align	4
@      mov     r2,r1
@      mov     r4,r3
_word_text:
.word	0x12345678
    @ add     r4,r3
    @ add     r6,r5,#0x01
    @  mov     r1,r1,lsl #2
    @  mov     r1,r2,lsl #2
    @ lsl	    r1, r2, #2
    @mov     r0,#2
    @ldr     r1,[r0,#2]
    mov     r0,#1
    @ldr     r0,#0x1
    @ adr     r1,_loop
     @ldr     r1,=_word_bss
     @str     r0,[r1]
    @ b       _word_test
 _loop:

     b       _loop
