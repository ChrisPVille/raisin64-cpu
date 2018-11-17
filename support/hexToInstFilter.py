#!/usr/bin/env python3

import sys
import tempfile
import binascii
import re
import io
import subprocess

binBlob = binascii.a2b_hex(sys.argv[1])
tf = tempfile.NamedTemporaryFile()
tf.write(binBlob)
tf.flush()

proc = subprocess.Popen(["raisin64-elf-objdump", "--no-show-raw-insn", "-D", "-b", "binary", "-m", "raisin64", str(tf.name)], stdout=subprocess.PIPE)

for line in io.TextIOWrapper(proc.stdout):
    if line != "":
        if re.match("^ *0: *", line):
            line = re.sub("^ *0:\s*", "", line)
            line = re.sub("\t", " ", line)
            print(line.rstrip())
            break
    else:
        break
