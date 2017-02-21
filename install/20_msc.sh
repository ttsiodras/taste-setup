#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASTE_PATHS=$HOME/.bashrc.taste

# Build MSC tools
cd $DIR/../taste-MSC/ || exit 1
make || exit 1
cp ./MSC-Antlr3/bin/msc2py.exe $HOME/.local/bin || exit 1
cp ./MSC-Antlr3/bin/taste-extract-asn-from-design.exe $HOME/.local/bin || exit 1

# Install them in .local/bin
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
grep "${PATH_CMD}" ${TASTE_PATHS} >/dev/null || echo "${PATH_CMD}" >> ${TASTE_PATHS}
