@prompt=$G
@echo  Cathy 2K bootloader make                          by Mr. Blinky April-May 2018 
@echo ________________________________________________________________________________

@rem Arduboy bootloaders
call :make arduboy2k-bootloader "-DARDUBOY -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy2k-bootloader-devkit "-DARDUBOY -DARDUBOY_DEVKIT -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy2k-bootloader-micro "-DARDUBOY -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
call :make arduboy2k-bootloader-promicro "-DARDUBOY -DARDUBOY_PROMICRO -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"

@rem Arduino bootloaders
call :make cathy2k-leonardo "-DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make cathy2k-micro "-DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
call :make cathy2k-esplora "-DDEVICE_VID=0x2341 -DDEVICE_PID=0x003C"
@pause
@exit

:make
@echo ________________________________________________________________________________
avr-gcc -c -mmcu=atmega32u4 -I. -x assembler-with-cpp -o %1.o cathy2k.asm %~2
avr-ld -T %AVR32_HOME%\avr\lib\ldscripts\avr5.x -Ttext=0x7800 -Tdata=0x800100 --section-start=.bootsignature=0x7ffc -o %1.elf %1.o
@rem avr-objdump -D %1.elf > %1.bin.asm
@rem avr-objcopy -O binary %1.elf %1.bin --gap-fill=0xff
avr-objcopy -O ihex %1.elf hexfiles\%1.hex
@del %1.o
@del %1.elf
@exit /b