
/*******************
* Hardware details *
*******************/
#define VENDOR_ID 0x165d
#define PRODUCT_ID 0x0001

#define ANCHOR_LOAD_INTERNAL    0xA0

#define VR_SET_REG              0xD0
#define VR_GET_REG              0xD1
#define VR_START_CONFIG         0xD2
#define VR_CONFIG_STATUS        0xD3
#define VR_SET_SIGNAL_DIR       0xD4
#define VR_SET_SIGNALS          0xD5
#define VR_GET_SIGNALS          0xD6
#define VR_WRITE_EEPROM         0xD7
#define VR_READ_EEPROM          0xD8
#define VR_READBACK_READ        0xD9
#define VR_READBACK_WRITE       0xDA
#define VR_READBACK_DONE        0xDB
#define VR_GET_FIRMWARE_VER     0xDC

#define EEPROM_SERIAL_ADDRESS 0xfffc
#define EEPROM_CARDID_ADDRESS 0xfffb
#define EEPROM_FPGA_ADDRESS 0xfffa
#define EEPROM_MEMORY_SIZE_ADDRESS 0xfff6

#define CPUCS_REG_FX2 0xE600

#define EP_CTRL_WRITE (USB_ENDPOINT_OUT | USB_TYPE_VENDOR)
#define EP_CTRL_READ (USB_ENDPOINT_IN | USB_TYPE_VENDOR)
#define EP_INT_READ (USB_ENDPOINT_IN | 1)
#define EP_DATA_WRITE (USB_ENDPOINT_OUT | 2)
#define EP_CONFIG_WRITE (USB_ENDPOINT_OUT | 2)
#define EP_DATA_READ (USB_ENDPOINT_IN | 6)
#define EP_CONFIG_READ (USB_ENDPOINT_IN | 6)

#define ZESTSC1_MAX_TRANSFER_LENGTH (16*1024) // Maximum transfer in one URB under Linux


/**************
* Error macro *
**************/
extern ZESTSC1_ERROR_FUNC ZestSC1_ErrorHandler;
#define ZESTSC1_ERROR(f, x) \
    { \
        if (ZestSC1_ErrorHandler!=NULL) \
            ZestSC1_ErrorHandler(f, Handle, x, ZESTSC1_ERROR_STRING(x)); \
        return (x); \
    }
#define ZESTSC1_ERROR_GENERAL(f, x) \
    { \
        if (ZestSC1_ErrorHandler!=NULL) \
            ZestSC1_ErrorHandler(f, NULL, x, ZESTSC1_ERROR_STRING(x)); \
        return (x); \
    }
#define ZESTSC1_ERROR_STRING(x) \
    ZestSC1_ErrorStrings[(x)>=ZESTSC1_ERROR_BASE ? \
                            (x)-ZESTSC1_ERROR_BASE+(ZESTSC1_MAX_INFO-ZESTSC1_INFO_BASE)+(ZESTSC1_MAX_WARNING-ZESTSC1_WARNING_BASE) : \
                        ((x)>=ZESTSC1_WARNING_BASE ? (x)-ZESTSC1_WARNING_BASE+(ZESTSC1_MAX_INFO-ZESTSC1_INFO_BASE) : (x)-ZESTSC1_INFO_BASE)]
extern char *ZestSC1_ErrorStrings[];


/************************
* Card handle structure *
************************/
#define ZESTSC1_HANDLE_MAGIC 0xfeedfac0
typedef struct
{
    unsigned long Magic;
    usb_dev_handle *DeviceHandle;
    unsigned long TimeOut;
    int Interface;
} ZESTSC1_HANDLE_STRUCT;

#define ZESTSC1_CHECK_HANDLE(f, x) \
    ZESTSC1_HANDLE_STRUCT *Struct = (ZESTSC1_HANDLE_STRUCT *)Handle; \
    if (Struct==NULL || \
        Struct->Magic!=ZESTSC1_HANDLE_MAGIC) \
            ZESTSC1_ERROR(f, ZESTSC1_ILLEGAL_HANDLE);


/*************************************
* FPGA configuration image structure *
*************************************/
#define ZESTSC1_IMAGE_HANDLE_MAGIC 0xdeadbee0
typedef struct
{
    unsigned long Magic;
    void *Buffer;
    unsigned long BufferSize;
    ZESTSC1_FPGA_TYPE PartType;
} ZESTSC1_IMAGE_HANDLE_STRUCT;

#define ZESTSC1_BITFILE_NAME  0x61
#define ZESTSC1_BITFILE_PART  0x62
#define ZESTSC1_BITFILE_DATE  0x63
#define ZESTSC1_BITFILE_TIME  0x64
#define ZESTSC1_BITFILE_IMAGE 0x65


/************
* Constants *
************/
#define ZESTSC1_DEFAULT_TIMEOUT 10000


/************
* Functions *
************/
ZESTSC1_STATUS ZestSC1_Reset8051(ZESTSC1_HANDLE Handle);
ZESTSC1_STATUS ZestSC1_Transfer(ZESTSC1_HANDLE Handle, int EP, void *Buffer, int Length);
