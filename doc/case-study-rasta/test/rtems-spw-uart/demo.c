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

#define RXPKT_BUF 5
#define PKTSIZE 1000
struct packet_hdr {
	unsigned char addr;
	unsigned char protid;
	unsigned char dummy;
  unsigned char channel;
  unsigned char data[PKTSIZE];
};

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
#include <apbuart_rasta.h>

#include <rtems/confdefs.h>
#include <stdio.h>
#include <stdlib.h>




#define NODE_ADR_RX 10
#define NODE_ADR_TX 22



rtems_task status_task1(rtems_task_argument argument);




int status_init(void);
void status_start(void);

static rtems_id   tds[3];        /* array of task ids */
static rtems_name tnames[3];     /* array of task names */

rtems_task loop_task (rtems_task_argument unused);
rtems_task loop_task2 (rtems_task_argument unused);
rtems_task loop_task_uart (rtems_task_argument unused);

amba_confarea_type amba_bus;
int spwfd;
int spwfd2;
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
    tnames[1] = rtems_build_name( 'T', 'D', 'U', '1');

  status = rtems_task_create( 
              tnames[1], 1, RTEMS_MINIMUM_STACK_SIZE * 2,
              RTEMS_TIMESLICE,
              RTEMS_DEFAULT_ATTRIBUTES, &tds[1]
              );

printf ("open\n");
  spwfd = open ("/dev/grspwrasta0", O_RDWR);
  spwfd2 = open ("/dev/grspwrasta1", O_RDWR);
  printf ("open result=%d\n", spwfd);
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_COREFREQ,30000); /* make driver calculate timings from 30MHz spacewire clock */
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_NODEADDR,22);
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_RXBLOCK,1);
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_TXBLOCK,0);
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_TXBLOCK_ON_FULL,1);
  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_RM_PROT_ID,1); /* remove protocol id */

  IOCTL(spwfd2,SPACEWIRE_IOCTRL_SET_COREFREQ,30000); /* make driver calculate timings from 30MHz spacewire clock */
  IOCTL(spwfd2,SPACEWIRE_IOCTRL_SET_NODEADDR,10);
  IOCTL(spwfd2,SPACEWIRE_IOCTRL_SET_RXBLOCK,1);
  IOCTL(spwfd2,SPACEWIRE_IOCTRL_SET_TXBLOCK,0);
  IOCTL(spwfd2,SPACEWIRE_IOCTRL_SET_TXBLOCK_ON_FULL,1);
  IOCTL(spwfd2,SPACEWIRE_IOCTRL_SET_RM_PROT_ID,1); /* remove protocol id */

  IOCTL(spwfd,SPACEWIRE_IOCTRL_START,2000); /* remove protocol id */
  IOCTL(spwfd2,SPACEWIRE_IOCTRL_START,2000); /* remove protocol id */

printf ("endconf\n");
/*  IOCTL(spwfd,SPACEWIRE_IOCTRL_SET_CLKDIV,0);*/


  printf ("spwfd = %d\n", spwfd);

printf ("fin configuration\n");

    tnames[2] = rtems_build_name( 'T', 'D', 'U', '2');

  status = rtems_task_create( 
              tnames[0], 1, RTEMS_MINIMUM_STACK_SIZE * 2,
              RTEMS_TIMESLICE,
              RTEMS_DEFAULT_ATTRIBUTES, &tds[2]
              );



  status = rtems_task_start(tds[1], loop_task2, NULL);
  status = rtems_task_start(tds[0], loop_task, NULL);

  status = rtems_task_start(tds[2], loop_task_uart, NULL);

  status = rtems_task_delete(RTEMS_SELF);
}

/* RX Task */
static unsigned char rxpkt[PKTSIZE*RXPKT_BUF];
static struct packet_hdr txpkts[1];

void init_pkt(struct packet_hdr *p){
  int i;
  unsigned char j=0;
  
  p->addr = NODE_ADR_RX;
  p->protid = 50;
  p->dummy = 0x01;
  p->channel = 0x01;
  for(i=0; i<PKTSIZE; i++){
    p->data[i] = j;
    j++;
  }

}


