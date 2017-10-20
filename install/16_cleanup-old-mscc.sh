#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

cd $DIR/../ || exit 1
[ -d mscc ] && rm -rf mscc
[ -d mscedit2 ] && rm -rf mscedit2

exit 0
