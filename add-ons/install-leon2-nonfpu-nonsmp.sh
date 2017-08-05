#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "${DIR}/common.sh"

InstallBSP \
    "a generic non-SMP Leon2 BSP, without support for native FPU" \
    "https://download.tuxfamily.org/taste/RTEMS/leon2-nfpu-nsmp.tar.bz2" \
    "/opt/rtems-4.12-2017.07.17/sparc-rtems4.12" \
    "leon2"
