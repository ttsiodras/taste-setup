#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

pip2 freeze | grep singledispatch >/dev/null \
    || pip2 install --user --upgrade singledispatch || exit 1
pip2 freeze | grep stringtemplate3 >/dev/null \
    || pip2 install --user --upgrade stringtemplate3 || exit 1
pip2 freeze | grep enum34 >/dev/null \
    || pip2 install --user --upgrade enum34 || exit 1
