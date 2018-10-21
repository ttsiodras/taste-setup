#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Fetch and install latest AdaCore ARM release
SIG=$(/usr/gnat/bin/arm-eabi-gcc -v 2>&1 | tail -1)
if [ "${SIG}" != "gcc version 6.3.1 20170510 (for GNAT GPL 2017 20170515) (GCC) " ] ; then
    cd /opt/ || exit 1
    sudo wget http://mirrors.cdn.adacore.com/art/591c6413c7a447af2deed0e3 || {
        echo "Failed to download AdaCore's ARM toolchain. Aborting..."
        exit 1
    }
    sudo tar zxvf 591c6413c7a447af2deed0e3 || {
        echo "AdaCore's ARM tarball failed to decompress properly. Aborting..."
        exit 1
    }
    sudo rm 591c6413c7a447af2deed0e3
    cd gnat-gpl-2017-arm-elf-linux-bin/ || {
        echo "AdaCore's ARM tarball structure has changed. Aborting..."
        exit 1
    }
    echo -en '\n\nY\nY\n' | sudo ./doinstall
    sudo rm -rf gnat-gpl-2017-arm-elf-linux-bin
fi

# Add to PATH
PATH_CMD='export PATH=$PATH:'"/usr/gnat/bin"
UpdatePATH
