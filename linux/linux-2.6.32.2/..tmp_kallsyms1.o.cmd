cmd_.tmp_kallsyms1.o := arm-linux-gcc -Wp,-MD,./..tmp_kallsyms1.o.d -D__ASSEMBLY__ -mabi=aapcs-linux -mno-thumb-interwork  -D__LINUX_ARM_ARCH__=4 -march=armv4t -mtune=arm9tdmi -include asm/unified.h -msoft-float   -nostdinc -isystem /home/guanglun/work/mini2440_uboot_linux/4.4.3/bin/../lib/gcc/arm-none-linux-gnueabi/4.4.3/include -Iinclude  -I/home/guanglun/work/mini2440_uboot_linux_github/linux/linux-2.6.32.2/arch/arm/include -include include/linux/autoconf.h -D__KERNEL__ -mlittle-endian -Iarch/arm/mach-s3c2410/include -Iarch/arm/mach-s3c2400/include -Iarch/arm/mach-s3c2412/include -Iarch/arm/mach-s3c2440/include -Iarch/arm/mach-s3c2442/include -Iarch/arm/mach-s3c2443/include -Iarch/arm/plat-s3c24xx/include -Iarch/arm/plat-s3c/include    -c -o .tmp_kallsyms1.o .tmp_kallsyms1.S

deps_.tmp_kallsyms1.o := \
  .tmp_kallsyms1.S \
  /home/guanglun/work/mini2440_uboot_linux_github/linux/linux-2.6.32.2/arch/arm/include/asm/unified.h \
    $(wildcard include/config/arm/asm/unified.h) \
    $(wildcard include/config/thumb2/kernel.h) \
  /home/guanglun/work/mini2440_uboot_linux_github/linux/linux-2.6.32.2/arch/arm/include/asm/types.h \
  include/asm-generic/int-ll64.h \
  /home/guanglun/work/mini2440_uboot_linux_github/linux/linux-2.6.32.2/arch/arm/include/asm/bitsperlong.h \
  include/asm-generic/bitsperlong.h \
    $(wildcard include/config/64bit.h) \

.tmp_kallsyms1.o: $(deps_.tmp_kallsyms1.o)

$(deps_.tmp_kallsyms1.o):
