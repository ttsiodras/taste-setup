#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/../taste-MSC/ || exit 1
make || exit 1
cp ./MSC-Antlr3/bin/msc2py.exe $HOME/.local/bin || exit 1
cp ./MSC-Antlr3/bin/taste-extract-asn-from-design.exe $HOME/.local/bin || exit 1
