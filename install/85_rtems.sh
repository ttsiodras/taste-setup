#!/bin/bash
INSTALLED_RTEMS_INFO="/opt/rtems_LATEST"
if [ -f "$INSTALLED_RTEMS_INFO" ] ; then
    read OLD_RTEMS_MTIME OLD_RTEMS_FOLDER <<< $(cat "$INSTALLED_RTEMS_INFO")
else
    OLD_RTEMS_MTIME=0
    OLD_RTEMS_FOLDER=""
fi

echo Checking for new version of the RTEMS compiler...
URL_OF_NEW_RTEMS_INFO=http://download.tuxfamily.org/taste/RTEMS/LATEST
if wget -q -O /tmp/syncup.$$ "$URL_OF_NEW_RTEMS_INFO" ; then
    read NEW_RTEMS_MTIME NEW_RTEMS_FOLDER NEW_RTEMS_URL <<< $(cat /tmp/syncup.$$)
    rm -f /tmp/syncup.$$
    if [ "$OLD_RTEMS_MTIME" -lt "$NEW_RTEMS_MTIME" ] ; then
        echo Downloading updated version of the RTEMS compiler...
        cd /opt
        NEW_COMPILER_TARBALL=/tmp/newCompiler.$$.tar.bz2
        if wget -O $NEW_COMPILER_TARBALL "$NEW_RTEMS_URL" ; then
            if [ ! -z "$OLD_RTEMS_FOLDER" ] ; then
                echo Removing old RTEMS compiler...
                sudo rm -rf "$OLD_RTEMS_FOLDER"
            fi
            sudo tar jxvf $NEW_COMPILER_TARBALL || {
                echo Failed to extract $NEW_COMPILER_TARBALL...
                echo Aborting.
                exit 1
            }
            NEWBIN=$NEW_RTEMS_FOLDER/bin
            if ! grep "^export PATH=.*$NEWBIN" ; then
                echo Adding new compiler "$NEWBIN" to PATH...
                echo "export PATH=$NEWBIN:$PATH" >> "$HOME/.bashrc.taste"
            fi
            echo $NEW_RTEMS_MTIME $NEW_RTEMS_FOLDER | \
                sudo tee "$INSTALLED_RTEMS_INFO"
        fi
    fi
else
    echo Failed to get http://download.tuxfamily.org/taste/RTEMS/LATEST ...
    echo Aborting.
    exit 1
fi
