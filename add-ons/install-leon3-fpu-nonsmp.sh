#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "${DIR}/common.sh"

InstallBSP \
    "a generic non-SMP Leon3 BSP, with support for FPU" \
    "https://download.tuxfamily.org/taste/RTEMS/leon3-fpu-nsmp.tar.bz2" \
    "/opt/rtems-4.12-2017.07.17/sparc-rtems4.12" \
    "leon3"
