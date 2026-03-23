# Windows File Association Setup for MDTool

This guide explains how to add "Open with MDTool" to the Windows Explorer context menu for Markdown files.

## Installation

1. **Build the application:**
   ```cmd
   flutter build windows
   ```

2. **Install the application:**
   - Copy the built application from `build/windows/x64/runner/Release/` to `C:\Program Files\MDTool\`
   - Or install to your preferred location and update the registry file paths

3. **Install file associations:**
   - Right-click `install_file_association.bat` and select "Run as administrator"
   - This will register MDTool with Windows for Markdown file types

## What gets installed

The registry entries will:
- Associate `.md`, `.markdown`, `.mdown`, `.mkd`, `.mkdn` files with MDTool
- Add "Open with MDTool" to the context menu when right-clicking Markdown files
- Set MDTool as an available program in the "Open with" dialog

## File Extensions Supported

- `.md` - Standard Markdown
- `.markdown` - Full Markdown extension  
- `.mdown` - Markdown down
- `.mkd` - Markdown abbreviated
- `.mkdn` - Markdown down abbreviated

## Uninstallation

To remove the file associations:
- Right-click `uninstall_file_association.bat` and select "Run as administrator"

## Customization

If you install MDTool to a different location than `C:\Program Files\MDTool\`, edit `mdtool_file_association.reg` and update the paths:

```reg
@="\"%YourInstallPath%\\MDTool.exe\" \"%1\""
```

## Troubleshooting

- **Context menu doesn't appear:** Make sure you ran the installer as Administrator
- **Application doesn't open:** Check that the path in the registry matches your actual installation
- **File associations not working:** Try logging out and back in, or restart Windows

## Technical Details

The installation creates these registry entries:
- File extension associations under `HKEY_CURRENT_USER\Software\Classes\`
- Document type definition for `MDTool.Document`
- Context menu entries under `HKEY_CURRENT_USER\Software\Classes\*\shell\MDTool`