; win64 driver written in FASM for executing ring0 privileged instructions from user mode programs,
; e.g. reading and writing to a ports
; you can start and stop it as you like and reuse it without rebooting win64 (beeper00 and beeper01 need reboot)
; implemented functions:
; - start driver	start + DispatchCreateClose procedures
; - stop driver		DispatchCreateClose + DriverUnload procedures
; - write to a driver	DispatchWrite procedure
; for install, start, stop, remove, write to a driver use included exe files
; some code is replaced by other with smaller opcodes,
; e.g. test ebx,ebx instead of cmp ebx,0 or xchg eax,ebx instead of mov eax,ebx
; this is for spare some bytes and reduce driver size


format PE64 native 5.02 at 10000h
entry start


include 'a05.inc'
include 'KMD64.inc'


section '.text' code readable executable notpageable

start:
; lpDriverObject, lpusRegistryPath
; rcx=pDriverObject rdx=pDriverPath

	push	rbx
	sub	rsp,8*(4+8)		; reserve 12 qwords on the stack, 8 for us
					; Low 4 qwords may be destroyed by API, we can't use them
; RSP is now aligned 16
	lea	rbx,[rcx]		; Save RCX to RBX. RBX is protected against destroing by API.

	; load structure to point to IRP handlers
virtual at 0
DriverObject	DRIVER_OBJECT
end virtual
	lea	rax,[DriverUnload]
	mov	qword [rbx + DriverObject.DriverUnload],rax

	lea	rax,[DispatchCreateClose]
	mov	qword [rbx + DriverObject.MajorFunction + IRP_MJ_CREATE_OFFSET],rax
	mov	qword [rbx + DriverObject.MajorFunction + IRP_MJ_CLOSE_OFFSET],rax

	lea	rax,[DispatchWrite]
	mov	qword [rbx + DriverObject.MajorFunction + IRP_MJ_WRITE_OFFSET],rax

	lea	rdx,[cusDevice_string]
	lea	rcx,[rsp+8*(4+4)]	; use 2 quadwords reserved on the stack
	call	qword [RtlInitUnicodeString]

	; create and initialize device object
	lea	rax,[rsp+8*(4+3)]	; 1 quadword for [DeviceObject] - we use stack for it
	mov	qword [rsp+8*(4+2)],rax	; pass address for [DeviceObject] - 7th arg to the API
	xor	eax,eax			; zeroing rax
	mov	qword [rsp+8*(4+1)],rax	; false -> rax = 0
	mov	qword [rsp+8*(4+0)],rax	; 5th arg for API
	mov	r9d,FILE_DEVICE_UNKNOWN	; 4th arg for API
	lea	r8,[rsp+8*(4+4)]	; [rsp+8*(4+4)] created by RtlInitUnicodeString
	xor	edx,edx			; AMD64 zero extend this xor to rdx
	lea	rcx,[rbx]		; lpDriverObject - 1st arg for API
	call	qword [IoCreateDevice]
if STATUS_SUCCESS = 0
	or	eax,eax			; 2 bytes opcode - smaller than cmp eax,0
else
	cmp	eax,STATUS_SUCCESS
end if
	jnz	driver_return		; break on error

	; create symbolic link to the user-visible name
	lea	rdx,[cusSymbolicLink_string]
	lea	rcx,[rsp+8*(4+6)]	; use 2 quadwords reserved on the stack
	call	qword [RtlInitUnicodeString]

	lea	rdx,[rsp+8*(4+4)]	; 2nd arg for API
	lea	rcx,[rsp+8*(4+6)]	; 1st arg for API
	call	qword [IoCreateSymbolicLink]

if STATUS_SUCCESS = 0
	or	eax,eax
else
	cmp	eax,STATUS_SUCCESS
end if
	jz	driver_return

	; save status
	xchg	ebx,eax			; 1 byte opcode, smaller than 2 byte opcode for mov ebx,eax

	; unsuccess, delete device object
	mov	rcx,qword [rsp+8*(4+3)]	; 1 quadword for [DeviceObject] - we use stack for it
					; qword is filled when call IoCreateDevice
	call	qword [IoDeleteDevice]

	; assign result
	xchg	ebx,eax

driver_return:
	add	rsp,8*(4+8)
	pop	rbx
	ret

