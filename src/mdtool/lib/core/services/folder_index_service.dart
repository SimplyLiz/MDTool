import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import '../models/folder_metadata.dart';

/// High-performance folder indexing service with async scanning and in-memory caching
/// Provides efficient folder metadata including file counts and hierarchical structure
class FolderIndexService {
  static FolderIndexService? _instance;
  static FolderIndexService get instance => _instance ??= FolderIndexService._();
  
  FolderIndexService._();
  
  /// In-memory cache of folder metadata
  final Map<String, FolderMetadata> _cache = {};
  
  /// Progress stream for ongoing scans
  final StreamController<FolderScanProgress> _progressController = StreamController.broadcast();
  Stream<FolderScanProgress> get progressStream => _progressController.stream;
  
  /// Invalidation stream for cache changes triggered by filesystem events
  final StreamController<String> _invalidationController = StreamController.broadcast();
  Stream<String> get invalidationStream => _invalidationController.stream;
  
  /// Currently running scan operations (path -> cancellation token)
  final Map<String, CancelToken> _activeScanTokens = {};
  
  /// Supported markdown file extensions
  static const _markdownExtensions = {'.md', '.markdown', '.mdown', '.mkd', '.mkdn'};
  
  /// Directories to exclude from scanning when filtering is enabled
  static const _excludedDirectories = {
    'node_modules', '.git', '.svn', '.hg', 'build', 'dist', 'target',
    '__pycache__', '.vscode', '.idea', 'vendor', 'coverage'
  };
  
  /// Files to ignore during scanning
  static const _ignoredFiles = {'.ds_store', 'thumbs.db', 'desktop.ini'};
  
  /// Maximum scanning depth to prevent infinite recursion
  static const _maxScanDepth = 50;
  
  /// Currently active filesystem watchers (one per active root)
  final Map<String, StreamSubscription<WatchEvent>> _watchers = {};
  
  /// Currently active root directories being watched
  String? _activeRoot;
  
  /// Get cached folder metadata, or null if not cached
  Future<FolderMetadata?> getCachedMetadata(String folderPath) async {
    final canonicalPath = await _canonicalizePath(folderPath);
    return _cache[canonicalPath];
  }
  
  /// Canonicalize path by resolving symlinks and normalizing
  /// Public API for use by providers to ensure consistent cache keys
  Future<String> canonicalizePath(String path) async {
    try {
      final resolved = await File(path).resolveSymbolicLinks();
      return p.normalize(resolved);
    } catch (_) {
      return p.normalize(path);
    }
  }
  
  /// Internal wrapper for backward compatibility
  Future<String> _canonicalizePath(String path) => canonicalizePath(path);
  
  /// Check if folder is currently being scanned
  Future<bool> isScanning(String folderPath) async {
    final canonicalPath = await _canonicalizePath(folderPath);
    return _activeScanTokens.containsKey(canonicalPath);
  }
  
  /// Get or scan folder metadata with progress tracking
  /// Returns cached data immediately if available, starts background scan if needed
  Future<FolderMetadata> getFolderMetadata(
    String folderPath, {
    bool forceRefresh = false,
    bool shouldFilter = true,
    Duration cacheValidDuration = const Duration(minutes: 5),
  }) async {
    final canonicalPath = await _canonicalizePath(folderPath);
    
    // Return cached data if valid and not forced refresh
    if (!forceRefresh) {
      final cached = _cache[canonicalPath];
      if (cached != null && DateTime.now().difference(cached.lastScanned) < cacheValidDuration) {
        return cached;
      }
    }
    
    // Cancel any existing scan for this path
    await cancelScan(canonicalPath);
    
    // Start new scan
    return _scanFolder(canonicalPath, shouldFilter: shouldFilter);
  }
  
  /// Perform quick scan to get immediate file counts without full recursive scan
  Future<FolderMetadata> quickScan(String folderPath, {bool shouldFilter = true}) async {
    final canonicalPath = await _canonicalizePath(folderPath);
    final directory = Directory(canonicalPath);
    if (!await directory.exists()) {
      throw FileSystemException('Directory does not exist', canonicalPath);
    }
    
    final name = p.basename(canonicalPath);
    final scanTime = DateTime.now();
    
    try {
      int markdownCount = 0;
      int subfolderCount = 0;
      
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File) {
          if (!_shouldIgnoreFile(entity.path) && _isMarkdownFile(entity.path)) {
            markdownCount++;
          }
        } else if (entity is Directory) {
          final dirName = p.basename(entity.path);
          if (!_shouldExcludeDirectory(dirName, shouldFilter)) {
            subfolderCount++;
          }
        }
      }
      
