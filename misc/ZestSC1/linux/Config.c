
#include <string.h>
#include <sys/stat.h>
#include <stdio.h>
#include <usb.h>
#include <errno.h>
#include "ZestSC1.h"
#include "Local.h"


/*
 * Table of part type data
 */
static struct _ZESTSC1_PART_TYPE_MAP 
{
    char *Name;
    ZESTSC1_FPGA_TYPE PartType;
    long MinLength;
    long MaxLength;
}
ZestSC1_PartTypes[] =
{
    { "3s400", ZESTSC1_XC3S400, 211000, 213000 }, 
    { "3s1000", ZESTSC1_XC3S1000, 401000, 404000 },
};
#define ZESTSC1_NUM_PART_TYPES (sizeof(ZestSC1_PartTypes)/sizeof(struct _ZESTSC1_PART_TYPE_MAP))

/*
 * Local function prototypes
 */
static ZESTSC1_STATUS ZestSC1_LoadFile(char *FileName,
                                       ZESTSC1_IMAGE *Image);
static ZESTSC1_STATUS ZestSC1_Configure(ZESTSC1_HANDLE Handle,
                                        ZESTSC1_IMAGE Image);
static ZESTSC1_STATUS ZestSC1_FreeImage(ZESTSC1_IMAGE Image);


/******************************************************************************
* Configure the FPGA on a board directly from a file                          *
******************************************************************************/
ZESTSC1_STATUS ZestSC1ConfigureFromFile(ZESTSC1_HANDLE Handle,
                                        char *FileName)
{
    ZESTSC1_IMAGE Image;
    ZESTSC1_STATUS Status;

    /*
     * Load image from disk
     */
    Status = ZestSC1_LoadFile(FileName, &Image);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR("ZestSC1ConfigureFromFile", Status);
    }

    /*
     * Configure FPGA
     */
    Status = ZestSC1_Configure(Handle, Image);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZestSC1_FreeImage(Image);
        ZESTSC1_ERROR("ZestSC1ConfigureFromFile", Status);
    }

    /*
     * Free image
     */
    Status = ZestSC1_FreeImage(Image);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR("ZestSC1ConfigureFromFile", Status);
    }

    return ZESTSC1_SUCCESS;
}


/******************************************************************************
* Load an FPGA configuration from a file into memory                          *
******************************************************************************/
ZESTSC1_STATUS ZestSC1LoadFile(char *FileName,
                               ZESTSC1_IMAGE *Image)
{
    ZESTSC1_STATUS Status;

    Status = ZestSC1_LoadFile(FileName, Image);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR_GENERAL("ZestSC1LoadFile", Status);
    }

    return  ZESTSC1_SUCCESS;
}


