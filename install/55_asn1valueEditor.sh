#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Setup asn1valueEditor in ~/.local/bin
cd $DIR/../asn1-value-editor || exit 1

# Skip install if the version installed is the same and the tree is clean
HEAD="$(grep __version asn1_value_editor/asn1_value_editor.py  | head -1 | awk -F\" '{print $(NF-1);}')"

VERSION_INSTALLED="$(taste-gui --version 2>&1 | head -1 | awk '{print $NF}')"
git status >/dev/null
TREE_CLEAN=$?
if [ ${TREE_CLEAN} -eq 0 -a "${HEAD}" == "${VERSION_INSTALLED}" ] ; then
    echo ASN.1 Value Editor tree is clean and already installed. Skipping asn1valueEditor install...
    exit 0
fi

# Unfortunately, the --upgrade DOES NOT ALWAYS WORK.
# Uninstall first...
echo y | pip2 uninstall asn1-value-editor
pip2 install --user --upgrade . || exit 1

# Add .local/bin to PATH
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
UpdatePATH
