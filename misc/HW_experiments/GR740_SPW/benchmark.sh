#!/bin/bash
export RTEMS=/opt/rtems-4.11-2016.04.01.FPU.SMP
make CFG=release LEON=leon3 FPU=1
time expect -f ./benchmark.expect
