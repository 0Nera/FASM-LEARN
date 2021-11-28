; this is special hybrid application
; it is 32-bit, but has 2 procedures holding 64-bit code

format PE console
entry start


include '%fasminc%\win32a.inc'
include 'sys\a05.inc'


section '.code' code readable executable

start:

	call	dword [GetCommandLineA]
	cld
	xchg	esi,eax     ; parse file name
	lea	edi,[device_name]
L00:	inc	esi
	cmp	byte [esi],' '
	ja	L00
L01:	cmp	byte [esi],0
	jz	shell_no_drv
	inc	esi
	cmp	byte [esi],' '
	jna	L01
L02:	cmp	dword [esi],'\\.\'
	jnz	shell_no_drv
L03:	movsb
	cmp	edi,device_name + magz_syze_dn
	jnbe	t00_10ng
	cmp	byte [esi],' '
	ja	L03
	mov	byte [edi],0

; open device
	push	0
	push	FILE_ATTRIBUTE_NORMAL
	push	OPEN_EXISTING
	push	0
	push	FILE_SHARE_READ or FILE_SHARE_WRITE
	push	GENERIC_READ or GENERIC_WRITE
	push	device_name
	call	dword [CreateFileA]
	cmp	eax,INVALID_HANDLE_VALUE
	jz	error_open_device

	xchg	ebx,eax

virtual at 0
a05dq	A05DriverQuery
end virtual

	lea	edx,[query]
	mov	dword [edx + a05dq.iocode],DRIVER_QUERY_PORT_OUT_BYTE
	mov	dword [edx + a05dq.wparam],70h	; cmos port
	mov	dword [edx + a05dq.lparam],09h	; year

	push	0
	push	BytezWritten
	push	size_of_A05DriverQuery
; edx is pointing to query now
	push	edx
	push	ebx
	call	dword [WriteFile]
	or	eax,eax
	jz	error_write_device


	lea	edx,[query]
	mov	dword [edx + a05dq.iocode],DRIVER_QUERY_PORT_IN_BYTE
	mov	dword [edx + a05dq.wparam],71h	; cmos port

	push	0
	push	BytezWritten
	push	size_of_A05DriverQuery
; edx is pointing to query now
	push	edx
	push	ebx
	call	dword [WriteFile]
	or	eax,eax
	jz	error_write_device


	movzx	eax,byte [query.lparam]
; al=year

	rol	ax,4+8
	shr	ah,4
	add	ax,'00'
	mov	word [change_year],ax

	push	MB_OK
	push	MsgCaption0
	push	MsgText0
	push	0
	call	dword [MessageBoxA]


	lea	edx,[query]
	mov	dword [edx + a05dq.iocode],DRIVER_QUERY_PROC_NOARGS
	mov	dword [edx + a05dq.wparam],beep_procedure
	mov	dword [edx + a05dq.wparam + 4],0	; zero extend 32-bit address to 64-bit address

	push	0
	push	BytezWritten
	push	size_of_A05DriverQuery
; edx is pointing to query now
	push	edx
	push	ebx
	call	dword [WriteFile]
	or	eax,eax
	jz	error_write_device


	lea	edx,[query]
	mov	dword [edx + a05dq.iocode],DRIVER_QUERY_PROC_NOARGS
	mov	dword [edx + a05dq.wparam],save_cmos
	mov	dword [edx + a05dq.wparam + 4],0	; zero extend 32-bit address to 64-bit address

	push	0
	push	BytezWritten
	push	size_of_A05DriverQuery
; edx is pointing to query now
	push	edx
	push	ebx
	call	dword [WriteFile]
	or	eax,eax
	jz	error_write_device


	push	ebx
	call	dword [CloseHandle]


; open file
	push	0
	push	FILE_ATTRIBUTE_NORMAL
	push	CREATE_ALWAYS
	push	0
	push	0
	push	GENERIC_WRITE
	push	file_name
	call	dword [CreateFileA]
	cmp	eax,INVALID_HANDLE_VALUE
	jz	egzyd	;error_create_file

	xchg	ebx,eax

	push	0
	push	BytezWritten
	push	cmos_buffer_size
	push	cmos_buffer
	push	ebx
	call	dword [WriteFile]

	push	ebx
	call	dword [CloseHandle]


