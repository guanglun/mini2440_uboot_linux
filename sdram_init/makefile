init_sdram.bin : init_sdram_elf
	arm-linux-objcopy -O binary -S init_sdram_elf init_sdram.bin
	arm-linux-objdump -D -m arm  init_sdram_elf > init_sdram.dis
 
init_sdram_elf : init.o
	arm-linux-ld -Ttext 0x00000000 -g  init.o  -o init_sdram_elf
 
init.o : init.S
	arm-linux-gcc -g -c -o init.o init.S
 
clean:
	rm -f   init_sdram.dis init_sdram.bin init_sdram_elf *.o
