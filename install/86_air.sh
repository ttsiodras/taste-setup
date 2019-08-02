#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

cd "$DIR"/../air || exit 1
git submodule init
git submodule update air/pos/rtems5

cd air || exit 1

# Pass the following configuration to AIR's "configure" script:
#
# Select the target architecture:
# * [0]: sparc
# Select the target board support package:
# * [0]: leon3_or_tsim2
#   [1]: tsim
#   [2]: leon4
# Select if FPU is:
# * [0]: Enabled
#   [1]: Disabled
# Select debug monitor:
# * [0]: GRMON
#   [1]: DMON
# Install All RTOS ?
# * [0]: No
#   [1]: Yes
# Install posixrtems5?
#   [0]: No
# * [1]: Yes
# Install rtems48i?
# * [0]: No
#   [1]: Yes
# Install rtems5?
#   [0]: No
# * [1]: Yes
# Install bare?
# * [0]: No
#   [1]: Yes
#
# Sadly, air's "configure" doesn't show these options in the same order;
# e.g. under a 32bit VM the order is different to that under a 64bit VM!
#
# So we can't do this..
# echo -e "0\n0\n0\n0\n0\n1\n0\n1\n0\n\n" | ./configure
# 
# Instead, we do this - which is arguably a hack:
../../install/air.expect || exit 1
make || exit 1

# Add to PATH
AIR_REAL_PATH="$(realpath $(pwd))"
PATH_CMD='export PATH=$PATH:"'"${AIR_REAL_PATH}"'"'
UpdatePATH

PATH_CMD='export AIR="'"${AIR_REAL_PATH}"'"'
UpdatePATH
