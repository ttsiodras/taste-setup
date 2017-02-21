#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Setup the tools in ~/.local/bin
cd $DIR/../ocarina || exit 1
make distclean # ignore any errors here
./support/reconfig || exit 1
./configure --prefix=${PREFIX} || exit 1
make || exit 1
make install

# Add Ocarina to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/bin"
UpdatePATH
