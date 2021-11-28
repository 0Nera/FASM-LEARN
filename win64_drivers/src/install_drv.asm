; install win64 driver
; needs set path with driver name at shell line (command prompt)
; e.g.
; install_drv.exe c:\windows\system32\drivers\a05.sys


format PE64 console
entry start


include '%fasminc%\win32a.inc'
include 'defines.inc'


section '.code' code readable executable

start:
	sub	rsp,8*(4+11)
	call	qword [GetCommandLineA]
	cld
	xchg	rsi,rax     	; parse shell line parameters
	lea	rdi,[driver_path_and_name]
	lea	rcx,[rdi + magz_syze_dpan]
L00:	inc	rsi
	cmp	byte [rsi],' '
	ja	L00
L01:	cmp	byte [rsi],0
	jz	shell_no_drv
	inc	rsi
	cmp	byte [rsi],' '
	jna	L01
L02:	movsb
	cmp	rdi,rcx
	jnbe	t00_10ng
	cmp	byte [rsi],' '
	ja	L02
	mov	byte [rdi],0

scan_name:
	dec	rdi
	cmp	byte [rdi-1],'\'
	jnz	scan_name
	mov	[driver_name_address],rdi

	mov	r8d,SC_MANAGER_CONNECT or SC_MANAGER_CREATE_SERVICE or SC_MANAGER_ENUMERATE_SERVICE or SC_MANAGER_LOCK or SC_MANAGER_QUERY_LOCK_STATUS or SC_MANAGER_MODIFY_BOOT_CONFIG or STANDARD_RIGHTS_REQUIRED
	xor	edx,edx		; zeroing rdx, AMD64 zero extend this to 64bit register
	xor	ecx,ecx
	call	qword [OpenSCManagerA]
	or	rax,rax
	jnz	L0

; Can't connect to Service Control Manager
	mov	r9d,MB_OK or MB_ICONERROR
	lea	r8,[ErrMsgCaption2]
	lea	rdx,[ErrMsgText2]
	xor	ecx,ecx
	call	qword [MessageBoxA]

	mov	ecx,2
	call	qword [ExitProcess]

L0:	xchg	rbx,rax

;	xor	eax,eax			; rax=0
;	lea	rcx,[rax+1]		; rcx=1
;	lea	rdx,[rax+3]		; rdx=3

	mov	qword [rsp+8*(4+8)],0	; 13th arg
	mov	qword [rsp+8*(4+7)],0
	mov	qword [rsp+8*(4+6)],0
	mov	qword [rsp+8*(4+5)],0
	mov	qword [rsp+8*(4+4)],0	; 9th arg
	lea	rax,[driver_path_and_name]
	mov	qword [rsp+8*(4+3)],rax	; 8th arg
	mov	qword [rsp+8*(4+2)],SERVICE_ERROR_NORMAL	; 7th arg
	mov	qword [rsp+8*(4+1)],SERVICE_DEMAND_START	; 6th arg
	mov	qword [rsp+8*(4+0)],SERVICE_KERNEL_DRIVER	; 5th arg
	mov	r9d,SERVICE_QUERY_CONFIG or SERVICE_CHANGE_CONFIG or SERVICE_QUERY_STATUS or SERVICE_ENUMERATE_DEPENDENTS or SERVICE_START or SERVICE_STOP or SERVICE_PAUSE_CONTINUE or SERVICE_INTERROGATE or SERVICE_USER_DEFINED_CONTROL or STANDARD_RIGHTS_REQUIRED
	mov	r8,[driver_name_address]; 3rd arg
	mov	rdx,r8			; 2nd arg
	mov	rcx,rbx			; 1st arg - handle_Service_Control_Manager
	call	qword [CreateServiceA]
	or	rax,rax
	jz	L1

	mov	rcx,rbx
	call	qword [CloseServiceHandle]

egzyd:	xor	ecx,ecx
	call	qword [ExitProcess]

L1:	mov	r9d,MB_OK or MB_ICONERROR
	lea	r8,[ErrMsgCaption3]
	lea	rdx,[ErrMsgText3]

	lea	rsi,[msg_ecs]
	mov	rdi,rdx

	mov	ecx,size_ecs
	cld
	repz movsb

;	xor	ecx,ecx			; not necessary, rcx=0 after repz movsb
	call	qword [MessageBoxA]

	mov	ecx,3
	call	qword [ExitProcess]

t00_10ng:
	mov	r9d,MB_OK or MB_ICONERROR
	lea	r8,[ErrMsgCaption1]
	lea	rdx,[ErrMsgText1]
	xor	ecx,ecx
	call	qword [MessageBoxA]

	mov	ecx,1
	call	qword [ExitProcess]

shell_no_drv:
	mov	r9d,MB_OK or MB_ICONERROR
	lea	r8,[ErrMsgCaption1_nogiveio]
	lea	rdx,[ErrMsgText1_nogiveio]
	xor	ecx,ecx
	call	qword [MessageBoxA]

	mov	ecx,1
	call	qword [ExitProcess]


section '.data' data readable writeable

ErrMsgCaption1		db	'Input shell',0
ErrMsgText1		db	'Too much input chars in command line! Must be <1024',0

ErrMsgCaption1_nogiveio	db	'Input shell',0
ErrMsgText1_nogiveio	db	'No path or no *.sys on command line end, set path and use lowercase only - CAPS LOCK off!',0

ErrMsgCaption2		db	'Install_drv',0
ErrMsgText2		db	"Can't connect to Service Control Manager",0

ErrMsgCaption3		db	'advapi32.dll',0
;ErrMsgText3
msg_ecs			db	'Error CreateService '
size_ecs = $ - msg_ecs
ErrMsgText3		rb	size_ecs

magz_syze_dpan=1024
driver_path_and_name	rb	magz_syze_dpan
driver_name_address	dq	?		; address at which is driver_name


section '.idata' import data readable writeable

			dd	0,0,0,	RVA kernel_name,	RVA kernel_table
			dd	0,0,0,	RVA user_name,		RVA user_table
			dd	0,0,0,	RVA advapi_name,	RVA advapi_table
			dd	0,0,0,	0,			0

kernel_table:
GetCommandLineA		dq	RVA _GetCommandLineA
ExitProcess		dq	RVA _ExitProcess
			dq	0
user_table:
MessageBoxA		dq	RVA _MessageBoxA
			dq	0
advapi_table:
OpenSCManagerA		dq	RVA _OpenSCManagerA
CreateServiceA		dq	RVA _CreateServiceA
CloseServiceHandle	dq	RVA _CloseServiceHandle
			dq	0

kernel_name		db	'KERNEL32.DLL',0
user_name		db	'USER32.DLL',0
advapi_name		db	'ADVAPI32.DLL',0

_GetCommandLineA	dw	0
			db	'GetCommandLineA',0
_ExitProcess		dw	0
			db	'ExitProcess',0

_MessageBoxA		dw	0
			db	'MessageBoxA',0

_OpenSCManagerA		dw	0
			db	'OpenSCManagerA',0
_CreateServiceA		dw	0
			db	'CreateServiceA',0
_CloseServiceHandle	dw	0
			db	'CloseServiceHandle',0
