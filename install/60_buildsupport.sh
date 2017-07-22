#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Setup the tools in ~/.local/bin
cd $DIR/../buildsupport || exit 1

# Skip Ocarina building if tree is clean and version is identical
HEAD="$(git log --oneline | head -1 | cut -d' ' -f1)"
VERSION_INSTALLED="$(buildsupport -v 2>&1 | grep Version | cut -f 4 -d' ' | tr -d '\012')"
git status >/dev/null
TREE_CLEAN=$?
if [ ${TREE_CLEAN} -eq 0 -a "${HEAD}" == "${VERSION_INSTALLED}" ] ; then
    echo Buildsupport tree is clean and already installed. Skipping Buildsupport build...
    exit 0
fi

make clean # ignore any errors here
make || exit 1
cp buildsupport ${PREFIX}/bin || exit 1

# Add Ocarina to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/bin"
UpdatePATH
