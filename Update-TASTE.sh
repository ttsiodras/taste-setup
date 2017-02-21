#!/bin/bash
git pull || exit 1
git submodule init || exit 1
git submodule update || exit 1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
for INSTALL_SCRIPT in install/[0-9]*sh ; do
    ${INSTALL_SCRIPT} || { echo Failed in execution of "${INSTALL_SCRIPT}" ; exit 1 ; }
done