      final metadata = FolderMetadata.quickScan(
        path: canonicalPath,
        name: name,
        markdownFileCount: markdownCount,
        subfolderCount: subfolderCount,
        lastScanned: scanTime,
      );
      
      _cache[canonicalPath] = metadata;
      // Note: Watcher setup is managed separately via setActiveRoot
      return metadata;
      
    } catch (e) {
      debugPrint('Error in quick scan for $canonicalPath: $e');
      rethrow;
    }
  }
  
  /// Full recursive scan with detailed file information using isolate for performance
  Future<FolderMetadata> _scanFolder(String folderPath, {required bool shouldFilter}) async {
    final canonicalPath = await _canonicalizePath(folderPath);
    final directory = Directory(canonicalPath);
    if (!await directory.exists()) {
      throw FileSystemException('Directory does not exist', canonicalPath);
    }
    
    final cancelToken = CancelToken();
    _activeScanTokens[canonicalPath] = cancelToken;
    
    try {
      // Start with quick scan for immediate results
      final quickResult = await quickScan(canonicalPath, shouldFilter: shouldFilter);
      
      // If cancelled during quick scan, return quick result
      if (cancelToken.isCancelled) {
        return quickResult;
      }
      
      // Emit initial progress
      _progressController.add(FolderScanProgress(
        currentPath: canonicalPath,
        foldersScanned: 0,
        totalFolders: 0, // Unknown initially - will show indeterminate
        filesFound: quickResult.markdownFileCount,
        status: FolderScanStatus.scanning,
      ));
      
      // Perform full recursive scan in isolate for large trees
      // Note: Isolate.run() cannot be cancelled mid-execution since isolates don't share memory.
      // We check cancellation before/after and discard late results if cancelled.
      final scanArgs = _IsolateScanArgs(
        rootPath: canonicalPath,
        shouldFilter: shouldFilter,
        maxDepth: _maxScanDepth,
        excludedDirs: _excludedDirectories,
        ignoredFiles: _ignoredFiles,
        markdownExts: _markdownExtensions,
      );
      
      final result = await Isolate.run(() => _isolateScanWork(scanArgs));
      
      // Check if cancelled after isolate completes and discard late results
      if (!cancelToken.isCancelled) {
        final metadata = result.metadata;
        _cache[canonicalPath] = metadata;
        
        _progressController.add(FolderScanProgress(
          currentPath: canonicalPath,
          foldersScanned: result.counters.visitedFolders,
          totalFolders: result.counters.visitedFolders,
          filesFound: result.counters.foundFiles,
          status: FolderScanStatus.completed,
        ));
        
        return metadata;
      } else {
        // Scan was cancelled - discard isolate results and return quick scan
        debugPrint('Discarding late isolate results for cancelled scan: $canonicalPath');
        return quickResult;
      }
      
    } catch (e) {
      _progressController.add(FolderScanProgress(
        currentPath: canonicalPath,
        foldersScanned: 0,
        totalFolders: 1,
        filesFound: 0,
        status: FolderScanStatus.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    } finally {
      _activeScanTokens.remove(canonicalPath);
    }
  }
  
  
  /// Set the active root directory and manage filesystem watcher
  /// Only one root is watched at a time to prevent unbounded watcher growth
  Future<void> setActiveRoot(String rootPath) async {
    final canonicalRoot = await _canonicalizePath(rootPath);
    
    // Guard: check if directory exists before setting up watcher
    if (!await Directory(canonicalRoot).exists()) {
      debugPrint('Skipping watcher setup for non-existent directory: $canonicalRoot');
      return;
    }
    
    // If already watching this root, nothing to do
    if (_activeRoot == canonicalRoot) return;
    
    // Cancel existing watcher
    if (_activeRoot != null) {
      _watchers[_activeRoot!]?.cancel();
      _watchers.remove(_activeRoot!);
    }
    
    // Setup new watcher for the root
    _activeRoot = canonicalRoot;
    _setupWatcherForRoot(canonicalRoot);
  }
  
  /// Setup filesystem watcher for the active root directory
  void _setupWatcherForRoot(String canonicalPath) {
    try {
      final watcher = DirectoryWatcher(canonicalPath);
      final subscription = watcher.events.listen((event) {
        _handleWatcherEvent(canonicalPath, event);
      }, onError: (error) {
        debugPrint('Watcher error for $canonicalPath: $error');
        _watchers.remove(canonicalPath)?.cancel();
        _activeRoot = null; // Clear active root on error
        
        // Clear stale cache for this root to avoid showing outdated counts
        // after permission changes or filesystem errors
        _invalidateCacheForPath(canonicalPath);
      });
      
      _watchers[canonicalPath] = subscription;
    } catch (e) {
      debugPrint('Failed to setup watcher for $canonicalPath: $e');
      _activeRoot = null;
    }
  }
  
  /// Handle filesystem watcher events
  void _handleWatcherEvent(String canonicalPath, WatchEvent event) {
    // Invalidate cache for the affected path and its parent chain
    _invalidateCacheForPath(canonicalPath);
    
    // If a markdown file was added/removed/modified, invalidate parent folders
    if (_isMarkdownFile(event.path)) {
      var currentPath = p.dirname(event.path);
      while (currentPath != canonicalPath && currentPath != p.dirname(currentPath)) {
        _invalidateCacheForPath(currentPath);
        currentPath = p.dirname(currentPath);
      }
    }
  }
  
  /// Invalidate cache entries for a specific path and its subtree
  void _invalidateCacheForPath(String rootPath) {
    _cache.removeWhere((key, value) => 
      p.equals(key, rootPath) || p.isWithin(rootPath, key));
    
    // Emit invalidation event for provider layer to refresh
    _invalidationController.add(rootPath);
  }
  
  /// Cancel ongoing scan for specified folder
  Future<void> cancelScan(String folderPath) async {
    final canonicalPath = await _canonicalizePath(folderPath);
    final token = _activeScanTokens[canonicalPath];
    if (token != null) {
      token.cancel();
      _activeScanTokens.remove(canonicalPath);
    }
  }
  
  /// Cancel all ongoing scans
  Future<void> cancelAllScans() async {
    for (final token in _activeScanTokens.values) {
      token.cancel();
    }
    _activeScanTokens.clear();
  }
  
  /// Clear cache for specific folder or all folders
  void clearCache([String? folderPath]) {
    if (folderPath != null) {
      _cache.remove(folderPath);
    } else {
      _cache.clear();
    }
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedFolders': _cache.length,
      'activeScans': _activeScanTokens.length,
      'totalCachedFiles': _cache.values.fold(0, (sum, folder) => sum + folder.totalMarkdownFilesRecursive),
    };
  }
  
  /// Check if file is a markdown file based on extension
  bool _isMarkdownFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return _markdownExtensions.contains(ext);
  }
  
  /// Check if directory should be excluded from scanning
  bool _shouldExcludeDirectory(String dirName, bool shouldFilter) {
    if (!shouldFilter) return false;
    
    // Exclude hidden directories
    if (dirName.startsWith('.')) return true;
    
    // Exclude common build/cache directories
    return _excludedDirectories.contains(dirName.toLowerCase());
  }
  
  /// Check if file should be ignored during scanning
  bool _shouldIgnoreFile(String fileName) {
    return _ignoredFiles.contains(p.basename(fileName).toLowerCase());
  }
  
  /// Dispose resources
  void dispose() {
    cancelAllScans();
    _progressController.close();
    _invalidationController.close();
    _cache.clear();
    
    // Cancel all watchers
    for (final subscription in _watchers.values) {
      subscription.cancel();
    }
    _watchers.clear();
  }
}

