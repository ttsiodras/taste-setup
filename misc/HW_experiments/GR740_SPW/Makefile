# Configuration section
#
# Use environment variables if found, otherwise fallback to sane defaults

# If not explicitely selected (with 'make FPU=1'), compile for FPU emulation
ifeq ($(FPU),)
FPU=1
endif

# To be able to properly handle any combination of (FPU, LEON, release) 
# options, create a SUFFIX (see below) to differentiate output folders
ifeq ($(FPU),1)
FPU_SUFFIX=FPU
else
FPU_SUFFIX=NONFPU
endif

# Build up our settings from our inputs and our environment
LEON ?= gr740
CROSS_PREFIX ?= sparc-rtems5
RTEMS ?= /opt/rtems-5.1-2018.03.06
RTEMS_MAKEFILE_PATH = ${RTEMS}/${CROSS_PREFIX}/${LEON}
RTEMS_LIB=${RTEMS_MAKEFILE_PATH}/lib

# If not selected, compile debug version of binary (no optimizations)
#ifeq ($(CFG),)
CFG=debug
#endif

# The directories containing the source files, separated by ':'
#
# DEAR USER, YOU MUST EDIT THIS AND ADD YOUR SOURCE FOLDERS
VPATH=src

# Your source files: regardless of where they reside in the source tree,
# VPATH will locate them...
#
# DEAR USER, YOU MUST EDIT THIS
SRC= spwrouter_custom_config.c test.c grspw_pkt_lib.c

SUFFIX=$(CFG).$(FPU_SUFFIX).$(LEON)

# Build a Dependency list and an Object list, by replacing the .c
# extension to .d for dependency files, and .o for object files.
DEP = $(patsubst %.c, deps.$(SUFFIX)/%.d, ${SRC})
OBJ = $(patsubst %.c, objs.$(SUFFIX)/%.o, ${SRC})

# Your final binary
#
# DEAR USER, YOU MUST EDIT THIS
TARGET=fputest

# What compiler to use for generating dependencies: 
# it will be invoked with -MM -MP
CC = ${RTEMS}/bin/${CROSS_PREFIX}-gcc
CDEP = ${CC}

# What include flags to pass to the compiler
INCLUDEFLAGS= -I src

# Compilation flags (common)
COMMON += -B${RTEMS_LIB} -specs bsp_specs -qrtems \
	  -mcpu=leon3 -DBSP_${LEON} \
	  -ffunction-sections -fdata-sections -Wall \
	  -Wmissing-prototypes -Wimplicit-function-declaration \
	  -Wstrict-prototypes -Wnested-externs

# Separate compile options per configuration
ifeq ($(CFG),debug)
CFLAGS += ${COMMON} -g -Wall -D_DEBUG ${INCLUDEFLAGS}
else
CFLAGS += ${COMMON} -g -O2 -Wall ${INCLUDEFLAGS}
endif

# Should we generate native FPU instructions for the SRC or not?
ifeq ($(FPU),0)
CFLAGS += -msoft-float
LDFLAGS += -msoft-float
endif

# A common link flag for all configurations
LDFLAGS += ${COMMON} -Wl,--gc-sections

all:	inform bin.$(SUFFIX)/${TARGET}

inform:
ifneq ($(CFG),release)
ifneq ($(CFG),debug)
	@echo " "
	@echo "Invalid or missing configuration (CFG) "$(CFG)" specified."
	@echo " "
	@echo "You must specify a configuration when running make, e.g."
	@echo " "
	@echo "    make CFG=debug LEON=leon3 FPU=1 V=1"
	@echo " "
	@echo "- Possible choices for CFG are 'release' and 'debug'"
	@echo "- Possible choices for LEON are 'leon2' and 'leon3' (default)"
	@echo "- Possible choices for FPU are '1' (native) and '0' (emulated) (default)"
	@echo "- Possible choices for V are '1' (show commands) and '0' (silent) (default)"
	@echo " "
	@exit 1
endif
endif


bin.$(SUFFIX)/${TARGET}: ${OBJ} | inform
	@mkdir -p $(dir $@)
ifeq ($(V),1)
	$(CC) -g -o $@ $^ ${LDFLAGS}
else
	@echo [LD] $@
	@$(CC) -g -o $@ $^ ${LDFLAGS}
endif
ifeq ($(CFG),release)
	@${RTEMS}/bin/${CROSS_PREFIX}-objcopy --only-keep-debug $@ ${@}.debug
	@${RTEMS}/bin/${CROSS_PREFIX}-strip $@
endif
	@echo Built with RTEMS at ${RTEMS_LIB} for ${LEON}.

objs.$(SUFFIX)/%.o: %.c | src/version.h
	@mkdir -p $(dir $@)
ifeq ($(V),1)
	$(CC) -c $(CFLAGS) -o $@ $<
else
	@echo [CC] $@
	@$(CC) -c $(CFLAGS) -o $@ $<
endif

deps.$(SUFFIX)/%.d: %.c
	@mkdir -p $(dir $@)
	@echo Generating dependencies for $<
	@set -e ; $(CDEP) -MM -MP $(INCLUDEFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,objs.$(SUFFIX)\/\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

src/version.h:	$(patsubst %, src/%, ${SRC}) Makefile
	@/bin/echo -en '#ifndef __VERSION_H__\n' > $@
	@/bin/echo -en "#define __VERSION_H__\n" >> $@
	@/bin/echo -en 'const char version[] = "1.' >> $@
	@git log --oneline | wc -l | tr -d '\n' >> $@
	@/bin/echo -n " (" >> $@
	@git log --oneline | head -1 | cut -d\  -f1 | tr -d '\n' >> $@
	@/bin/echo ')";' >> $@
	@/bin/echo -en "#endif\n" >> $@

clean:
	@rm -rf deps.* objs.* bin.*

# Unless "make clean" is called, include the dependency files
# which are auto-generated. Don't fail if they are missing
# (-include), since they will be missing in the first invocation!
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(CFG),)
-include ${DEP}
endif
endif
