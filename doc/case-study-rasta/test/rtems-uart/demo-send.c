/* Simple GRCAN interface test.
 * 
 * Gaisler Research 2007,
 * Daniel Hellström
 *
 */

#include <rtems.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sched.h>
#include <ctype.h>
#include <string.h>

#define CONFIGURE_INIT
#include <bsp.h> /* for device driver prototypes */

#define IOCTL(fd,num,arg) \
        { \
    int ret; \
        if ( (ret=ioctl(fd,num,arg)) != RTEMS_SUCCESSFUL ) { \
                        printf("ioctl " #num " failed: errno: %d (%d)\n",errno,ret); \
      return -1;\
                } \
  }


rtems_task Init( rtems_task_argument argument);	/* forward declaration needed */

/* configuration information */
#define CONFIGURE_APPLICATION_NEEDS_CONSOLE_DRIVER
#define CONFIGURE_APPLICATION_NEEDS_CLOCK_DRIVER
#define CONFIGURE_APPLICATION_NEEDS_NULL_DRIVER 1
#define CONFIGURE_MAXIMUM_TASKS             16
#define CONFIGURE_RTEMS_INIT_TASKS_TABLE
#define CONFIGURE_EXTRA_TASK_STACKS         (20 * RTEMS_MINIMUM_STACK_SIZE)
#define CONFIGURE_LIBIO_MAXIMUM_FILE_DESCRIPTORS 32
#define CONFIGURE_INIT_TASK_PRIORITY	100
#define CONFIGURE_MAXIMUM_DRIVERS 16

#include <rtems/confdefs.h>
#include <stdio.h>
#include <stdlib.h>

#include <pci.h>
#include <rasta.h>
#include <apbuart_rasta.h>

rtems_task status_task1(rtems_task_argument argument);


extern int uart_init(void);
extern void uart_start(void);
extern void uart_print_stats(void);


int status_init(void);
void status_start(void);

static rtems_id   tds[1];        /* array of task ids */
static rtems_name tnames[1];     /* array of task names */

rtems_task loop_task (rtems_task_argument unused);

amba_confarea_type amba_bus;
int uartfd;

/* ========================================================= 
   initialisation */

rtems_task Init(
  rtems_task_argument ignored
)
{
  rtems_status_code status;
  
  printf("******** Starting RASTA test ********\n");
  
  
  printf("Initializing PCI\n");
  /* Init AT697 PCI Controller */
	init_pci();
  
  printf("Registering RASTA drivers: ");
  fflush(NULL);
  if  ( rasta_register() ){
    printf("Error in rasta_register()\n");
    /*exit(1);*/
  }
  printf("OK\n");
    tnames[0] = rtems_build_name( 'T', 'D', 'U', '0');

  status = rtems_task_create( 
              tnames[0], 1, RTEMS_MINIMUM_STACK_SIZE * 2,
              RTEMS_TIMESLICE,
              RTEMS_DEFAULT_ATTRIBUTES, &tds[0]
              );
  status = rtems_task_start(tds[0], loop_task, NULL);

  status = rtems_task_delete(RTEMS_SELF);
}


rtems_task loop_task (rtems_task_argument unused) 
{
   int n;
/*
  amba_scan (&amba_bus, 0xfff00000, NULL);
  if (apbuart_register (&amba_bus))
  {
     printf ("REGISTRATION FAILED\n");
  } 
  */

  uartfd = open ("/dev/apburasta0", O_RDWR);
          IOCTL(uartfd, APBUART_SET_BAUDRATE, 19200); /* stream mode */
        IOCTL(uartfd, APBUART_SET_BLOCKING, APBUART_BLK_RX | APBUART_BLK_TX | APBUART_BLK_FLUSH);
        IOCTL(uartfd, APBUART_SET_TXFIFO_LEN, 64);  /* Transmitt buffer 64 chars */
        IOCTL(uartfd, APBUART_SET_RXFIFO_LEN, 256); /* Receive buffer 256 chars */
        IOCTL(uartfd, APBUART_SET_ASCII_MODE, 0); /* Make \n go \n\r or \r\n */
        IOCTL(uartfd, APBUART_CLR_STATS, 0);
        IOCTL(uartfd, APBUART_START, 0);



  printf ("uartfd = %d\n", uartfd);


  while(1){
     n = write (uartfd, "hello\n", 6); 
     printf ("print hello\n");
     printf ("write() returns %d\n", n);
     sleep(2);
  }
}
