@echo off
REM Uninstall MDTool file associations from Windows Explorer context menu
REM Run this batch file as Administrator to remove the associations

echo Uninstalling MDTool file associations...

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as administrator - OK
) else (
    echo This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Remove registry entries
echo Removing registry entries...

reg delete "HKEY_CURRENT_USER\Software\Classes\.md" /f >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Classes\.markdown" /f >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Classes\.mdown" /f >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Classes\.mkd" /f >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Classes\.mkdn" /f >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Classes\MDTool.Document" /f >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Classes\*\shell\MDTool" /f >nul 2>&1

echo File associations removed successfully!
echo MDTool has been removed from the "Open with" context menu

pause