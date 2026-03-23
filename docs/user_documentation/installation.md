# Installation Guide

This guide covers installing MDTool on macOS and Windows, including setting up file associations for seamless integration with your system.

## System Requirements

### macOS
- **Operating System**: macOS 10.15 (Catalina) or later
- **Processor**: Intel or Apple Silicon (M1/M2/M3)
- **Memory**: 4 GB RAM minimum, 8 GB recommended
- **Storage**: 200 MB free space

### Windows
- **Operating System**: Windows 10 (64-bit) or Windows 11
- **Memory**: 4 GB RAM minimum, 8 GB recommended
- **Storage**: 200 MB free space

## Installation Methods

### macOS Installation

#### Method 1: Pre-built Release (Recommended)
1. Download the latest `MDTool.app` from the releases page
2. Open the downloaded `.dmg` file
3. Drag `MDTool.app` to your Applications folder
4. On first launch, you may need to allow the app in System Preferences > Security & Privacy

#### Method 2: Build from Source
```bash
git clone [repository-url]
cd MDTool/src/mdtool
flutter pub get
cd macos && pod install && cd ..
flutter build macos --release
```
The built app will be in `build/macos/Build/Products/Release/MDTool.app`

### Windows Installation

#### Method 1: Windows Installer (Recommended)
1. Download `MDTool-1.0.0-win64.exe` from the releases page
2. Run the installer as Administrator
3. Follow the installation wizard
4. The installer automatically sets up file associations

**What the installer includes:**
- MDTool application and all dependencies
- Automatic Markdown file associations (.md, .markdown, .mdown, .mkd, .mkdn)
- "Open with MDTool" context menu in Windows Explorer
- Start Menu shortcuts
- Optional desktop shortcut
- Clean uninstaller for easy removal

#### Method 2: Portable Version
1. Download the portable ZIP file
2. Extract to your preferred location
3. Run `MDTool.exe` directly
4. For file associations, see [Manual File Association Setup](#manual-file-association-setup)

#### Method 3: Build from Source
```cmd
git clone [repository-url]
cd MDTool/src/mdtool
flutter pub get
flutter build windows --release
```

## File Associations

### macOS
File associations are automatically configured when you install MDTool. After installation:

1. Right-click any Markdown file (.md, .markdown, etc.)
2. Select "Open With" > "MDTool"
3. To make MDTool the default: "Get Info" > "Open with" > Select MDTool > "Change All"

**Supported file types:**
- .md, .markdown, .mdown, .mkd, .mkdn

### Windows
The installer automatically sets up file associations. If using the portable version or need manual setup:

#### Automatic Setup (Installer)
File associations are handled automatically during installation. You'll see:
- "Open with MDTool" in Windows Explorer context menu
- MDTool as an option in "Open with" dialogs
- Optional: Set as default for Markdown files

#### Manual File Association Setup
If you need to set up associations manually:

1. **Using the Registry** (Advanced users):
   ```cmd
   # Run as Administrator
   cd src/mdtool/windows
   install_file_association.bat
   ```

2. **Using Windows Settings**:
   - Go to Settings > Apps > Default apps
   - Click "Choose default apps by file type"
   - Find ".md" and select MDTool
   - Repeat for other Markdown extensions

## First-Time Setup

### 1. Launch MDTool
- **macOS**: Open from Applications folder or Launchpad
- **Windows**: Use Start Menu or desktop shortcut

### 2. Grant Permissions (macOS)
On first launch, macOS may ask for permissions:
- **File Access**: Allow MDTool to access files and folders
- **Security**: Click "Allow" if prompted about an unidentified developer

### 3. Initial Configuration
1. MDTool will open with a welcome interface
2. You can immediately start by:
   - Opening an existing Markdown file
   - Creating a new document
   - Setting a base folder for file navigation

### 4. Optional: Configure AI Features
If you plan to use AI chat features:
1. Go to Preferences (Cmd/Ctrl + ,)
2. Navigate to AI Settings
3. Configure OpenAI API key or Ollama settings
4. See [Advanced Features](advanced-features.md) for details

## Verification

### Test Your Installation
1. **Launch MDTool** - Ensure the application starts without errors
2. **Open a Markdown file** - Test file association by double-clicking a .md file
3. **Create a new document** - Use File > New or Cmd/Ctrl + N
4. **Test preview** - Switch to preview mode to ensure rendering works

### Common First-Run Issues

#### macOS: "App can't be opened"
```bash
# Remove quarantine flag
xattr -dr com.apple.quarantine /Applications/MDTool.app
```

#### Windows: Missing dependencies
- Install [Microsoft Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)
- Ensure Windows is up to date

#### File associations not working
- **macOS**: Try logging out and back in
- **Windows**: Re-run installer as Administrator

## Uninstallation

### macOS
1. Drag MDTool.app from Applications to Trash
2. Optional: Clear preferences from `~/Library/Preferences/`

### Windows
1. **If installed via installer**: Use Windows "Add or Remove Programs"
2. **If portable**: Simply delete the MDTool folder
3. **To remove file associations**: Run `uninstall_file_association.bat` as Administrator

## Next Steps
- [Getting Started Guide](getting-started.md) - Learn the basics
- [Interface Guide](interface-guide.md) - Understand the layout
- [Preferences](preferences.md) - Customize your experience