#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
for INSTALL_SCRIPT in install/* ; do
    ${INSTALL_SCRIPT} || { echo Failed in execution of "${INSTALL_SCRIPT}" ; exit 1 ; }
done