rtems_task loop_task (rtems_task_argument unused) 
{
   /*
   int n;
  while(1){
     n = write (spwfd, "hello\n", 6); 
     printf ("print hello in first link\n");
     printf ("write() returns %d\n", n);
     sleep(1);
  }
  */
  unsigned char i;
  int j;
  int len,cnt=0;
  int loop;
  printf("SpaceWire TX Task started\n");
  
  for(i=0; i<1; i++)
    init_pkt(&txpkts[i]);
    
  i=0;
  loop=0;
  while ( 1 ) {
      memcpy (txpkts[0].data, "bonjour", 6);

    if ( (len=write(spwfd,txpkts,PKTSIZE+4)) < 0 ){
      printf("Failed to write errno:%d (%d)\n",errno,cnt);
      break;
    }
    else
    {
         printf ("Data sent over the link\n");
    }
    sleep (1);
    sched_yield();
  }


}

rtems_task loop_task2 (rtems_task_argument unused) 
{
/*   int n;
   char buf[6];
   printf("start task receiver\n");
  while(1){
     n = read (spwfd2, buf, 6);
     printf ("read() returns %d\n", n);
     buf[5] = '\0';
     printf ("read %s\n", buf);
     sleep(1);
  }
  */
   char buf[1024];
  int len;
  int cnt=0;
  int j;
  unsigned char i=0;
  int n;
  unsigned int tot=0;
  int pktofs=0;

  printf("SpaceWire RX Task started\n");
  while(1){
    /*memset(&rxpkt,0,sizeof(rxpkt));*/
    
    if ( (len=read(spwfd2,&rxpkt[0],PKTSIZE*RXPKT_BUF)) < 1 ){
      printf("Failed read: len: %d, errno: %d (%d)\n",len,errno,cnt);
    }
    else
    {
         printf ("Good read\n");
    }
    
    /* skip first 2bytes (vchan and dummy) */
    if ( (rxpkt[0]==1) && (rxpkt[1]==1) ){
      j=2; /* strip virtual channel protocol, non-ssspw device */
    }else{
      j=0; /* hardware uses virtual channel protocol, hw already stripped it */
    }

   n = 0; 
memcpy (buf, rxpkt, 6);
buf[6] = '\0';
    printf("received: %s\n", buf);
   sleep (1);  
    sched_yield();
  }

}


rtems_task loop_task_uart (rtems_task_argument unused) 
{
   int n;
   char buf[1024];
/*
  amba_scan (&amba_bus, 0xfff00000, NULL);
  if (apbuart_register (&amba_bus))
  {
     printf ("REGISTRATION FAILED\n");
  } 
  */

  uartfd = open ("/dev/apburasta0", O_RDWR);
          IOCTL(uartfd, APBUART_SET_BAUDRATE, 19200); /* stream mode */
        /*IOCTL(uartfd, APBUART_SET_BLOCKING, APBUART_BLK_RX | APBUART_BLK_TX);*/

        IOCTL(uartfd, APBUART_SET_BLOCKING, APBUART_BLK_RX | APBUART_BLK_TX | APBUART_BLK_FLUSH);
        IOCTL(uartfd, APBUART_SET_TXFIFO_LEN, 64);  /* Transmitt buffer 64 chars */
        IOCTL(uartfd, APBUART_SET_RXFIFO_LEN, 256); /* Receive buffer 256 chars */
        IOCTL(uartfd, APBUART_SET_ASCII_MODE, 1); /* Make \n go \n\r or \r\n */
        IOCTL(uartfd, APBUART_CLR_STATS, 0);
        IOCTL(uartfd, APBUART_START, 0);



  printf ("uartfd = %d\n", uartfd);


  while(1){
     n = read (uartfd, &buf, 1024); 
     printf ("read() returns %d\n", n);
     if (n > 0)
     {
        buf[n] = '\0';
         printf ("Received: %s\n", buf);
     }
     sleep(2);
  }
}


