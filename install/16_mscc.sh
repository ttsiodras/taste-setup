#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Install tools necesarry for Mscc compilation
sudo apt install -y mono-devel mono-xbuild

# Compile Mscc
pushd "${DIR}/../mscc" >/dev/null
git submodule update --init
make release

# Move binaries to the installation folder
mkdir -p ${PREFIX}/share/mscc/ || exit 1
mv bin/Release/* "${PREFIX}/share/mscc/"
popd >/dev/null

cd ${PREFIX}/share/  || exit 1

# Add to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/share/mscc/"
UpdatePATH