/******************************************************************************
* Load an FPGA configuration from a file into memory                          *
* Internal version that always returns errors (i.e. no error callback)        *
******************************************************************************/
static ZESTSC1_STATUS ZestSC1_LoadFile(char *FileName,
                                       ZESTSC1_IMAGE *Image)
{
    int ImageDone = 0;
    int PartDone = 0;
    int Char[5];
    char *PartString = 0;
    unsigned long Count;
    unsigned long BufferLength;
    char *Buffer = 0;
#ifdef MSVC
    struct _stat FileStat;
#else
    struct stat FileStat;
#endif
    int Length;
    FILE *FileHandle;
    ZESTSC1_IMAGE_HANDLE_STRUCT *NewHandle;
    ZESTSC1_STATUS RetVal = ZESTSC1_SUCCESS;

    /*
     * Open file
     */
    if (FileName==NULL || Image==NULL)
    {
        return ZESTSC1_NULL_PARAMETER;
    }

    FileHandle = fopen(FileName, "rb");
    if (FileHandle==NULL)
    {
        return ZESTSC1_FILE_NOT_FOUND;
    }

    /*
     * Get the file length
     */
    if (stat(FileName, &FileStat)!=0)
    {
        /*
         * Could not get file status
         */
        fclose(FileHandle);

        return ZESTSC1_FILE_ERROR;
    }

    /*
     * Allocate a new handle and initialise
     */
    NewHandle = (ZESTSC1_IMAGE_HANDLE_STRUCT *)malloc(sizeof(ZESTSC1_IMAGE_HANDLE_STRUCT));
    if (NewHandle==NULL)
    {
        return ZESTSC1_OUT_OF_MEMORY;
    }
    NewHandle->Magic = ZESTSC1_IMAGE_HANDLE_MAGIC;
    NewHandle->Buffer = NULL;

    /*
     * Need to search for part type and image fields in the file
     */
    while (ImageDone==0 || PartDone==0)
    {
        Char[0] = fgetc(FileHandle);
        if (Char[0]==EOF)
        {
            /*
             * Not expecting an end of file
             */
            RetVal = ZESTSC1_ILLEGAL_FILE;
            goto fail;
        }

        switch (Char[0])
        {
        case ZESTSC1_BITFILE_NAME:
        case ZESTSC1_BITFILE_DATE:
        case ZESTSC1_BITFILE_TIME:
            /*
             * String field encountered - ignore
             */
            Char[1] = fgetc(FileHandle);
            Char[2] = fgetc(FileHandle);
            if (Char[1]==EOF || Char[2]==EOF)
            {
                /*
                 * Not expecting an end of file
                 */
                RetVal = ZESTSC1_ILLEGAL_FILE;
                goto fail;
            }

            Length = (((unsigned long)Char[1])<<8) | (unsigned long)Char[2];
            if (Length>FileStat.st_size)
            {
                /*
                 * Illegal value - assume its a bad format file
                 */
                RetVal = ZESTSC1_ILLEGAL_FILE;
                goto fail;
            }

            /*
             * Drop the string but check it is a valid string
             */
            for (Count=Length; Count>0; Count--)
            {
                Char[0]=fgetc(FileHandle);
                if (Char[0]==EOF)
                {
                    RetVal = ZESTSC1_ILLEGAL_FILE;
                    goto fail;
                }

                if (Char[0]==0 && Count!=1)
                {
                    RetVal = ZESTSC1_ILLEGAL_FILE;
                    goto fail;
                }
            }
            break;

        case ZESTSC1_BITFILE_PART:
            /*
             * Field containing the part type
             */
            Char[1] = fgetc(FileHandle);
            Char[2] = fgetc(FileHandle);
            if (Char[1]==EOF || Char[2]==EOF)
            {
                /*
                 * Not expecting an end of file
                 */
                RetVal = ZESTSC1_ILLEGAL_FILE;
                goto fail;
            }

            Length = (((unsigned long)Char[1])<<8) | (unsigned long)Char[2];

            /*
             * Read the string
             */
            if (Length>16)
            {
                /*
                 * This is not a part type
                 */
                RetVal = ZESTSC1_ILLEGAL_FILE;
                goto fail;
            }
            PartString=malloc(Length);
            if (PartString==NULL)
            {
                /*
                 * Could not allocate buffer for string
                 */
                RetVal = ZESTSC1_OUT_OF_MEMORY;
                goto fail;
            }
            if (fgets(PartString, Length, FileHandle)==NULL)
            {
                /*
                 * File error while reading string
                 */
                RetVal = ZESTSC1_ILLEGAL_FILE;
                goto fail;
            }

            PartDone=1;
            break;

        case ZESTSC1_BITFILE_IMAGE:
            /*
             * Field containing the image data
             */
            Char[1] = fgetc(FileHandle);
            Char[2] = fgetc(FileHandle);
            Char[3] = fgetc(FileHandle);
            Char[4] = fgetc(FileHandle);
            if (Char[1]==EOF || Char[2]==EOF || Char[3]==EOF || Char[4]==EOF)
            {
                /*
                 * Not expecting an end of file
                 */
                RetVal = ZESTSC1_ILLEGAL_FILE;
                goto fail;
            }

            BufferLength = (((unsigned long)Char[1])<<24) |
                           (((unsigned long)Char[2])<<16) |
                           (((unsigned long)Char[3])<<8) |
                           ((unsigned long)Char[4]);

            if (BufferLength>(unsigned long)FileStat.st_size)
            {
                /*
                 * Illegal value - assume its a bad format file
                 */
                RetVal = ZESTSC1_ILLEGAL_FILE;
                goto fail;
            }

            Buffer = malloc((BufferLength+511+512)&~511);
            if (Buffer==NULL)
            {
                /*
                 * Could not allocate buffer for image
                 */
                RetVal = ZESTSC1_ILLEGAL_FILE;
                goto fail;
            }

            ImageDone=1;
            if (fread(Buffer, sizeof(char), BufferLength, FileHandle)!=BufferLength*sizeof(char))
            {
                /*
                 * Error while reading data
                 */
                RetVal = ZESTSC1_ILLEGAL_FILE;
                goto fail;
            }
            memset(Buffer+BufferLength, 0, ((BufferLength+511+512)&~511)-BufferLength);

            NewHandle->Buffer = Buffer;
            NewHandle->BufferSize = BufferLength;
            break;
        }
    }

    /*
     * Try to find part type
     */
    NewHandle->PartType = ZESTSC1_FPGA_UNKNOWN;
    for (Count=0; Count<ZESTSC1_NUM_PART_TYPES; Count++)
    {
        if (PartString && strstr(PartString, ZestSC1_PartTypes[Count].Name)!=NULL)
        {
            NewHandle->PartType = ZestSC1_PartTypes[Count].PartType;
            break;
        }
    }
    
    fclose(FileHandle);
    free(PartString);

    if (NewHandle->PartType==ZESTSC1_FPGA_UNKNOWN)
    {
        free(Buffer);

        return ZESTSC1_INVALID_PART_TYPE;
    }
    else
    {
        *Image = NewHandle;

        return ZESTSC1_SUCCESS;
    }

fail:
    /* 
     * Failure while reading file
     */
    if (FileHandle!=NULL)
    {
        fclose(FileHandle);
    }
    if (PartDone==1)
    {
        free(PartString);
    }
    if (ImageDone==1)
    {
        free(Buffer);
    }
    free(NewHandle);

    return RetVal;
}


