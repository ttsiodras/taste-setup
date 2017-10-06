
#include <stdio.h>
#include <usb.h>
#include <errno.h>
#include "ZestSC1.h"
#include "Local.h"

/*
 * Local function declaration
 */
static ZESTSC1_STATUS ZestSC1_CountCards(unsigned long *NumCards,
                                         unsigned long *CardIDs,
                                         unsigned long *SerialNumbers,
                                         ZESTSC1_FPGA_TYPE *FPGATypes,
                                         usb_dev_handle **RetHandle,
                                         int *Interface,
                                         unsigned long ReqCardID);
static ZESTSC1_STATUS ZestSC1_SetTimeOut(ZESTSC1_HANDLE Handle,
                                         unsigned long MilliSeconds);
static ZESTSC1_STATUS ZestSC1_ReadEEPROMRaw(usb_dev_handle *Handle,
                                            unsigned long Address,
                                            unsigned char *Data);


/******************************************************************************
* Return the total number of cards in the system                              *
* If CardIDs is non-NULL then fill in with a list of the card IDs             *
* If SerialNumbers is non-NULL then fill in with a list of the serial numbers *
******************************************************************************/
ZESTSC1_STATUS ZestSC1CountCards(unsigned long *NumCards,
                                 unsigned long *CardIDs,
                                 unsigned long *SerialNumbers,
                                 ZESTSC1_FPGA_TYPE *FPGATypes)
{
    ZESTSC1_STATUS Status;
    
    Status = ZestSC1_CountCards(NumCards, CardIDs, SerialNumbers, FPGATypes, NULL, NULL, 0);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR_GENERAL("ZestSC1CountCards", Status);
    }

    return ZESTSC1_SUCCESS;
}
static ZESTSC1_STATUS ZestSC1_CountCards(unsigned long *NumCards,
                                         unsigned long *CardIDs,
                                         unsigned long *SerialNumbers,
                                         ZESTSC1_FPGA_TYPE *FPGATypes,
                                         usb_dev_handle **RetHandle,
                                         int *Interface,
                                         unsigned long ReqCardID)
{
    int Count = 0;
    //usb_dev_handle *DeviceHandle;
    struct usb_bus *Buses;
    struct usb_bus *Bus;

    // Find ZestSC1 devices
    usb_init();

    usb_find_busses();
    usb_find_devices();
    Buses = usb_get_busses();
    for (Bus = Buses; Bus!=NULL; Bus = Bus->next)
    {
        struct usb_device *Dev;
        for (Dev = Bus->devices; Dev!=NULL; Dev = Dev->next)
        {
            if (Dev->descriptor.idVendor == VENDOR_ID &&
                Dev->descriptor.idProduct == PRODUCT_ID)
            {
                ZESTSC1_STATUS Status;
                unsigned char Value;
                unsigned long CardID = 255;
                unsigned long SerialNum = 0;
                ZESTSC1_FPGA_TYPE FPGAType = ZESTSC1_FPGA_UNKNOWN;
                int i;
                usb_dev_handle *DeviceHandle = usb_open(Dev);

                if (DeviceHandle==NULL)
                {
                    // Can't open device - move to next
                    continue;
                }

                // Get device details
                Status = ZestSC1_ReadEEPROMRaw(DeviceHandle, EEPROM_CARDID_ADDRESS, &Value);
                if (Status!=ZESTSC1_SUCCESS)
                {
                    usb_close(DeviceHandle);
                    continue;
                }
                CardID = Value;

                int ok = 1;
                for (i=0; i<4; i++)
                {
                    Status = ZestSC1_ReadEEPROMRaw(DeviceHandle, EEPROM_SERIAL_ADDRESS+i, &Value);
                    if (Status!=ZESTSC1_SUCCESS)
                    {
                        usb_close(DeviceHandle);
                        ok = 0;
                        break;
                    }
                    SerialNum = (SerialNum<<8) | Value;
                }
                if (!ok) continue;
                Status = ZestSC1_ReadEEPROMRaw(DeviceHandle, EEPROM_FPGA_ADDRESS, &Value);
                if (Status!=ZESTSC1_SUCCESS)
                {
                    usb_close(DeviceHandle);
                    continue;
                }
                FPGAType = Value;

                if (RetHandle!=NULL && CardID==ReqCardID)
                {
                    // Caller was requesting a specific card and this is it
                    // We know there is only one interface on the ZestSC1 - claim it
                    *Interface = Dev->config[0].interface[0].altsetting[0].bInterfaceNumber;
                    int ret = usb_claim_interface(DeviceHandle, Dev->config[0].interface[0].altsetting[0].bInterfaceNumber);
                    if (ret!=0)
                    {
                        usb_close(DeviceHandle);
                        return ZESTSC1_INTERNAL_ERROR;
                    }
                    *RetHandle = DeviceHandle;

                    return ZESTSC1_SUCCESS;
                }
                else
                {
                    // Caller was asking about all cards
                    if (CardIDs!=NULL)
                        CardIDs[Count] = CardID;
                    if (SerialNumbers!=NULL)
                        SerialNumbers[Count] = SerialNum;
                    if (FPGATypes!=NULL)
                        FPGATypes[Count] = FPGAType;
                    Count++;
                }
                usb_close(DeviceHandle);
            }
        }
    }

    if (RetHandle!=NULL)
    {
        return ZESTSC1_ILLEGAL_CARD_ID;
    }

    // Copy data to return parameters
    if (NumCards!=NULL)
    {
        *NumCards = Count;
    }

    return ZESTSC1_SUCCESS;
}