align 10h
DriverUnload:
;proc DriverUnload lpDriverObject
; rcx = lpDriverObject
	push	rbx
	sub	rsp,8*(4+2)			; reserve 6 qwords on the stack, top 2 qword can be used, low 4 qwords may be destroyed because API can use them.
	lea	rbx,[rcx]
	lea	rdx,[cusSymbolicLink_string]
	lea	rcx,[rsp+8*(4+0)]		; need 2 quadwords reserved
	call	qword [RtlInitUnicodeString]
	lea	rcx,[rsp+8*(4+0)]
	call	qword [IoDeleteSymbolicLink]
	mov	rcx,[rbx + DriverObject.DeviceObject]
	call	qword [IoDeleteDevice]
	add	rsp,8*(4+2)
	pop	rbx
	ret

align 10h
DispatchCreateClose:
;proc DispatchCreateClose pDeviceObject, lpIrp
; rcx = pDeviceObject , rdx = lpIrp
	sub	rsp,8*(4+1)			; align 16 stack
virtual at 0
vIRP	IRP
end virtual

	xor	eax,eax
if STATUS_SUCCESS = 0
	mov	dword [rdx + vIRP.IoStatus.Status],eax
else
	mov	dword [rdx + vIRP.IoStatus.Status],STATUS_SUCCESS
end if
	mov	qword [rdx + vIRP.IoStatus.Information],rax
	lea	rcx,[rdx]
if IO_NO_INCREMENT=0
	xor	edx,edx
else
	mov	edx,IO_NO_INCREMENT
end if
	call	qword [IofCompleteRequest]
if STATUS_SUCCESS=0
	xor	eax,eax
else
	mov	eax,STATUS_SUCCESS
end if
	add	rsp,8*(4+1)
	ret

align 10h
DispatchWrite:
; function called when write to the device
;proc DispatchWrite lpDeviceObject, lpIrp
; rcx = lpDeviceObject , rdx = lpIrp
	push	rbp
	push	rsi
	push	rdi
	push	rcx
	push	rdx
	push	rbx
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
; we protect so much registers because calling routine in user-mode application may destroy them
	sub	rsp,8*(4+1)		; stack is now aligned 16

	mov	ebx,STATUS_UNSUCCESSFUL		; rbx : current status
	lea	rdi,[rdx]			; rdi = lpIrp = PIRP

;	lea	rcx,[rdx]
;	call	qword [IoIs32bitProcess]
;	cmp	al,1				; 0 = 64 bit process, 1 = 32 bit process (aka WOW64)
;	jz	compactibility_32_bit_process
; not necessary for our purposed, maybe for another driver...

	xor	eax,eax
	mov	[rdi + vIRP.IoStatus.Information],rax

	mov	rsi, [rdi + vIRP.Tail.Overlay.CurrentStackLocation]

; word [rsi] must contain IRP_MJ_WRITE = 4
; But we don't check this because we are sure on DispatchWrite procedure.
; Usefull for branch if one procedure handle more functions, e.g. Write and Read from driver.

; structure used by driver to comunicate with write_device.exe
virtual at 0
a05dq	A05DriverQuery
end virtual

virtual at 0
iosl	IO_STACK_LOCATION
end virtual

	cmp	[rsi + iosl.Parameters.Write.Length],size_of_A05DriverQuery;size_of_A05DriverQuery
	jnz	egzyduz			; number of bytes written to device match or differ ?

; get address of DriverQuery
	mov	rsi,[rdi + vIRP.UserBuffer]	; PDriverQuery

; assume we have failed until we don't have success
	mov	ebx,STATUS_NOT_IMPLEMENTED

; get iocode from DriverQuery
	mov	eax,[rsi + a05dq.iocode]	; eax : user I/O code
	cmp	eax,DRIVER_QUERY_PROC_NOARGS
	jz	proc_noargs
	cmp	eax,DRIVER_QUERY_PROC_STDCALL
	jz	proc_stdcall
	cmp	eax,DRIVER_QUERY_PORT_IN_BYTE
	jz	port_in_byte
	cmp	eax,DRIVER_QUERY_PORT_IN_WORD
	jz	port_in_word
	cmp	eax,DRIVER_QUERY_PORT_IN_DWORD
	jz	port_in_dword
	cmp	eax,DRIVER_QUERY_PORT_OUT_BYTE
	jz	port_out_byte
	cmp	eax,DRIVER_QUERY_PORT_OUT_WORD
	jz	port_out_word
	cmp	eax,DRIVER_QUERY_PORT_OUT_DWORD
	jz	port_out_dword
	jmp	egzyduz

proc_noargs:
; call a procedure from user program with privileged instructions without params
	call	qword [rsi + a05dq.wparam]
	jmp	egzyduz_STATUS_SUCCESS

proc_stdcall:
; get argument for procedure
	mov	rcx,qword [rsi + a05dq.lparam]
