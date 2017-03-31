#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

pip freeze | grep singledispatch >/dev/null \
    || pip install --user --upgrade singledispatch || exit 1
pip freeze | grep stringtemplate3 >/dev/null \
    || pip install --user --upgrade stringtemplate3 || exit 1
pip freeze | grep enum34 >/dev/null \
    || pip install --user --upgrade enum34 || exit 1
