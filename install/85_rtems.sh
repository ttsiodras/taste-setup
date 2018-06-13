#!/bin/bash
TIMESTAMP="$(stat /opt/rtems-5.1-2018.03.08 2>/dev/null | grep ^Modify | cut -c1-18)"
if [ "${TIMESTAMP}" != "Modify: 2018-06-05" ] ; then
    echo "Installing the latest RTEMS cross-compiler..."
    cd /opt || exit 1
    NEW_COMPILER_TARBALL=/tmp/newCompiler.$$.tar.gz
    if wget -O $NEW_COMPILER_TARBALL "https://download.tuxfamily.org/taste/RTEMS/rtems-5.1-2018.03.08.tar.bz2" ; then
        sudo tar zxvf $NEW_COMPILER_TARBALL || {
            echo Failed to extract $NEW_COMPILER_TARBALL...
            ls -l $NEW_COMPILER_TARBALL
            echo Aborting.
            exit 1
        }
        rm -f $NEW_COMPILER_TARBALL
        NEWBIN=/opt/rtems-5.1-2018.03.08/bin
        if ! grep "^export PATH=.*$NEWBIN" $HOME/.bashrc.taste ; then
            echo Adding new compiler "$NEWBIN" to PATH...
            echo "export PATH=$NEWBIN:\$PATH" >> "$HOME/.bashrc.taste"
        fi
    else
        echo Failed to download the new compiler... Aborting.
        exit 1
    fi
fi

# Remove obsolete "hack" around test-era compiler
sudo rm -f /opt/rtems-4.11.2-SMP-FPU-2017.07.13 2>/dev/null

# DEPRECATED: The QEMU for SPARC doesn't support SMP - at least not yet.
# For Dockerfiles and chroots, the LEON3 simulator depends on these i386 libraries
# ARCH=$(uname -m)
# if [ "${ARCH}" == "x86_64" ] ; then
#     sudo apt-get install -y --force-yes libcurl3-gnutls:i386 libbz2-1.0:i386 libncurses5:i386 libglib2.0-0:i386
# fi
