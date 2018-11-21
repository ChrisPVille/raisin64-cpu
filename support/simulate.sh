#!/bin/zsh
iverilog -Wall -Winfloop -Wno-timescale -Wno-implicit-dimensions -o $1.vpp $1 ../rtl/**/*.v -I../rtl/include &&
vvp $1.vpp -fst
rm -f $1.vpp
