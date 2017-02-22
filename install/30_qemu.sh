#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Setup the tools in ${PREFIX}/bin
cd $DIR/../qemu-Leon3 || exit 1
cp -u qemu-Leon3/qemu-Leon3*.sh ${PREFIX}/bin/

# Add Leon simulators to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/bin"
UpdatePATH
