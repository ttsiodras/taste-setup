#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Fetch and install latest ASN1SCC release
mkdir -p ${PREFIX}/share/asn1scc/ || exit 1
cd ${PREFIX}/share/  || exit 1
ASN1SCC_BIN=$(which asn1.exe)
VER=$(mono ~/tool-inst/share/asn1scc/asn1.exe -v | grep ^FullSemVer | awk '{print $NF}')
if [ "${VER}" != "3.3.10-ASN1SCC-V4.1+389" ] ; then
    wget -q -O - https://github.com/ttsiodras/asn1scc/releases/download/4.1e/asn1scc-bin-4.1e.tar.bz2 \
        | tar jxvf -
fi

# Add to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/share/asn1scc/"
UpdatePATH
