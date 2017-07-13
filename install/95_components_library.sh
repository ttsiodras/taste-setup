#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# Fetch and install latest ASN1SCC release
LIBDIR=${PREFIX}/share/components_library
mkdir -p ${LIBDIR} || exit 1

getver() {
    grep TASTE_IV_Properties::Version "$@" | head -1 | \
        awk -F\" '{print $(NF-1)}'
}

cd "${DIR}"/../components_library || exit 1
for i in * ; do
    # Only check folders (the components folder has files, too)
    cd "${DIR}"/../components_library || exit 1
    [ ! -d "$i" ] && continue
    # Is it already installed?
    if [ ! -d ${LIBDIR}/"$i" ] ; then
        # No, install component in library
        echo "[-] Installing $i in component library..."
        cp -a "$i" ${LIBDIR} || exit 1
        cd ${LIBDIR}/"$i" || exit 1
        echo "[-] Updating ASN.1 file paths..."
        taste-update-data-view *asn
    else
        # Yes, it is - check for updates
        cd "${DIR}"/../components_library/"$i" || exit 1
        NEWVER=$(getver *aadl)
        cd ${LIBDIR}/"$i" || exit 1
        OLDVER=$(getver *aadl)
        if [ "${OLDVER}" != "${NEWVER}" ] ; then
            echo "[-] Updating $i in component library..."
            rm -f *
            cp -a "${DIR}"/../components_library/"$i"/* . 
            echo "[-] Updating ASN.1 file paths..."
            taste-update-data-view *asn
        fi
    fi
done
