#!/bin/sh
openocd -f "raisin64_nodeps_openocd.cfg" -c "init; raisin64_program \"`readlink -f "$1"`\" \"`readlink -f "$2"`\"; exit"
