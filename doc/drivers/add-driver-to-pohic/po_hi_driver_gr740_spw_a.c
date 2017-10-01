/*
 * This is a part of PolyORB-HI-C distribution, a minimal
 * middleware written for generated code from AADL models.
 * You should use it with the Ocarina toolsuite.
 *
 * For more informations, please visit http://taste.tuxfamily.org/wiki
 *
 * Copyright (C) 2017 ESA
 */

#include <deployment.h>
/* Generated code header */

// The following pattern is __PO_HI_NEED_DRIVER_<Driver_Name> 
// the Driver_Name is in the AADL file (Deployment::Driver_Name)
// Then the definition will be done in deployment.h automatically
#ifdef __PO_HI_NEED_DRIVER_GR740_SPW_A

#include <activity.h>
#include <marshallers.h>
#include <deployment.h>

#include <po_hi_debug.h>
#include <po_hi_transport.h>
#include <po_hi_gqueue.h>
#include <po_hi_messages.h>
#include <po_hi_returns.h>

#include <drivers/po_hi_driver_gr740_spw_a.h>

#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#include <stdio.h>
/* POSIX-style files */

//__po_hi_request_t __po_hi_c_driver_gr740_spw_a_request;
//__po_hi_msg_t     __po_hi_c_driver_gr740_spw_a_poller_msg;

void __po_hi_c_driver_gr740_spw_a_poller (const __po_hi_device_id dev_id)
{
    printf("[SPW_A_Port] Polling (in fact doing nothing)\n");

//  __po_hi_c_driver_gr740_spw_a_poller_msg.length = n;
//  __po_hi_unmarshall_request (&__po_hi_c_driver_gr740_spw_a_request, &__po_hi_c_driver_gr740_spw_a_poller_msg);
//  __po_hi_main_deliver (&__po_hi_c_driver_gr740_spw_a_request);


}

void __po_hi_c_driver_gr740_spw_a_init (__po_hi_device_id id)
{
   int i;
   __po_hi_c_spacewire_conf_t* drv_conf;  // instance of ASN.1 type with the configuration
   printf("[SPW_A_Port] Initializing\n");

   drv_conf = (__po_hi_c_spacewire_conf_t*) __po_hi_get_device_configuration (id);

   __po_hi_transport_set_sending_func (id, __po_hi_c_driver_gr740_spw_a_sender);

   printf("[SPW_A_Port] Device Name = %s\n", drv_conf->devname);
}

// I hope there can't be simultaneous callers....
__po_hi_msg_t           __po_hi_c_driver_gr740_spw_a_sender_msg;

int __po_hi_c_driver_gr740_spw_a_sender (const __po_hi_task_id task_id, const __po_hi_port_t port)
{
   int                     n;
   int                     ts;

   uint8_t buf[__PO_HI_MESSAGES_MAX_SIZE+1];

   unsigned long* swap_pointer;
   unsigned long swap_value;
   __po_hi_local_port_t    local_port;
   __po_hi_request_t*      request;
   __po_hi_port_t          destination_port;
   __po_hi_device_id       dev_id;
   __po_hi_device_id       remote_device;
   __po_hi_c_spacewire_conf_t* remote_drv_conf;  // instance of ASN.1 type with the configuration

   dev_id = __po_hi_get_device_from_port (port);

   if (dev_id == invalid_device_id)
   {
      __PO_HI_DEBUG_DEBUG ("[GR740_SPW_A] Invalid device id for sending\n");
      return __PO_HI_UNAVAILABLE;
   }

   local_port = __po_hi_get_local_port_from_global_port (port);

   request = __po_hi_gqueue_get_most_recent_value (task_id, local_port);

   if (request->port == -1)
   {
      __PO_HI_DEBUG_DEBUG ("[GR740_SPW_A] Send output task %d, port %d (local_port=%d): no value to send\n", task_id, port, local_port);
      return __PO_HI_SUCCESS;
   }

   destination_port     = __po_hi_gqueue_get_destination (task_id, local_port, 0);
   // Identify remote device, to get its configuration
   remote_device        = __po_hi_get_device_from_port (destination_port);

   remote_drv_conf = (__po_hi_c_spacewire_conf_t*) __po_hi_get_device_configuration (remote_device);
   printf("[GR740_SPW_A_Sender] Sending to device name %s\n", remote_drv_conf->devname);

   __po_hi_msg_reallocate (&__po_hi_c_driver_gr740_spw_a_sender_msg);

   request->port = destination_port;
   printf ("[USB-SPW] Destination port= %d, send through device %d \n", destination_port, dev_id);

   __po_hi_marshall_request (request, &__po_hi_c_driver_gr740_spw_a_sender_msg);
   swap_pointer  = (unsigned long*) &__po_hi_c_driver_gr740_spw_a_sender_msg.content[0];
   swap_value    = *swap_pointer;
   *swap_pointer = __po_hi_swap_byte (swap_value);

   memcpy (&buf[1], __po_hi_c_driver_gr740_spw_a_sender_msg.content, __PO_HI_MESSAGES_MAX_SIZE);
   for (ts = 0 ; ts < __PO_HI_MESSAGES_MAX_SIZE ; ts++)
   {
      __PO_HI_DEBUG_DEBUG ("%x", __po_hi_c_driver_gr740_spw_a_sender_msg.content[ts]);
   }
   __PO_HI_DEBUG_DEBUG ("|\n");

   request->port = __PO_HI_GQUEUE_INVALID_PORT;

   return 1;
}

#endif
