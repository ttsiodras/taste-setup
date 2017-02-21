#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/../opengeode || exit 1
pip install --user --upgrade . || exit 1

# Add .local/bin to PATH
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
grep "${PATH_CMD}" ${TASTE_PATHS} >/dev/null || echo "${PATH_CMD}" >> ${TASTE_PATHS}
