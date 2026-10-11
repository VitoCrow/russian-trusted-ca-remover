@echo off
setlocal
cd /d "%~dp0"
title Russian Trusted CA - Certificate Cleanup
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Remove-RussianTrustedCA.ps1"
if errorlevel 1 (
    echo.
    echo Script exited with an error.
    pause
)
endlocal
