#!/bin/bash
#
# This script builds the RTEMS/SPARC cross-compiler and the
# LEON2/GR712/GR740 BSPs.
#
# The call to sb-check below will stop the build if your environment
# is missing the necessary dependencies. Note that in addition to these,
# the build depends on GCC7 AND GNAT7 - otherwise the creation of the
# toolchain will fail.
#
# If you want to get a pre-made toolchain that was built by this script,
# you can download it in standalone form from:
#
#   http://download.tuxfamily.org/taste/RTEMS/rtems-4.12-2017.07.17.tar.bz2
#
# This compiler is also automatically installed in the TASTE VM 
# (available from https://taste.tuxfamily.org/ - navigate to the Download
# Area, and get the .ova file - which you then import in VirtualBox).
# Upon entering the VM, call Update-TASTE (as indicated in the help
# screen shown upon boot) and the RTEMS toolchain will be installed.


# Stop on any error
set -e

DATE=$(date +"%Y.%m.%d")
mkdir -p $HOME/rtems.build.logs
BUILD_LOG=$HOME/rtems.build.logs/${DATE}.log
[ -f ${BUILD_LOG} ] && {
    echo "There's already a build log:"
    echo "    " ${BUILD_LOG}
    echo Remove it to continue.
    exit 1
}

# Record the output in $BUILD_LOG (see matching brace)
{
    # Begin by checking out the RTEMS Source Builder

    RSBPARENT=$HOME/development/rtems/src
    mkdir -p $RSBPARENT
    RSB=$RSBPARENT/rtems-source-builder-${DATE}
    RTPREFIX=/opt/rtems-4.12-${DATE}
    rm -rf ${RTPREFIX}
    [ ! -d $RSB ] && {
        cd $RSBPARENT
        git clone https://github.com/RTEMS/rtems-source-builder.git rtems-source-builder-${DATE}
    }
    cd $RSB

    # What tag/branch to work on? By default this will be in the master branch,
    # but you can switch - to e.g. 4.11.2:
    #
    #     git checkout -f 4.11.2
    #
    # RSB commit ID recommended by Embedded Brains for using RTEMS/SMP:
    git checkout -f e2952bb185c1f40027caa76cfd9e4a45b17a8886

    # Verify that we have all we need to build
    source-builder/sb-check

    cd rtems

    # Your network firewall may or may not be an issue at this point:
    # Many of the source tarballs needed by the RSB are fetched over
    # PASV-enabled FTP servers.
    #
    # If your network is like the one in ESA/ESTEC and this is forbidden,
    # you'll have to fetch these tarballs and hardlink to them each time
    # (so no FTP action is triggered by the RTEMS RSB builder).
    # The sed invocation below also replaces ftp: with http:
    # (since this needs no PASV port meddling - which some firewalls object to)
    #
    # This is the way I do it - adapt it according to your needs:
    #
    # [ ! -d sources ] && {
    #     mkdir -p sources
    #     cd sources
    #     cp -al ~/development/rtems/pkg_sources_cache/* .
    #     cd ..
    #     for i in config/tools/*cfg ; do
    #         cat "$i" | sed 's,ftp://ftp.gnu.org,http://ftp.gnu.org,;s,ftp://gcc.gnu.org,http://gcc.gnu.org,;' > "$i".new && mv "$i".new "$i"
    #     done
    # }

    # Build the cross compiling toolchain
    # (we're in the master branch, which is currently the "unofficial" 4.12)
    ../source-builder/sb-set-builder --with-ada --log=stage1.log --prefix=${RTPREFIX} 4.12/rtems-sparc 

    # Add the cross compiler to the PATH and checkout RTEMS
    export PATH=${RTPREFIX}/bin:$PATH
    cd ..
    [ ! -d rtems-git ] && {
        git clone https://github.com/RTEMS/rtems.git rtems-git
        cd rtems-git

        # RTEMS commit ID recommended by Embedded Brains for using RTEMS/SMP
        git checkout -f 96ce1ec743a1fcf27593ee72cf1695d9eb0290de
        cd ..
    }

    # Build RTEMS
    cd rtems-git
    ./bootstrap
    cd ..
    rm -rf build.${DATE}
    mkdir build.${DATE}
    cd build.${DATE}
    ../rtems-git/configure \
        --target=sparc-rtems4.12 --prefix=${RTPREFIX} \
        --enable-rtemsbsp="leon2 leon3 ngmp" --enable-posix --enable-ada \
        --enable-smp --enable-cxx --enable-networking
    make all
    make install
} |& tee ${BUILD_LOG}
