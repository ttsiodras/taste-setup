#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

sudo apt-get install -y --force-yes libusb-dev || exit 1

cd ${DIR} || exit 1
make -C ../misc/ZestSC1/linux/ || exit 1
mkdir -p ${PREFIX}/share/ZestSC1
cp -u ../misc/ZestSC1/linux/Lib/libZestSC1.a ${PREFIX}/share/ZestSC1/
