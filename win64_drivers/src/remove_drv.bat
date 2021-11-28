set fasmbin=\asm\fasm\bin
set fasminc=\asm\fasm\include
@echo off
if not exist remove_drv.exe goto 1
del remove_drv.exe
:1
%fasmbin%\fasm.exe remove_drv.asm
pause
