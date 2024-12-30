@echo off
rem OpentTxl-C Version 11 Installation script
rem Copyright 2023, James R. Cordy and others

rem Announce our plans
echo/
echo Installing OpenTxl-C 11 on your system.
echo/
pause
cls

rem What kind of place are we
if "%OS%"=="Windows_NT" goto systemok
echo/
echo Sorry, Windows 10 or 11 is required.
echo/
pause
exit
: systemok
set CommandDir="%windir%\System32"

rem Check we have the TXL distribution files
set HERE=%~dp0
chdir %HERE%
if exist bin\txl.exe goto gotem
echo/
echo Can't find the OpenTxl distribution files -
echo please run this install script directly in the distribution folder.
echo/
pause
exit
: gotem

rem Install TXL commands
echo Installing TXL commands into %CommandDir%
copy/y bin\*.* %CommandDir%
if errorlevel 2 goto failed
echo Done.
echo/
pause
cls

rem Install TXL library
echo Installing TXL library into %CommandDir%\..\txl
mkdir %CommandDir%\..\txl
copy/y lib\*.* %CommandDir%\..\txl
if errorlevel 2 goto failed
echo Done.
echo/
pause
cls

rem Test TXL
echo Testing TXL
echo/
chdir .\test
txl ultimate.question
echo/
if errorlevel 2 goto failed
echo Ok.
echo/
pause
cls
exit

: failed
echo/
echo Installation failed!
echo/
echo Possibly you are not logged in as adminstrator -
echo if so, please log in as adminstrator and try again.
echo/
pause
exit

rem Rev 10.4.23
