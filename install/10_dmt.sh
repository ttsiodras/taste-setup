#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASTE_PATHS=$HOME/.bashrc.taste

# Setup the tools in ~/.local/bin
cd $DIR/../dmt || exit 1
pip3 install --user --upgrade . || exit 1

# Add .local/bin to PATH
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
grep "${PATH_CMD}" ${TASTE_PATHS} >/dev/null || echo "${PATH_CMD}" >> ${TASTE_PATHS}
