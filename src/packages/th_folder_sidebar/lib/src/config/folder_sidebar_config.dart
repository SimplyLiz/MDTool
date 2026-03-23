import 'package:flutter/material.dart';
import '../interfaces/file_service_interface.dart';
import '../interfaces/folder_service_interface.dart';
import '../interfaces/permissions_service_interface.dart';
import '../interfaces/state_manager_interface.dart';
import '../models/file_operations.dart';
import '../models/tree_item.dart';

/// Configuration class for the FolderSidebar widget
/// This allows customization of behavior, styling, and service implementations
class FolderSidebarConfig {
  // Core Services (required)
  final FileServiceInterface fileService;
  final FolderServiceInterface folderService;
  final PermissionsServiceInterface permissionsService;
  final StateManagerInterface stateManager;
  
  // Appearance & Layout
  final double width;
  final bool isVisible;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets padding;
  final double itemHeight;
  final double indentationWidth;
  
  // Header Configuration
  final String headerTitle;
  final Widget? headerIcon;
  final List<HeaderAction> headerActions;
  final bool showHeader;
  final TextStyle? headerTextStyle;
  
  // Tree Behavior
  final bool enableLazyLoading;
  final bool enableVirtualization;
  final bool autoExpandRoot;
  final int maxCacheSize;
  final Duration cacheExpiration;
  
  // File Operations
  final bool enableFileOperations;
  final bool enableContextMenus;
  final bool enableDragAndDrop;
  final bool enableKeyboardNavigation;
  final Set<FileOperationType> allowedOperations;
  
  // Visual Customization  
  final FolderSidebarIcons icons;
  final FolderSidebarColors colors;
  final FolderSidebarTextStyles textStyles;
  final AnimationConfig animationConfig;
  
  // Interaction Callbacks
  final void Function(String filePath)? onFileSelected;
  final void Function(String filePath)? onFileDoubleClicked;
  final void Function(String folderPath)? onFolderSelected;
  final void Function(String folderPath, bool isExpanded)? onFolderExpansionChanged;
  final void Function(FileOperationEvent event)? onFileOperation;
  final void Function(String message, {bool isError})? onMessage;
  
  // Context Menu Customization
  final List<ContextMenuItem> Function(FolderTreeItem folder)? customFolderMenuItems;
  final List<ContextMenuItem> Function(FileTreeItem file)? customFileMenuItems;
  final bool showDefaultMenuItems;
  
  // Filter & Search
  final bool Function(String path)? fileFilter;
  final bool Function(String path)? folderFilter;
  final bool showOnlyMarkdownFiles;
  final bool showHiddenFiles;
  final Set<String> excludedFolders;
  final Set<String> excludedFileExtensions;
  
  const FolderSidebarConfig({
    // Required services
    required this.fileService,
    required this.folderService,
    required this.permissionsService,
    required this.stateManager,
    
    // Appearance & Layout
    this.width = 280.0,
    this.isVisible = true,
    this.backgroundColor,
    this.borderColor,
    this.padding = const EdgeInsets.all(0),
    this.itemHeight = 40.0,
    this.indentationWidth = 16.0,
    
    // Header Configuration
    this.headerTitle = 'Markdown Files',
    this.headerIcon,
    this.headerActions = const [],
    this.showHeader = true,
    this.headerTextStyle,
    
    // Tree Behavior
    this.enableLazyLoading = true,
    this.enableVirtualization = true,
    this.autoExpandRoot = false,
    this.maxCacheSize = 100,
    this.cacheExpiration = const Duration(minutes: 30),
    
    // File Operations
    this.enableFileOperations = true,
    this.enableContextMenus = true,
    this.enableDragAndDrop = true,
    this.enableKeyboardNavigation = true,
    this.allowedOperations = const {
      FileOperationType.create,
      FileOperationType.read,
      FileOperationType.rename,
      FileOperationType.delete,
      FileOperationType.reveal,
    },
    
    // Visual Customization
    this.icons = const FolderSidebarIcons(),
    this.colors = const FolderSidebarColors(),
    this.textStyles = const FolderSidebarTextStyles(),
    this.animationConfig = const AnimationConfig(),
    
    // Interaction Callbacks
    this.onFileSelected,
    this.onFileDoubleClicked,
    this.onFolderSelected,
    this.onFolderExpansionChanged,
    this.onFileOperation,
    this.onMessage,
    
    // Context Menu Customization
    this.customFolderMenuItems,
    this.customFileMenuItems,
    this.showDefaultMenuItems = true,
    
    // Filter & Search
    this.fileFilter,
    this.folderFilter,
    this.showOnlyMarkdownFiles = true,
    this.showHiddenFiles = false,
    this.excludedFolders = const {
      '.git', '.svn', '.hg', '.bzr',
      'node_modules', '.npm', '.yarn',
      '.vscode', '.idea', '.vs',
      'build', 'dist', 'out', 'target',
      '.dart_tool', '.packages',
    },
    this.excludedFileExtensions = const {'.DS_Store', '.gitkeep'},
  });
  