; call a procedure from user program
	call	qword [rsi + a05dq.wparam]
; call procedure may destroy regs !!! we will handle it at egzyduz
	jmp	egzyduz_STATUS_SUCCESS

port_in_byte:
; read from a port is ring0 privileged instruction so allowed to be executed by win64 driver
	mov	edx,dword [rsi + a05dq.wparam]
	in	al,dx
; We save value readed from port to a DriverQuery.lparam
	mov	dword [rsi + a05dq.lparam],eax
	jmp	egzyduz_STATUS_SUCCESS

port_in_word:
; get port number from DriverQuery
	mov	edx,dword [rsi + a05dq.wparam]
	in	ax,dx
	mov	dword [rsi + a05dq.lparam],eax
	jmp	egzyduz_STATUS_SUCCESS

port_in_dword:
	mov	edx,dword [rsi + a05dq.wparam]
	in	eax,dx
	mov	dword [rsi + a05dq.lparam],eax
	jmp	egzyduz_STATUS_SUCCESS

port_out_byte:
	mov	edx,dword [rsi + a05dq.wparam]
	mov	eax,dword [rsi + a05dq.lparam]
	out	dx,al
	jmp	egzyduz_STATUS_SUCCESS

port_out_word:
	mov	edx,dword [rsi + a05dq.wparam]
	mov	eax,dword [rsi + a05dq.lparam]
	out	dx,ax
	jmp	egzyduz_STATUS_SUCCESS

port_out_dword:
	mov	edx,dword [rsi + a05dq.wparam]
	mov	eax,dword [rsi + a05dq.lparam]
	out	dx,eax
egzyduz_STATUS_SUCCESS:
if STATUS_SUCCESS = 0
	xor	ebx,ebx
else
	mov	ebx,STATUS_SUCCESS
end if

egzyduz:
	mov	rdi,qword [rsp + 8*(4+1+9)]	; restore rdi=lpIrp in case call qword [rsi + 8] destroy rdi register
						; lpIrp was saved in stack when push rdx
	mov	dword [rdi + vIRP.IoStatus.Status], ebx

if IO_NO_INCREMENT=0
	xor	edx,edx
else
	mov	edx,IO_NO_INCREMENT
end if
	lea	rcx,[rdi]		; lpIrp
	call	qword [IofCompleteRequest]

	xchg	ebx,eax			; put result to eax e.g. STATUS_SUCCESS

	add	rsp,8*(4+1)
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rbx
	pop	rdx
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rbp
	ret

;compactibility_32_bit_process:
;	jmp	...


align 10h
cusDevice_string	du	'\Device\a05',0

align 10h
cusSymbolicLink_string	du	'\DosDevices\a05',0


section '.rdata' readable notpageable  

data 12  

ImportLookup:  
RtlInitUnicodeString	dq	rva szRtlInitUnicodeString
IoCreateDevice		dq	rva szIoCreateDevice
IoCreateSymbolicLink	dq	rva szIoCreateSymbolicLink
IoDeleteDevice		dq	rva szIoDeleteDevice
IoDeleteSymbolicLink	dq	rva szIoDeleteSymbolicLink
IofCompleteRequest	dq	rva szIofCompleteRequest
;IoIs32bitProcess	dq	rva szIoIs32bitProcess
			dq	0

end data


section 'INIT' data import readable notpageable

			dd	rva ImportAddress
			dd	0
			dd	0
			dd	rva szntoskrnl
			dd	rva ImportLookup
		times 5	dd	0

ImportAddress		dq	rva szRtlInitUnicodeString
			dq	rva szIoCreateDevice
			dq	rva szIoCreateSymbolicLink
			dq	rva szIoDeleteDevice
			dq	rva szIoDeleteSymbolicLink
			dq	rva szIofCompleteRequest
;			dq	rva szIoIs32bitProcess
			dq	0

szRtlInitUnicodeString	dw	0
			db	'RtlInitUnicodeString',0
szIoCreateDevice	dw	0
			db	'IoCreateDevice',0
szIoCreateSymbolicLink	dw	0
			db	'IoCreateSymbolicLink',0
szIoDeleteDevice	dw	0
			db	'IoDeleteDevice',0
szIoDeleteSymbolicLink	dw	0
			db	'IoDeleteSymbolicLink',0
szIofCompleteRequest	dw	0
			db	'IofCompleteRequest',0
;szIoIs32bitProcess	dw	0
;			db	'IoIs32bitProcess',0

szntoskrnl 		db	'ntoskrnl.exe',0
