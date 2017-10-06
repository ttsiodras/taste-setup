/**********************************************************
*                                                         *
* (c) 2004 Orange Tree Technologies Ltd                   *
*                                                         *
* ZestSC1.h                                               *
* Version 1.0                                             *
*                                                         *
* Header file for ZestSC1 USB FPGA card                   *
*                                                         *
**********************************************************/

#ifndef __ZESTSC1_H__
#define __ZESTSC1_H__

#ifdef __cplusplus
extern "C"
{
#endif


/**********************************************************
* Handles for referencing boards and configuration images *
**********************************************************/
typedef void *ZESTSC1_HANDLE;
typedef void *ZESTSC1_IMAGE;


/************************
* Function return codes *
************************/
#define ZESTSC1_INFO_BASE 0
#define ZESTSC1_WARNING_BASE 0x4000
#define ZESTSC1_ERROR_BASE 0x8000
typedef enum
{
    ZESTSC1_SUCCESS = ZESTSC1_INFO_BASE,
    ZESTSC1_MAX_INFO,

    ZESTSC1_MAX_WARNING = ZESTSC1_WARNING_BASE,

    ZESTSC1_ILLEGAL_HANDLE = ZESTSC1_ERROR_BASE,
    ZESTSC1_ILLEGAL_STATUS_CODE,
    ZESTSC1_NULL_PARAMETER,
    ZESTSC1_DEVICE_IN_USE,
    ZESTSC1_ILLEGAL_CARD_ID,
    ZESTSC1_INTERNAL_ERROR,
    ZESTSC1_OUT_OF_MEMORY,
    ZESTSC1_FILE_NOT_FOUND,
    ZESTSC1_FILE_ERROR,
    ZESTSC1_ILLEGAL_FILE,
    ZESTSC1_TIMEOUT,
    ZESTSC1_DRIVER_MISSING,
    ZESTSC1_SIGNAL_IS_INPUT,
    ZESTSC1_SIGNAL_IS_OUTPUT,
    ZESTSC1_ILLEGAL_IMAGE_HANDLE,
    ZESTSC1_INVALID_PART_TYPE,

    ZESTSC1_MAX_ERROR
} ZESTSC1_STATUS;
typedef void (*ZESTSC1_ERROR_FUNC)(const char *Function, 
                                   ZESTSC1_HANDLE Handle,
                                   ZESTSC1_STATUS Status,
                                   const char *Msg);


/*******************
* Valid FPGA types *
*******************/
typedef enum
{
    ZESTSC1_FPGA_UNKNOWN,
    ZESTSC1_XC3S400,
    ZESTSC1_XC3S1000,
} ZESTSC1_FPGA_TYPE;


/*****************************
* Card information structure *
*****************************/
typedef struct
{
    unsigned long CardID;
    unsigned long SerialNumber;
    ZESTSC1_FPGA_TYPE FPGAType;
    unsigned long MemorySize;
    unsigned long TimeOut;
    unsigned long FirmwareVersion;
} ZESTSC1_CARD_INFO;


/**********************
* Function prototypes *
**********************/
ZESTSC1_STATUS ZestSC1CountCards(unsigned long *NumCards,
                                 unsigned long *CardIDs,
                                 unsigned long *SerialNumbers,
                                 ZESTSC1_FPGA_TYPE *FPGATypes);
ZESTSC1_STATUS ZestSC1OpenCard(unsigned long CardId,
                               ZESTSC1_HANDLE *Handle);
ZESTSC1_STATUS ZestSC1SetTimeOut(ZESTSC1_HANDLE Handle,
                                 unsigned long MilliSeconds);
ZESTSC1_STATUS ZestSC1SetCardID(ZESTSC1_HANDLE Handle,
                                unsigned long CardID);
ZESTSC1_STATUS ZestSC1GetCardInfo(ZESTSC1_HANDLE Handle,
                                  ZESTSC1_CARD_INFO *Info);
ZESTSC1_STATUS ZestSC1CloseCard(ZESTSC1_HANDLE Handle);

ZESTSC1_STATUS ZestSC1RegisterErrorHandler(ZESTSC1_ERROR_FUNC Function);
ZESTSC1_STATUS ZestSC1GetErrorMessage(ZESTSC1_STATUS Status,
                                      char **Buffer);

ZESTSC1_STATUS ZestSC1ConfigureFromFile(ZESTSC1_HANDLE Handle,
                                        char *FileName);
ZESTSC1_STATUS ZestSC1LoadFile(char *FileName,
                               ZESTSC1_IMAGE *Image);
ZESTSC1_STATUS ZestSC1Configure(ZESTSC1_HANDLE Handle,
                                ZESTSC1_IMAGE Image);
ZESTSC1_STATUS ZestSC1RegisterImage(void *Buffer,
                                    unsigned long BufferLength,
                                    ZESTSC1_IMAGE *Image);
ZESTSC1_STATUS ZestSC1FreeImage(ZESTSC1_IMAGE Image);

ZESTSC1_STATUS ZestSC1WriteRegister(ZESTSC1_HANDLE Handle,
                                    unsigned long Offset,
                                    unsigned char Value);
ZESTSC1_STATUS ZestSC1ReadRegister(ZESTSC1_HANDLE Handle,
                                   unsigned long Offset,
                                   unsigned char *Value);

ZESTSC1_STATUS ZestSC1ReadData(ZESTSC1_HANDLE Handle,
                               void *Buffer,
                               unsigned long Length);
ZESTSC1_STATUS ZestSC1WriteData(ZESTSC1_HANDLE Handle,
                                void *Buffer,
                                unsigned long Length);

ZESTSC1_STATUS ZestSC1SetSignalDirection(ZESTSC1_HANDLE Handle,
                                         unsigned char Direction);
ZESTSC1_STATUS ZestSC1SetSignals(ZESTSC1_HANDLE Handle,
                                 unsigned char Value);
ZESTSC1_STATUS ZestSC1ReadSignals(ZESTSC1_HANDLE Handle,
                                  unsigned char *Value);

ZESTSC1_STATUS ZestSC1WaitForInterrupt(ZESTSC1_HANDLE Handle);


#ifdef __cplusplus
}
#endif

#endif // __ZESTSC1_H__

