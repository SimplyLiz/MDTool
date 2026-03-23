# TH Folder Sidebar

A reusable Flutter package providing a hierarchical folder sidebar with file navigation, lazy loading, and customizable file operations.

## Features

- 🌳 **Hierarchical File Navigation**: Tree-based folder and file display
- ⚡ **Lazy Loading**: Efficient loading of folder contents on-demand
- 🚀 **Virtualization**: High performance with large directory structures  
- 📱 **Cross-Platform**: Works on macOS, Windows, Linux, iOS, and Android
- 🎨 **Customizable**: Extensive theming and configuration options
- 🔧 **Abstracted Services**: Pluggable implementations for file operations
- 📝 **Context Menus**: Right-click operations for files and folders
- 🎯 **Drag & Drop**: Support for drag and drop operations
- 🔒 **Permission Handling**: Built-in permission management for secure file access
- ⚙️ **State Management Agnostic**: Works with any state management solution

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  th_folder_sidebar:
    path: ../packages/th_folder_sidebar
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:th_folder_sidebar/th_folder_sidebar.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Create service implementations
    final fileService = DefaultFileService();
    final permissionsService = DefaultPermissionsService();
    
    // You'll need to provide your own implementations for these:
    final folderService = MyFolderService(); 
    final stateManager = MyStateManager();
    
    // Configure the sidebar
    final config = FolderSidebarConfig(
      fileService: fileService,
      folderService: folderService,
      permissionsService: permissionsService,
      stateManager: stateManager,
      width: 300.0,
      showOnlyMarkdownFiles: true,
      onFileSelected: (filePath) {
        print('File selected: $filePath');
      },
    );
    
    return MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            FolderSidebar(config: config), // Will be available after implementation
            Expanded(
              child: Container(
                child: Text('Main content area'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Custom Service Implementation

The package uses abstract interfaces that you can implement according to your needs:

```dart
class MyFolderService implements FolderServiceInterface {
  @override
  Future<FolderMetadata> getFolderMetadata(
    String folderPath, {
    bool shouldFilter = false,
    bool forceRefresh = false,
    bool includeHidden = false,
  }) async {
    // Your implementation here
    // This could use a database, cache, web service, etc.
  }
  
  // Implement other required methods...
}

class MyStateManager implements StateManagerInterface {
  // Implement with your preferred state management solution
  // (Riverpod, Provider, BLoC, GetX, etc.)
}
```

## Configuration Options

### FolderSidebarConfig

The `FolderSidebarConfig` class provides extensive customization options:

```dart
FolderSidebarConfig(
  // Required Services
  fileService: fileService,
  folderService: folderService,
  permissionsService: permissionsService,
  stateManager: stateManager,
  
  // Appearance
  width: 280.0,
  isVisible: true,
  backgroundColor: Colors.white,
  borderColor: Colors.grey,
  padding: EdgeInsets.all(8.0),
  
  // Header
  headerTitle: 'Files',
  showHeader: true,
  headerActions: [
    HeaderAction.refresh(() => refresh()),
    HeaderAction.addFolder(() => createFolder()),
  ],
  
  // Behavior
  enableLazyLoading: true,
  enableVirtualization: true,
  enableFileOperations: true,
  enableContextMenus: true,
  enableDragAndDrop: true,
  
  // Filtering
  showOnlyMarkdownFiles: true,
  showHiddenFiles: false,
  fileFilter: (path) => path.endsWith('.md'),
  
  // Callbacks
  onFileSelected: (filePath) {
    // Handle file selection
  },
  onFileDoubleClicked: (filePath) {
    // Handle file double-click
  },
  onFolderExpansionChanged: (folderPath, isExpanded) {
    // Handle folder expand/collapse
  },
  
  // Visual Customization
  icons: FolderSidebarIcons(
    folderClosed: Icons.folder,
    folderOpen: Icons.folder_open,
    file: Icons.description,
  ),
  colors: FolderSidebarColors(
    folderColor: Colors.amber,
    fileColor: Colors.blue,
  ),
)
```

## Architecture

The package is designed with a clean architecture using dependency injection:

```
┌─────────────────────┐
│   FolderSidebar     │  ← Main Widget
│     Widget          │
└─────────────────────┘
           │
┌─────────────────────┐
│ FolderSidebarConfig │  ← Configuration
└─────────────────────┘
           │
    ┌──────┴──────┐
┌───▼───┐    ┌───▼────┐
│Services│    │Widgets │
└───────┘    └────────┘
    │            │
┌───▼───┐    ┌───▼────┐
│File   │    │Tree    │
│Folder │    │Context │
│Perms  │    │Menus   │
│State  │    └────────┘
└───────┘
```

### Core Components

1. **Services Layer**: Abstract interfaces for file operations, folder indexing, permissions, and state management
2. **Widgets Layer**: UI components including tree controller, context menus, and the main sidebar
3. **Models Layer**: Data classes for tree items, folder metadata, and file operations
4. **Configuration Layer**: Centralized configuration with extensive customization options

## Service Interfaces

### FileServiceInterface

Handles basic file and directory operations:

```dart
abstract class FileServiceInterface {
  Future<String> readFile(String path);
  Future<void> writeFile(String path, String content);
  Future<FileOperationResult> createFile(String path);
  Future<FileOperationResult> createDirectory(String path);
  Future<FileOperationResult> delete(String path);
  Future<FileOperationResult> rename(String oldPath, String newPath);
  Future<FileOperationResult> revealInFileManager(String path);
  // ... and more
}
```

### FolderServiceInterface

Manages folder indexing and metadata:

```dart
abstract class FolderServiceInterface {
  Future<FolderMetadata> getFolderMetadata(String folderPath);
  Future<void> setActiveRoot(String rootPath);
  Stream<FolderScanProgress> get progressStream;
  Stream<FolderChangeEvent> get changeStream;
  // ... and more
}
```

### PermissionsServiceInterface

Handles file system permissions:

```dart
abstract class PermissionsServiceInterface {
  Future<bool> canAccessDirectory(String directoryPath);
  Future<bool> requestAccessToDirectory(String directoryPath);
  Future<List<Directory>> pickDirectories();
  Future<List<File>> pickFiles();
  // ... and more
}
```

### StateManagerInterface

Manages application state:

```dart
abstract class StateManagerInterface {
  AppStateData get currentState;
  Stream<AppStateData> get stateStream;
  Future<void> updateCurrentFile(String? filePath, String? content);
  Future<void> updateFolderState(String folderPath, FolderStateData state);
  // ... and more
}
```

## Default Implementations

The package provides default implementations that work out of the box:

- **DefaultFileService**: Uses `dart:io` for file operations
- **DefaultPermissionsService**: Basic cross-platform permission handling

You'll need to provide your own implementations for:
- **FolderServiceInterface**: Depends on your indexing/caching strategy
- **StateManagerInterface**: Depends on your state management choice

## Data Models

### TreeItem Hierarchy

```dart
abstract class TreeItem {
  final String name;
  final String path;
  int depth;
}

class FolderTreeItem extends TreeItem {
  bool isExpanded;
  bool isLoaded;
  List<TreeItem> children;
  // ...
}

class FileTreeItem extends TreeItem {
  final DateTime? lastModified;
  final int? sizeBytes;
  // ...
}
```

### File Operations

```dart
enum FileOperationType {
  create, read, update, delete, rename, copy, move, reveal
}

class FileOperationResult {
  final bool success;
  final String? message;
  final Exception? error;
  // ...
}
```

## Performance Considerations

The package is optimized for performance with large directory structures:

1. **Lazy Loading**: Folder contents are loaded only when expanded
2. **Virtualization**: Only visible items are rendered (ListView.builder)
3. **Caching**: Intelligent caching of folder metadata and tree state
4. **Efficient Updates**: Minimal rebuilds using version tracking

## Platform Support

- ✅ **macOS**: Full support including security bookmarks
- ✅ **Windows**: Full support with native file dialogs
- ✅ **Linux**: Full support with file manager integration
- ✅ **iOS**: Mobile-optimized with permission handling
- ✅ **Android**: Mobile-optimized with storage permissions
- ✅ **Web**: Basic support (limited file system access)

## Examples

See the `/example` folder for complete examples showing:

- Basic usage with default services
- Custom service implementations
- Advanced theming and customization
- Integration with different state management solutions
- Platform-specific optimizations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This package is part of the MDTool project and follows the same license terms.

## Changelog

### 1.0.0
- Initial release with core functionality
- Tree-based folder navigation
- Lazy loading and virtualization
- Context menus and file operations
- Cross-platform permission handling
- Extensive configuration options