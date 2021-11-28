set fasmbin=\asm\fasm\bin
set fasminc=\asm\fasm\include
@echo off
if not exist start_drv.exe goto 1
del start_drv.exe
:1
%fasmbin%\fasm.exe start_drv.asm
pause
