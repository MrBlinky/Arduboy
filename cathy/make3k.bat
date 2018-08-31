@prompt=$G
@echo  Cathy 3K bootloader make                      by Mr. Blinky Oct 2017 - Jul 2018
@echo ________________________________________________________________________________

@rem Arduboy bootloaders
call :make arduboy3k-bootloader "-DARDUBOY -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-devkit "-DARDUBOY -DARDUBOY_DEVKIT -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-sh1106 "-DARDUBOY -DOLED_SH1106 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-ssd132x-96x96 "-DARDUBOY -DOLED_SSD132X_96X96 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-ssd132x-128x96 "-DARDUBOY -DOLED_SSD132X_128X96 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-ssd132x-128x128 "-DARDUBOY -DOLED_SSD132X_128X128 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-micro "-DARDUBOY -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
call :make arduboy3k-bootloader-micro-sh1106 "-DARDUBOY -DOLED_SH1106 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
call :make arduboy3k-bootloader-micro-ssd132x-96x96 "-DARDUBOY -DOLED_SSD132X_96X96 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
call :make arduboy3k-bootloader-micro-ssd132x-128x96 "-DARDUBOY -DOLED_SSD132X_128X96 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
call :make arduboy3k-bootloader-micro-ssd132x-128x128 "-DARDUBOY -DOLED_SSD132X_128X128 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
call :make arduboy3k-bootloader-promicro "-DARDUBOY -DARDUBOY_PROMICRO -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-promicro-sh1106 "-DARDUBOY -DARDUBOY_PROMICRO -DOLED_SH1106 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-promicro-ssd132x-96x96 "-DARDUBOY -DARDUBOY_PROMICRO -DOLED_SSD132X_96X96 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-promicro-ssd132x-128x96 "-DARDUBOY -DARDUBOY_PROMICRO -DOLED_SSD132X_128X96 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-promicro-ssd132x-128x128 "-DARDUBOY -DARDUBOY_PROMICRO -DOLED_SSD132X_128X128 -DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-st7565 "-DARDUBOY -DDEVICE_VID=0x2341 -DLCD_ST7565 -DDEVICE_PID=0x0036"
call :make arduboy3k-bootloader-micro-st7565 "-DARDUBOY -DDEVICE_VID=0x2341 -DLCD_ST7565 -DDEVICE_PID=0x0037"
call :make arduboy3k-bootloader-promicro-st7565 "-DARDUBOY -DARDUBOY_PROMICRO -DDEVICE_VID=0x2341 -DLCD_ST7565 -DDEVICE_PID=0x0036"

@rem Arduino bootloaders (obselete due to cathy2k)
@rem call :make cathy3k-leonardo "-DDEVICE_VID=0x2341 -DDEVICE_PID=0x0036"
@rem call :make cathy3k-micro "-DDEVICE_VID=0x2341 -DDEVICE_PID=0x0037"
@rem call :make cathy3k-esplora "-DDEVICE_VID=0x2341 -DDEVICE_PID=0x003C"
@pause
@exit

:make
@echo ________________________________________________________________________________
avr-gcc -c -mmcu=atmega32u4 -I. -x assembler-with-cpp -o %1.o cathy3k.asm %~2
avr-ld -T %AVR32_HOME%\avr\lib\ldscripts\avr5.x -Ttext=0x7400 -Tdata=0x800100 --section-start=.boot=0x7800 --section-start=.bootsignature=0x7ffc -o %1.elf %1.o
@rem avr-objdump -D %1.elf > %1.bin.asm
@rem avr-objcopy -O binary %1.elf %1.bin --gap-fill=0xff
avr-objcopy -O ihex %1.elf cathy3k\%1.hex
@del %1.o
@del %1.elf
@rem @for %%A in (%1.bin) do @echo Size of "%%A" is %%~zA bytes
@exit /b