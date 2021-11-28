format PE64 GUI at 100000000h
entry start


include '%fasminc%\win32a.inc'


section '.text' code readable executable

start:
	sub	rsp,8*(4+3)

	call	qword [GetCommandLineA]
	cld
	xchg	rsi,rax     	; parse shell line parameters
	lea	rdi,[file_name]
	lea	rcx,[rdi + file_name_max_size - 1]
L00:	inc	rsi
	cmp	byte [rsi],' '
	ja	L00
L01:	cmp	byte [rsi],0
	jz	exit
	inc	rsi
	cmp	byte [rsi],' '
	jna	L01
L02:	movsb
	cmp	rdi,rcx
	jnbe	exit		; too long, too many characters on shell line
	cmp	byte [rsi],' '
	ja	L02
	mov	byte [rdi],0

	lea	rax,[file_name]
	mov	rcx,rdi
	sub	rcx,rax
	dec	rdi
	mov	al,'.'
	std
	repnz scasb
	jnz	exit
	cld
	lea	rdi,[rdi+2]

have_file_extension:
	mov	eax,dword [rdi]
	or	eax,00202020h	; convert capitals to lowercase, e.g. 'Sys' -> 'sys'
	cmp	eax,'sys'
	jnz	exit

	lea	rcx,[file_name]
	call	qword [DeleteFileA]
; If the function succeeds, the return value is nonzero. If the function fails, the return value is zero.

	mov	edx,MB_ICONHAND
	xor	r9,r9		;	mov	r9,MB_OK = 0
	or	rax,rax
	cmovz	r9,rdx
	lea	rcx,[caption_error]
	lea	r8,[caption_OK]
	cmovz	r8,rcx
	lea	rdx,[file_name]
	xor	ecx,ecx
	call	qword [MessageBoxA]

exit:	xor	ecx,ecx
	call	qword [ExitProcess]

align 16
caption_OK		db	'Delete success.',0
align 16
caption_error		db	'Delete error !',0,0


section '.data' data readable writeable

align 16
file_name_max_size	=	1024
file_name		rb	file_name_max_size


section '.idata' import data readable writeable

			dd	0,0,0,	RVA kernel_name,	RVA kernel_table
			dd	0,0,0,	RVA user_name,		RVA user_table
			dd	0,0,0,	0,			0

kernel_table:
GetCommandLineA		dq	RVA _GetCommandLineA
DeleteFileA		dq	RVA _DeleteFileA
ExitProcess		dq	RVA _ExitProcess
			dq	0
user_table:
MessageBoxA		dq	RVA _MessageBoxA
			dq	0

kernel_name		db	'KERNEL32.DLL',0
user_name		db	'USER32.DLL',0

; kernel32.dll:
_GetCommandLineA	db	0,0,'GetCommandLineA',0
_DeleteFileA		db	0,0,'DeleteFileA',0
_ExitProcess		db	0,0,'ExitProcess',0
; user32.dll:
_MessageBoxA		db	0,0,'MessageBoxA',0
