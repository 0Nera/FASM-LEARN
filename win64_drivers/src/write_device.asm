format PE64 console at 100000000h
entry start


include '%fasminc%\win32a.inc'
include 'sys\a05.inc'


section '.code' code readable executable

start:

	sub	rsp,8*(4+3)

	call	qword [GetCommandLineA]
	cld
	xchg	rsi,rax     ; parse file name
	lea	rdi,[device_name]
	lea	rcx,[rdi + magz_syze_dn]
L00:	inc	rsi
	cmp	byte [rsi],' '
	ja	L00
L01:	cmp	byte [rsi],0
	jz	shell_no_drv
	inc	rsi
	cmp	byte [rsi],' '
	jna	L01
L02:	cmp	dword [rsi],'\\.\'
	jnz	shell_no_drv
L03:	movsb
	cmp	rdi,rcx
	jnbe	t00_10ng
	cmp	byte [rsi],' '
	ja	L03
	mov	byte [rdi],0

; open device
	mov	qword [rsp+8*(4+2)],0
	mov	qword [rsp+8*(4+1)],FILE_ATTRIBUTE_NORMAL
	mov	qword [rsp+8*(4+0)],OPEN_EXISTING
	xor	r9,r9
	mov	r8d,FILE_SHARE_READ or FILE_SHARE_WRITE
	mov	edx,GENERIC_READ or GENERIC_WRITE
	lea	rcx,[device_name]
	call	qword [CreateFileA]
	cmp	rax,INVALID_HANDLE_VALUE
	jz	error_open_device

	xchg	rbx,rax

virtual at 0
a05dq	A05DriverQuery
end virtual

	lea	rdx,[query]
	mov	dword [rdx + a05dq.iocode],DRIVER_QUERY_PORT_OUT_BYTE
	mov	dword [rdx + a05dq.wparam],70h	; cmos port
	mov	byte [rdx + a05dq.lparam],09h	; year

	mov	qword [rsp+8*(4+0)],0
	lea	r9,[BytezWritten]
	mov	r8d,size_of_A05DriverQuery
; rdx is pointing to query now, we needn't set it again lea rdx,[query]
	mov	rcx,rbx
	call	qword [WriteFile]
	or	rax,rax
	jz	error_write_device

	lea	rdx,[query]
	mov	dword [rdx + a05dq.iocode],DRIVER_QUERY_PORT_IN_BYTE
	mov	dword [rdx + a05dq.wparam],71h	; cmos port

	mov	qword [rsp+8*(4+0)],0
	lea	r9,[BytezWritten]
	mov	r8d,size_of_A05DriverQuery
; rdx is pointing to query now, we needn't set it again lea rdx,[query]
	mov	rcx,rbx
	call	qword [WriteFile]
	or	rax,rax
	jz	error_write_device

	movzx	eax,byte [query.lparam]
; al=year
	rol	ax,4+8
	shr	ah,4
	add	ax,'00'
	mov	word [change_year],ax

	xor	r9,r9				; MB_OK=0
	lea	r8,[MsgCaption0]
	lea	rdx,[MsgText0]
	xor	ecx,ecx
	call	qword [MessageBoxA]


	lea	rdx,[query]
	lea	rax,[beep_procedure]
	mov	dword [rdx + a05dq.iocode],DRIVER_QUERY_PROC_NOARGS
	mov	qword [rdx + a05dq.wparam],rax

	mov	qword [rsp+8*(4+0)],0
	lea	r9,[BytezWritten]
	mov	r8d,size_of_A05DriverQuery
; rdx is pointing to query now, we needn't set it again lea rdx,[query]
	mov	rcx,rbx
	call	qword [WriteFile]
	or	rax,rax
	jz	error_write_device


	lea	rdx,[query]
	lea	rax,[save_cmos]
	mov	dword [rdx + a05dq.iocode],DRIVER_QUERY_PROC_NOARGS
	mov	qword [rdx + a05dq.wparam],rax

	mov	qword [rsp+8*(4+0)],0
	lea	r9,[BytezWritten]
	mov	r8d,size_of_A05DriverQuery
; rdx is pointing to query now, we needn't set it again lea rdx,[query]
	mov	rcx,rbx
	call	qword [WriteFile]
	or	rax,rax
	jz	error_write_device


	mov	rcx,rbx
	call	qword [CloseHandle]


; open file
	mov	qword [rsp+8*(4+2)],0
	mov	qword [rsp+8*(4+1)],FILE_ATTRIBUTE_NORMAL
	mov	qword [rsp+8*(4+0)],CREATE_ALWAYS
	xor	r9,r9
	xor	r8,r8
	mov	edx,GENERIC_WRITE
	lea	rcx,[file_name]
	call	qword [CreateFileA]
	cmp	rax,INVALID_HANDLE_VALUE
	jz	egzyd	;error_create_file

	xchg	rbx,rax

	mov	qword [rsp+8*(4+0)],0
	lea	r9,[BytezWritten]
	mov	r8d,cmos_buffer_size
	lea	rdx,[cmos_buffer]
	mov	rcx,rbx
	call	qword [WriteFile]

	mov	rcx,rbx
	call	qword [CloseHandle]


egzyd:	xor	ecx,ecx
egzapy:	call	qword [ExitProcess]

t00_10ng:
	lea	rdx,[ErrMsgText1]
	jmp	CMB
shell_no_drv:
	lea	rdx,[ErrMsgText1_noarg]
CMB:	lea	r8,[ErrMsgCaption1]
CMB2:	mov	r9d,MB_OK or MB_ICONERROR
	xor	ecx,ecx
	call	qword [MessageBoxA]

	mov	ecx,1
	jmp	egzapy

error_open_device:
	lea	r8,[ErrMsgCaption2]
	lea	rdx,[ErrMsgText2]
	jmp	CMB2

error_write_device:
	lea	r8,[ErrMsgCaption2]
	lea	rdx,[ErrMsgText3]
	jmp	CMB2

align 16
beep_procedure:
	pushf
	push	rax
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
	mov	eax,20000000h
delay_loop:
	dec	rax
	or	rax,rax
	jnz	delay_loop
	cli
	in	al,61h
	and	al,0FCh
	out	61h,al
	sti
	pop	rax
	popf
	ret

align 16
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


section '.data' data readable writeable

file_name		db	'cmos512byte.bin',0

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
GetCommandLineA		dq	RVA _GetCommandLineA
CreateFileA		dq	RVA _CreateFileA
WriteFile		dq	RVA _WriteFile
CloseHandle		dq	RVA _CloseHandle
ExitProcess		dq	RVA _ExitProcess
			dq	0
user_table:
MessageBoxA		dq	RVA _MessageBoxA
			dq	0

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
