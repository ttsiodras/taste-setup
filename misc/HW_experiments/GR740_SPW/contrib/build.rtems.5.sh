#!/bin/bash
#
# This script builds the RTEMS/SPARC cross-compiler and the
# Leon2/Leon3/NGMP BSPs.
#
# To have a reproducible setup, it would be prudent if you
# executed this script under a Debian stretch chroot,
# bootstrapped via the following:
#
#     mkdir /opt/stretch-chroot
#     debootstrap stretch /opt/stretch-chroot
#     mount -t proc none /opt/stretch-chroot/proc/
#     mount -t sysfs none /opt/stretch-chroot/sys/
#     mount -o bind /dev /opt/stretch-chroot/dev/
#     mount -o bind /dev/pts /opt/stretch-chroot/dev/pts/
#     chroot /opt/stretch-chroot
#     apt-get update
#     apt-get install flex bison make texinfo binutils gcc g++ gdb unzip git python2.7-dev pax libncurses5-dev
#
# Then chroot inside it and run this script:
#
#     chroot /opt/stretch-chroot
#     /path/to/build.rtems.MORA.sh


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
    RTPREFIX=/opt/rtems-5.1-${DATE}
    # rm -rf ${RTPREFIX}
    [ ! -d $RSB ] && {
        cd $RSBPARENT
        git clone https://github.com/RTEMS/rtems-source-builder.git rtems-source-builder-${DATE}
    }
    cd $RSB
    git checkout -f 703532cb04c6990fb21e97cb7347a16e9df11108

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
    [ ! -d sources ] && mkdir -p sources
    cd sources
    cp -al ~/development/rtems/pkg_sources_cache/* .
    cd ..
    for i in config/tools/*cfg ; do
        cat "$i" | sed 's,ftp://ftp.gnu.org,http://ftp.gnu.org,;s,ftp://gcc.gnu.org,http://gcc.gnu.org,;' > "$i".new && mv "$i".new "$i"
    done

    # Build the cross compiling toolchain
    # (we're in the master branch, which is currently the "unofficial" 5.1)
    ../source-builder/sb-set-builder --with-ada --log=stage1.log --prefix=${RTPREFIX} 5/rtems-sparc 

    # Add the cross compiler to the PATH and checkout RTEMS
    export PATH=${RTPREFIX}/bin:$PATH
    cd ..
    if [ ! -d rtems-git ] ; then
	    git clone https://github.com/RTEMS/rtems.git rtems-git
	    cd rtems-git
	    git checkout -f 337a1869092779be0afca381dba674d3de4d7c9b
	    cd ..
    fi

    # Build RTEMS
    cd rtems-git
    ./bootstrap
    cd ..
    rm -rf build.${DATE}
    mkdir build.${DATE}
    cd build.${DATE}
    ../rtems-git/configure \
        --target=sparc-rtems5 --prefix=${RTPREFIX} \
        --enable-rtemsbsp="gr712rc gr740" --enable-posix --enable-ada \
        --enable-tests --enable-cxx --enable-networking --enable-smp
    make all
    make install
} |& tee ${BUILD_LOG}
