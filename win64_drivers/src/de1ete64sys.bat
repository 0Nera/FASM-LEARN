set fasmbin=\asm\fasm\bin
set fasminc=\asm\fasm\include
@echo off
if not exist de1ete64sys.exe goto 1
del de1ete64sys.exe
:1
%fasmbin%\fasm.exe de1ete64sys.asm
pause
