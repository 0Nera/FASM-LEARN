struc	A05DriverQuery
{
.iocode				dd	?	; user I/O code
				dd	?	; padding
.wparam				dq	?	; parameter
.lparam				dq	?	; parameter
size_of_A05DriverQuery		=	$ - $$
}

; values for iocode (user I/O code) used for communicate with write_device.exe
DRIVER_QUERY_PROC_NOARGS	=	10h
DRIVER_QUERY_PROC_STDCALL	=	11h
DRIVER_QUERY_PORT_IN_BYTE	=	20h
DRIVER_QUERY_PORT_IN_WORD	=	21h
DRIVER_QUERY_PORT_IN_DWORD	=	22h
DRIVER_QUERY_PORT_OUT_BYTE	=	30h
DRIVER_QUERY_PORT_OUT_WORD	=	31h
DRIVER_QUERY_PORT_OUT_DWORD	=	33h
