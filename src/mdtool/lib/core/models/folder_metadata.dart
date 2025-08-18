/// Metadata for cached folder information including file counts and structure
class FolderMetadata {
  final String path;
  final String name;
  final int markdownFileCount;
  final int totalFileCount;
  final int subfolderCount;
  final DateTime lastScanned;
  final List<FolderMetadata> subfolders;
  final List<FileMetadata> markdownFiles;
  final bool isFullyScanned;
  
  const FolderMetadata({
    required this.path,
    required this.name,
    required this.markdownFileCount,
    required this.totalFileCount,
    required this.subfolderCount,
    required this.lastScanned,
    this.subfolders = const [],
    this.markdownFiles = const [],
    this.isFullyScanned = false,
  });
  
  /// Quick metadata with just counts (for initial display)
  FolderMetadata.quickScan({
    required this.path,
    required this.name,
    required this.markdownFileCount,
    required this.subfolderCount,
    required this.lastScanned,
  }) : totalFileCount = 0,
       subfolders = const [],
       markdownFiles = const [],
       isFullyScanned = false;
  
  /// Whether this folder has subfolders (computed property)
  bool get hasSubfolders => subfolders.isNotEmpty;
  
  /// Create a copy with updated values
  FolderMetadata copyWith({
    String? path,
    String? name,
    int? markdownFileCount,
    int? totalFileCount,
    int? subfolderCount,
    DateTime? lastScanned,
    List<FolderMetadata>? subfolders,
    List<FileMetadata>? markdownFiles,
    bool? isFullyScanned,
  }) {
    return FolderMetadata(
      path: path ?? this.path,
      name: name ?? this.name,
      markdownFileCount: markdownFileCount ?? this.markdownFileCount,
      totalFileCount: totalFileCount ?? this.totalFileCount,
      subfolderCount: subfolderCount ?? this.subfolderCount,
      lastScanned: lastScanned ?? this.lastScanned,
      subfolders: subfolders ?? this.subfolders,
      markdownFiles: markdownFiles ?? this.markdownFiles,
      isFullyScanned: isFullyScanned ?? this.isFullyScanned,
    );
  }
  
  /// Get total markdown files recursively
  int get totalMarkdownFilesRecursive {
    return markdownFileCount + subfolders.fold(0, (sum, folder) => sum + folder.totalMarkdownFilesRecursive);
  }
  
  /// Get display text for file count
  String get countDisplayText {
    if (markdownFileCount == 0) return 'No markdown files';
    if (markdownFileCount == 1) return '1 markdown file';
    return '$markdownFileCount markdown files';
  }
  
  /// Get detailed display text with subfolders
  String get detailedCountDisplayText {
    final parts = <String>[];
    
    if (markdownFileCount > 0) {
      parts.add(countDisplayText);
    }
    
    if (subfolderCount > 0) {
      parts.add('$subfolderCount ${subfolderCount == 1 ? 'folder' : 'folders'}');
    }
    
    return parts.isEmpty ? 'Empty folder' : parts.join(', ');
  }
}

/// Metadata for individual markdown files
class FileMetadata {
  final String path;
  final String name;
  final DateTime lastModified;
  final int size;
  
  const FileMetadata({
    required this.path,
    required this.name,
    required this.lastModified,
    required this.size,
  });
}

/// Status of folder scanning operation
enum FolderScanStatus {
  pending,
  scanning,
  completed,
  error,
}

/// Progress information for folder scanning
class FolderScanProgress {
  final String currentPath;
  final int foldersScanned;
  final int totalFolders;
  final int filesFound;
  final FolderScanStatus status;
  final String? errorMessage;
  
  const FolderScanProgress({
    required this.currentPath,
    required this.foldersScanned,
    required this.totalFolders,
    required this.filesFound,
    required this.status,
    this.errorMessage,
  });
  
  double get progress => totalFolders > 0 ? foldersScanned / totalFolders : 0.0;
  
  FolderScanProgress copyWith({
    String? currentPath,
    int? foldersScanned,
    int? totalFolders,
    int? filesFound,
    FolderScanStatus? status,
    String? errorMessage,
  }) {
    return FolderScanProgress(
      currentPath: currentPath ?? this.currentPath,
      foldersScanned: foldersScanned ?? this.foldersScanned,
      totalFolders: totalFolders ?? this.totalFolders,
      filesFound: filesFound ?? this.filesFound,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}