/// Isolate-based recursive scanning to prevent UI jank
/// This function runs in a separate isolate and has no access to the main thread
Future<_IsolateScanResult> _isolateScanWork(_IsolateScanArgs args) async {
  // Import path utilities in the isolate
  // Note: package:path must be imported at top level for isolate use
  final counters = _ScanCounters();
  
  // Perform the recursive scan
  final metadata = await _recursiveScanInIsolate(
    Directory(args.rootPath),
    counters: counters,
    shouldFilter: args.shouldFilter,
    maxDepth: args.maxDepth,
    excludedDirs: args.excludedDirs,
    ignoredFiles: args.ignoredFiles,
    markdownExts: args.markdownExts,
    depth: 0,
  );
  
  return _IsolateScanResult(
    metadata: metadata,
    counters: counters,
  );
}

/// Recursive folder scanning for isolate execution
Future<FolderMetadata> _recursiveScanInIsolate(
  Directory directory, {
  required _ScanCounters counters,
  required bool shouldFilter,
  required int maxDepth,
  required Set<String> excludedDirs,
  required Set<String> ignoredFiles,
  required Set<String> markdownExts,
  required int depth,
}) async {
  // Import path for isolate context
  
  if (depth > maxDepth) {
    return FolderMetadata(
      path: directory.path,
      name: p.basename(directory.path),
      markdownFileCount: 0,
      totalFileCount: 0,
      subfolderCount: 0,
      lastScanned: DateTime.now(),
      isFullyScanned: true,
    );
  }
  
  counters.visitedFolders++;
  final path = directory.path;
  final name = p.basename(path);
  final scanTime = DateTime.now();
  
  final subfolders = <FolderMetadata>[];
  final markdownFiles = <FileMetadata>[];
  int totalFileCount = 0;
  
  try {
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File) {
        totalFileCount++;
        final fileName = p.basename(entity.path);
        
        // Skip ignored files
        if (ignoredFiles.contains(fileName.toLowerCase())) continue;
        
        // Check if markdown file
        final ext = p.extension(entity.path).toLowerCase();
        if (markdownExts.contains(ext)) {
          counters.foundFiles++;
          final stat = await entity.stat();
          markdownFiles.add(FileMetadata(
            path: entity.path,
            name: fileName,
            lastModified: stat.modified,
            size: stat.size,
          ));
        }
      } else if (entity is Directory) {
        final dirName = p.basename(entity.path);
        
        // Check exclusion rules
        bool shouldExclude = false;
        if (shouldFilter) {
          if (dirName.startsWith('.') || excludedDirs.contains(dirName.toLowerCase())) {
            shouldExclude = true;
          }
        }
        
        if (!shouldExclude) {
          try {
            final subfolderMetadata = await _recursiveScanInIsolate(
              entity,
              counters: counters,
              shouldFilter: shouldFilter,
              maxDepth: maxDepth,
              excludedDirs: excludedDirs,
              ignoredFiles: ignoredFiles,
              markdownExts: markdownExts,
              depth: depth + 1,
            );
            
            // Only include subfolders that have markdown files
            if (subfolderMetadata.totalMarkdownFilesRecursive > 0) {
              subfolders.add(subfolderMetadata);
            }
          } catch (e) {
            // Continue with other folders on error
          }
        }
      }
      
      // Yield control periodically
      if (totalFileCount % 50 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
    
    // Sort results
    subfolders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    markdownFiles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    return FolderMetadata(
      path: path,
      name: name,
      markdownFileCount: markdownFiles.length,
      totalFileCount: totalFileCount,
      subfolderCount: subfolders.length,
      lastScanned: scanTime,
      subfolders: subfolders,
      markdownFiles: markdownFiles,
      isFullyScanned: true,
    );
    
  } catch (e) {
    return FolderMetadata(
      path: path,
      name: name,
      markdownFileCount: 0,
      totalFileCount: 0,
      subfolderCount: 0,
      lastScanned: scanTime,
      isFullyScanned: false,
    );
  }
}

/// Progress tracking counters for scanning
class _ScanCounters {
  int visitedFolders = 0;
  int foundFiles = 0;
  int estimatedTotal = 0;
}

/// Data structure for isolate-based scanning
class _IsolateScanArgs {
  final String rootPath;
  final bool shouldFilter;
  final int maxDepth;
  final Set<String> excludedDirs;
  final Set<String> ignoredFiles;
  final Set<String> markdownExts;
  
  const _IsolateScanArgs({
    required this.rootPath,
    required this.shouldFilter,
    required this.maxDepth,
    required this.excludedDirs,
    required this.ignoredFiles,
    required this.markdownExts,
  });
}

/// Result from isolate scanning
class _IsolateScanResult {
  final FolderMetadata metadata;
  final _ScanCounters counters;
  
  const _IsolateScanResult({
    required this.metadata,
    required this.counters,
  });
}

/// Simple cancellation token for async operations
class CancelToken {
  bool _isCancelled = false;
  
  bool get isCancelled => _isCancelled;
  
  void cancel() {
    _isCancelled = true;
  }
}