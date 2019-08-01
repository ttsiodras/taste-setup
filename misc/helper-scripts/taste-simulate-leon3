#!/bin/bash

# Use the recent functionality introduced by Jiri Gaisler...
#
#   https://lists.rtems.org/pipermail/devel/2019-February/024794.html
#
# ...to simulate a 4-core Leon3 SMP machine.
#
if [ $# -ne 1 ] ; then
    echo Usage: $0 sparc_ELF_binary
    exit 1
fi
echo -en "tar sim -leon3 -m 4\nload \"$@\"\nrun\nquit\n" | \
    /opt/rtems-5.1-2019.07.25/bin/sparc-rtems5-gdb "$@"
