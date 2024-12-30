@echo off
rem OpentTxl-C 11.1 Application Compiler

rem Do we have a C compiler?
if not "%VCINSTALLDIR%" == "" goto cfound

echo txlc: MS Visual Studio C command line tools must be installed and enabled to use txlc
echo txlc: (Available free from Microsoft MSDN as Visual Studio Community, http://visualstudio.com)
goto exit

: cfound
rem Where's FreeTXL?
if "%OS%"=="Windows_NT" set CommandDir=%windir%\System32
if "%OS%"==""  set CommandDir=%windir%\Command
if NOT "%TXLBIN%"=="" goto txlfound
set TXLBIN=%CommandDir%
: txlfound
if NOT "%TXLLIB%"=="" goto libfound
set TXLLIB=%CommandDir%\..\txl
: libfound

rem Find our source file and command arguments
set name=
for %%i in (%1 %2 %3 %4 %5 %6 %7 %8 %9) do if exist %%i set name=%%i
if "%name%" == "" goto noname
for /F %%i in ("%name%") do @set prog=%%~ni
if exist %name% goto namefound

: noname
echo Usage:  txlc [txloptions] txlfile
goto exit

rem Compile to TXLVM byte code using TXL
: namefound
if exist %prog%.ctxl del %prog%.ctxl
%TXLBIN%\txl.exe -q -c %1 %2 %3 %4 %5 %6 %7 %8 %9

rem Check that we got a result
if exist %prog%.ctxl goto compiled

echo txlc: TXL compile failed!
goto exit

rem Convert TXLVM byte code to initialized C byte array
: compiled
if exist %prog%_TXL.c del %prog%_TXL.c
%TXLLIB%\txlcvt.exe %prog%.ctxl

rem Clean up
if exist %prog%.ctxl  del %prog%.ctxl

: exit
set CommandDir=
set TXLBIN=
set TXLLIB=
set name=
set result=
set prog=

rem Rev 18.5.24

