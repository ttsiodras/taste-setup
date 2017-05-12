#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Setup the stlink tools (if not there)
cd $DIR/../stlink || exit 1
make release || exit 1

STUTIL_PATH=$(realpath "${DIR}/ ../stlink/build/Release/src/gdbserver")
PATH_CMD='export PATH=$PATH:'"${STUTIL_PATH}"
UpdatePATH

STFLASH_PATH=$(realpath "${DIR}/ ../stlink/build/Release")
PATH_CMD='export PATH=$PATH:'"${STFLASH_PATH}"
UpdatePATH

