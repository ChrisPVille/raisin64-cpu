#!/bin/sh
raisin64-elf-as $1 -o prog.elf &&
raisin64-elf-objdump -s -j .data prog.elf &&
raisin64-elf-objdump -d -j .text prog.elf &&
raisin64-elf-objcopy -O binary -j .text prog.elf imem.bin &&
raisin64-elf-objcopy -O binary -j .data prog.elf dmem.bin &&
xxd -c 8 -ps imem.bin > imem.hex &&
xxd -c 8 -ps dmem.bin > dmem.hex