/******************************************************************************
* Open a card with a specified card ID                                        *
******************************************************************************/
ZESTSC1_STATUS ZestSC1OpenCard(unsigned long CardID,
                               ZESTSC1_HANDLE *Handle)
{
    ZESTSC1_STATUS Status;
    ZESTSC1_HANDLE_STRUCT *Struct;
    usb_dev_handle *DeviceHandle;
    int Interface = 0;
    int Count = 0;
    char Buffer[4096] = {0};
    int RetVal = 0;
    
    /*
     * Find the device index of the card
     */
    Status = ZestSC1_CountCards(NULL, NULL, NULL, NULL, &DeviceHandle, &Interface, CardID);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR("ZestSC1OpenCard", Status);
    }

    /*
     * Initialise the device structure
     */
    Struct = (ZESTSC1_HANDLE_STRUCT *)malloc(sizeof(ZESTSC1_HANDLE_STRUCT));
    if (Struct==NULL)
    {
        usb_release_interface(DeviceHandle, Interface);
        usb_close(DeviceHandle);
        ZESTSC1_ERROR("ZestSC1OpenCard", ZESTSC1_OUT_OF_MEMORY);
    }
    Struct->Magic = ZESTSC1_HANDLE_MAGIC;
    Struct->DeviceHandle = DeviceHandle;
    Struct->TimeOut = ZESTSC1_DEFAULT_TIMEOUT;
    Struct->Interface = Interface;

    /*
     * Set the default timeout
     */
    Status = ZestSC1_SetTimeOut((ZESTSC1_HANDLE)Struct, ZESTSC1_DEFAULT_TIMEOUT);
    if (Status!=ZESTSC1_SUCCESS)
    {
        usb_release_interface(DeviceHandle, Interface);
        usb_close(DeviceHandle);
        free(Struct);
        ZESTSC1_ERROR("ZestSC1OpenCard", Status);
    }

    *Handle = (ZESTSC1_HANDLE)Struct;

    // FIXME: First configuration after plugging in sometimes fails
    // Doing a dummy configuration of 4096 bytes seems to fix this
    /*
     * Reset 8051 and endpoints
     */
