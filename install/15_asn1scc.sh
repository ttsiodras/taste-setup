#!/bin/bash
mkdir -p $HOME/tool-inst/share/asn1scc/ || exit 1
cd $HOME/tool-inst/share/asn1scc/  || exit 1
wget -q -O - https://github.com/ttsiodras/asn1scc/releases/download/3.3.9/asn1scc-bin-3.3.9.tar.gz \
    | tar zxvf -
