#!/bin/bash
INSTALLED_RTEMS_INFO="/opt/rtems_LATEST"
if [ -f "$INSTALLED_RTEMS_INFO" ] ; then
    cat "$INSTALLED_RTEMS_INFO" | read OLD_RTEMS_MTIME OLD_RTEMS_FOLDER
else
    OLD_RTEMS_MTIME=0
    OLD_RTEMS_FOLDER=""
fi

echo Checking for new version of the RTEMS compiler...
if wget -q -O - http://download.tuxfamily.org/taste/RTEMS/LATEST \
        | read NEW_RTEMS_MTIME NEW_RTEMS_FOLDER NEW_RTEMS_URL ; then
    if [ "$OLD_RTEMS_MTIME" -lt "$NEW_RTEMS_MTIME" ] ; then
        echo Downloading updated version of the RTEMS compiler...
        cd /opt
        if wget -q -O - "$NEW_RTEMS_URL" | sudo tar jxvf - ; then
            if [ ! -z "$OLD_RTEMS_FOLDER" ] ; then
                echo Removing old RTEMS compiler...
                sudo rm -rf "$OLD_RTEMS_FOLDER"
            fi
            NEWBIN=$NEW_RTEMS_FOLDER/bin
            if ! grep "^export PATH=.*$NEWBIN" ; then
                echo Adding new compiler $NEWBIN to PATH...
                echo "export PATH=$NEWBIN:$PATH" >> $HOME/.bashrc.taste 
            fi
        fi
    fi
else
    echo Failed to get http://download.tuxfamily.org/taste/RTEMS/LATEST ...
    echo Aborting.
    exit 1
fi
