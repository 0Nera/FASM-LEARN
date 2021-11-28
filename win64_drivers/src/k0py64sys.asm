format PE64 GUI at 100000000h
entry start


include '%fasminc%\win32a.inc'


section '.text' code readable executable

start:
	sub	rsp,8*(4+5)

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

	lea	rdi,[path_name]
	lea	rcx,[rdi + path_name_max_size - 1]
L03:	cmp	byte [rsi],0
	jz	exit
	inc	rsi
	cmp	byte [rsi],' '
	jna	L03
L04:	movsb
	cmp	rdi,rcx
	jnbe	exit		; too long, too many characters on shell line
	cmp	byte [rsi],' '
	ja	L04
	mov	al,'\'
	cmp	byte [rdi-1],al
	jz	L05
	stosb
	cmp	rdi,rcx
	jnbe	exit
L05:	mov	byte [rdi],0

	mov	qword [rsp + 8*(4+2)],0
	mov	qword [rsp + 8*(4+1)],FILE_ATTRIBUTE_NORMAL
	mov	qword [rsp + 8*(4+0)],OPEN_EXISTING
	xor	r9,r9
	mov	r8,FILE_SHARE_READ
	mov	edx,GENERIC_READ
	lea	rcx,[file_name]
	call	qword [CreateFileA]
	cmp	rax,INVALID_HANDLE_VALUE
	jz	exit
	mov	qword [rsp + 8*(4+2)],rax	; save hFile

	xor	edx,edx
	mov	rcx,rax
	call	qword [GetFileSize]
	cmp	rax,-1
	jz	close_exit
	mov	qword [rsp + 8*(4+4)],rax	; size

	mov	r9d,PAGE_READWRITE
	mov	r8d,MEM_COMMIT
	mov	rdx,rax
	xor	ecx,ecx
	call	qword [VirtualAlloc]
; If the function succeeds, the return value is the base address of the allocated region of pages.
; If the function fails, the return value is NULL.
	or	rax,rax
	jz	close_exit
	mov	qword [rsp + 8*(4+3)],rax	; address

	mov	qword [rsp + 8*(4+0)],0
	lea	r9,[rsp + 8*(4+1)]
	mov	r8,qword [rsp + 8*(4+4)]
	xchg	rdx,rax
	mov	rcx,qword [rsp + 8*(4+2)]	; hFile
	call	qword [ReadFile]
; If the function succeeds, the return value is nonzero.
	mov	qword [rsp + 8*(4+0)],rax

	mov	rcx,qword [rsp + 8*(4+2)]
	call	qword [CloseHandle]
; If the function succeeds, the return value is nonzero
	or	rax,rax
	jz	decomit_exit

	mov	rax,qword [rsp + 8*(4+0)]	; return value of ReadFile
	or	rax,rax
	jz	decomit_exit
	mov	rax,qword [rsp + 8*(4+4)]
	cmp	qword [rsp + 8*(4+1)],rax
	jnz	decomit_exit

IMAGE_DOS_SIGNATURE		=	5A4Dh		; MZ
IMAGE_NT_SIGNATURE		=	00004550h	; PE00

IMAGE_SUBSYSTEM_UNKNOWN		=	0		; Unknown subsystem.
IMAGE_SUBSYSTEM_NATIVE		=	1		; Image doesn't require a subsystem.
IMAGE_SUBSYSTEM_WINDOWS_GUI	=	2		; Image runs in the Windows GUI subsystem.
IMAGE_SUBSYSTEM_WINDOWS_CUI	=	3		; Image runs in the Windows character subsystem.

PROCESSOR_AMD_X8664		=	8664h

