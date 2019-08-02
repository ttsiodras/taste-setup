#!/bin/bash
TMP=${TMP:-/tmp}

if [ -t 0 ] ; then
    COLORON="\e[1m\e[31m"
    COLOROFF="\e[0m"
else
    COLORON=""
    COLOROFF=""
fi
INFO="${COLORON}[INFO]${COLOROFF}"

echo $PATH | sed 's,:,\n,g' | sort -u > ${TMP}/oldPaths
bash -c '. ~/.bashrc.taste ; echo $PATH' | sed 's,:,\n,g' | sort -u > ${TMP}/newPaths

diff -u  ${TMP}/oldPaths ${TMP}/newPaths || {
    echo -e "${INFO} A new PATH folder was introduced in your ~/.bashrc.taste"
    echo -e "${INFO} Source it now with..."
    echo -e "${INFO} "
    echo -e "${INFO}     source ~/.bashrc.taste"
    echo -e "${INFO} "
    echo -e "${INFO} ...and make sure your ~/.bashrc is sourcing it as well."
    echo -e "${INFO} (if you are using the TASTE VM, this has already been done)."
}

rm -f ${TMP}/oldPaths ${TMP}/newPaths
