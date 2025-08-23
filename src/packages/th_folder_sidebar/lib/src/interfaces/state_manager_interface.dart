import 'dart:async';
import '../models/folder_metadata.dart';

/// Abstract interface for state management
/// This allows different implementations (Riverpod, Provider, BLoC, etc.)
abstract class StateManagerInterface {
  /// Get the current app state
  AppStateData get currentState;
  
  /// Stream of app state changes
  Stream<AppStateData> get stateStream;
  
  /// Update the current file being viewed
  Future<void> updateCurrentFile(String? filePath, String? content);
  
  /// Update the current folder root
  Future<void> updateCurrentFolderRoot(String? folderPath);
  
  /// Update folder sidebar visibility
  Future<void> updateFolderSidebarVisibility(bool isVisible);
  
  /// Add a recent folder to the list
  Future<void> addRecentFolder(String folderPath);
  
  /// Set dropped folder for processing
  Future<void> setDroppedFolder(String? folderPath);
  
  /// Clear dropped folder state
  Future<void> clearDroppedFolder();
  
  /// Request folder picker to be shown
  Future<void> requestFolderPicker();
  
  /// Get folder state for a specific path
  Future<FolderStateData> getFolderState(String folderPath);
  
  /// Update folder state
  Future<void> updateFolderState(String folderPath, FolderStateData state);
  
  /// Get user preferences
  Future<PreferencesData> getPreferences();
  
  /// Update user preferences
  Future<void> updatePreferences(PreferencesData preferences);
  
  /// Dispose any resources
  Future<void> dispose();
}

/// Application state data
class AppStateData {
  final String? currentFile;
  final String? content;
  final bool isDirty;
  final String? currentFolderRoot;
  final bool isFolderSidebarVisible;
  final List<String> recentFolders;
  final String? droppedFolder;
  final int? folderPickerRequestId;
  final DateTime lastUpdated;
  