  /// Create a minimal configuration with required services
  factory FolderSidebarConfig.minimal({
    required FileServiceInterface fileService,
    required FolderServiceInterface folderService,
    required PermissionsServiceInterface permissionsService,
    required StateManagerInterface stateManager,
  }) {
    return FolderSidebarConfig(
      fileService: fileService,
      folderService: folderService,
      permissionsService: permissionsService,
      stateManager: stateManager,
    );
  }
  
  /// Create configuration optimized for markdown files
  factory FolderSidebarConfig.markdownOptimized({
    required FileServiceInterface fileService,
    required FolderServiceInterface folderService,
    required PermissionsServiceInterface permissionsService,
    required StateManagerInterface stateManager,
    double width = 280.0,
  }) {
    return FolderSidebarConfig(
      fileService: fileService,
      folderService: folderService,
      permissionsService: permissionsService,
      stateManager: stateManager,
      width: width,
      showOnlyMarkdownFiles: true,
      headerTitle: 'Markdown Files',
      headerIcon: const Icon(Icons.description, color: Colors.blue),
    );
  }
  
  /// Create a copy with updated values
  FolderSidebarConfig copyWith({
    FileServiceInterface? fileService,
    FolderServiceInterface? folderService,
    PermissionsServiceInterface? permissionsService,
    StateManagerInterface? stateManager,
    double? width,
    bool? isVisible,
    Color? backgroundColor,
    Color? borderColor,
    EdgeInsets? padding,
    double? itemHeight,
    double? indentationWidth,
    String? headerTitle,
    Widget? headerIcon,
    List<HeaderAction>? headerActions,
    bool? showHeader,
    TextStyle? headerTextStyle,
    bool? enableLazyLoading,
    bool? enableVirtualization,
    bool? autoExpandRoot,
    int? maxCacheSize,
    Duration? cacheExpiration,
    bool? enableFileOperations,
    bool? enableContextMenus,
    bool? enableDragAndDrop,
    bool? enableKeyboardNavigation,
    Set<FileOperationType>? allowedOperations,
    FolderSidebarIcons? icons,
    FolderSidebarColors? colors,
    FolderSidebarTextStyles? textStyles,
    AnimationConfig? animationConfig,
    void Function(String filePath)? onFileSelected,
    void Function(String filePath)? onFileDoubleClicked,
    void Function(String folderPath)? onFolderSelected,
    void Function(String folderPath, bool isExpanded)? onFolderExpansionChanged,
    void Function(FileOperationEvent event)? onFileOperation,
    void Function(String message, {bool isError})? onMessage,
    List<ContextMenuItem> Function(FolderTreeItem folder)? customFolderMenuItems,
    List<ContextMenuItem> Function(FileTreeItem file)? customFileMenuItems,
    bool? showDefaultMenuItems,
    bool Function(String path)? fileFilter,
    bool Function(String path)? folderFilter,
    bool? showOnlyMarkdownFiles,
    bool? showHiddenFiles,
    Set<String>? excludedFolders,
    Set<String>? excludedFileExtensions,
  }) {
    return FolderSidebarConfig(
      fileService: fileService ?? this.fileService,
      folderService: folderService ?? this.folderService,
      permissionsService: permissionsService ?? this.permissionsService,
      stateManager: stateManager ?? this.stateManager,
      width: width ?? this.width,
      isVisible: isVisible ?? this.isVisible,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      padding: padding ?? this.padding,
      itemHeight: itemHeight ?? this.itemHeight,
      indentationWidth: indentationWidth ?? this.indentationWidth,
      headerTitle: headerTitle ?? this.headerTitle,
      headerIcon: headerIcon ?? this.headerIcon,
      headerActions: headerActions ?? this.headerActions,
      showHeader: showHeader ?? this.showHeader,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      enableLazyLoading: enableLazyLoading ?? this.enableLazyLoading,
      enableVirtualization: enableVirtualization ?? this.enableVirtualization,
      autoExpandRoot: autoExpandRoot ?? this.autoExpandRoot,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      cacheExpiration: cacheExpiration ?? this.cacheExpiration,
      enableFileOperations: enableFileOperations ?? this.enableFileOperations,
      enableContextMenus: enableContextMenus ?? this.enableContextMenus,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      enableKeyboardNavigation: enableKeyboardNavigation ?? this.enableKeyboardNavigation,
      allowedOperations: allowedOperations ?? this.allowedOperations,
      icons: icons ?? this.icons,
      colors: colors ?? this.colors,
      textStyles: textStyles ?? this.textStyles,
      animationConfig: animationConfig ?? this.animationConfig,
      onFileSelected: onFileSelected ?? this.onFileSelected,
      onFileDoubleClicked: onFileDoubleClicked ?? this.onFileDoubleClicked,
      onFolderSelected: onFolderSelected ?? this.onFolderSelected,
      onFolderExpansionChanged: onFolderExpansionChanged ?? this.onFolderExpansionChanged,
      onFileOperation: onFileOperation ?? this.onFileOperation,
      onMessage: onMessage ?? this.onMessage,
      customFolderMenuItems: customFolderMenuItems ?? this.customFolderMenuItems,
      customFileMenuItems: customFileMenuItems ?? this.customFileMenuItems,
      showDefaultMenuItems: showDefaultMenuItems ?? this.showDefaultMenuItems,
      fileFilter: fileFilter ?? this.fileFilter,
      folderFilter: folderFilter ?? this.folderFilter,
      showOnlyMarkdownFiles: showOnlyMarkdownFiles ?? this.showOnlyMarkdownFiles,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      excludedFolders: excludedFolders ?? this.excludedFolders,
      excludedFileExtensions: excludedFileExtensions ?? this.excludedFileExtensions,
    );
  }
}

