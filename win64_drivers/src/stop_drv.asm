; stop a installed and started win64 driver
; need set driver name at shell line (command prompt)
; e.g.
; stop_drv.exe a05.sys


format PE64 console
entry start


include '%fasminc%\win32a.inc'
include 'defines.inc'


section '.code' code readable executable

start:
	sub	rsp,8*(4+1)
	call	qword [GetCommandLineA]
	cld
	xchg	rsi,rax     ; parse file name
	lea	rdi,[driver_name]
	lea	rcx,[rdi + magz_syze_dn]
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

	mov	r8d,SC_MANAGER_CONNECT or SC_MANAGER_CREATE_SERVICE or SC_MANAGER_ENUMERATE_SERVICE or SC_MANAGER_LOCK or SC_MANAGER_QUERY_LOCK_STATUS or SC_MANAGER_MODIFY_BOOT_CONFIG or STANDARD_RIGHTS_REQUIRED
	xor	edx,edx
	xor	rcx,rcx
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

L0:	mov	r8d,SERVICE_QUERY_CONFIG or SERVICE_CHANGE_CONFIG or SERVICE_QUERY_STATUS or SERVICE_ENUMERATE_DEPENDENTS or SERVICE_START or SERVICE_STOP or SERVICE_PAUSE_CONTINUE or SERVICE_INTERROGATE or SERVICE_USER_DEFINED_CONTROL or STANDARD_RIGHTS_REQUIRED
	lea	rdx,[driver_name]
	xchg	rcx,rax			; handle_Service_Control_Manager
	call	qword [OpenServiceA]
	or	rax,rax
	jnz	L1

	mov	r9d,MB_OK or MB_ICONERROR
	lea	r8,[ErrMsgCaption3]
	lea	rdx,[ErrMsgText3]
	xor	ecx,ecx
	call	qword [MessageBoxA]

	mov	ecx,3
	call	qword [ExitProcess]

L1:	xchg	rbx,rax
	lea	rdx,[Service_status]
	mov	rcx,rbx
	call	qword [QueryServiceStatus]
	cmp	byte [Service_status + 4],SERVICE_STOPPED
	jz	ess

	lea	r8,[Service_status]
	mov	edx,SERVICE_CONTROL_STOP
	mov	rcx,rbx
	call	qword [ControlService]
	or	rax,rax
	jnz	L2

ess:	mov	r9d,MB_OK or MB_ICONERROR
	lea	r8,[ErrMsgCaption3]
	lea	rdx,[ErrMsgText4]
	xor	ecx,ecx
	call	qword [MessageBoxA]

	mov	ecx,4
	call	qword [ExitProcess]

L2:	mov	rcx,rbx
	call	qword [CloseServiceHandle]

egzyd:	xor	ecx,ecx
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
	lea	r8,[ErrMsgCaption1]
	lea	rdx,[ErrMsgText1_nodrv]
	xor	ecx,ecx
	call	qword [MessageBoxA]

	mov	ecx,1
	call	qword [ExitProcess]
 

section '.data' data readable writeable

ErrMsgCaption1		db	'Input shell',0
ErrMsgText1		db	'Too much input chars in command line! Must be <1024',0
ErrMsgText1_nodrv	db	'No *.sys on command line!',0

ErrMsgCaption2		db	'Open_drv',0
ErrMsgText2		db	"Can't connect to Service Control Manager",0

ErrMsgCaption3		db	'advapi32.dll',0
ErrMsgText3		db	'Error OpenService',0

;ErrMsgCaption4		db	'advapi32.dll',0
ErrMsgText4		db	'Error StopService',0


magz_syze_dn=1024
driver_name		rb	magz_syze_dn

align 16
Service_status		rd	1	;dwServiceType 1=SERVICE_KERNEL_DRIVER
			rd	1	;dwCurrentState
			rd	1	;dwControlsAccepted
			rd	1	;dwWin32ExitCode
			rd	1	;dwServiceSpecificExitCode
			rd	1	;dwCheckPoint
			rd	1	;dwWaitHint
; win64 returns:
; 00000000004024c0  01 00 00 00 - 01 00 00 00 - 00 00 00 00 - 02 00 00 00
; 00000000004024d0  00 00 00 00 - 00 00 00 00 - 00 00 00 00 - 00 00 00 00
;01 service_kernel_drived
;01 CurrentState STOPPED
; ...


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
OpenServiceA		dq	RVA _OpenServiceA
QueryServiceStatus	dq	RVA _QueryServiceStatus
ControlService		dq	RVA _ControlService
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
_OpenServiceA		dw	0
			db	'OpenServiceA',0
_QueryServiceStatus	dw	0
			db	'QueryServiceStatus',0
_ControlService		dw	0
			db	'ControlService',0
_CloseServiceHandle	dw	0
			db	'CloseServiceHandle',0
