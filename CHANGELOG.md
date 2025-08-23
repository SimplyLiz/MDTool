# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2025-08-23

### Added
- **Save Changes Dialog** - Prevents accidental data loss when closing modified documents
  - Shows confirmation dialog when closing files with unsaved changes
  - Three options: Save, Discard Changes, or Cancel
  - Works for both primary and secondary files in split screen mode
  - Automatically triggered when opening new files or closing the application
- **Keyboard Shortcuts** - Cross-platform save functionality
  - **macOS**: `Cmd + S` to save the active document
  - **Windows/Linux**: `Ctrl + S` to save the active document
  - Smart active window detection (saves currently focused document)
  - User feedback for save success, no changes, or no file open
- **File and Folder Renaming** - Complete rename functionality in folder sidebar
  - Right-click context menu "Rename" option for files and folders
  - Professional rename dialogs with validation
  - Collision detection (prevents overwriting existing files/folders)
  - Automatic UI refresh after successful rename
  - Smart file extension handling (preserves extensions during rename)
  - App state updates when renaming currently open files
- **New Folder Creation** - Fully implemented folder creation
  - Right-click "New Folder" context menu option
  - Professional creation dialog with validation
  - Recursive folder creation support
  - Automatic UI refresh to show new folders
- **Window Header Menu** - Three-dot menu in window pane headers
  - Moved "Chat about this file" functionality to dropdown menu
  - Added "Export as PDF" option (placeholder implementation)
  - Clean, organized header UI with more space

### Improved
- Enhanced error handling and user feedback across all file operations
- Better dialog lifecycle management to prevent crashes
- Improved async operation handling with proper context management
- Professional UI consistency across all dialogs
- Cross-platform compatibility for all file operations
- Streamlined window header design by removing open file button

### Fixed
- Fixed TextEditingController disposal issues in dialogs
- Resolved BuildContext async usage warnings
- Improved Flutter syntax compliance and type safety

## [1.0.1] - 2025-08-23

### Added
- **New Document** context menu option in folder sidebar - Create new markdown documents directly from folder right-click menu
- **Reveal in Finder** context menu option in folder sidebar - Open folders in system file manager (cross-platform support for macOS, Windows, and Linux)
- **New Folder** context menu option in folder sidebar (placeholder implementation)

### Improved
- Enhanced folder sidebar context menu with additional file management options
- Cross-platform file system integration for revealing folders

## [1.0.0] - Initial Release

### Added
- Initial release of MDTool
- Markdown viewing and editing capabilities
- File sidebar navigation
- Mermaid chart support with interactive viewer
- WebView controller improvements for chart rendering