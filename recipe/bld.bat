@echo off
setlocal enabledelayedexpansion

if "%ARCH%"=="32" (
    set "EPICS_HOST_ARCH=win32-x86"
) else (
    set "EPICS_HOST_ARCH=windows-x64"
)

echo EPICS_BASE=%EPICS_BASE%> configure\RELEASE.local

set "SCRIPTS="                       :: avoid python-scripts masking make
set "PATH=%BUILD_PREFIX%\Library\bin;%BUILD_PREFIX%\Library\usr\bin;%PATH%"

make -j %CPU_COUNT%
if errorlevel 1 (
    echo MAKE FAILED
    exit /b 1
)

mkdir "%PREFIX%\bin" "%PREFIX%\lib" ^
      "%PREFIX%\include\pvxs" "%PREFIX%\pvxs\dbd" "%PREFIX%\pvxs\db"

copy "bin\%EPICS_HOST_ARCH%\*.exe" "%PREFIX%\bin\"   >nul
copy "lib\%EPICS_HOST_ARCH%\*.dll" "%PREFIX%\bin\"   >nul
copy "lib\%EPICS_HOST_ARCH%\*.lib" "%PREFIX%\lib\"   >nul
copy "include\pvxs\*"              "%PREFIX%\include\pvxs\" >nul
copy "dbd\*"                       "%PREFIX%\pvxs\dbd\"     >nul
copy "db\*"                        "%PREFIX%\pvxs\db\"      >nul

mkdir "%PREFIX%\etc\conda\activate.d" "%PREFIX%\etc\conda\deactivate.d"
echo @echo off> "%PREFIX%\etc\conda\activate.d\pvxs_activate.bat"
echo set PVXS=%PREFIX%\pvxs\>> "%PREFIX%\etc\conda\activate.d\pvxs_activate.bat"
echo @echo off> "%PREFIX%\etc\conda\deactivate.d\pvxs_deactivate.bat"
echo set PVXS=>> "%PREFIX%\etc\conda\deactivate.d\pvxs_deactivate.bat"
