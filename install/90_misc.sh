#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/common.sh

# ELLIDISS?=/opt/Ellidiss-TASTE-linux

# taste-config
mkdir -p ${PREFIX}/bin
sed -e "s:INSTALL_PREFIX:${PREFIX}:g" taste-config.pl > taste-config.pl.tmp
cp taste-config.pl.tmp ${PREFIX}/bin/taste-config

# TASTE-Directives.asn
mkdir -p ${PREFIX}/share/taste
cp taste-directives/TASTE-Directives.asn ${PREFIX}/share/taste/TASTE-Directives.asn || exit 1

# Gnuplot
cp gnuplot/driveGnuPlotsStreams.pl ${PREFIX}/bin/taste-gnuplot-streams

# PeekPoke component
mkdir -p ${PREFIX}/share/peekpoke
mkdir -p ${PREFIX}/share/peekpoke/component
cp peek-poke/peekpoke.py ${PREFIX}/share/peekpoke/peekpoke.py
cp peek-poke/PeekPoke.glade ${PREFIX}/share/peekpoke/PeekPoke.glade
for i in DataView.aadl DataView.asn export_PeekPoke.aadl taste_probe.zip ; do \
        cp peek-poke/component/$$i ${PREFIX}/share/peekpoke/component/$$i ; \
done

mkdir -p ${PREFIX}/share/config_ellidiss
cp ellidiss/*.tcl $(ELLIDISS)/config/externalTools
cp ellidiss/TASTE_IV_Properties.aadl ${PREFIX}/share/config_ellidiss
cp ellidiss/TASTE_DV_Properties.aadl ${PREFIX}/share/config_ellidiss
sudo cp ellidiss/IVConfig.ini /opt/Ellidiss-TASTE-linux/config/
mkdir -p ${PREFIX}/share/taste-types
cp taste-common-types/taste-types.asn ${PREFIX}/share/taste-types
cp -rf config-files/.kde ~/
cd git-transition/ && ./local_install.sh
ln -sf $(HOME)/.local/bin/opengeode ${PREFIX}/bin/opengeode
$(MAKE) -C qemu-Leon3 || exit 1