#if 0
    RetVal = usb_clear_halt(Struct->DeviceHandle, EP_INT_READ);
    if (RetVal!=0)
    {
        printf("RetVal = %d\n", RetVal);
        usb_release_interface(DeviceHandle, Interface);
        usb_close(DeviceHandle);
        free(Struct);
        ZESTSC1_ERROR("ZestSC1OpenCard", ZESTSC1_INTERNAL_ERROR);
    }
#endif
    Status = ZestSC1_Reset8051(*Handle);
    if (Status!=ZESTSC1_SUCCESS)
    {
        usb_release_interface(DeviceHandle, Interface);
        usb_close(DeviceHandle);
        free(Struct);
        ZESTSC1_ERROR("ZestSC1OpenCard", Status);
    }
#if 0
    if (usb_clear_halt(Struct->DeviceHandle, EP_DATA_WRITE)!=0)
    {
        usb_release_interface(DeviceHandle, Interface);
        usb_close(DeviceHandle);
        free(Struct);
        ZESTSC1_ERROR("ZestSC1OpenCard", ZESTSC1_INTERNAL_ERROR);
    }
    if (usb_clear_halt(Struct->DeviceHandle, EP_DATA_READ)!=0)
    {
        usb_release_interface(DeviceHandle, Interface);
        usb_close(DeviceHandle);
        free(Struct);
        ZESTSC1_ERROR("ZestSC1OpenCard", ZESTSC1_INTERNAL_ERROR);
    }
#endif

    /*
     * Send data to the card
     */
    RetVal = usb_control_msg(Struct->DeviceHandle, EP_CTRL_READ, VR_START_CONFIG,
                             sizeof(Buffer)&0xffff, sizeof(Buffer)&0xffff,
                             Buffer, 2, Struct->TimeOut);
    if (RetVal<=0)
    {
        usb_release_interface(DeviceHandle, Interface);
        usb_close(DeviceHandle);
        free(Struct);
        return ZESTSC1_INTERNAL_ERROR;
    }
    if (Buffer[1]!=0)
    {
        usb_release_interface(DeviceHandle, Interface);
        usb_close(DeviceHandle);
        free(Struct);
        return ZESTSC1_TIMEOUT;
    }
    for (Count=0; Count<(int)sizeof(Buffer); Count+=ZESTSC1_MAX_TRANSFER_LENGTH)
    {
        int Bytes;

        if ((sizeof(Buffer)-Count)<ZESTSC1_MAX_TRANSFER_LENGTH)
            Bytes = sizeof(Buffer)-Count;
        else
            Bytes = ZESTSC1_MAX_TRANSFER_LENGTH;

        if (usb_bulk_write(Struct->DeviceHandle, EP_CONFIG_WRITE,
                           Buffer+Count, Bytes, Struct->TimeOut)!=Bytes)
        {
            usb_release_interface(DeviceHandle, Interface);
            usb_close(DeviceHandle);
            free(Struct);
            return ZESTSC1_INTERNAL_ERROR;
        }
    }
    Status = ZestSC1_Reset8051(*Handle);
    if (Status!=ZESTSC1_SUCCESS)
    {
        usb_release_interface(DeviceHandle, Interface);
        usb_close(DeviceHandle);
        free(Struct);
        ZESTSC1_ERROR("ZestSC1OpenCard", Status);
    }
    // End FIXME

    return ZESTSC1_SUCCESS;
}


