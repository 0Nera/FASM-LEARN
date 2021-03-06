;write boot sector to CHS sector 0,0,1 of drive A:, preserving boot record
;information

	org	100h

;scan command line for a file name
	mov	ch,01h
	mov	di,81h
	mov	al,' '
	repe	scasb
	lea	dx,[di-1]
	dec	di
	mov	al,13
	repne	scasb
	mov	byte [di-1],0

;open the file
	mov	ax,3D00h
	int	21h
	jc	quit

	xchg	bx,ax

;read boot sector from it
	mov	ah,3Fh
	mov	cx,512
	mov	dx,sektor
	int	21h
	jc	quit

;read the original boot sector from floppy
	mov	bp,3

	mov	cx,0001h
	xor	dx,dx			;mov    dx,cx for drive B:
	mov	bx,original

read_retry:
	mov	ax,0201h
	int	13h
	jnc	read_ok

	xor	ah,ah
	int	13h

	dec	bp
	jnz	read_retry

	retn

read_ok:
	mov	si,original+0Bh
	mov	di,sektor+0Bh
	mov	cl,28
	rep	movsb

	mov	bp,3
	mov	cx,0001h
	mov	bx,sektor

write_retry:
	mov	ax,0301h
	int	13h
	jnc	quit

	xor	ah,ah
	int	13h

	dec	bp
	jnz	write_retry

quit:
	retn
original	rb 512
sektor		rb 512
