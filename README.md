TASTE
=====

This is the meta package that is used to install all git modules required
to make a TASTE installation.

Installation
============

TASTE Virtual Machine
---------------------
If possible, please use the TASTE VM - it is available at [http://taste.tools](http://taste.tools)
(follow the 'Downloads' link and download the .ova file - that's a VirtualBox
machine that you can import via VirtualBox's *"File/Import Appliance"*).

Docker container
----------------
The repository includes a Dockerfile, that creates a fully functional "taste" Docker image,
built from the sources necessary in all the submodules.

Simply Process this Dockerfile with:

    docker build -t taste .

And we then recommend to launch a fresh TASTE container with proper X11 redirection setup, with...

    ./Docker-run.sh

This script does all the necessary setup to map your local X11 socket inside the container,
allowing you to use X11 applications. In addition, your `$HOME` folder is mapped inside the
container under the `/root/work` folder, so any work you do in there will survive the
container's eventual closing. As with all Docker containers, you can also commit the 
changes you perform in your container (via `docker commit...`) and create your own
customized images.

For users where the TASTE VM is a concern for reasons of security *(e.g. uncertainty of what
exactly is included inside it)* the Docker container is a complete and clear answer: 
it is built from source, so there is full visibility on what is inside it.

In Debian-based distributions
-----------------------------
In theory,  under a modern Debian-based distribution a native install is also possible:
you would start by creating a new 'taste' user, and...

    $ git clone https://gitrepos.estec.esa.int/taste/taste-setup.git tool-src
    $ cd tool-src
    $ ./Update-TASTE.sh

You'd then have to follow the prompts to fix whatever issues are detected in your configuration.

In any native distribution offering `debootstrap`
-------------------------------------------------
Since the installation scripts depend on Debian tools, the setup process only works as-is inside environments that are Debian-based. Note however that almost all distributions offer `debootstrap` - a tool that allows the setup of a complete Debian chroot:

    # mkdir /opt/jessie-chroot
    # debootstrap jessie /opt/jessie-chroot
    # mount -t proc none /opt/jessie-chroot/proc/
    # mount -t sysfs none /opt/jessie-chroot/sys/
    # mount -o bind /dev /opt/jessie-chroot/dev/
    # mount -o bind /dev/pts /opt/jessie-chroot/dev/pts/
    # chroot /opt/jessie-chroot

At this point, you can continue with the normal process described above for Debian-based distributions - for (almost) all intents and purposes, this chroot will behave just like a native Debian install; and thus allows you to have a "sandboxed" TASTE install that will not interfere with your main distribution.

In fact, this is reason enough to employ this process even if you do have a Debian-based distribution; the chroot will contain all TASTE-related work, and will therefore leave your main distribution undisturbed.
