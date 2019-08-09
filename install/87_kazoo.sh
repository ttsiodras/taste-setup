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

# Sadly, AdaCore has not responded to our pull request:
#    https://github.com/AdaCore/templates-parser/pull/21
#
# To avoid false notification of "dirty" git status,
# clean up their mess in the "templates-parser" after their build
rm "${DIR}/../kazoo/templates-parser/tp_xmlada.gpr"

# Add kazoo binary to the PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/share/kazoo"
UpdatePATH
