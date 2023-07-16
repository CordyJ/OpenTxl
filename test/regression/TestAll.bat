@echo off
rem OpenTxl-C 11 Regression Test script
rem J.R. Cordy, Jan 2023

rem The TXLs to compare
set CommandDir=%windir%\System32
set OLDTXL=%CommandDir%\txl.exe
set NEWTXL=..\..\bin\txl.exe

if exist %OLDTXL%  goto oldok
echo ERROR: No installed TXL to compare to (%OLDTXL%)
exit 
: oldok

if exist %NEWTXL%  goto newok
echo ERROR: No new TXL to compare to (%NEWTXL% - did you remember to build it?)
exit 
: newok
set NEWTXL=..\..\..\bin\txl.exe

rem Set up fake input
echo 42 > .\42.txt

rem Clean up old results
for /d %%a in (*) do for %%f in (%%a\*output) do del "%%f"

rem Keep track of success
echo ==== TESTING ====
set success=true

rem For all of the tests in the regression set
for /d %%d in (*) do (
    rem echo %%d
    cd .\%%d

    for %%e in (.\eg*) do (

        rem Run old TXL
        echo. > %%e-oldoutput
        %OLDTXL% -v -s 400 -w 200 %%e -o %%e-oldoutput < ..\42.txt > %%e-olderroutput 2>&1

        rem Run new TXL
        echo. > %%e-newoutput
        %NEWTXL% -v -s 400 -w 200 %%e -o %%e-newoutput < ..\42.txt > %%e-newerroutput 2>&1

        rem Diff them
        fc /l %%e-oldoutput %%e-newoutput > nul 2>&1
        if errorlevel 1 (
            echo ** Output for %%d\%%e differs
            set success=false
        )
    )

    cd ..
)

del .\42.txt

rem Report results
if %success% == true   echo ==== SUCCEEDED ====
if %success% == false  echo ==== FAILED ====
exit
