#!/bin/bash
if [ -t 0 ] ; then
    COLORON="\e[1m\e[31m"
    COLOROFF="\e[0m"
else
    COLORON=""
    COLOROFF=""
fi
ERROR="${COLORON}[ERROR]${COLOROFF}"

/bin/sh --version 2>&1 | grep -i bash || {
    echo -e "${ERROR} Many legacy Makefiles used depend on /bin/sh pointing to bash."
    echo -e "${ERROR} You need to change your /bin/sh appropriately - e.g."
    echo -e "${ERROR}"
    echo -e "${ERROR}    cd /bin ; sudo rm sh ; sudo ln -s bash sh"
    exit 1
}
