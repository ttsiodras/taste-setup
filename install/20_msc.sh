#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Build MSC tools
cd $DIR/../taste-MSC/ || exit 1
make || exit 1

# Install them alongside ASN1SCC (they share DLLs)
cp ./MSC-Antlr3/bin/msc2py.exe ${PREFIX}/share/asn1scc/ || exit 1
cp ./MSC-Antlr3/bin/taste-extract-asn-from-design.exe ${PREFIX}/share/asn1scc/ || exit 1

# Install the MSC tracing-related tools (tracerd.py, etc) 
cd $DIR/../misc/AutoGUI || exit 1
TARGET=${PREFIX}/share/AutoGUI/
mkdir -p ${TARGET}
cp -a * ${TARGET}

# Update the path
PATH_CMD='export PATH=$PATH:$HOME/.local/bin'
UpdatePATH
