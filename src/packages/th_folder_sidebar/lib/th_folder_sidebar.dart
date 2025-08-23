/// A reusable Flutter package providing a hierarchical folder sidebar
/// with file navigation, lazy loading, and customizable file operations.
///
/// This package provides a comprehensive solution for displaying and
/// interacting with folder hierarchies in Flutter applications.
///
/// ## Features
/// 
/// - **Hierarchical File Navigation**: Tree-based folder and file display
/// - **Lazy Loading**: Efficient loading of folder contents on-demand  
/// - **Virtualization**: High performance with large directory structures
/// - **Context Menus**: Right-click operations for files and folders
/// - **Drag & Drop**: Support for drag and drop operations
/// - **Cross-Platform**: Works on macOS, Windows, Linux, iOS, and Android
/// - **Customizable**: Extensive theming and configuration options
/// - **Abstracted Services**: Pluggable implementations for file operations
/// 
/// ## Basic Usage
/// 
/// ```dart
/// import 'package:th_folder_sidebar/th_folder_sidebar.dart';
/// 
/// // Create service implementations
/// final fileService = DefaultFileService();
/// final permissionsService = DefaultPermissionsService();
/// final folderService = MyFolderService(); // Your implementation
/// final stateManager = MyStateManager(); // Your implementation
/// 
/// // Configure the sidebar
/// final config = FolderSidebarConfig(
///   fileService: fileService,
///   folderService: folderService,
///   permissionsService: permissionsService,
///   stateManager: stateManager,
///   width: 300.0,
///   showOnlyMarkdownFiles: true,
/// );
/// 
/// // Use the widget
/// FolderSidebar(config: config)
/// ```
library th_folder_sidebar;

// Core Widget (will be implemented)
// export 'src/widgets/folder_sidebar.dart';

// Configuration
export 'src/config/folder_sidebar_config.dart';

// Tree Management
export 'src/widgets/tree_controller.dart';

// Context Menus
export 'src/widgets/context_menus/folder_context_menu.dart';
export 'src/widgets/context_menus/file_context_menu.dart';

// Data Models
export 'src/models/tree_item.dart';
export 'src/models/folder_metadata.dart';
export 'src/models/file_operations.dart';

// Interfaces (for custom implementations)
export 'src/interfaces/file_service_interface.dart';
export 'src/interfaces/folder_service_interface.dart';
export 'src/interfaces/permissions_service_interface.dart';
export 'src/interfaces/state_manager_interface.dart';

// Default Service Implementations
export 'src/services/default_file_service.dart';
export 'src/services/default_permissions_service.dart';