#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Setup the tools in ~/.local/bin
cd $DIR/../dmt || exit 1

# Skip install if the version installed is the same and the tree is clean
HEAD="$(grep version= setup.py  | awk -F\" '{print $2}')"
VERSION_INSTALLED="$(dmt --version 2>/dev/null | grep ^TAST | awk '{print $NF}')"
git status >/dev/null
TREE_CLEAN=$?
if [ ${TREE_CLEAN} -eq 0 -a "${HEAD}" == "${VERSION_INSTALLED}" ] ; then
    echo DMT tree is clean and already installed. Skipping DMT install...
    exit 0
fi

# Unfortunately, the --upgrade DOES NOT ALWAYS WORK.
# Uninstall first...
echo y | pip3 uninstall  dmt

# ...then install the new version:
pip3 install --user --upgrade . || exit 1

# Add .local/bin to PATH
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
UpdatePATH
