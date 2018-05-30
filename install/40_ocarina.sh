#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "${DIR}/common.sh"

function overWriteAADLcomponents()
{
    # Install TASTE customized version of available deployment targets
    # Also done in misc, but doing it here allows standalone update of ocarina
    echo Installing TASTE-supported deployment targets
    cat ../misc/aadl-library/ocarina_components.aadl  | \
        sed "s,/home/taste/tool-inst,$(taste-config --prefix)," > \
        "${PREFIX}/share/ocarina/AADLv2/ocarina_components.aadl"
}

# Setup the tools in ~/.local/bin
cd "$DIR/../ocarina" || exit 1

# Skip Ocarina building if tree is clean and version is identical
HEAD="$(git log --oneline | head -1 | cut -d' ' -f1)"
VERSION_INSTALLED="$(ocarina -v 2>&1 | grep ^Oca | awk '{print $NF}' | sed 's,),,;s,r,,')"
GIT_OUTPUT=$(git status --porcelain)
if [ "${GIT_OUTPUT}" == "" ] ; then
    TREE_DIRTY=0
else
    TREE_DIRTY=1
fi
if [ ${TREE_DIRTY} -eq 0 ] && [ "${HEAD}" == "${VERSION_INSTALLED}" ] ; then
    echo Ocarina tree is clean and already installed. Skipping Ocarina build...
    overWriteAADLcomponents
    exit 0
fi

make distclean # ignore any errors here
./support/reconfig || exit 1
./configure --enable-python --enable-shared --prefix="${PREFIX}" || exit 1
make || exit 1
make install

overWriteAADLcomponents

# Add Ocarina to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/bin"
UpdatePATH

# Add Ocarina Python-binding libraries to LD_LIBRARY_PATH
PATH_CMD='export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'"${PREFIX}/lib"
UpdatePATH

# Add Ocarina env var necessary for Python mappings to function
PATH_CMD="export OCARINA_PATH=`ocarina-config --prefix`"
UpdatePATH

# Add Ocarina-specific PYTHONPATH dependencies
PATH_CMD='export PYTHONPATH=$OCARINA_PATH/include/ocarina/runtime/python:$OCARINA_PATH/lib:$PYTHONPATH'
UpdatePATH
