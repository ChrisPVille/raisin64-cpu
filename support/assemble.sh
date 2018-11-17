#!/bin/sh
export RAISIN64_BINUTILS=/tmp/staging/bin
export RAISIN64_CROSS=raisin64-elf
$RAISIN64_BINUTILS/$RAISIN64_CROSS-as $1 -o prog.elf &&
$RAISIN64_BINUTILS/$RAISIN64_CROSS-objdump -s -j .data prog.elf &&
$RAISIN64_BINUTILS/$RAISIN64_CROSS-objdump -d -j .text prog.elf &&
$RAISIN64_BINUTILS/$RAISIN64_CROSS-objcopy -O binary -j .text prog.elf imem.bin &&
$RAISIN64_BINUTILS/$RAISIN64_CROSS-objcopy -O binary -j .data prog.elf dmem.bin &&
xxd -c 1 -ps imem.bin > imem.hex &&
xxd -c 1 -ps dmem.bin > dmem.hex
