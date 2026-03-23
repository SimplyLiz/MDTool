import 'dart:async';
import '../models/folder_metadata.dart';

/// Abstract interface for folder indexing and metadata operations
/// This allows different implementations for scanning and caching folder contents
abstract class FolderServiceInterface {
  /// Get metadata for a folder, optionally forcing a refresh
  Future<FolderMetadata> getFolderMetadata(
    String folderPath, {
    bool shouldFilter = false,
    bool forceRefresh = false,
    bool includeHidden = false,
  });
  
  /// Get cached metadata for a folder without triggering a scan
  Future<FolderMetadata?> getCachedMetadata(String folderPath);
  
  /// Perform a quick scan of a folder to get basic file counts
  Future<FolderMetadata> quickScan(
    String folderPath, {
    bool shouldFilter = false,
  });
  
  /// Set the active root folder for watching and caching
  Future<void> setActiveRoot(String rootPath);
  
  /// Get the current active root folder
  String? get activeRoot;
  
  /// Start watching a folder for changes
  Future<void> startWatching(String folderPath);
  
  /// Stop watching a folder for changes
  Future<void> stopWatching(String folderPath);
  
  /// Stop watching all folders
  Future<void> stopWatchingAll();
  
  /// Clear cached metadata for a specific folder
  Future<void> clearCache(String folderPath);
  
  /// Clear all cached metadata
  Future<void> clearAllCaches();
  
  /// Get the size of the metadata cache
  int get cacheSize;
  
  /// Check if a folder is currently being scanned
  bool isScanning(String folderPath);
  
  /// Cancel an ongoing scan
  Future<void> cancelScan(String folderPath);
  
  /// Get a stream of scan progress updates
  Stream<FolderScanProgress> get progressStream;
  
  /// Get a stream of folder change events
  Stream<FolderChangeEvent> get changeStream;
  
  /// Refresh metadata for all cached folders
  Future<void> refreshAllCaches();
  
  /// Get statistics about the folder service
  FolderServiceStats get stats;
  
  /// Dispose any resources used by the service
  Future<void> dispose();
}

/// Event representing a change in folder contents
class FolderChangeEvent {
  final String folderPath;
  final FolderChangeType type;
  final String? affectedPath;
  final DateTime timestamp;
  