egzyd:	push	0
egzapy:	call	dword [ExitProcess]

t00_10ng:
	lea	edx,[ErrMsgText1]
	jmp	CMB
shell_no_drv:
	lea	edx,[ErrMsgText1_noarg]
CMB:
	lea	ecx,[ErrMsgCaption1]
CMB2:	push	MB_OK or MB_ICONERROR
	push	ecx
	push	edx
	push	0
	call	dword [MessageBoxA]

	push	1
	jmp	egzapy

error_open_device:
	lea	ecx,[ErrMsgCaption2]
	lea	edx,[ErrMsgText2]
	jmp	CMB2

error_write_device:
	lea	ecx,[ErrMsgCaption2]
	lea	edx,[ErrMsgText3]
	jmp	CMB2

align 16
use64		; must be here, code is executed in long mode,
		; drivers run only in 64-bit and they don't support 32-bit emulation
		; like syswow64 in user applications (ring3)
beep_procedure:
	pushf
	push	rax
	push	r8
	cli
	mov	al,0B6h
	out	43h,al
	mov	al,74h
	out	42h,al
	mov	al,4
	out	42h,al
	in	al,61h
	or	al,3
	out	61h,al
	sti
	mov	r8d,40000000h
delay_loop:
	dec	r8
	or	r8,r8			; dummy instruction here, only for slow down loop speed
	jnz	delay_loop
	cli
	in	al,61h
	and	al,0FCh
	out	61h,al
	sti
	pop	r8
	pop	rax
	popf
	ret

align 16
use64
save_cmos:
	pushf
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi
; sub rsp,8*(4+1)	; note, for preserve pushed registers before destroing,
; you must reserve 4 qwords of stack if you will use API
; API can use and change them, so pushed registers mustn't be on them
	lea	rdi,[cmos_buffer]
	cld
	mov	ecx,cmos_buffer_size
	xor	ebx,ebx
	cli
L0:	mov	edx,72h
	add	dl,bh
	add	dl,bh
	mov	al,bl
	out	dx,al
	inc	edx
	insb
	inc	ebx
	loop	L0
	sti
; add rsp,8*(4+1)	; restore stack if above sub rsp,8* has been used
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	popf
	ret

use32		; back to the old 32-bit world


section '.data' data readable writeable

file_name		db	'cmos512byte_written_by_32_bit_process_under_win_64.bin',0

MsgCaption0		db	'Year:',0
MsgText0		db	'Year by read CMOS byte is: 2000 !',0
change_year = $ - 5

ErrMsgCaption1		db	'Input shell',0
ErrMsgText1		db	'Too much input chars in command line! Must be <1024',0

ErrMsgText1_noarg	db	'Nothing on command line or no device_name arg!',0

ErrMsgCaption2		db	'Error',0
ErrMsgText2		db	'Error open device',0

ErrMsgText3		db	'Error write to device',0

align 16
query			A05DriverQuery

BytezWritten		rq	1

cmos_buffer_size 	=	512
cmos_buffer		rb	cmos_buffer_size

magz_syze_dn		=	1024
device_name		rb	magz_syze_dn
			rb	1			; for zero-terminator


section '.idata' import data readable writeable

			dd	0,0,0,	RVA kernel_name,	RVA kernel_table
			dd	0,0,0,	RVA user_name,		RVA user_table
			dd	0,0,0,	0,			0

kernel_table:
GetCommandLineA		dd	RVA _GetCommandLineA
CreateFileA		dd	RVA _CreateFileA
WriteFile		dd	RVA _WriteFile
CloseHandle		dd	RVA _CloseHandle
ExitProcess		dd	RVA _ExitProcess
			dd	0
user_table:
MessageBoxA		dd	RVA _MessageBoxA
			dd	0

kernel_name		db	'KERNEL32.DLL',0
user_name		db	'USER32.DLL',0

_GetCommandLineA	dw	0
			db	'GetCommandLineA',0
_CreateFileA		dw	0
			db	'CreateFileA',0
_WriteFile		dw	0
			db	'WriteFile',0
_CloseHandle		dw	0
			db	'CloseHandle',0
_ExitProcess		dw	0
			db	'ExitProcess',0

_MessageBoxA		dw	0
			db	'MessageBoxA',0
