#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Install the scripts
cd ${DIR} || exit 1

cd .. || exit 1

make -C upython-taste/mpy-cross/
