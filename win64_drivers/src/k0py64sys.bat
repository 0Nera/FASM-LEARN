set fasmbin=\asm\fasm\bin
set fasminc=\asm\fasm\include
@echo off
if not exist k0py64sys.exe goto 1
del k0py64sys.exe
:1
%fasmbin%\fasm.exe k0py64sys.asm
pause
