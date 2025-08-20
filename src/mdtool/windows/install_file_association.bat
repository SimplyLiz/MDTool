@echo off
REM Install MDTool file associations for Windows Explorer context menu
REM Run this batch file as Administrator after building the application

echo Installing MDTool file associations...

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

REM Apply registry entries
echo Applying registry entries...
reg import "%~dp0mdtool_file_association.reg"

if %errorLevel% == 0 (
    echo File associations installed successfully!
    echo MDTool will now appear in the "Open with" context menu for Markdown files
) else (
    echo Failed to install file associations
    echo Error code: %errorLevel%
)

echo.
echo Note: Make sure MDTool.exe is installed in %ProgramFiles%\MDTool\
echo If installed elsewhere, edit mdtool_file_association.reg with the correct path

pause