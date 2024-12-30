@echo off
rem OpentTxl-C Version 11 Uninstallation script
rem Copyright 2023, James R. Cordy and others

rem Announce our plans
echo/
echo Removing OpenTxl-C from your system.
echo/
pause
cls

rem Default location
set CommandDir="%windir%\System32"

rem Uninstall TXL commands
echo Uninstalling TXL commands from %CommandDir%
del %CommandDir%\txl.exe
del %CommandDir%\txldb.exe
del %CommandDir%\txlc.bat
del %CommandDir%\txlp.bat
echo Done.
echo/
pause
cls

rem Uninstall TXL library
echo Uninstalling the TXL library %CommandDir%\..\txl
del /q %CommandDir%\..\txl\*.*
rmdir %CommandDir%\..\txl
echo Done.
echo/
pause
cls
exit

rem Rev 10.4.23