/******************************************************************************
* Get information about a card                                                *
******************************************************************************/
ZESTSC1_STATUS ZestSC1GetCardInfo(ZESTSC1_HANDLE Handle,
                                  ZESTSC1_CARD_INFO *Info)
{
    ZESTSC1_STATUS Status;
    unsigned char Value;
    unsigned long CardID = 255;
    unsigned long SerialNum = 0;
    ZESTSC1_FPGA_TYPE FPGAType = ZESTSC1_FPGA_UNKNOWN;
    unsigned long MemorySize = 0;
    unsigned long FirmwareVersion = 0;
    int i;
    char Buffer[3];

    ZESTSC1_CHECK_HANDLE("ZestSC1GetCardInfo", Handle);
    if (Info==NULL)
    {
        return ZESTSC1_SUCCESS;
    }

    // Get device details
    Status = ZestSC1_ReadEEPROMRaw(Struct->DeviceHandle, EEPROM_CARDID_ADDRESS, &Value);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR("ZestSC1GetCardInfo", ZESTSC1_INTERNAL_ERROR);
    }
    CardID = Value;

    for (i=0; i<4; i++)
    {
        Status = ZestSC1_ReadEEPROMRaw(Struct->DeviceHandle, EEPROM_SERIAL_ADDRESS+i, &Value);
        if (Status!=ZESTSC1_SUCCESS)
        {
            ZESTSC1_ERROR("ZestSC1GetCardInfo", ZESTSC1_INTERNAL_ERROR);
        }
        SerialNum = (SerialNum<<8) | Value;
    }

    Status = ZestSC1_ReadEEPROMRaw(Struct->DeviceHandle, EEPROM_FPGA_ADDRESS, &Value);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR("ZestSC1GetCardInfo", ZESTSC1_INTERNAL_ERROR);
    }
    FPGAType = Value;

    for (i=0; i<4; i++)
    {
        Status = ZestSC1_ReadEEPROMRaw(Struct->DeviceHandle, EEPROM_MEMORY_SIZE_ADDRESS+i, &Value);
        if (Status!=ZESTSC1_SUCCESS)
        {
            ZESTSC1_ERROR("ZestSC1GetCardInfo", ZESTSC1_INTERNAL_ERROR);
        }
        MemorySize = (MemorySize<<8) | Value;
    }

    if (usb_control_msg(Struct->DeviceHandle, EP_CTRL_READ, VR_GET_FIRMWARE_VER, 0, 0, Buffer, 3, Struct->TimeOut)<=0)
    {
        ZESTSC1_ERROR("ZestSC1GetCardInfo", ZESTSC1_INTERNAL_ERROR);
    }
    FirmwareVersion = Buffer[1] | (Buffer[2]<<8);

    Info->CardID = CardID;
    Info->SerialNumber = SerialNum;
    Info->FPGAType = FPGAType;
    Info->MemorySize = MemorySize;
    Info->TimeOut = Struct->TimeOut;
    Info->FirmwareVersion = FirmwareVersion;

    return ZESTSC1_SUCCESS;
}


/******************************************************************************
* Set the timeout value for a card.                                           *
* All blocking functions from now on will use this timeout value (in ms).     *
******************************************************************************/
ZESTSC1_STATUS ZestSC1_SetTimeOut(ZESTSC1_HANDLE Handle,
                                  unsigned long MilliSeconds)
{
    ZESTSC1_HANDLE_STRUCT *Struct = (ZESTSC1_HANDLE_STRUCT *)Handle;

    /*
     * Check the card handle is OK
     */
    if (Struct==NULL ||
        Struct->Magic!=ZESTSC1_HANDLE_MAGIC)
    {
        return ZESTSC1_ILLEGAL_HANDLE;
    }

    Struct->TimeOut = MilliSeconds;

    return ZESTSC1_SUCCESS;
}
ZESTSC1_STATUS ZestSC1SetTimeOut(ZESTSC1_HANDLE Handle,
                                 unsigned long MilliSeconds)
{
    ZESTSC1_STATUS Status;

    Status = ZestSC1_SetTimeOut(Handle, MilliSeconds);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR("ZestSC1SetTimeout", Status);
    }

    return  ZESTSC1_SUCCESS;
}

/******************************************************************************
* Set the ID of a card                                                        *
******************************************************************************/
ZESTSC1_STATUS ZestSC1SetCardID(ZESTSC1_HANDLE Handle,
                                unsigned long CardID)
{
    char Buffer[3];

    ZESTSC1_CHECK_HANDLE("ZestSC1SetCardID", Handle);

    if (usb_control_msg(Struct->DeviceHandle, EP_CTRL_READ, VR_WRITE_EEPROM, EEPROM_CARDID_ADDRESS, CardID, Buffer, 3, Struct->TimeOut)<=0 ||
        Buffer[1]!=0)
    {
        ZESTSC1_ERROR("ZestSC1SetCardID", ZESTSC1_INTERNAL_ERROR);
    }

    return ZESTSC1_SUCCESS;
}


