set fasmbin=\asm\fasm\bin
set fasminc=\asm\fasm\include
@echo off
if not exist write_device.exe goto 1
del write_device.exe
:1
%fasmbin%\fasm.exe write_device.asm
pause
