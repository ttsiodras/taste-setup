
# Compile with slower (but safer) block transfer code
SAFEMODE = 1

TARGET = Lib/libZestSC1.a
ARFLAGS = r

OBJS = Main.o Error.o Data.o Config.o
ifdef SAFEMODE
#   OBJS += DataMac.o
# else
  OBJS += DataLinux.o
endif

CC = gcc


ifdef SAFEMODE
# Debugging values:
  CFLAGS = -c -fPIC -g -O0 -W -Wall -fno-inline -I../Inc
else
# Production values:
  CFLAGS = -c -O2 -W -Wall -I../Inc
endif

all: $(TARGET)

clean:
	rm $(TARGET)
	rm $(OBJS)

$(TARGET): $(OBJS)
	mkdir -p Lib
	$(AR) $(ARFLAGS) $(TARGET) $(OBJS)

