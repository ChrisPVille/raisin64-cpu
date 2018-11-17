#!/bin/zsh
iverilog -o $1.vpp $1 ../rtl/**/*.v -I../rtl/include &&
./$1.vpp
rm -f $1.vpp
