; the most simple win64 "driver"
; when started (use start_drv.exe) it produce a beep
; it can't be stopped because it hasn't implemented procedure for stop
; so if you want to use it again, you must reboot win64

format PE64 native 5.02 at 10000h
entry start


section '.text' code readable executable notpageable

start:
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
	mov	eax,30000000h
delay_loop:
	dec	rax
	or	rax,rax
; it's enough to use dec eax... but we used 2 instructions for slow-down the loop
	jnz	delay_loop
	cli
	in	al,61h
	and	al,0FCh
	out	61h,al
	sti

	xor	eax,eax			; success exit code

	ret
