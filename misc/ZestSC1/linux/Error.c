#include <usb.h>
#include "ZestSC1.h"
#include "Local.h"


/******************************************************************************
* Globals                                                                     *
******************************************************************************/
char *ZestSC1_ErrorStrings[] =
{
    "Success (no error)",
    "Attempt to use illegal card handle",
    "Status code is out of range",
    "NULL was used illegally as one of the parameter values",
    "The requested device is being used by another application",
    "The requested card ID does not correspond to any devices in the system",
    "An unspecified internal error occurred while communicating with the driver",
    "Not enough memory to complete the requested operation",
    "File not found",
    "Error while reading file",
    "File format is not recognised",
    "Operation timed out",
    "The device driver has not been installed correctly",
    "One of the requested signals is an input and cannot be set",
    "One of the requested signals is an output and cannot be waited for",
    "The image handle does not point to valid configuration data",
    "The configuration part type does not match the FPGA fitted to this board"

};
ZESTSC1_ERROR_FUNC ZestSC1_ErrorHandler = 0;


/******************************************************************************
* Register a user error handling function to be called                        *
* Set to NULL to disable error callbacks                                      *
******************************************************************************/
ZESTSC1_STATUS ZestSC1RegisterErrorHandler(ZESTSC1_ERROR_FUNC Function)
{
    ZestSC1_ErrorHandler = Function;
    return ZESTSC1_SUCCESS;
}


/******************************************************************************
* Get a human-readable error string for a status code                         *
******************************************************************************/
ZESTSC1_STATUS ZestSC1GetErrorMessage(ZESTSC1_STATUS Status,
                                      char **Buffer)
{
    if (Status>ZESTSC1_MAX_ERROR ||
        (Status<ZESTSC1_ERROR_BASE && Status>=ZESTSC1_MAX_WARNING) ||
        (Status<ZESTSC1_WARNING_BASE && Status>=ZESTSC1_MAX_INFO))
    {
        return ZESTSC1_ILLEGAL_STATUS_CODE;
    }

    *Buffer = ZESTSC1_ERROR_STRING(Status);
    return ZESTSC1_SUCCESS;
}

