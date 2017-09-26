#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Install development tools to compile (pyside-rcc)
# Note: Opengeode does not need this, because they check in
# all temporary files into the repo. These have been ignored in
# mscedit2, therefore they need to be compiled explicitly.
sudo apt-get install -y pyside-tools || exit 1

cd $DIR/../mscedit2 || exit 1
make
pip2 install --user --upgrade . || exit 1

# Add .local/bin to PATH
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
UpdatePATH
