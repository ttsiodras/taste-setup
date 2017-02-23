#!/bin/bash
TMP=${TMP:-/tmp}

if [ -t 0 ] ; then
    COLORON="\e[1m\e[32m"
    COLOROFF="\e[0m"
else
    COLORON=""
    COLOROFF=""
fi
INFO="${COLORON}[INFO]${COLOROFF}"

echo $PATH | sed 's,:,\n,g' | sort -u > ${TMP}/oldPaths
bash -c '. ~/.bashrc.taste ; echo $PATH' | sed 's,:,\n,g' | sort -u > ${TMP}/newPaths

diff -u  ${TMP}/oldPaths ${TMP}/newPaths || {
    echo "${INFO} A new PATH folder was introduced in your ~/.bashrc.taste"
    echo "${INFO} Source it now..."
    echo
    echo "${INFO}     . ~/.bashrc.taste"
    echo
    echo "${INFO} ...and make sure your ~/.bashrc is sourcing it as well."
    echo "${INFO} (if you are using the TASTE VM, this has already been done)."
}

rm -f ${TMP}/oldPaths ${TMP}/newPaths || {
