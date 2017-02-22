#!/bin/bash
echo "Use sparc-rtems4.11-gdb to connect via 'tar extended-remote :9976'"
/home/assert/tool-src/misc/qemu-Leon3/qemu-system-sparc -no-reboot -nographic -M leon3_generic -m 64M -kernel "$@" -gdb tcp::9976 -S