/******************************************************************************
* Configure the FPGA on a board from a configuration image in memory          *
******************************************************************************/
ZESTSC1_STATUS ZestSC1Configure(ZESTSC1_HANDLE Handle,
                                ZESTSC1_IMAGE Image)
{
    ZESTSC1_STATUS Status;
    
    Status = ZestSC1_Configure(Handle, Image);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR("ZestSC1Configure", Status);
    }

    return  ZESTSC1_SUCCESS;
}


/******************************************************************************
* Configure the FPGA on a board from a configuration image in memory          *
* Internal version that always returns errors (i.e. no error callback)        *
******************************************************************************/
static ZESTSC1_STATUS ZestSC1_Configure(ZESTSC1_HANDLE Handle,
                                        ZESTSC1_IMAGE Image)
{
    char Buffer[3] = {0,0,0};
    ZESTSC1_HANDLE_STRUCT *Struct = (ZESTSC1_HANDLE_STRUCT *)Handle;
    ZESTSC1_IMAGE_HANDLE_STRUCT *ImageStruct = (ZESTSC1_IMAGE_HANDLE_STRUCT *)Image;
    int RetVal = 0;
    unsigned long Length = 0;
    ZESTSC1_STATUS Status;

    /*
     * Check the card handle is OK
     */
    if (Struct==NULL ||
        Struct->Magic!=ZESTSC1_HANDLE_MAGIC)
    {
        return ZESTSC1_ILLEGAL_HANDLE;
    }

    /*
     * Check the image handle is OK
     */
    if (ImageStruct==NULL ||
        ImageStruct->Magic!=ZESTSC1_IMAGE_HANDLE_MAGIC)
    {
        return ZESTSC1_ILLEGAL_IMAGE_HANDLE;
    }

    /*
     * Abort all current transfers
     */
    // FIXME: There is no Linux equivalent of AbortPipe

    /*
     * Reset 8051
     */
    Status = ZestSC1_Reset8051(Handle);
    if (Status!=ZESTSC1_SUCCESS)
    {
        return Status;
    }

    /*
     * Send data to the card
     */
    Length = (ImageStruct->BufferSize+511+512)&~511;
    RetVal = usb_control_msg(Struct->DeviceHandle, EP_CTRL_READ, VR_START_CONFIG,
                             (Length>>16)&0xffff, Length&0xffff,
                             Buffer, 2, Struct->TimeOut);
    if (RetVal<=0)
    {
        return ZESTSC1_INTERNAL_ERROR;
    }
    if (Buffer[1]!=0)
    {
        return ZESTSC1_TIMEOUT;
    }

    if (usb_bulk_write(Struct->DeviceHandle, EP_CONFIG_WRITE,
                       ImageStruct->Buffer, Length, Struct->TimeOut)!=(long)Length)
    {
        return ZESTSC1_INTERNAL_ERROR;
    }

    RetVal = usb_control_msg(Struct->DeviceHandle, EP_CTRL_READ, VR_CONFIG_STATUS,
                             0, 0, Buffer, 3, Struct->TimeOut);
    if (RetVal<=0)
    {
        return ZESTSC1_INTERNAL_ERROR;
    }
    if (Buffer[1]!=0)
    {
        return ZESTSC1_TIMEOUT;
    }

    return ZESTSC1_SUCCESS;
}


