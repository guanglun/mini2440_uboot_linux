fled.S : led.bin
	arm-linux-objdump -D -b binary -m arm led.bin > fled.S

led.bin : led_elf
	arm-linux-objcopy -O binary -S led_elf led.bin
	arm-linux-objdump -D -m arm  led_elf > led.dis
 	
led_elf : led.o
	arm-linux-ld -Tled.lds -g  led.o  -o led_elf
 
led.o : led.S
	arm-linux-gcc -g -c -o led.o led.S
 
clean:
	rm -f   led.dis led.bin led_elf *.o
