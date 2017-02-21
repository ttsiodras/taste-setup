#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Setup the tools in ~/.local/bin
cd $DIR/../ocarina || exit 1

# Skip Ocarina building if tree is clean and version is identical
HEAD="$(git log --oneline | head -1 | cut -d' ' -f1)"
VERSION_INSTALLED="$(ocarina -v 2>&1 | grep ^Oca | awk '{print $NF}' | sed 's,),,;s,r,,')"
git status >/dev/null
TREE_CLEAN=$?
if [ ${TREE_CLEAN} -eq 0 -a "${HEAD}" == "${VERSION_INSTALLED}" ] ; then
    echo Ocarina tree is clean and already installed. Skipping Ocarina build...
    exit 0
fi

make distclean # ignore any errors here
./support/reconfig || exit 1
./configure --prefix=${PREFIX} || exit 1
make || exit 1
make install

# Add Ocarina to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/bin"
UpdatePATH
