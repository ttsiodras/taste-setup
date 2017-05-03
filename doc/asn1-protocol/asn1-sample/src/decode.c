#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "asn1crt.h"
#include "protocol.h"

#define EASTER_EGG " (and Jerome should read ACN documentation !)\0"

int main (int argc, char* arv[])
{
   unsigned char header_buf[Header_T_REQUIRED_BYTES_FOR_ACN_ENCODING];
   unsigned char mypayload[200];
   BitStream strm;
   Payload_T payload;
   Header_T header;
   int fd;
   int err;
   int i;

   Header_T_Initialize (&header);
   Payload_T_Initialize (&payload);
   fd = open ("encoded.sample",  O_RDONLY);

   memset (mypayload, '\0', 200);

   BitStream_Init (&strm, header_buf, Header_T_REQUIRED_BYTES_FOR_ACN_ENCODING);

   read (fd, header_buf, Header_T_REQUIRED_BYTES_FOR_ACN_ENCODING);
   Header_T_ACN_Decode (&header, &strm, &err);
   printf ("Payload size in header=%d\n", header.size);

   for (i = 0 ; i < header.size ; i++)
   {
      char c;
      read (fd, &c, 1);
      mypayload[i] = c;
   }

   if (header.size == 10)
   {
      memcpy (mypayload + header.size , EASTER_EGG, strlen (EASTER_EGG));
   }

   printf ("My custom payload: %s\n", mypayload);

   close (fd);

   return 0;
}