;typedef struct _IMAGE_DOS_HEADER {      // DOS .EXE header
;    WORD   e_magic;                     // Magic number
;    WORD   e_cblp;                      // Bytes on last page of file
;    WORD   e_cp;                        // Pages in file
;    WORD   e_crlc;                      // Relocations
;    WORD   e_cparhdr;                   // Size of header in paragraphs
;    WORD   e_minalloc;                  // Minimum extra paragraphs needed
;    WORD   e_maxalloc;                  // Maximum extra paragraphs needed
;    WORD   e_ss;                        // Initial (relative) SS value
;    WORD   e_sp;                        // Initial SP value
;    WORD   e_csum;                      // Checksum
;    WORD   e_ip;                        // Initial IP value
;    WORD   e_cs;                        // Initial (relative) CS value
;    WORD   e_lfarlc;                    // File address of relocation table
;    WORD   e_ovno;                      // Overlay number
;    WORD   e_res[4];                    // Reserved words
;    WORD   e_oemid;                     // OEM identifier (for e_oeminfo)
;    WORD   e_oeminfo;                   // OEM information; e_oemid specific
;    WORD   e_res2[10];                  // Reserved words
;    LONG   e_lfanew;                    // File address of new exe header
;  } IMAGE_DOS_HEADER, *PIMAGE_DOS_HEADER;

;typedef struct _IMAGE_FILE_HEADER {
;    WORD    Machine;
;    WORD    NumberOfSections;
;    DWORD   TimeDateStamp;
;    DWORD   PointerToSymbolTable;
;    DWORD   NumberOfSymbols;
;    WORD    SizeOfOptionalHeader;
;    WORD    Characteristics;
;} IMAGE_FILE_HEADER, *PIMAGE_FILE_HEADER;
;
;#define IMAGE_SIZEOF_FILE_HEADER             20

;typedef struct _IMAGE_OPTIONAL_HEADER64 {
;    WORD        Magic;
;    BYTE        MajorLinkerVersion;
;    BYTE        MinorLinkerVersion;
;    DWORD       SizeOfCode;
;    DWORD       SizeOfInitializedData;
;    DWORD       SizeOfUninitializedData;
;    DWORD       AddressOfEntryPoint;
;    DWORD       BaseOfCode;
;    ULONGLONG   ImageBase;
;    DWORD       SectionAlignment;
;    DWORD       FileAlignment;
;    WORD        MajorOperatingSystemVersion;
;    WORD        MinorOperatingSystemVersion;
;    WORD        MajorImageVersion;
;    WORD        MinorImageVersion;
;    WORD        MajorSubsystemVersion;
;    WORD        MinorSubsystemVersion;
;    DWORD       Win32VersionValue;
;    DWORD       SizeOfImage;
;    DWORD       SizeOfHeaders;
;    DWORD       CheckSum;
;    WORD        Subsystem;
;    WORD        DllCharacteristics;
;    ULONGLONG   SizeOfStackReserve;
;    ULONGLONG   SizeOfStackCommit;
;    ULONGLONG   SizeOfHeapReserve;
;    ULONGLONG   SizeOfHeapCommit;
;    DWORD       LoaderFlags;
;    DWORD       NumberOfRvaAndSizes;
;    IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];
;} IMAGE_OPTIONAL_HEADER64, *PIMAGE_OPTIONAL_HEADER64;

	mov	rax,qword [rsp + 8*(4+3)]
	cmp	word [rax],IMAGE_DOS_SIGNATURE	; IMAGE_DOS_HEADER.e_magic = IMAGE_DOS_SIGNATURE
	jnz	decomit_exit
	mov	ecx,[rax+3Ch]			; IMAGE_DOS_HEADER.e_lfanew
	cmp	word [rax+rcx],IMAGE_NT_SIGNATURE; IMAGE_NT_SIGNATURE ; ??? cmp dword [],...
	jnz	decomit_exit
	cmp	word [rax+rcx+4],PROCESSOR_AMD_X8664; IMAGE_FILE_HEADER.Machine = PROCESSOR_AMD_X8664
	jnz	decomit_exit
	cmp	word [rax+rcx+5Ch],IMAGE_SUBSYSTEM_NATIVE
	jnz	decomit_exit

; prepare path + filename
; strip file name from last '\'
	lea	rsi,[file_name]
	lea	rdi,[rsi]