  FolderChangeEvent({
    required this.folderPath,
    required this.type,
    this.affectedPath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Get the name of the affected item
  String? get affectedName => affectedPath?.split('/').last;
  
  /// Check if this change affects a markdown file
  bool get affectsMarkdownFile {
    if (affectedPath == null) return false;
    final ext = affectedPath!.toLowerCase();
    return ext.endsWith('.md') || 
           ext.endsWith('.markdown') || 
           ext.endsWith('.mdown') || 
           ext.endsWith('.mkd') || 
           ext.endsWith('.mkdn');
  }
  
  @override
  String toString() {
    return 'FolderChangeEvent($type in $folderPath${affectedPath != null ? ', affected: $affectedName' : ''})';
  }
}

/// Types of folder changes
enum FolderChangeType {
  /// A file or folder was added
  added,
  /// A file or folder was removed
  removed,
  /// A file or folder was modified
  modified,
  /// A file or folder was moved/renamed
  moved,
  /// The folder itself was deleted
  deleted,
  /// The folder structure changed significantly
  restructured,
}

extension FolderChangeTypeExtension on FolderChangeType {
  /// Get a human-readable name for the change type
  String get displayName {
    switch (this) {
      case FolderChangeType.added:
        return 'Added';
      case FolderChangeType.removed:
        return 'Removed';
      case FolderChangeType.modified:
        return 'Modified';
      case FolderChangeType.moved:
        return 'Moved';
      case FolderChangeType.deleted:
        return 'Deleted';
      case FolderChangeType.restructured:
        return 'Restructured';
    }
  }
  
  /// Check if this change type affects the folder structure
  bool get affectsStructure => this == FolderChangeType.added || 
                              this == FolderChangeType.removed || 
                              this == FolderChangeType.moved ||
                              this == FolderChangeType.deleted ||
                              this == FolderChangeType.restructured;
}

/// Statistics about the folder service
class FolderServiceStats {
  final int totalFoldersWatched;
  final int totalFoldersInCache;
  final int totalScansPerformed;
  final int totalFilesIndexed;
  final int totalMarkdownFilesIndexed;
  final DateTime lastScanTime;
  final Duration totalScanTime;
  final int activeScanCount;
  
  FolderServiceStats({
    this.totalFoldersWatched = 0,
    this.totalFoldersInCache = 0,
    this.totalScansPerformed = 0,
    this.totalFilesIndexed = 0,
    this.totalMarkdownFilesIndexed = 0,
    DateTime? lastScanTime,
    this.totalScanTime = Duration.zero,
    this.activeScanCount = 0,
  }) : lastScanTime = lastScanTime ?? DateTime.fromMicrosecondsSinceEpoch(0);
  
  /// Get the average scan time if scans have been performed
  Duration get averageScanTime {
    if (totalScansPerformed == 0) return Duration.zero;
    return Duration(microseconds: totalScanTime.inMicroseconds ~/ totalScansPerformed);
  }
  
  /// Get the ratio of markdown files to total files
  double get markdownFileRatio {
    if (totalFilesIndexed == 0) return 0.0;
    return totalMarkdownFilesIndexed / totalFilesIndexed;
  }
  
  /// Check if any scans are currently active
  bool get hasActiveScans => activeScanCount > 0;
  
  /// Get a human-readable string representation
  String get summary {
    return 'Watching: $totalFoldersWatched folders, '
           'Cached: $totalFoldersInCache, '
           'Scans: $totalScansPerformed, '
           'Files: $totalFilesIndexed ($totalMarkdownFilesIndexed markdown)';
  }
  
  @override
  String toString() {
    return 'FolderServiceStats($summary)';
  }
}

/// Configuration for folder scanning behavior
class FolderScanConfig {
  /// Whether to include hidden files and folders
  final bool includeHidden;
  
  /// Whether to follow symbolic links
  final bool followSymlinks;
  
  /// Maximum depth to scan (null for unlimited)
  final int? maxDepth;
  
  /// File extensions to include (null for all files)
  final Set<String>? includeExtensions;
  
  /// File extensions to exclude
  final Set<String> excludeExtensions;
  
  /// Folder names to exclude
  final Set<String> excludeFolders;
  
  /// Whether to filter common development/system directories
  final bool filterSystemDirectories;
  
  /// Maximum number of files to process per folder
  final int? maxFilesPerFolder;
  
  /// Timeout for individual folder scans
  final Duration scanTimeout;
  
  const FolderScanConfig({
    this.includeHidden = false,
    this.followSymlinks = false,
    this.maxDepth,
    this.includeExtensions,
    this.excludeExtensions = const {'.DS_Store', '.git', '.svn'},
    this.excludeFolders = const {
      '.git', '.svn', '.hg', '.bzr',
      'node_modules', '.npm', '.yarn',
      '.vscode', '.idea', '.vs',
      'build', 'dist', 'out', 'target',
      '.dart_tool', '.packages',
    },
    this.filterSystemDirectories = true,
    this.maxFilesPerFolder,
    this.scanTimeout = const Duration(minutes: 5),
  });
  
  /// Create a configuration optimized for markdown files
  factory FolderScanConfig.markdownOptimized({
    bool includeHidden = false,
    int? maxDepth,
  }) {
    return FolderScanConfig(
      includeHidden: includeHidden,
      maxDepth: maxDepth,
      includeExtensions: {'.md', '.markdown', '.mdown', '.mkd', '.mkdn'},
      filterSystemDirectories: true,
    );
  }
  
  /// Check if a file should be included based on its path
  bool shouldIncludeFile(String filePath) {
    final fileName = filePath.split('/').last;
    
    // Check hidden files
    if (!includeHidden && fileName.startsWith('.')) {
      return false;
    }
    
    // Check excluded extensions
    for (final ext in excludeExtensions) {
      if (fileName.toLowerCase().endsWith(ext.toLowerCase())) {
        return false;
      }
    }
    
    // Check included extensions (if specified)
    if (includeExtensions != null) {
      bool matchesIncluded = false;
      for (final ext in includeExtensions!) {
        if (fileName.toLowerCase().endsWith(ext.toLowerCase())) {
          matchesIncluded = true;
          break;
        }
      }
      if (!matchesIncluded) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Check if a folder should be included based on its path
  bool shouldIncludeFolder(String folderPath) {
    final folderName = folderPath.split('/').last;
    
    // Check hidden folders
    if (!includeHidden && folderName.startsWith('.')) {
      return false;
    }
    
    // Check excluded folders
    if (excludeFolders.contains(folderName)) {
      return false;
    }
    
    return true;
  }
  
  @override
  String toString() {
    return 'FolderScanConfig(includeHidden: $includeHidden, maxDepth: $maxDepth, filterSystem: $filterSystemDirectories)';
  }
}