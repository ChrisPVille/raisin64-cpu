#!/bin/sh
openocd -f "raisin64_nodeps_openocd.cfg" -c "init; raisin64_halt; exit"
