export DISABLE_TASTE_BANNER=1
TASTE_PATHS=$HOME/.bashrc.taste
PREFIX=$HOME/tool-inst

[ -e $HOME/.bashrc.taste ] && . $HOME/.bashrc.taste

UpdatePATH() {
    if [ -z "${PATH_CMD}" ] ; then
        echo You forgot to set your PATH_CMD. Aborting...
        exit 1
    fi
    grep "${PATH_CMD}$" ${TASTE_PATHS} >/dev/null || echo "${PATH_CMD}" >> ${TASTE_PATHS}
}
