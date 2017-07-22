#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Setup opengeode in ~/.local/bin
cd $DIR/../opengeode || exit 1

# Skip install if the version installed is the same and the tree is clean
HEAD="$(grep _version_ opengeode/opengeode.py | head -1 | awk -F\' '{print $2}')"

VERSION_INSTALLED="$(opengeode --version 2>&1)"
git status >/dev/null
TREE_CLEAN=$?
if [ ${TREE_CLEAN} -eq 0 -a "${HEAD}" == "${VERSION_INSTALLED}" ] ; then
    echo OpenGEODE tree is clean and already installed. Skipping OpenGEODE install...
    exit 0
fi

# Unfortunately, the --upgrade DOES NOT ALWAYS WORK.
# Uninstall first...
echo y | pip2 uninstall opengeode

pip2 install --user --upgrade . || exit 1

# Add .local/bin to PATH
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
UpdatePATH
