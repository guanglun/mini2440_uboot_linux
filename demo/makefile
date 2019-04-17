demo.bin : demo.S
	echo $(CURDIR)
	arm-linux-gcc -g -c -o demo.o demo.S
	arm-linux-ld  -g -Tdemo.lds demo.o  -o demo_elf
	arm-linux-objcopy -g -O binary -S demo_elf demo.bin
	arm-linux-objdump -D demo_elf > dis_file 
	arm-linux-objdump -D -b binary -m arm demo.bin > objdump
clean:
	rm -f   demo.bin demo_elf *. 

