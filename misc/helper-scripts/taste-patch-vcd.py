#!/usr/bin/env python3
import sys
import re
try:
    from typing import Tuple, List
except ImportError:
    print("mypy unavailable - typing module not found")

tasks = []  # type: List[Tuple[str, int]]
bEnum = False  # type: bool

'''
Extract from deployment.h (generated by Ocarina) the literal task names
in order to patch the VCD file with reference to the name of the tasks in
place of task_0,..task_i
'''

if(len(sys.argv) < 3 or not sys.argv[1].endswith("deployment.h")
   or not sys.argv[2].endswith('vcd')):
    print('usage: {} path/to/deployment.h path/to/file.vcd'
          .format(sys.argv[0]))
    sys.exit(1)

for line in open(sys.argv[1]):
    if line.strip().startswith('typedef enum'):
        bEnum = True
    elif line.strip().startswith('}') and bEnum:
        bEnum = False
        if line.strip() == "} __po_hi_task_id;":
            break
        else:
            tasks = []
    elif bEnum and not line.strip().startswith('{'):
        name, val = line.strip(", \n").split("=")
        if int(val) != -1:
            tasks.append((name.strip()[:-2], int(val)))

result = []  # type: List[str]
for line in open(sys.argv[2]):
    newline = line
    for name, val in tasks:
        newline = re.sub("task_" + str(val), name, newline)
    result.append(newline)

with open(sys.argv[2] + ".new", "w") as newfile:
    newfile.write(''.join(result))
