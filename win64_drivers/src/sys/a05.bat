set fasmbin=\asm\fasm\bin
set fasminc=\asm\fasm\include
@echo off
if not exist a05.sys goto 1
del a05.sys
:1
%fasmbin%\fasm.exe a05.asm
pause
