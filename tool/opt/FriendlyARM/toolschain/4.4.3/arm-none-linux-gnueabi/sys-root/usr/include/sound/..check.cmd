cmd_/opt/FriendlyARM/toolschain/4.4.3/arm-none-linux-gnueabi//sys-root/usr/include/sound/.check := for f in asequencer.h asound.h asound_fm.h emu10k1.h hdsp.h hdspm.h sb16_csp.h sfnt_info.h sscape_ioctl.h ; do echo "/opt/FriendlyARM/toolschain/4.4.3/arm-none-linux-gnueabi//sys-root/usr/include/sound/$${f}"; done | xargs perl /opt/FriendlyARM/mini2440/build-toolschain/working/src/linux-2.6.32.2/scripts/headers_check.pl /opt/FriendlyARM/toolschain/4.4.3/arm-none-linux-gnueabi//sys-root/usr/include arm; touch /opt/FriendlyARM/toolschain/4.4.3/arm-none-linux-gnueabi//sys-root/usr/include/sound/.check
