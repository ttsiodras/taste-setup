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
                        printf("ioctl " #num " failed: errno: %d (%d) - \n",errno,ret, strerror(errno)); \
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
#include <pci.h>
#include <rasta.h>
#include <grspw_rasta.h>

#include <rtems/confdefs.h>
#include <stdio.h>
#include <stdlib.h>



#define NODE_ADR_RX 10
#define NODE_ADR_TX 22



rtems_task status_task1(rtems_task_argument argument);




int status_init(void);
void status_start(void);

static rtems_id   tds[1];        /* array of task ids */
static rtems_name tnames[1];     /* array of task names */

rtems_task loop_task (rtems_task_argument unused);

amba_confarea_type amba_bus;
int spwfd;

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
  
  printf("Registering SpaceWire drivers: ");
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
printf ("open\n");
  spwfd = open ("/dev/grspwrasta0", O_RDWR);
  printf ("open result=%d\n", spwfd);
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_COREFREQ,30000); /* make driver calculate timings from 30MHz spacewire clock */
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_NODEADDR,10);
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_RXBLOCK,1);
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_TXBLOCK,0);
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_TXBLOCK_ON_FULL,1);
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_RM_PROT_ID,1); /* remove protocol id */
  IOCTL(spwfd,SPACEWIRE_IOCTRL_START,2000); /* remove protocol id */
printf ("endconf\n");
/*  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_CLKDIV,0);*/



  printf ("spwfd = %d\n", spwfd);

printf ("fin configuration\n");

  status = rtems_task_start(tds[0], loop_task, NULL);

  status = rtems_task_delete(RTEMS_SELF);
}


rtems_task loop_task (rtems_task_argument unused) 
{
   int n;
  while(1){
     n = write (spwfd, "hello\n", 6); 
     printf ("print hello\n");
     printf ("write() returns %d\n", n);
     sleep(2);
  }
}
