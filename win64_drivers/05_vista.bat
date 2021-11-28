@echo off
echo Disable driver sign check as described in txt file
pause
echo.
echo Righ click on this bat file and select Run as administrator
pause
cls
echo Installing driver
k0py64sys.exe sys\a05.sys c:\windows\system32\drivers
install_drv.exe c:\windows\system32\drivers\a05.sys
pause
echo.
echo Starting driver
start_drv.exe a05.sys
pause
echo.
echo Writing to device, this cause:
echo Display CMOS year, make a beep, save 512 bytes of CMOS memory to a file
write_device.exe \\.\a05
pause
echo.
echo 32 bit compactibility, writing to device, this cause:
echo Display CMOS year, make a beep, save 512 bytes of CMOS memory to a file
write_device_32_bit.exe \\.\a05
pause
echo.
echo Stopping driver
stop_drv.exe a05.sys
pause
echo.
echo Removing driver
remove_drv.exe a05.sys
de1ete64sys.exe c:\windows\system32\drivers\a05.sys
