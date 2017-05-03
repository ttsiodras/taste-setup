CC=sparc-rtems-gcc
LD=sparc-rtems-ld
OBJDUMP=sparc-rtems-objdump

PROGS = demo
COPTS = -O2 
CFLAGS = -Wall -g3 $(COPTS) -qleon2

L2=-qleon2


all: $(PROGS)
	

demo: demo.o 
	$(CC) $(L2) $(CFLAGS) -o demo demo.c

clean:
	rm -f $(PROGS) *.o *.S
        