/******************************************************************************
* Close a card and free up associated resources                               *
******************************************************************************/
ZESTSC1_STATUS ZestSC1CloseCard(ZESTSC1_HANDLE Handle)
{
    int RetVal;
    char Buffer[3];
    ZESTSC1_CHECK_HANDLE("ZestSC1CloseCard", Handle);

    /*
     * Clear FPGA
    */
    RetVal = usb_control_msg(Struct->DeviceHandle, EP_CTRL_READ, VR_START_CONFIG,
                             sizeof(Buffer)&0xffff, sizeof(Buffer)&0xffff,
                             Buffer, 2, Struct->TimeOut);
    /*
     * Reset 8051
     */
    /* ZestSC1_Reset8051(Struct->DeviceHandle); FIXED EC */
    ZestSC1_Reset8051(Handle);

    /*
     * Free other resources
     */
    usb_release_interface(Struct->DeviceHandle, Struct->Interface);
    usb_close(Struct->DeviceHandle);
    free(Struct);

    return ZESTSC1_SUCCESS;
}


/******************************************************************************
* Set the signal pin directions                                               *
******************************************************************************/
ZESTSC1_STATUS ZestSC1SetSignalDirection(ZESTSC1_HANDLE Handle,
                                         unsigned char Direction)
{
    char Buffer[1];

    ZESTSC1_CHECK_HANDLE("ZestSC1SetSignalDirection", Handle);

    if (usb_control_msg(Struct->DeviceHandle, EP_CTRL_READ, VR_SET_SIGNAL_DIR, Direction, 0, Buffer, 1, Struct->TimeOut)<=0)
    {
        ZESTSC1_ERROR("ZestSC1SetSignalDirection", ZESTSC1_INTERNAL_ERROR);
    }

    return ZESTSC1_SUCCESS;
}

/******************************************************************************
* Set the value on the signal pins                                            *
******************************************************************************/
ZESTSC1_STATUS ZestSC1SetSignals(ZESTSC1_HANDLE Handle,
                                 unsigned char Value)
{
    char Buffer[1];

    ZESTSC1_CHECK_HANDLE("ZestSC1SetSignals", Handle);

    if (usb_control_msg(Struct->DeviceHandle, EP_CTRL_READ, VR_SET_SIGNALS, Value, 0, Buffer, 1, Struct->TimeOut)<=0)
    {
        ZESTSC1_ERROR("ZestSC1SetSignals", ZESTSC1_INTERNAL_ERROR);
    }

    return ZESTSC1_SUCCESS;
}

/******************************************************************************
* Read the signals                                                            *
******************************************************************************/
ZESTSC1_STATUS ZestSC1ReadSignals(ZESTSC1_HANDLE Handle,
                                  unsigned char *Value)
{
    char Buffer[2];

    ZESTSC1_CHECK_HANDLE("ZestSC1ReadSignals", Handle);

    *Value = 0;

    if (usb_control_msg(Struct->DeviceHandle, EP_CTRL_READ, VR_GET_SIGNALS, 0, 0, Buffer, 2, Struct->TimeOut)<=0)
    {
        ZESTSC1_ERROR("ZestSC1ReadSignals", ZESTSC1_INTERNAL_ERROR);
    }

    *Value = Buffer[1];

    return ZESTSC1_SUCCESS;
}


