Introduction
============

This folder contains the OAR RTEMS scaffold. The Makefile and example
source code demonstrates how to:

* support both debug and release compilations
* support compilation for native and emulated FPU usage
* support targetting Leon2 and Leon3 CPUs
* enable/disable showing compilation commands
* perform memory, FPU and integer testing of any Leon-based board

Building RTEMS via the RSB
--------------------------
The contrib folder includes a script that you can use to compile RTEMS4.12
with the Leon2 and Leon3 BSPs from the OAR repository. Note that
[as discussed in the RTEMS mailing list](https://lists.rtems.org/pipermail/users/2016-February/029782.html),
you will need to compile your BSP for native or emulated FPU, based
on what your desired target is (i.e. edit the leon2.cfg/leon3.cfg 
files to remove `-msoft-float` or not). The Makefile mirrors this
need, by pointing to different paths (see FPU_SUFFIX variable),
depending on whether you build with FPU=1 or not.

Executive summary: if you want to build native-FPU-using binaries,
you'll need to edit leon2.cfg/leon3.cfg and remove the `-msoft-float`
before building the BSPs (that is, right after the clone from
the RTEMS git repository - in line 87 of the script).

Application sources
-------------------
The sources of your project must be set inside the Makefile, in the SRC
variable. The VPATH can be used to automatically locate them in 
your source tree:

    VPATH=src:Library/foo:Library/bar:...

    SRC= \
        init.c           \
        tasking.c        \
        gnc.c            \
        compute_pi.c

# Compilation options

There are 4 orthogonal compilation options that you can control:

- debug/release compilation (`CFG`)
- emulated/native FPU compilation (`FPU`)
- Leon2/Leon3 target (`LEON`)
- show/hide compilation commands (`V`)

## Debug/Release mode

Using the `CFG` Makefile parameter, you can select debug or release 
compilation:

    $ make CFG=debug
    ...
    $ ls -l bin.debug.NONFPU.leon3/
    -rwxr-xr-x 1 user user 645273 Mar 16 17:43 fputest

    $ make CFG=release
    ...
    $ ls -l bin.release.NONFPU.leon3/
    -rwxr-xr-x 1 root root  47860 Mar 16 17:48 fputest
    -rwxr-xr-x 1 root root 585178 Mar 16 17:48 fputest.debug

Notice that:

- In release compilation, the process creates a small binary
  (containing only the executable code) and separately, the debug information -
  for loading from inside GDB via the `file` command.
- Notice also that the output folder tells you this build did not use
  native FPU, and targeted Leon3 (the defaults). To compile for 
  native FPU or a different Leon target, use the next two options.

## Native or emulated FPU compilation for the source files

To use native FPU compilation for the source files, use the `FPU`
Makefile parameter:

    $ make CFG=debug FPU=1

To use emulation (default, if `FPU` option is not provided), pass `FPU=0`:

    $ make CFG=debug FPU=0

...or just don't mention `FPU` at all:

    $ make CFG=debug

The `FPU` and `CFG` options are completely independent ; you can e.g.
compile a debug version that uses native FPU, and a release one that uses
emulation. Just keep in mind that currently, 4.12 
[does not allow you to use the same BSP](https://lists.rtems.org/pipermail/users/2016-February/029782.html),
for both native and emulated FPU usage ; you'll have to build separate
BSPs by tweaking the `leon2.cfg`/`leon3.cfg` files when you build RTEMS.

## Select Leon target

Use the `LEON` Makefile parameter to decide which target to build for
(currently, only `leon2` and `leon3` are supported):

    $ make CFG=debug FPU=1 LEON=leon3

## Verbosity

Messages shown during compilation follow the semantics of the Linux kernel
compilation process, emitting short messages by default (CC for compilation,
 LD for linking). The compilation is also incremental, taking into account
the modification timestamps of the files and their dependencies:

    $ touch src/task1.c
    $ make
    [CC] objs.debug.NONFPU.leon3/task1.o
    [LD] bin.debug.NONFPU.leon3/fputest

If you want to see the complete commands used, pass `V=1`:

    $ touch src/task1.c
    $ make CFG=debug FPU=0 V=1
    /opt/rtems-4.12-2016.06.13.NONFPU/bin/sparc-rtems4.12-gcc -c \
        -B/opt/rtems-4.12-2016.06.13.NONFPU/sparc-rtems4.12/leon3/lib \
        -specs bsp_specs -qrtems -mcpu=cypress -DBSP_leon3 -ffunction-sections \
        -fdata-sections -Wall -Wmissing-prototypes \
        -Wimplicit-function-declaration -Wstrict-prototypes -Wnested-externs \
        -g -Wall -D_DEBUG -I src -msoft-float \
        -o objs.debug.NONFPU.leon3/task1.o src/task1.c
    /opt/rtems-4.12-2016.06.13.NONFPU/bin/sparc-rtems4.12-gcc -g \
        -o bin.debug.NONFPU.leon3/fputest objs.debug.NONFPU.leon3/init.o \
        objs.debug.NONFPU.leon3/task1.o objs.debug.NONFPU.leon3/task2.o \
        objs.debug.NONFPU.leon3/common.o -msoft-float \
        -B/opt/rtems-4.12-2016.06.13.NONFPU/sparc-rtems4.12/leon3/lib \
        -specs bsp_specs -qrtems -mcpu=cypress -DBSP_leon3 \
        -ffunction-sections -fdata-sections -Wall -Wmissing-prototypes \
        -Wimplicit-function-declaration -Wstrict-prototypes \
        -Wnested-externs -Wl,--gc-sections
    Built with RTEMS at /opt/rtems-4.12-2016.06.13.NONFPU/sparc-rtems4.12/leon3/lib for leon3.

# Support

For any questions/feedback, raise tickets in the repository and/or contact
me directly:

    Thanassis Tsiodras
    Real-time Embedded Software Engineer 
    System, Software and Technology Department
    Address:
        ESTEC/Office EF216
        Keplerlaan 1, PO Box 299
        NL-2200 AG Noordwi
    E-mail:
        Athanasios.Tsiodras@esa.int
    Phone:
        +31 71 565 5332
