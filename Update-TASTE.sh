#!/bin/bash

if [ -t 1 ] ; then
    COLORON="\e[1m\e[32m"
    COLOROFF="\e[0m"
else
    COLORON=""
    COLOROFF=""
fi

function banner()
{
    echo -e "${COLORON}"
    echo "$1" | sed 's,.,=,g'
    echo "$1"
    echo "$1" | sed 's,.,=,g'
    echo -e "${COLOROFF}"
}

git pull || exit 1
if [ -z "$1" -o "$1" == "--stable" ] ; then
    git submodule init || exit 1
    git submodule update || exit 1
else
    git submodule | awk '{print $2}' | while read FOLDER ; do
        cd "$FOLDER" || exit 1
        git fetch || exit 1
        git checkout master || exit 1
        git pull || exit 1
        cd ..
    done
fi
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DISABLE_TASTE_BANNER=1
:> timings.log
for INSTALL_SCRIPT in install/[0-9]*sh ; do
    if [ ! -z "${TASTE_IN_DOCKER}" ] ; then
        if [ "${INSTALL_SCRIPT}" == "install/65_postgres.sh" ] ; then
            echo Skipping over postgres installation in Docker container.
            continue
        fi
    fi
    MSG="executing: ${INSTALL_SCRIPT}"
    banner "$MSG"
    echo -n "Calling ${INSTALL_SCRIPT} took: " >> timings.log
    bash -c "time -p ${INSTALL_SCRIPT}" > >(tee stdout.log) 2> >(tee stderr.log >&2) || { echo Failed in execution of "${INSTALL_SCRIPT}" ; exit 1 ; }
    grep ^real stderr.log | sed 's,real ,,' >> timings.log
done
echo -e "${COLORON}"
echo "==========================="
echo "Update completed - timings:"
echo "==========================="
echo -e "${COLOROFF}"
cat timings.log | column -t | sort -n -k 4
rm -f timings.log stdout.log stderr.log
echo -e "\e[1m\e[31m"
echo "====================================================="
echo "Please close this terminal and open a new one"
echo "(to make sure the environment variables are updated)."
echo "====================================================="
echo -e "${COLOROFF}"
