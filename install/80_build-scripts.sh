#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Install the scripts
cd ${DIR}
for i in checkStackUsage.py patchAPLCs.py
do
    cp -a ../orchestrator/orchestrator/$i ${PREFIX}/bin/
done
COMMITID=$(cd ../orchestrator/ ; git log --oneline | head -1 | awk '{print $1}')
cat ../orchestrator/orchestrator/taste-orchestrator.py | \
    sed "s,COMMITID,${COMMITID}," > ${PREFIX}/bin/taste-orchestrator.py

# Install a symlink for the old name of the build tool
cd ${PREFIX}/bin/ || exit 1
[ ! -h assert-builder-ocarina.py ] && ln -s taste-orchestrator.py assert-builder-ocarina.py

# Add to PATH
PATH_CMD='export PATH=$PATH:'"${PREFIX}/bin"
UpdatePATH
