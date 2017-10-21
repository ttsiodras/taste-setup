#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "${DIR}"/common.sh

cd "${DIR}"/../misc || exit 1

# taste-config
mkdir -p "${PREFIX}"/bin
sed -e "s:INSTALL_PREFIX:${PREFIX}:g" taste-config.pl > taste-config.pl.tmp
install -m 755 taste-config.pl.tmp "${PREFIX}"/bin/taste-config
rm -f taste-config.pl.tmp
