#!/bin/bash
export TASTE_IN_DOCKER=1 
export CIRCLECI 
export CI
rm -rf artifacts
mkdir artifacts
docker run \
    -e DISPLAY \
    -e CIRCLE_BRANCH \
    -e TASTE_IN_DOCKER \
    -e CIRCLECI \
    -e CI \
    -v $(pwd)/artifacts:/tmp/artifacts \
    -it taste \
    /bin/bash -c 'apt-get install -y --force-yes xvfb ; Xvfb & export DISPLAY=:0 ; export GIT_SSL_NO_VERIFY=true ; cd /root/ ; . .bashrc.taste ; cd tool-src ; git fetch ; git checkout -f "${CIRCLE_BRANCH}" ; git branch --set-upstream-to=origin/${CIRCLE_BRANCH} ${CIRCLE_BRANCH} ; ./Update-TASTE.sh || exit 1 ; cd testSuites/ ; ./regression.py | tee /tmp/artifacts/A_complete_regression.log ; for i in Demo*/*.log ; do cp "$i" /tmp/artifacts/"${i/\//_}" ; done ; grep Demo /tmp/artifacts/A_complete_regression.log | grep -v OK$ && exit 1'
