@echo off
set process_name="NetbirdPublicIPCheckerPass.exe"

:loop_start
tasklist /FI "IMAGENAME eq NetbirdPublicIPCheckerPass.exe" 2>NUL | find /I "NetbirdPublicIPCheckerPas" > NUL
if %errorlevel% == 0 (
    echo Process NetbirdPublicIPCheckerPass.exe is running...
    
    REM Place commands to execute while the process is running here
    cls
    echo off
    echo "as long as this process is running and your posture checks are correctly configured, netbird should stay connected to the VPN"
    

    timeout /t 5 /nobreak > NUL
    goto loop_start
) else (
    echo Process NetbirdPublicIPCheckerPass.exe is not running. Exiting loop.

    REM remove batch file
    del /Q "%~dp0\NetbirdIPCheckerPass.bat"
)

echo Script finished.