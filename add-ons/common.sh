function InstallBSP() {
    DESCRIPTION="$1"
    URL="$2"
    BASE="$3"
    FOLDER="${BASE}/$4"
    echo '[-] This will install '"${DESCRIPTION}"','
    echo '[-] under:'
    echo '[-] '
    echo '[-]     '"${FOLDER}"
    echo '[-] '
    [ -e "${FOLDER}" ] && { \
        echo '[-] It will remove anything that is currently there.'
        echo '[-] '
    }
    echo -n '[-] Are you sure you want this? (y/n) '
    read -r ANS
    if [ "$ANS" != "y" ] ; then
        echo '[-] Response was not "y", aborting...'
        exit 1
    fi
    sudo rm -rf "${FOLDER}" 2>/dev/null
    wget -q -O - "${URL}"  | \
        ( cd "${BASE}" || exit 1 ; sudo tar jxvf - )
}
