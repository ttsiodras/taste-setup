#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "asn1crt.h"
#include "protocol.h"


int main (int argc, char* arv[])
{
   unsigned char encoded[Packet_T_REQUIRED_BITS_FOR_ACN_ENCODING];
   BitStream strm;
   Packet_T pkt;
   int fd;
   int err;

   Packet_T_Initialize (&pkt);
   BitStream_Init (&strm, encoded, Packet_T_REQUIRED_BITS_FOR_ACN_ENCODING);

   pkt.header.size = 10;
   pkt.header.port = 2;
   pkt.payload.nCount = 10;
   memcpy (pkt.payload.arr, "ACN rocks!", 10);

   if (Packet_T_ACN_Encode (&pkt, &strm, &err, 1))
   {
      printf ("Encoding OK, size of the stream is %d\n", strm.count);
      fd = open ("encoded.sample",  O_RDWR | O_CREAT, S_IRUSR | S_IWUSR );
      write (fd, encoded, strm.count);
      close (fd);
   }
   else
   {
      printf ("Encoding KO\n");
   }
   return 0;
}


