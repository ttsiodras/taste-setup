#!/bin/bash
sudo -n "bash -c 'echo OK'" >/dev/null
if [ $? -ne 0 ] ; then
    echo You need to install and configure password-less sudo.
    echo "The update process touches system files, so, from a root account:"
    echo
    echo "    sudo apt-get install sudo"
    echo
    echo "...and then add this line to /etc/sudoers :"
    echo
    echo "    $USER  ALL=(root) NOPASSWD: ALL"
    echo
    echo "You can then re-run Update-TASTE.sh".
    echo
    echo "If you don't feel comfortable with giving sudo credentials to the"
    echo "update scripts, remember that you can apply this process in a chroot,"
    echo "or in a VM ; and you can also use the pre-built TASTE VM or use our"
    echo "Vagrant/Docker support to automatically build a sandboxed 'machine'."
    echo "The scripts are open for reviewing anyway - they exist under the"
    echo "install/ folder."
    exit 1
fi
