Vista Beta2 x64 Build 5384

To enable driver to work we have to break one protection.
Warning! You will decrease your security level and make your OS more vulnerable!

The problem is that driver isn't signed.
We need to set nointegrity check for drivers and reboot OS.
Start -> All Programs -> Accessories -> right click on Command Prompt -> Run as admin
bcdedit.exe /set nointegritychecks ON
reboot OS

Don't forget to RIGHT CLICK on a05_vista.bat file and then select RUN AS ADMINISTRATOR !

Copy into c:\windows\system32\drivers
Please don't use any 32 bit application to copy into C:\Windows\System32
System32 is only shadowed copy of syswow64 directory for every 32 bit app.
After copying with 32 bit app, 64 bit app isn't able to find the file in system32
because it is in syswow64.
even 32 in system32, it holds 64 bit apps and 64 bit drivers
even 64 in syswow64 name, it holds 32 bit apps and any drivers
(32 bit drivers don't work on win64 - instruction set differs in long mode and 32 bit PM)
