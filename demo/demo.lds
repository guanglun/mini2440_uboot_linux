OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)
SECTIONS
{
	. = 0x00000000;
    .text :   { *(.text) }
    . = 0x00004000;
    .data :   { *(.data) }
    . = 0x00008000;
    .bss  :   { *(.bss)  }
}