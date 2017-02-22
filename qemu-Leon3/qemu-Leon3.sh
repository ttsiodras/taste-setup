#!/bin/bash
/home/assert/tool-src/misc/qemu-Leon3/qemu-system-sparc -no-reboot -nographic -M leon3_generic -m 64M -kernel "$@"
