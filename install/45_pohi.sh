#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Setup the tools in ~/.local/bin
cd $DIR/../polyorb-hi-c || exit 1
make distclean # ignore any errors here
./support/reconfig || exit 1
PATH=${PREFIX}/bin:${PATH} ./configure || exit 1
make || exit 1
make install

# Add POHI to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/bin"
UpdatePATH
