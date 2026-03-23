# Folder Sidebar - Internal Documentation

## Overview
The folder sidebar is a core component of MDTool that provides hierarchical file navigation, file management operations, and serves as the primary interface for working with markdown files and folders.

## File Location
- **Main Component**: `/lib/ui/widgets/folder_sidebar.dart`
- **Related Files**:
  - `/lib/core/providers/app_state_provider.dart` (state management)
  - `/lib/ui/dialogs/save_changes_dialog.dart` (confirmation dialogs)
  - `/lib/core/services/file_service.dart` (file operations)

## Architecture

### Core Classes
1. **`FolderSidebar`** - Main ConsumerStatefulWidget
2. **`TreeController`** - Manages hierarchical tree structure
3. **`TreeItem`** (abstract) - Base class for tree items
4. **`FolderTreeItem`** - Represents folders with lazy loading
5. **`FileTreeItem`** - Represents markdown files

### Key Features Implemented

#### 1. Context Menu System (Lines 698-836)
**Folder Context Menu**:
- New Folder (creates folders with dialog)
- New Document (creates "New Document.md" files)  
- Set as Base Folder (changes root directory)
- Reveal in Finder (cross-platform file manager integration)
- Rename (professional rename dialog with validation)
- Move to Trash (placeholder)
- Chat About Folder (placeholder)

**File Context Menu**:
- Open in Current Window
- Rename (preserves file extensions)
- Move to Trash (placeholder)
- Chat About File (placeholder)

#### 2. File Operations

**New Document Creation** (Lines 858-921):
```dart
Future<void> _createNewDocument(String folderPath) async
```
- Creates "New Document.md" with template content
- Collision detection
- Auto-refresh UI
- Opens created file automatically

**New Folder Creation** (Lines 923-1002):
```dart
Future<void> _createNewFolder(String parentPath) async
```
- Professional dialog with validation
- Collision detection
- Recursive folder creation
- Auto-refresh UI

**File/Folder Renaming** (Lines 1032-1227):
```dart
Future<void> _renameFolder(String folderPath) async
Future<void> _renameFile(String filePath) async
```
- Smart extension handling for files
- Collision detection
- App state updates for open files
- Professional dialogs with proper lifecycle management

**File Opening with Confirmation** (Lines 678-700):
```dart
Future<void> _openFile(String filePath) async
```
- Integrates with save changes dialog
- Prevents data loss when switching files

#### 3. Tree Management

**Virtualized Rendering** (Lines 186-204):
- Uses `ListView.builder` for performance
- Fixed item height (40.0) for consistency
- Efficient for large file counts

**Lazy Loading** (Lines 435-519):
- Folders load contents on-demand
- Progress indicators during loading
- Metadata caching integration

**State Management** (Lines 26-96):
- `TreeController` manages expansion state
- `_selectedItemPath` tracks selection
- `_treeController` handles tree operations

## Technical Implementation Details

### Context Menu Type Safety (Lines 707 & 793)
Fixed Flutter type inference issues:
```dart
items: <PopupMenuEntry<dynamic>>[
  PopupMenuItem<dynamic>(...),
  const PopupMenuDivider(),
]
```

### Dialog Lifecycle Management
Resolved TextEditingController disposal issues by:
- Creating controllers inside dialog builders
- Explicit disposal in button handlers
- Using external variables for results

### Cross-Platform Integration
**File Manager Integration** (Lines 1004-1018):
```dart
if (Platform.isMacOS) {
  await Process.run('open', [folderPath]);
} else if (Platform.isWindows) {
  await Process.run('explorer', [folderPath]);
} else {
  await Process.run('xdg-open', [folderPath]); // Linux
}
```

### Performance Optimizations
- **Efficient Tree Flattening** (Lines 865-881)
- **Virtualized Rendering** with fixed item heights
- **Metadata Caching** via `FolderIndexService`
- **Quick Scan** for immediate file count display

## Integration Points

### App State Provider Integration
- **File Opening**: Uses `openFileWithConfirmation()`
- **State Updates**: Updates `currentFile`, `content`, `isDirty` states
- **Active Window**: Respects `activeWindow` for proper file handling

### Save Changes Dialog Integration
- **File Switching**: Confirms before opening new files
- **File Closing**: Integrated with window close operations
- **Data Loss Prevention**: Three-option confirmation (Save/Discard/Cancel)

### File Service Integration
- **Read Operations**: `fileService.readFile(filePath)`
- **Write Operations**: `fileService.writeFile(filePath, content)`
- **File System**: Direct `File` and `Directory` operations

## Known Issues & Limitations

### Implemented
✅ **Context Menu Type Safety** - Fixed PopupMenuEntry type issues  
✅ **Dialog Lifecycle** - Fixed TextEditingController disposal  
✅ **Cross-Platform Support** - File manager integration  
✅ **Save Confirmation** - Prevents data loss  
✅ **Professional Dialogs** - Consistent UI/UX  

### Placeholders (Not Implemented)
❌ **Move to Trash** - File/folder deletion  
❌ **Chat About File/Folder** - AI integration  

## Performance Characteristics

### Strengths
- **Lazy Loading**: Only loads visible/expanded folders
- **Virtualization**: Handles large file counts efficiently
- **Metadata Caching**: Fast file count displays
- **Efficient Updates**: Minimal UI refreshes

### Optimization Opportunities
- **Tree State Persistence**: Could save expansion state
- **Background Loading**: Async folder scanning
- **Search Integration**: Quick file finding

## Testing Scenarios

### Manual Testing Checklist
1. **Context Menu Operations**:
   - Right-click folders → verify all menu options
   - Right-click files → verify all menu options
   - Test on different platforms (Mac/Windows/Linux)

2. **File Operations**:
   - Create new documents and folders
   - Rename files and folders (test edge cases)
   - Open files with/without unsaved changes

3. **Dialog Behavior**:
   - Test cancel operations
   - Test collision detection
   - Verify proper error handling

4. **Performance**:
   - Test with large folder structures
   - Verify smooth scrolling and expansion

## Future Enhancement Ideas

### Immediate Improvements
- **Drag & Drop**: File moving between folders
- **Multi-Selection**: Bulk operations
- **Search/Filter**: Quick file finding
- **Keyboard Navigation**: Arrow key support

### Advanced Features  
- **Git Integration**: Show file status
- **File Thumbnails**: Preview for images
- **Recent Files**: Quick access panel
- **Bookmarks**: Favorite folders

## Error Handling Patterns

### Current Implementation
```dart
try {
  // File operation
  await fileService.writeFile(path, content);
  // Success feedback
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Success message'))
  );
} catch (e) {
  // Error feedback  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'))
    );
  }
}
```

### Best Practices
- Always check `mounted` before showing UI feedback
- Use try/catch for all file operations
- Provide specific error messages
- Handle platform-specific edge cases

## State Management Flow

```
User Action → Context Menu → Dialog → File Operation → State Update → UI Refresh
     ↓              ↓           ↓            ↓             ↓           ↓
Right-click → Show Menu → Input → File API → App State → Re-render
```

## Dependencies

### Core Dependencies
- `flutter_riverpod` - State management
- `dart:io` - File system operations
- Flutter's material widgets

### Service Dependencies
- `FileService` - File read/write operations
- `FolderIndexService` - Metadata and scanning
- `AppStateProvider` - Application state management

This documentation should provide complete context for future Claude sessions working on the folder sidebar component.