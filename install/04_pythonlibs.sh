#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

cd ${DIR}
pip2 freeze > allPyPackages.txt

for LIB in numpy singledispatch stringtemplate3 enum34 'ply==3.4' ; do
    echo "Upgrading ${LIB}..."
    grep "${LIB}" allPyPackages.txt >/dev/null \
        || pip2 install --user --upgrade "${LIB}" || {
        rm -f allPyPackages.txt
        exit 1
    }
done

rm -f allPyPackages.txt