/******************************************************************************
* Register a configuration image in memory ready for configuration            *
******************************************************************************/
ZESTSC1_STATUS ZestSC1RegisterImage(void *Buffer,
                                    unsigned long BufferLength,
                                    ZESTSC1_IMAGE *Image)
{
    int Count;
    ZESTSC1_IMAGE_HANDLE_STRUCT *NewHandle;

    /* 
     * Allocate a new handle and initialise
     */
    NewHandle = (ZESTSC1_IMAGE_HANDLE_STRUCT *)malloc(sizeof(ZESTSC1_IMAGE_HANDLE_STRUCT));
    if (NewHandle==NULL)
    {
        ZESTSC1_ERROR_GENERAL("ZestSC1RegisterImage", ZESTSC1_OUT_OF_MEMORY);
    }
    NewHandle->Magic = ZESTSC1_IMAGE_HANDLE_MAGIC;
    NewHandle->Buffer = malloc((BufferLength+511+512)&~511);
    if (NewHandle->Buffer==NULL)
    {
        free(NewHandle);
        ZESTSC1_ERROR_GENERAL("ZestSC1RegisterImage", ZESTSC1_OUT_OF_MEMORY);
    }
    memcpy(NewHandle->Buffer, Buffer, BufferLength);
    memset((char *)NewHandle->Buffer+BufferLength, 0, ((BufferLength+511+512)&~511)-BufferLength);
    NewHandle->BufferSize = BufferLength;

    /*
     * Determine part type
     */
    NewHandle->PartType = ZESTSC1_FPGA_UNKNOWN;
    for (Count=0; Count<(int)ZESTSC1_NUM_PART_TYPES; Count++)
    {
        if ((ZestSC1_PartTypes[Count].MinLength==-1 || BufferLength>=(unsigned long)ZestSC1_PartTypes[Count].MinLength) &&
            (ZestSC1_PartTypes[Count].MaxLength==-1 || BufferLength<=(unsigned long)ZestSC1_PartTypes[Count].MaxLength))
        {
            NewHandle->PartType = ZestSC1_PartTypes[Count].PartType;
            break;
        }
    }
    
    if (NewHandle->PartType == ZESTSC1_FPGA_UNKNOWN)
    {
        free(NewHandle->Buffer);
        free(NewHandle);
        ZESTSC1_ERROR_GENERAL("ZestSC1RegisterImage", ZESTSC1_INVALID_PART_TYPE);
    }
    else
    {
        *Image = NewHandle;
        return ZESTSC1_SUCCESS;
    }
}


/******************************************************************************
* Free a registered FPGA configuration image                                  *
******************************************************************************/
ZESTSC1_STATUS ZestSC1FreeImage(ZESTSC1_IMAGE Image)
{
    ZESTSC1_STATUS Status;
    
    Status = ZestSC1_FreeImage(Image);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR_GENERAL("ZestSC1FreeImage", Status);
    }

    return ZESTSC1_SUCCESS;
}


/******************************************************************************
* Free a registered FPGA configuration image                                  *
* Internal version that always returns errors (i.e. no error callback)        *
******************************************************************************/
static ZESTSC1_STATUS ZestSC1_FreeImage(ZESTSC1_IMAGE Image)
{
    ZESTSC1_IMAGE_HANDLE_STRUCT *ImageStruct = (ZESTSC1_IMAGE_HANDLE_STRUCT *)Image;

    /*
     * Check the image handle is OK
     */
    if (ImageStruct==NULL ||
        ImageStruct->Magic!=ZESTSC1_IMAGE_HANDLE_MAGIC)
    {
        return ZESTSC1_ILLEGAL_IMAGE_HANDLE;
    }

    /* 
     * Free buffer
     */
    ImageStruct->Magic = 0;
    free(ImageStruct->Buffer);
    free(ImageStruct);

    return  ZESTSC1_SUCCESS;
}



