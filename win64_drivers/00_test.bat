@echo off
echo Installing driver
copy sys\beeper00.sys c:\windows\syswow64\drivers
install_drv.exe c:\windows\syswow64\drivers\beeper00.sys
pause
echo.
echo Starting driver - this produce a beep
start_drv.exe beeper00.sys
pause
echo.
echo Removing driver
remove_drv.exe beeper00.sys
del c:\windows\syswow64\drivers\beeper00.sys
pause
