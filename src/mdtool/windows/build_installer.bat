@echo off
REM Build MDTool Windows installer using CPack
REM Run this from the windows directory after building the Flutter app

echo Building MDTool Windows Installer...

REM Check if Flutter build exists
if not exist "build\windows\x64\runner\Release\MDTool.exe" (
    echo Error: Flutter build not found!
    echo Please run 'flutter build windows --release' first
    pause
    exit /b 1
)

REM Create build directory for installer
if not exist "installer_build" mkdir installer_build
cd installer_build

REM Configure CMake for installer
echo Configuring installer build...
cmake .. -G "Visual Studio 17 2022" -A x64 ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX=dist

if %errorLevel% neq 0 (
    echo CMake configuration failed!
    pause
    exit /b 1
)

REM Build the project
echo Building project...
cmake --build . --config Release --target install

if %errorLevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

REM Create the installer package
echo Creating installer package...
cpack -G NSIS -C Release

if %errorLevel% neq 0 (
    echo CPack failed!
    echo Make sure NSIS is installed: https://nsis.sourceforge.io/Download
    pause
    exit /b 1
)

echo.
echo ============================================
echo Installer created successfully!
echo.
echo Output: installer_build\MDTool-1.0.0-win64.exe
echo.
echo The installer includes:
echo - MDTool application
echo - File associations for Markdown files
echo - Start menu shortcuts
echo - Desktop shortcut (optional)
echo - Uninstaller
echo ============================================

pause