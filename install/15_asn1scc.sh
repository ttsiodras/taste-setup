#!/bin/bash
TASTE_PATHS=$HOME/.bashrc.taste

# Fetch and install latest ASN1SCC release
mkdir -p $HOME/tool-inst/share/asn1scc/ || exit 1
cd $HOME/tool-inst/share/  || exit 1
wget -q -O - https://github.com/ttsiodras/asn1scc/releases/download/3.3.9/asn1scc-bin-3.3.9.tar.gz \
    | tar zxvf -

# Add ~/tool-inst/share/asn1scc/ to PATH
PATH_CMD='export PATH=$PATH:$HOME/tool-inst/share/asn1scc/'
grep "${PATH_CMD}" ${TASTE_PATHS} || echo "${PATH_CMD}" >> ${TASTE_PATHS}
