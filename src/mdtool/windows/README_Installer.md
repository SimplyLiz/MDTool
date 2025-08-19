# MDTool Windows Installer

This directory contains the configuration and scripts for building a professional Windows installer using CPack and NSIS.

## Prerequisites

1. **NSIS (Nullsoft Scriptable Install System)**
   - Download from: https://nsis.sourceforge.io/Download
   - Install to default location (`C:\Program Files (x86)\NSIS\`)
   - CPack will automatically find NSIS if installed in the default location

2. **Visual Studio Build Tools**
   - Required for CMake and CPack
   - Can use Visual Studio Community or Build Tools

3. **Flutter Windows Build**
   - Must have a successful Flutter Windows build first

## Building the Installer

### Option 1: Using the Build Script (Recommended)

1. Build your Flutter app for Windows:
   ```cmd
   flutter build windows --release
   ```

2. Run the installer build script:
   ```cmd
   cd windows
   build_installer.bat
   ```

### Option 2: Manual Build

1. Build Flutter app:
   ```cmd
   flutter build windows --release
   ```

2. Configure CMake:
   ```cmd
   cd windows
   mkdir installer_build
   cd installer_build
   cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Release
   ```

3. Build and install:
   ```cmd
   cmake --build . --config Release --target install
   ```

4. Create installer:
   ```cmd
   cpack -G NSIS -C Release
   ```

## Installer Features

The generated installer (`MDTool-1.0.0-win64.exe`) includes:

- **Main Application**: Installs MDTool.exe and all dependencies
- **File Associations**: Automatically registers Markdown file types (.md, .markdown, .mdown, .mkd, .mkdn)
- **Context Menu**: Adds "Open with MDTool" to Explorer right-click menu
- **Start Menu**: Creates Start Menu shortcuts
- **Desktop Shortcut**: Optional desktop shortcut
- **Uninstaller**: Clean removal with registry cleanup

## Customization

### Installer Metadata
Edit `CMakeLists.txt` to customize:
- Version numbers (`CPACK_PACKAGE_VERSION_*`)
- Company information (`CPACK_PACKAGE_VENDOR`)
- URLs and contact info
- Icon paths

### NSIS Script
The `installer.nsi` file provides additional customization:
- Custom installer pages
- Additional file associations
- Registry entries
- Installation components

### File Associations
File associations are configured in `CMakeLists.txt`:
- Modify `CPACK_NSIS_EXTRA_INSTALL_COMMANDS` to add/remove file types
- Update `CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS` to match

## Troubleshooting

### CPack can't find NSIS
- Install NSIS from the official website
- Ensure NSIS is in your system PATH
- Or set `CMAKE_PROGRAM_PATH` to NSIS directory

### Build errors
- Ensure Flutter build was successful first
- Check that all required dependencies are available
- Verify Visual Studio Build Tools are installed

### File associations not working
- Run installer as Administrator
- Check Windows Event Viewer for registry errors
- Verify NSIS script syntax

## Distribution

The generated installer:
- Is a self-contained executable
- Requires no additional dependencies
- Can be signed with code signing certificates
- Works on Windows 10/11 (64-bit)

## Advanced Configuration

### Code Signing
To sign the installer, add to `CMakeLists.txt`:
```cmake
set(CPACK_NSIS_EXECUTABLES_DIRECTORY ".")
set(CPACK_NSIS_MUI_FINISHPAGE_RUN "MDTool.exe")
```

### Multi-language Support
Add to `installer.nsi`:
```nsis
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "German"
```

### Custom License
Replace `LICENSE` file reference in `installer.nsi` with your license file.