/// Configuration for icons used in the folder sidebar
class FolderSidebarIcons {
  final IconData folderClosed;
  final IconData folderOpen;
  final IconData file;
  final IconData markdownFile;
  final IconData expandMore;
  final IconData expandLess;
  final IconData refresh;
  final IconData addFolder;
  final IconData addFile;
  final IconData delete;
  final IconData rename;
  final IconData reveal;
  final IconData loading;
  
  const FolderSidebarIcons({
    this.folderClosed = Icons.folder,
    this.folderOpen = Icons.folder_open,
    this.file = Icons.description,
    this.markdownFile = Icons.description,
    this.expandMore = Icons.keyboard_arrow_right,
    this.expandLess = Icons.keyboard_arrow_down,
    this.refresh = Icons.refresh,
    this.addFolder = Icons.create_new_folder,
    this.addFile = Icons.note_add,
    this.delete = Icons.delete_outline,
    this.rename = Icons.edit,
    this.reveal = Icons.open_in_new,
    this.loading = Icons.hourglass_empty,
  });
}

/// Configuration for colors used in the folder sidebar
class FolderSidebarColors {
  final Color? folderColor;
  final Color? fileColor;
  final Color? selectedBackgroundColor;
  final Color? hoverBackgroundColor;
  final Color? borderColor;
  final Color? loadingColor;
  final Color? errorColor;
  final Color? scanningIndicatorColor;
  
  const FolderSidebarColors({
    this.folderColor,
    this.fileColor,
    this.selectedBackgroundColor,
    this.hoverBackgroundColor,
    this.borderColor,
    this.loadingColor,
    this.errorColor,
    this.scanningIndicatorColor,
  });
}

/// Configuration for text styles used in the folder sidebar
class FolderSidebarTextStyles {
  final TextStyle? folderNameStyle;
  final TextStyle? fileNameStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? headerStyle;
  final TextStyle? loadingTextStyle;
  final TextStyle? errorTextStyle;
  
  const FolderSidebarTextStyles({
    this.folderNameStyle,
    this.fileNameStyle,
    this.subtitleStyle,
    this.headerStyle,
    this.loadingTextStyle,
    this.errorTextStyle,
  });
}

/// Configuration for animations in the folder sidebar
class AnimationConfig {
  final Duration expansionDuration;
  final Duration hoverDuration;
  final Duration loadingDuration;
  final Curve expansionCurve;
  final Curve hoverCurve;
  final bool enableAnimations;
  
  const AnimationConfig({
    this.expansionDuration = const Duration(milliseconds: 200),
    this.hoverDuration = const Duration(milliseconds: 100),
    this.loadingDuration = const Duration(milliseconds: 1000),
    this.expansionCurve = Curves.easeInOut,
    this.hoverCurve = Curves.easeInOut,
    this.enableAnimations = true,
  });
}

/// Configuration for header actions
class HeaderAction {
  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isEnabled;
  
  const HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isEnabled = true,
  });
  
  /// Create a refresh action
  factory HeaderAction.refresh(VoidCallback onPressed) {
    return HeaderAction(
      icon: const Icon(Icons.refresh, size: 18),
      tooltip: 'Refresh',
      onPressed: onPressed,
    );
  }
  
  /// Create an add folder action
  factory HeaderAction.addFolder(VoidCallback onPressed) {
    return HeaderAction(
      icon: const Icon(Icons.create_new_folder, size: 18),
      tooltip: 'Add Folder',
      onPressed: onPressed,
    );
  }
  
  /// Create an add file action
  factory HeaderAction.addFile(VoidCallback onPressed) {
    return HeaderAction(
      icon: const Icon(Icons.note_add, size: 18),
      tooltip: 'Add File',
      onPressed: onPressed,
    );
  }
}