set fasmbin=\asm\fasm\bin
set fasminc=\asm\fasm\include
@echo off
if not exist install_drv.exe goto 1
del install_drv.exe
:1
%fasmbin%\fasm.exe install_drv.asm
pause
