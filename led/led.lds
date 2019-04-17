OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm","elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)
SECTIONS
{
. = 0×10000;
.text :     { *(.text) }
. = 0×8000000;
.data :   { *(.data) }
.bss :     { *(.bss) }
}