:loop_start

tasklist /FI "IMAGENAME eq NetBirdPublicIPCheckerService.exe" 2>NUL | find /I "NetbirdPublicIPCheckerSer" > NUL
if %errorlevel% == 0 (

REM execute IPCheck.ps1 powershell script to check with netbird server for public IP address
powershell.exe -executionpolicy bypass -file "%~dp0IPCheck.ps1"

goto loop_start
) else (
    echo Process NetBirdPublicIPCheckerService.exe is not running. Exiting loop.
)
