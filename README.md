TASTE
=====

This is the meta package that is used to install all git modules required
to make a TASTE installation.

If possible, please use the TASTE VM - available at http://taste.tools
(follow the 'Downloads' link and download the .ova file - that's a VirtualBox
machine that you can import via VirtualBox's "File/Import Appliance")

Otherwise, use a Debian-based distribution, create a new 'taste' user, and...

    $ git clone --recursive https://gitrepos.estec.esa.int/taste/taste-setup.git tool-src
    
...followed by 

    $ cd tool-src
    $ ./Update-TASTE.sh

Then follow the prompts to fix whatever issues are detected in your configuration.

The setup depends on the environment being a Debian distro; if this is not the case,
you can try the setup from inside a debootstrap-ed chroot:

    # mkdir /opt/stretch-chroot
    # debootstrap stretch /opt/stretch-chroot
    # mount -t proc none /opt/stretch-chroot/proc/
    # mount -t sysfs none /opt/stretch-chroot/sys/
    # mount -o bind /dev /opt/stretch-chroot/dev/
    # mount -o bind /dev/pts /opt/stretch-chroot/dev/pts/
    # chroot /opt/stretch-chroot

There is also a Dockerfile (currently under construction) that will eventually
automate the setup enough to allow working under any distribution.
