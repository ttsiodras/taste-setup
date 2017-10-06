
#include <usb.h>
#include <errno.h>
#include <memory.h>
#include <linux/usbdevice_fs.h> // interface to kernel portion of user mode usb driver
#include <sys/ioctl.h>
#include <sys/time.h>
#include "ZestSC1.h"
#include "Local.h"


/******************************************************************************
* Perform bulk transfer                                                       *
* Maintain 2 active asynchronous URBs to maximise data transfer rate.         *
******************************************************************************/
ZESTSC1_STATUS ZestSC1_Transfer(ZESTSC1_HANDLE Handle, int EP, void *Buffer, int Length)
{
    ZESTSC1_HANDLE_STRUCT *Struct = (ZESTSC1_HANDLE_STRUCT *)Handle;
    unsigned long Count = 0;
    int fd = *((int *)(Struct->DeviceHandle)); // FIXME: Watch out here!
    struct usbdevfs_urb *urb[2];
    struct usbdevfs_urb urbs[2]; /*EC*/
    int Queued[2] = {0,0};
    ZESTSC1_STATUS Status = ZESTSC1_SUCCESS;
    struct usbdevfs_urb *urbreap = 0;
    int i;
    struct timeval TimeEnd;
    struct timeval TimeOut;
    int Bytes = 0;
    int LastTransfer;

    for (i=0; i<2; i++)
    {
      urb[i] = &urbs[i]; /*EC*/
    /* *EC*
        urb[i] = malloc(sizeof(struct usbdevfs_urb));
        if (urb[i]==NULL)
        {
            for (i--; i>=0; i--)
                free(urb[i]);
            return ZESTSC1_OUT_OF_MEMORY;
        }
    */
    }

    gettimeofday(&TimeEnd, NULL);
    TimeEnd.tv_sec += Struct->TimeOut/1000;
    TimeEnd.tv_usec += (Struct->TimeOut%1000)*1000;
    TimeOut.tv_sec = 0;
    TimeOut.tv_usec = 1000; // 1msec

    i = 0;
    LastTransfer = 1;
    for (Count=0; Count<(unsigned long)Length || LastTransfer==1; Count+=Bytes)
    {
        int RetVal;

        if ((Length-Count)<ZESTSC1_MAX_TRANSFER_LENGTH)
            Bytes = Length-Count;
        else
            Bytes = ZESTSC1_MAX_TRANSFER_LENGTH;
        if (Bytes==0)
            LastTransfer = 0;

        if (Bytes!=0)
        {
            /*
             * Submit the next URB
             */
            memset(urb[i], 0, sizeof(struct usbdevfs_urb));

            urb[i]->buffer_length = Bytes;
            urb[i]->actual_length = Bytes;
            urb[i]->buffer = ((char *)Buffer)+Count;
            urb[i]->type = ((EP==EP_INT_READ) ? USBDEVFS_URB_TYPE_INTERRUPT : USBDEVFS_URB_TYPE_BULK);
            urb[i]->endpoint = EP;

            RetVal = ioctl(fd, USBDEVFS_SUBMITURB, urb[i]);
            if (RetVal<0)
            {
                Status = ZESTSC1_INTERNAL_ERROR;
                goto Error;
            }
            Queued[i] = 1;
        }

        i=1-i;

        if (Count!=0)
        {
            /*
             * Reap the previous URB
             */
            struct timeval TimeNow;
            fd_set fset;

            FD_ZERO(&fset);
            FD_SET(fd, &fset);
            gettimeofday(&TimeNow, 0);

            while ((RetVal=ioctl(fd, USBDEVFS_REAPURBNDELAY, &urbreap))==-1 &&
                   ((TimeNow.tv_sec<TimeEnd.tv_sec) ||
                    (TimeNow.tv_sec==TimeEnd.tv_sec && TimeNow.tv_usec<TimeEnd.tv_usec)))
            {
                if (errno!=EAGAIN)
                {
                    Status = ZESTSC1_INTERNAL_ERROR;
                    goto Error;
                }
                select(fd+1, NULL, &fset, NULL, &TimeOut);
                gettimeofday(&TimeNow, 0);
            }
            if (RetVal==-1)
            {
                Status = ZESTSC1_TIMEOUT;
                goto Error;
            }
            if (urbreap->status!=0)
            {
                Status = ZESTSC1_INTERNAL_ERROR;
                goto Error;
            }
            Queued[i] = 0;
        }
    }

    /* *EC*
    for (i=0; i<2; i++)
        free(urb[i]);
    */

    return ZESTSC1_SUCCESS;

Error:
    for (i=0; i<2; i++)
    {
        if (Queued[i])
        {
            // Cancel URB
            ioctl(fd, USBDEVFS_DISCARDURB, &urb[i]);
        }
        /* *EC* free(urb[i]); */
    }

    return Status;
}

