#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Setup ANTL3 support in ~/.local/bin
cd $DIR/../antlr/antlr_python_runtime-3.1.3 || exit 1
pip2 freeze | grep antlr-python-runtime >/dev/null \
    || pip2 install --user --upgrade . || exit 1

# Add .local/bin to PATH
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
UpdatePATH
