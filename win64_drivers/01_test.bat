@echo off
echo Installing driver
copy sys\beeper01.sys c:\windows\syswow64\drivers
install_drv.exe c:\windows\syswow64\drivers\beeper01.sys
pause
echo.
echo Starting driver - this produce a beep
start_drv.exe beeper01.sys
pause
echo.
echo Removing driver
remove_drv.exe beeper01.sys
del c:\windows\syswow64\drivers\beeper01.sys
pause
