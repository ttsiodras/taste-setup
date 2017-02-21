TASTE_PATHS=$HOME/.bashrc.taste
PREFIX=$HOME/tool-inst

UpdatePATH() {
    if [ -z "${PATH_CMD}" ] ; then
        echo You forgot to set your PATH_CMD. Aborting...
        exit 1
    fi
    grep "${PATH_CMD}" ${TASTE_PATHS} >/dev/null || echo "${PATH_CMD}" >> ${TASTE_PATHS}
}
