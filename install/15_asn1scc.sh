#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Fetch and install latest ASN1SCC release
mkdir -p ${PREFIX}/share/asn1scc/ || exit 1
cd ${PREFIX}/share/  || exit 1
ASN1SCC_BIN=$(which asn1.exe)
VER=$(mono ~/GitHub/asn1scc/Asn1f4/bin/Debug/a/asn1scc/asn1.exe -v | grep ^FullSemVer | awk '{print $NF}')
if [ "${VER}" != "3.3.10-ASN1SCC-V4.1+325" ] ; then
    wget -q -O - https://github.com/ttsiodras/asn1scc/releases/download/4.1a/asn1scc-bin-4.1a.tar.bz2 \
        | tar jxvf -
fi

# Add to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/share/asn1scc/"
UpdatePATH
