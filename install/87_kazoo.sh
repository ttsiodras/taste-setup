#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

cd "$DIR"/../kazoo || exit 1
git submodule init
git submodule update

make || exit 1

mkdir -p ${PREFIX}/share/kazoo || exit 1
cp -a kazoo ${PREFIX}/share/kazoo || exit 1
cp -a ../kazoo/templates ${PREFIX}/share/kazoo || exit 1

# Add kazoo binary to the PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/share/kazoo"
UpdatePATH
