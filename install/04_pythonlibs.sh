#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

pip install --user --upgrade singledispatch || exit 1
pip install --user --upgrade stringtemplate3 || exit 1