  AppStateData({
    this.currentFile,
    this.content,
    this.isDirty = false,
    this.currentFolderRoot,
    this.isFolderSidebarVisible = false,
    this.recentFolders = const [],
    this.droppedFolder,
    this.folderPickerRequestId,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  
  /// Create a copy with updated values
  AppStateData copyWith({
    String? currentFile,
    String? content,
    bool? isDirty,
    String? currentFolderRoot,
    bool? isFolderSidebarVisible,
    List<String>? recentFolders,
    String? droppedFolder,
    int? folderPickerRequestId,
    DateTime? lastUpdated,
  }) {
    return AppStateData(
      currentFile: currentFile ?? this.currentFile,
      content: content ?? this.content,
      isDirty: isDirty ?? this.isDirty,
      currentFolderRoot: currentFolderRoot ?? this.currentFolderRoot,
      isFolderSidebarVisible: isFolderSidebarVisible ?? this.isFolderSidebarVisible,
      recentFolders: recentFolders ?? this.recentFolders,
      droppedFolder: droppedFolder ?? this.droppedFolder,
      folderPickerRequestId: folderPickerRequestId ?? this.folderPickerRequestId,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
  
  /// Get the current file name without path
  String? get currentFileName => currentFile?.split('/').last;
  
  /// Get the current file directory
  String? get currentFileDirectory => currentFile?.substring(0, currentFile!.lastIndexOf('/'));
  
  /// Check if a file is currently open
  bool get hasOpenFile => currentFile != null;
  
  /// Check if there are unsaved changes
  bool get hasUnsavedChanges => isDirty;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppStateData &&
           other.currentFile == currentFile &&
           other.content == content &&
           other.isDirty == isDirty &&
           other.currentFolderRoot == currentFolderRoot &&
           other.isFolderSidebarVisible == isFolderSidebarVisible;
  }
  
  @override
  int get hashCode => Object.hash(
    currentFile,
    content,
    isDirty,
    currentFolderRoot,
    isFolderSidebarVisible,
  );
  
  @override
  String toString() {
    return 'AppStateData(file: $currentFileName, isDirty: $isDirty, sidebarVisible: $isFolderSidebarVisible)';
  }
}

/// Folder-specific state data
class FolderStateData {
  final FolderMetadata? metadata;
  final bool isScanning;
  final FolderScanProgress? scanProgress;
  final DateTime? lastScanned;
  final String? error;
  
  const FolderStateData({
    this.metadata,
    this.isScanning = false,
    this.scanProgress,
    this.lastScanned,
    this.error,
  });
  
  /// Create an empty folder state
  const FolderStateData.empty() : this();
  
  /// Create a loading folder state
  const FolderStateData.loading({
    FolderScanProgress? scanProgress,
  }) : this(
    isScanning: true,
    scanProgress: scanProgress,
  );
  
  /// Create an error folder state
  const FolderStateData.error(String error) : this(error: error);
  
  /// Create a folder state with metadata
  FolderStateData.withMetadata(FolderMetadata metadata) : this(
    metadata: metadata,
    isScanning: false,
    lastScanned: DateTime.now(),
  );
  
  /// Create a copy with updated values
  FolderStateData copyWith({
    FolderMetadata? metadata,
    bool? isScanning,
    FolderScanProgress? scanProgress,
    DateTime? lastScanned,
    String? error,
  }) {
    return FolderStateData(
      metadata: metadata ?? this.metadata,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      lastScanned: lastScanned ?? this.lastScanned,
      error: error ?? this.error,
    );
  }
  
  /// Check if this folder has data
  bool get hasData => metadata != null;
  
  /// Check if this folder has an error
  bool get hasError => error != null;
  
  /// Check if the scan is complete
  bool get isComplete => !isScanning && hasData && !hasError;
  
  /// Get the folder path if available
  String? get folderPath => metadata?.path;
  
  /// Get the folder name if available
  String? get folderName => metadata?.name;
  
  @override
  String toString() {
    return 'FolderStateData(path: $folderPath, scanning: $isScanning, hasData: $hasData, hasError: $hasError)';
  }
}

/// User preferences data
class PreferencesData {
  final bool autoNavigateToFileFolder;
  final bool filterDirectories;
  final bool showHiddenFiles;
  final bool enableFileWatching;
  final int maxRecentFolders;
  final Duration scanTimeout;
  final bool showFileExtensions;
  final bool showFileSize;
  final bool showLastModified;
  final SortOrder fileSortOrder;
  final bool groupFoldersFirst;
  
  const PreferencesData({
    this.autoNavigateToFileFolder = false,
    this.filterDirectories = false,
    this.showHiddenFiles = false,
    this.enableFileWatching = true,
    this.maxRecentFolders = 10,
    this.scanTimeout = const Duration(minutes: 5),
    this.showFileExtensions = true,
    this.showFileSize = false,
    this.showLastModified = false,
    this.fileSortOrder = SortOrder.name,
    this.groupFoldersFirst = true,
  });
  
  /// Create a copy with updated values
  PreferencesData copyWith({
    bool? autoNavigateToFileFolder,
    bool? filterDirectories,
    bool? showHiddenFiles,
    bool? enableFileWatching,
    int? maxRecentFolders,
    Duration? scanTimeout,
    bool? showFileExtensions,
    bool? showFileSize,
    bool? showLastModified,
    SortOrder? fileSortOrder,
    bool? groupFoldersFirst,
  }) {
    return PreferencesData(
      autoNavigateToFileFolder: autoNavigateToFileFolder ?? this.autoNavigateToFileFolder,
      filterDirectories: filterDirectories ?? this.filterDirectories,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      enableFileWatching: enableFileWatching ?? this.enableFileWatching,
      maxRecentFolders: maxRecentFolders ?? this.maxRecentFolders,
      scanTimeout: scanTimeout ?? this.scanTimeout,
      showFileExtensions: showFileExtensions ?? this.showFileExtensions,
      showFileSize: showFileSize ?? this.showFileSize,
      showLastModified: showLastModified ?? this.showLastModified,
      fileSortOrder: fileSortOrder ?? this.fileSortOrder,
      groupFoldersFirst: groupFoldersFirst ?? this.groupFoldersFirst,
    );
  }
  
  @override
  String toString() {
    return 'PreferencesData(autoNavigate: $autoNavigateToFileFolder, filter: $filterDirectories, sortOrder: $fileSortOrder)';
  }
}

/// Sort order for files and folders
enum SortOrder {
  name,
  nameDesc,
  size,
  sizeDesc,
  modified,
  modifiedDesc,
  type,
  typeDesc,
}

extension SortOrderExtension on SortOrder {
  /// Get a human-readable name for the sort order
  String get displayName {
    switch (this) {
      case SortOrder.name:
        return 'Name (A-Z)';
      case SortOrder.nameDesc:
        return 'Name (Z-A)';
      case SortOrder.size:
        return 'Size (Small to Large)';
      case SortOrder.sizeDesc:
        return 'Size (Large to Small)';
      case SortOrder.modified:
        return 'Modified (Oldest First)';
      case SortOrder.modifiedDesc:
        return 'Modified (Newest First)';
      case SortOrder.type:
        return 'Type (A-Z)';
      case SortOrder.typeDesc:
        return 'Type (Z-A)';
    }
  }
  
  /// Check if this is a descending sort order
  bool get isDescending {
    switch (this) {
      case SortOrder.nameDesc:
      case SortOrder.sizeDesc:
      case SortOrder.modifiedDesc:
      case SortOrder.typeDesc:
        return true;
      default:
        return false;
    }
  }
  
  /// Get the ascending version of this sort order
  SortOrder get ascending {
    switch (this) {
      case SortOrder.nameDesc:
        return SortOrder.name;
      case SortOrder.sizeDesc:
        return SortOrder.size;
      case SortOrder.modifiedDesc:
        return SortOrder.modified;
      case SortOrder.typeDesc:
        return SortOrder.type;
      default:
        return this;
    }
  }
  
  /// Get the descending version of this sort order
  SortOrder get descending {
    switch (this) {
      case SortOrder.name:
        return SortOrder.nameDesc;
      case SortOrder.size:
        return SortOrder.sizeDesc;
      case SortOrder.modified:
        return SortOrder.modifiedDesc;
      case SortOrder.type:
        return SortOrder.typeDesc;
      default:
        return this;
    }
  }
}