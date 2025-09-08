@echo off
setlocal enabledelayedexpansion

if "%ARCH%"=="32" (
    set "EPICS_HOST_ARCH=win32-x86"
) else (
    set "EPICS_HOST_ARCH=windows-x64"
)

echo EPICS_BASE=%EPICS_BASE%> configure\RELEASE.local

set "SCRIPTS=" & :: avoid python-scripts masking make
set "PATH=%BUILD_PREFIX%\Library\bin;%BUILD_PREFIX%\Library\usr\bin;%PATH%"

make -j %CPU_COUNT%
if errorlevel 1 (
    echo MAKE FAILED
    exit /b 1
)

rem Install to both conda and EPICS locations
mkdir "%PREFIX%\Library\bin" ^
      "%PREFIX%\Library\lib" ^
      "%PREFIX%\Library\include\pvxs" ^
      "%PREFIX%\pvxs\include\pvxs" ^
      "%PREFIX%\pvxs\dbd" ^
      "%PREFIX%\pvxs\db" >nul

copy "bin\%EPICS_HOST_ARCH%\*.exe" "%PREFIX%\Library\bin\" >nul
copy "bin\%EPICS_HOST_ARCH%\*.dll" "%PREFIX%\Library\bin\" >nul
copy "lib\%EPICS_HOST_ARCH%\*.lib" "%PREFIX%\Library\lib\" >nul
copy "include\pvxs\*"              "%PREFIX%\Library\include\pvxs\" >nul

copy "include\pvxs\*"              "%PREFIX%\pvxs\include\pvxs\" >nul
copy "dbd\*"                       "%PREFIX%\pvxs\dbd\" >nul
copy "db\*"                        "%PREFIX%\pvxs\db\" >nul

if not exist "%PREFIX%\etc\conda\activate.d" mkdir "%PREFIX%\etc\conda\activate.d"
if not exist "%PREFIX%\etc\conda\deactivate.d" mkdir "%PREFIX%\etc\conda\deactivate.d"
echo @echo off> "%PREFIX%\etc\conda\activate.d\pvxs_activate.bat"
echo set PVXS=%PREFIX%\pvxs\>> "%PREFIX%\etc\conda\activate.d\pvxs_activate.bat"
echo @echo off> "%PREFIX%\etc\conda\deactivate.d\pvxs_deactivate.bat"
echo set PVXS=>> "%PREFIX%\etc\conda\deactivate.d\pvxs_deactivate.bat"
