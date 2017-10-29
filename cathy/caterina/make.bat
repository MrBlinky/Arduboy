avr-gcc -c -mmcu=atmega32u4 -I. -x assembler-with-cpp Caterina-Leonardo-bootloader.asm
avr-ld -T %AVR32_HOME%\avr\lib\ldscripts\avr5.x -Ttext=0x7000 -Tdata=0x800100 -o Caterina-Leonardo-bootloader.elf Caterina-Leonardo-bootloader.o
@rem avr-objdump -D Caterina-Leonardo-bootloader.elf > Caterina-Leonardo-bootloader.bin.asm
@rem avr-objcopy -O binary Caterina-Leonardo-bootloader.elf Caterina-Leonardo-bootloader.bin
avr-objcopy -O ihex Caterina-Leonardo-bootloader.elf Caterina-Leonardo-bootloader.hex
@del Caterina-Leonardo-bootloader.o
@del Caterina-Leonardo-bootloader.elf
pause
