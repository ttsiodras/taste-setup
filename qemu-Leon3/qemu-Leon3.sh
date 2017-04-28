#!/bin/bash
$HOME/tool-src/qemu-Leon3/qemu-system-sparc -no-reboot -nographic -M leon3_generic -m 64M -kernel "$@"
