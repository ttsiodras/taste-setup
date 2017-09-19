#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "${DIR}/common.sh"

# Setup speedometer library in ~/.local
cd "$DIR/../speedometer" || exit 1

# Skip install if the version installed is the same and the tree is clean
HEAD="$(grep version speedometer/speedometer.py  | head -1 | awk -F\" '{print $(NF-1)}')"
# This is much slower than a --version option would be...
# But there's no such functionality in speedometer :-(
VERSION_INSTALLED="$(pip2 freeze | grep speedometer | awk -F= '{print $NF}')"
GIT_OUTPUT=$(git status --porcelain)
if [ "${GIT_OUTPUT}" == "" ] ; then
    TREE_DIRTY=0
else
    TREE_DIRTY=1
fi

if [ ${TREE_DIRTY} -eq 0 ] && [ "${HEAD}" == "${VERSION_INSTALLED}" ] ; then
    echo Speedometer tree is clean and already installed. Skipping Speedometer install...
    exit 0
fi

# Unfortunately, the --upgrade DOES NOT ALWAYS WORK.
# Uninstall first...
echo y | pip2 uninstall speedometer
pip2 install --user --upgrade . || exit 1

# Add .local/bin to PATH
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
UpdatePATH
