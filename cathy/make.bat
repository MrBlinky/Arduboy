@prompt=$G
@echo  Cathy 3K bootloader make                          by Mr. Blinky October 2017 
@echo ________________________________________________________________________________

@rem Arduboy bootloaders
call :make arduboy-bootloader "-DARDUBOY -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
@rem pause
@rem exit
call :make arduboy-bootloader-devkit "-DARDUBOY -DARDUBOY_DEVKIT -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy-bootloader-sh1106 "-DARDUBOY -DOLED_SH1106 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy-bootloader-micro "-DARDUBOY -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
call :make arduboy-bootloader-micro-sh1106 "-DARDUBOY -DOLED_SH1106 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
call :make arduboy-bootloader-promicro "-DARDUBOY -DARDUBOY_PROMICRO -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy-bootloader-promicro-sh1106 "-DARDUBOY -DARDUBOY_PROMICRO -DOLED_SH1106 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"

@rem Arduino bootloaders
call :make cathy3k-leonardo "-DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make cathy3k-micro "-DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
call :make cathy3k-esplora "-DDEVICE_VID=0x2341 -DDEVICE_PID=0x003C"
@pause
@exit

:make
@echo ________________________________________________________________________________
avr-gcc -c -mmcu=atmega32u4 -I. -x assembler-with-cpp -o %1.o cathy3k.asm %~2
avr-ld -T %AVR32_HOME%\avr\lib\ldscripts\avr5.x -Ttext=0x7400 -Tdata=0x800100 --section-start=.boot=0x7800 --section-start=.bootsignature=0x7ffe -o %1.elf %1.o
@rem avr-objdump -D %1.elf > %1.bin.asm
@rem avr-objcopy -O binary %1.elf %1.bin --gap-fill=0xff
avr-objcopy -O ihex %1.elf hexfiles\%1.hex
@del %1.o
@del %1.elf
@rem @for %%A in (%1.bin) do @echo Size of "%%A" is %%~zA bytes
@exit /b