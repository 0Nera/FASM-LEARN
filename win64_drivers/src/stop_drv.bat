set fasmbin=\asm\fasm\bin
set fasminc=\asm\fasm\include
@echo off
if not exist stop_drv.exe goto 1
del stop_drv.exe
:1
%fasmbin%\fasm.exe stop_drv.asm
pause