/******************************************************************************
* Wait for the FPGA to generate an interrupt                                  *
******************************************************************************/
ZESTSC1_STATUS ZestSC1WaitForInterrupt(ZESTSC1_HANDLE Handle)
{
    char Buffer[8];
    //int RetVal;
    ZESTSC1_STATUS Status;

    // FIXME
    ZESTSC1_ERROR("ZestSC1WaitForInterrupt", ZESTSC1_INTERNAL_ERROR);
    
    ZESTSC1_CHECK_HANDLE("ZestSC1WaitForInterrupt", Handle);

    Status = ZestSC1_Transfer(Handle, EP_INT_READ, Buffer, 1);
    if (Status!=ZESTSC1_SUCCESS)
    {
        ZESTSC1_ERROR("ZestSC1WaitForInterrupt", Status);
    }

    return ZESTSC1_SUCCESS;
}


/*********************
* INTERNAL FUNCTIONS *
*********************/

/******************************************************************************
* Write a byte to the EEPROM                                                  *
******************************************************************************/
ZESTSC1_STATUS ZestSC1_WriteEEPROM(ZESTSC1_HANDLE Handle,
                                   unsigned long Address,
                                   unsigned char Data)
{
    char Buffer[3];
    
    ZESTSC1_CHECK_HANDLE("ZestSC1_WriteEEPROM", Handle);

    if (usb_control_msg(Struct->DeviceHandle, EP_CTRL_READ, VR_WRITE_EEPROM, Address, Data, Buffer, 3, Struct->TimeOut)<=0 ||
        Buffer[1]!=0)
    {
        ZESTSC1_ERROR("ZestSC1SetCardID", ZESTSC1_INTERNAL_ERROR);
    }

    return ZESTSC1_SUCCESS;
}

/******************************************************************************
* Read a byte from the EEPROM                                                 *
******************************************************************************/
ZESTSC1_STATUS ZestSC1_ReadEEPROM(ZESTSC1_HANDLE Handle,
                                  unsigned long Address,
                                  unsigned char *Data)
{
    ZESTSC1_CHECK_HANDLE("ZestSC1_ReadEEPROM", Handle);

    return ZestSC1_ReadEEPROMRaw(Struct->DeviceHandle, Address, Data);
}
static ZESTSC1_STATUS ZestSC1_ReadEEPROMRaw(usb_dev_handle *Handle,
                                            unsigned long Address,
                                            unsigned char *Data)
{
    char Buffer[3] = {0,0,0};

    if (usb_control_msg(Handle, EP_CTRL_READ, VR_READ_EEPROM, Address, 0, Buffer, 3, ZESTSC1_DEFAULT_TIMEOUT)<=0 ||
        Buffer[1]!=0)
    {
        return ZESTSC1_INTERNAL_ERROR;
    }

    *Data = Buffer[2];

    return ZESTSC1_SUCCESS;
}

/******************************************************************************
* Reset the 8051 microcontroller                                              *
******************************************************************************/
ZESTSC1_STATUS ZestSC1_Reset8051(ZESTSC1_HANDLE Handle)
{
    char Buffer[3];
    int RetVal;
    /* ZESTSC1_HANDLE_STRUCT *Struct = (ZESTSC1_HANDLE_STRUCT *)Handle; FIXED EC */
    ZESTSC1_CHECK_HANDLE("ZestSC1_Reset8051", Handle);
    
    Buffer[0] = 1;
    RetVal = usb_control_msg(Struct->DeviceHandle, EP_CTRL_WRITE, ANCHOR_LOAD_INTERNAL, 
                             CPUCS_REG_FX2, 0, Buffer, 1, Struct->TimeOut);
    if (RetVal<=0)
    {
        return ZESTSC1_INTERNAL_ERROR;
    }
    Buffer[0] = 0;
    RetVal = usb_control_msg(Struct->DeviceHandle, EP_CTRL_WRITE, ANCHOR_LOAD_INTERNAL, 
                             CPUCS_REG_FX2, 0, Buffer, 1, Struct->TimeOut);
    if (RetVal<=0)
    {
        return ZESTSC1_INTERNAL_ERROR;
    }
    
    return ZESTSC1_SUCCESS;
}


