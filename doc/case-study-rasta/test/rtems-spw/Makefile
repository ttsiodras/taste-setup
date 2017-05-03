CC=sparc-rtems-gcc
LD=sparc-rtems-ld
OBJDUMP=sparc-rtems-objdump

PROGS = demo-send demo-send-receive
COPTS = -O2 
CFLAGS = -Wall -g3 $(COPTS) -qleon2

L2=-qleon2


all: $(PROGS)
	

demo-send: demo-send.o 
	$(CC) $(L2) $(CFLAGS) -o demo-send demo-send.c

demo-send-receive: demo-send-receive.o 
	$(CC) $(L2) $(CFLAGS) -o demo-send-receive demo-send-receive.c

clean:
	rm -f $(PROGS) *.o *.S
        
