#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

cd $DIR/../asn1-value-editor || exit 1
pip install --user --upgrade . || exit 1

# Add .local/bin to PATH
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
UpdatePATH
