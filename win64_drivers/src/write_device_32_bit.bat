set fasmbin=\asm\fasm\bin
set fasminc=\asm\fasm\include
@echo off
if not exist write_device_32_bit.exe goto 1
del write_device_32_bit.exe
:1
%fasmbin%\fasm.exe write_device_32_bit.asm
pause
