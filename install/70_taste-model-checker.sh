#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Install model checker
cd $DIR/../taste-model-checker || exit 1
make install || exit 1
make clean || exit 1

# Update PATH - to where?
