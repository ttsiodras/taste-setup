#!/bin/bash
if [ -t 0 ] ; then
    COLORON="\e[1m\e[31m"
    COLOROFF="\e[0m"
else
    COLORON=""
    COLOROFF=""
fi
INFO="${COLORON}[INFO]${COLOROFF}"

/bin/sh --version 2>&1 | grep -i bash || {
    echo -e "${INFO} Many legacy Makefiles used depend on /bin/sh pointing to bash."
    echo -e "${INFO} Please change your /bin/sh appropriately."
    exit 1
}
