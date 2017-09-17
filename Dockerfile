#
# Process with:
#     docker build -t taste .
#
FROM debian:stretch
RUN apt-get update
RUN apt-get -y install netcat net-tools wget
# There is immense waste of re-downloading the .deb files
# in every attempt to setup the Docker image.
# The following uses a locally-provided proxy
# that will make sure the .deb files are only downloaded once,
# and are re-used in all subsequent attempts to build the image.
RUN route -n | awk '/^0.0.0.0/ {print $2}' > /tmp/host_ip.txt
RUN echo "HEAD /" | nc `cat /tmp/host_ip.txt` 8000 | grep squid-deb-proxy \
  && (echo "Acquire::http::Proxy \"http://$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) \
  && (echo "Acquire::http::Proxy::ppa.launchpad.net DIRECT;" >> /etc/apt/apt.conf.d/30proxy) \
  || echo "No squid-deb-proxy detected on docker host"
RUN bash -c 'export DEBIAN_FRONTEND=noninteractive ; apt-get -y install git sudo'
RUN bash -c 'cd /root ; git clone https://gitrepos.estec.esa.int/taste/taste-setup.git tool-src'
# The following pieces correspond to the execution of Update-TASTE.sh ;
# but the execution has to be broken down into steps, so that Docker
# can resume the build from whichever step failed in the last attempt.
RUN bash -c 'cd /root/tool-src ; git submodule init ; git submodule update'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/01_sudo.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/03_debian.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/04_pythonlibs.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/05_antlr.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/06_stlink.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/10_dmt.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/15_asn1scc.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/20_msc.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/30_qemu.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/40_ocarina.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/45_pohi.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/50_opengeode.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/53_pymsc.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/54_speedometer.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/55_asn1valueEditor.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/56_msc-editor.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/60_buildsupport.sh'
# Those that need postgres can set it up themselves (avoid creating huge Docker image)
# RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/65_postgres.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/70_taste-model-checker.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/80_build-scripts.sh'
# Those that need RTEMS can set it up themselves (avoid creating huge Docker image)
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/85_rtems.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/90_misc.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/91_env.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/95_components_library.sh'
RUN bash -c 'cd /bin ; sudo rm sh ; sudo ln -s bash sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/98_bash.sh'
RUN bash -c 'cd /root/tool-src ; DISABLE_TASTE_BANNER=1 install/99_paths.sh'
RUN bash -c 'echo ". ~/.bashrc.taste" >> /root/.bashrc'
# 
# Now run the Docker image with 
#
#     docker run -it taste /bin/bash
