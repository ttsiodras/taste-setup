#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh


# Setup the tools in ~/.local/bin
cd $DIR/../msc-editor || exit 1

# Skip install if the version installed is the same and the tree is clean
HEAD="$(grep __version msce/msce.py  | head -1 | awk -F\' '{print $(NF-1)}')"
# This is much slower than a --version option would be...
# But there's no such functionality in msc-editor :-(
VERSION_INSTALLED="$(pip2 freeze | grep msce | awk -F= '{print $NF}')"

git status >/dev/null
TREE_CLEAN=$?
if [ ${TREE_CLEAN} -eq 0 -a "${HEAD}" == "${VERSION_INSTALLED}" ] ; then
    echo MSC editor tree is clean and already installed. Skipping MSCE install...
    exit 0
fi

# Unfortunately, the --upgrade DOES NOT ALWAYS WORK.
# Uninstall first...
echo y | pip2 uninstall msce
pip2 install --user --upgrade . || exit 1

# Add .local/bin to PATH
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
UpdatePATH
