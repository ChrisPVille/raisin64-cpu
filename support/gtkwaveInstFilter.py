#!/usr/bin/env python3

import sys
import tempfile
import binascii
import re
import io
import subprocess

while True:
    #Bleh, python tries to be too smart for its own good
    #Read up to a newline but no further because that's 
    #how data is passed to us from GTKWave, and it waits
    #until we return something before proceeding.
    inst = ''
    while True:
        ret = sys.stdin.read(1)
        if ret == "": sys.exit()
        elif ret != "\n": inst += ret
        else: break

    try:
        binBlob = binascii.a2b_hex(inst)
    except:
        binBlob = b""
    tf = tempfile.NamedTemporaryFile()
    tf.write(binBlob)
    tf.flush()

    try:
        proc = subprocess.Popen(["raisin64-elf-objdump", "--no-show-raw-insn", "-D", "-b", "binary", "-m", "raisin64", str(tf.name)], stdout=subprocess.PIPE)

        foundMatch = False

        for line in io.TextIOWrapper(proc.stdout):
            if line != "":
                if re.match("^ *0: *", line):
                    line = re.sub("^ *0:\s*", "", line)
                    line = re.sub("\t", " ", line)
                    foundMatch = True
                    print(line.rstrip())
                    break
            else:
                break

        if not foundMatch:
            print(inst)
    except Exception as e:
        print(str(e))
        continue

    sys.stdout.flush()