ppfnL0:	lodsb
	cmp	al,'\'
	cmovz	rdi,rsi
	or	al,al
	jnz	ppfnL0

	lea	rsi,[rdi]			; save string begin
	call	scan_lenght
	xchg	rcx,rax				; save size

	lea	rdi,[path_name]
	call	scan_lenght
	lea	rdi,[rdi+rax]			; add string size
	repz movsb
	mov	byte [rdi],cl			; zero_terminated_string

	mov	qword [rsp + 8*(4+2)],0
	mov	qword [rsp + 8*(4+1)],FILE_ATTRIBUTE_NORMAL
	mov	qword [rsp + 8*(4+0)],CREATE_ALWAYS	; Creates a new file. The function overwrites the file if it exists.
	xor	r9,r9
	xor	r8,r8
	mov	edx,GENERIC_WRITE
	lea	rcx,[path_name]
	call	qword [CreateFileA]
	cmp	rax,INVALID_HANDLE_VALUE
	jz	decomit_exit
	mov	qword [rsp + 8*(4+2)],rax	; save hFile

	mov	qword [rsp + 8*(4+0)],0
	lea	r9,[rsp + 8*(4+1)]
	mov	r8,qword [rsp + 8*(4+4)]	; size
	mov	rdx,qword [rsp + 8*(4+3)]	; address
	xchg	rcx,rax				; hFile
	call	qword [WriteFile]
; If the function succeeds, the return value is nonzero.
	mov	qword [rsp + 8*(4+0)],rax

	mov	rcx,qword [rsp + 8*(4+2)]
	call	qword [CloseHandle]
; If the function succeeds, the return value is nonzero
	or	rax,rax
	jz	decomit_exit

	mov	rax,qword [rsp + 8*(4+0)]	; return value of WriteFile
	or	rax,rax
	jz	decomit_exit
	mov	rax,qword [rsp + 8*(4+4)]
	cmp	qword [rsp + 8*(4+1)],rax
	jnz	decomit_exit

	xor	r9,r9				;	mov	r9,MB_OK = 0
	lea	r8,[caption_OK]
	lea	rdx,[path_name]
	xor	ecx,ecx
	call	qword [MessageBoxA]

decomit_exit:
	mov	r8d,MEM_DECOMMIT
	mov	rdx,qword [rsp + 8*(4+4)]	; size
	mov	rcx,qword [rsp + 8*(4+3)]	; address
	call	qword [VirtualFree]
; If the function succeeds, the return value is nonzero. If the function fails, the return value is zero.
;	or	rax,rax
;	jz	exit

exit:	xor	ecx,ecx
	call	qword [ExitProcess]

close_exit:
	mov	rcx,qword [rsp + 8*(4+2)]	; hFile
	call	qword [CloseHandle]

	jmp	exit

scan_lenght:
	push	rcx
	push	rdi
	xor	eax,eax
	or	rcx,-1
	repnz scasb
	not	rcx
	lea	rax,[rcx-1]
	pop	rdi
	pop	rcx
	ret

	dd	0,0,0

align 16
caption_OK		db	'Copy success.',0


section '.data' data readable writeable

align 16
path_name_max_size	=	1024
path_name		rb	path_name_max_size

align 16
file_name_max_size	=	1024
file_name		rb	file_name_max_size


section '.idata' import data readable writeable

			dd	0,0,0,	RVA kernel_name,	RVA kernel_table
			dd	0,0,0,	RVA user_name,		RVA user_table
			dd	0,0,0,	0,			0

kernel_table:
GetCommandLineA		dq	RVA _GetCommandLineA
CreateFileA		dq	RVA _CreateFileA
GetFileSize		dq	RVA _GetFileSize
ReadFile		dq	RVA _ReadFile
WriteFile		dq	RVA _WriteFile
CloseHandle		dq	RVA _CloseHandle
VirtualAlloc		dq	RVA _VirtualAlloc
VirtualFree		dq	RVA _VirtualFree
ExitProcess		dq	RVA _ExitProcess
    			dq	0
user_table:
MessageBoxA		dq	RVA _MessageBoxA
    			dq	0

kernel_name		db	'KERNEL32.DLL',0
user_name		db	'USER32.DLL',0

; kernel32.dll:
_GetCommandLineA	db	0,0,'GetCommandLineA',0
_CreateFileA		db	0,0,'CreateFileA',0
_GetFileSize		db	0,0,'GetFileSize',0
_ReadFile		db	0,0,'ReadFile',0
_WriteFile		db	0,0,'WriteFile',0
_CloseHandle		db	0,0,'CloseHandle',0
_VirtualAlloc		db	0,0,'VirtualAlloc',0
_VirtualFree		db	0,0,'VirtualFree',0
_ExitProcess		db	0,0,'ExitProcess',0
; user32.dll:
_MessageBoxA		db	0,0,'MessageBoxA',0
