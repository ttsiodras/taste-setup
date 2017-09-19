#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Fetch and install latest ASN1SCC release
mkdir -p ${PREFIX}/share/asn1scc/ || exit 1
cd ${PREFIX}/share/  || exit 1
ASN1SCC_BIN=$(which asn1.exe)
VER=$(mono $ASN1SCC_BIN 2>&1 | grep '^Current' | awk '{print $NF}')
if [ "${VER}" != "3.3.21" ] ; then
    wget -q -O - https://github.com/ttsiodras/asn1scc/releases/download/3.3.21/asn1scc-bin-3.3.21.tar.bz2 \
        | tar jxvf -
fi

# Add to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/share/asn1scc/"
UpdatePATH
