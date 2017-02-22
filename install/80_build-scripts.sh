#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

for i in checkStackUsage.py patchAPLCs.py taste_orchestrator.py 
do
    cp -u ../orchestrator/orchestrator/$i ${PREFIX}/bin/
done
