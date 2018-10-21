#!/bin/bash
ARCH=$(uname -m)
if [ "${ARCH}" == "x86_64" ] ; then
    dpkg --print-foreign-architectures | grep i386 >/dev/null || {
        sudo dpkg --add-architecture i386
    }
fi
sudo apt-get update
if [ "${ARCH}" == "x86_64" ] ; then
    sudo apt-get install -y --force-yes libc6:i386 libgcc1:i386 libxft2:i386 libxss1:i386 libcairo2:i386 libc6-dev-i386 
fi

VERSION=$(uname -v)
echo "Checking whether running inside Docker-ized Debian environment..."
if [ -f /.dockerenv ] ; then
    VERSION=DockerizedDebian
fi
echo "Version detected: ${VERSION}"

case "$VERSION" in
    *14.04*Ubuntu* )
        sudo apt-get install -y --force-yes wget autoconf automake curl exuberant-ctags gcc git gnat gtkwave kate lcov libacl1 libacl1-dev libarchive-dev libattr1 libattr1-dev libbonoboui2-0 libdbd-sqlite3-perl libdbi-perl libfile-copy-recursive-perl libglib2.0-0 libgnome2-0 libgnome2-perl libgnome2-vfs-perl libgnomeui-0 libgnomevfs2-0 libgnomevfs2-common libgtk2-gladexml-perl libgtk2-perl libgraphviz-dev libmono-system-data-linq4.0-cil libmono-system-numerics4.0-cil libmono-system-runtime-serialization-formatters-soap4.0-cil libmono-system-runtime4.0-cil libmono-system-web4.0-cil libmono-system-xml4.0-cil libmono-system4.0-cil libsqlite3-dev libtool libxml-libxml-perl libxml-libxml-simple-perl libxml-parser-perl libxml2-dev libxslt1-dev libzmq3-dev mono-mcs mono-runtime nedit net-tools pgadmin3 postgresql postgresql-client postgresql-client-common postgresql-common python-antlr python-coverage python-gtk2-dev python-jinja2 python-lxml python-matplotlib python-pexpect python-pip python-ply python-psycopg2 python-pygraphviz python-pyside python3-pip qemu-system sqlite3 sudo tk8.5 tree vim-gtk wmctrl xmldiff xpdf xterm xterm zip openjdk-6-jre python3-lxml bash-completion strace libusb-1.0-0-dev cmake dfu-util gnuplot libstdc++-4.8-dev ;;
    *16.04*Ubuntu* )
        sudo apt-get install -y --force-yes wget autoconf automake curl exuberant-ctags gcc git gnat gtkwave kate lcov libacl1 libacl1-dev libarchive-dev libattr1 libattr1-dev libbonoboui2-0 libdbd-sqlite3-perl libdbi-perl libfile-copy-recursive-perl libglib2.0-0 libgnome2-0 libgnome2-perl libgnome2-vfs-perl libgnomeui-0 libgnomevfs2-0 libgnomevfs2-common libgtk2-gladexml-perl libgtk2-perl libgraphviz-dev libmono-system-data-linq4.0-cil libmono-system-numerics4.0-cil libmono-system-runtime-serialization-formatters-soap4.0-cil libmono-system-runtime4.0-cil libmono-system-web4.0-cil libmono-system-xml4.0-cil libmono-system4.0-cil libsqlite3-dev libtool libxml-libxml-perl libxml-libxml-simple-perl libxml-parser-perl libxml2-dev libxslt1-dev libzmq3-dev mono-mcs mono-reference-assemblies-2.0 mono-runtime nedit net-tools pgadmin3 postgresql postgresql-client postgresql-client-common postgresql-common python-antlr python-coverage python-gtk2-dev python-jinja2 python-lxml python-matplotlib python-pexpect python-pip python-psycopg2 python-pygraphviz python-pyside python3-pip qemu-system sqlite3 sudo tk8.5 tree vim-gtk wmctrl xmldiff xpdf xterm xterm zip openjdk-8-jre python3-lxml bash-completion strace libusb-1.0-0-dev cmake dfu-util gnuplot libstdc++-5-dev ;;
    * )
        sudo apt-get install -y --force-yes wget autoconf automake curl exuberant-ctags gcc git gnat gtkwave kate lcov libacl1 libacl1-dev libarchive-dev libattr1 libattr1-dev libbonoboui2-0 libdbd-sqlite3-perl libdbi-perl libfile-copy-recursive-perl libglib2.0-0 libgnome2-0 libgnome2-perl libgnome2-vfs-perl libgnomeui-0 libgnomevfs2-0 libgnomevfs2-common libgtk2-gladexml-perl libgtk2-perl libgraphviz-dev libmono-system-data-linq4.0-cil libmono-system-numerics4.0-cil libmono-system-runtime-serialization-formatters-soap4.0-cil libmono-system-runtime4.0-cil libmono-system-web4.0-cil libmono-system-xml4.0-cil libmono-system4.0-cil libsqlite3-dev libtool libxml-libxml-perl libxml-libxml-simple-perl libxml-parser-perl libxml2-dev libxslt1-dev libzmq3-dev mono-mcs mono-reference-assemblies-2.0 mono-runtime nedit net-tools pgadmin3 postgresql postgresql-client postgresql-client-common postgresql-common python-antlr python-coverage python-gtk2-dev python-jinja2 python-lxml python-matplotlib python-pexpect python-pip python-psycopg2 python-pygraphviz python-pyside python3-pip qemu-system sqlite3 sudo tk8.5 tree vim-gtk wmctrl xmldiff xpdf xterm xterm zip openjdk-8-jre python3-lxml bash-completion strace libusb-1.0-0-dev cmake dfu-util gnuplot libstdc++-6-dev libgnatcoll-python1.7-dev ;;
esac
