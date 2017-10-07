#!/bin/bash
if ! command -v docker ; then
    echo "[x] You don't have Docker installed. Aborting..."
    exit 1
fi
docker images | grep ^taste > /dev/null || {
    echo "[x] You haven't built the TASTE Docker container."
    echo '[x] You need to execute this to create it:'
    echo '[x]'
    echo '[x]     docker build -t taste .'
    echo '[x]'
    exit 1
}
echo '[-] ==========================================='
echo '[-] Both Docker and the TASTE image were found.'
echo '[-] You will be able to run all TASTE applications, including X11 ones,'
echo -e "[-] and \e[1m\e[31m your \$HOME folder is mapped under /root/work (save files ONLY\e[0m"
echo -e "[-]\e[1m\e[31m there, everything else will be deleted when the container dies).\e[0m"
echo -e '[-] Also, \e[1m\e[32m the TASTE repositories are under /root/tool-src.\e[0m'
echo '[-]'
echo '[-] Launching the TASTE Docker container...'
echo '[-]'
HOMEB=/root
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch ${XAUTH}
xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f ${XAUTH} nmerge -
HOME=/root
docker run \
    --privileged \
    -e DISPLAY \
    -e HOME \
    -e XAUTHORITY=${XAUTH} \
    -v ${XSOCK}:${XSOCK} \
    -v ${XAUTH}:${XAUTH} \
    -v "$HOME":"$HOMEB"/work \
    -it taste /bin/bash -i
