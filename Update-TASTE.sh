#!/bin/bash
git pull || exit 1
git submodule init || exit 1
git submodule update || exit 1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DISABLE_TASTE_BANNER=1
for INSTALL_SCRIPT in install/[0-9]*sh ; do
    if [ ! -z "${TASTE_IN_DOCKER}" ] ; then
        if [ "${INSTALL_SCRIPT}" == "install/65_postgres.sh" ] ; then
            echo Skipping over postgres installation in Docker container.
            continue
        fi
    fi
    ${INSTALL_SCRIPT} || { echo Failed in execution of "${INSTALL_SCRIPT}" ; exit 1 ; }
done
echo "Please close this terminal and open a new one (to"
echo "(make sure the environment variables are updated)."
