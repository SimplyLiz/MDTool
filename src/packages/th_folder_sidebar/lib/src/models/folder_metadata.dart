/// Metadata for a folder including file counts and nested structure information
class FolderMetadata {
  final String path;
  final String name;
  final int markdownFileCount;
  final int totalFileCount;
  final int totalFolderCount;
  final List<FolderMetadata> subfolders;
  final List<FileMetadata> markdownFiles;
  final List<FileMetadata> allFiles;
  final DateTime lastScanned;
  final bool isComplete;
  
  FolderMetadata({
    required this.path,
    required this.name,
    this.markdownFileCount = 0,
    this.totalFileCount = 0,
    this.totalFolderCount = 0,
    this.subfolders = const [],
    this.markdownFiles = const [],
    this.allFiles = const [],
    DateTime? lastScanned,
    this.isComplete = true,
  }) : lastScanned = lastScanned ?? DateTime.now();

  /// Create a minimal metadata object with just path and name
  FolderMetadata.minimal({
    required this.path,
    required this.name,
  }) : markdownFileCount = 0,
       totalFileCount = 0,
       totalFolderCount = 0,
       subfolders = const [],
       markdownFiles = const [],
       allFiles = const [],
       lastScanned = DateTime.now(),
       isComplete = false;

  /// Get a detailed count display text
  String get detailedCountDisplayText {
    if (!isComplete) return 'Scanning...';
    
    if (markdownFileCount == 0 && totalFolderCount == 0) {
      return 'Empty folder';
    }
    
    final List<String> parts = [];
    
    if (markdownFileCount > 0) {
      parts.add('$markdownFileCount markdown file${markdownFileCount == 1 ? '' : 's'}');
    }
    
    if (totalFolderCount > 0) {
      parts.add('$totalFolderCount folder${totalFolderCount == 1 ? '' : 's'}');
    }
    
    if (totalFileCount > markdownFileCount) {
      final otherFiles = totalFileCount - markdownFileCount;
      parts.add('$otherFiles other file${otherFiles == 1 ? '' : 's'}');
    }
    
    return parts.join(', ');
  }
  
  /// Get a simple count display text
  String get simpleCountDisplayText {
    if (!isComplete) return 'Scanning...';
    
    if (markdownFileCount > 0) {
      return '$markdownFileCount markdown file${markdownFileCount == 1 ? '' : 's'}';
    }
    
    if (totalFileCount > 0) {
      return '$totalFileCount file${totalFileCount == 1 ? '' : 's'}';
    }
    
    return 'Empty';
  }
  
  /// Check if this folder has any content
  bool get hasContent => totalFileCount > 0 || totalFolderCount > 0;
  
  /// Check if this folder contains markdown files
  bool get hasMarkdownFiles => markdownFileCount > 0;
  
  /// Get the total number of items (files + folders)
  int get totalItemCount => totalFileCount + totalFolderCount;
  
  /// Check if the metadata is stale (older than specified duration)
  bool isStale(Duration maxAge) {
    return DateTime.now().difference(lastScanned) > maxAge;
  }
  
  /// Create a copy with updated values
  FolderMetadata copyWith({
    String? path,
    String? name,
    int? markdownFileCount,
    int? totalFileCount,
    int? totalFolderCount,
    List<FolderMetadata>? subfolders,
    List<FileMetadata>? markdownFiles,
    List<FileMetadata>? allFiles,
    DateTime? lastScanned,
    bool? isComplete,
  }) {
    return FolderMetadata(
      path: path ?? this.path,
      name: name ?? this.name,
      markdownFileCount: markdownFileCount ?? this.markdownFileCount,
      totalFileCount: totalFileCount ?? this.totalFileCount,
      totalFolderCount: totalFolderCount ?? this.totalFolderCount,
      subfolders: subfolders ?? this.subfolders,
      markdownFiles: markdownFiles ?? this.markdownFiles,
      allFiles: allFiles ?? this.allFiles,
      lastScanned: lastScanned ?? this.lastScanned,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FolderMetadata && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() {
    return 'FolderMetadata(path: $path, markdownFiles: $markdownFileCount, totalFiles: $totalFileCount, folders: $totalFolderCount)';
  }
}

/// Metadata for an individual file
class FileMetadata {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime lastModified;
  final String extension;
  final bool isMarkdownFile;
  
  const FileMetadata({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.lastModified,
    required this.extension,
    required this.isMarkdownFile,
  });

  /// Create FileMetadata from a file path and basic info
  factory FileMetadata.fromPath(
    String path, {
    int? sizeBytes,
    DateTime? lastModified,
  }) {
    final name = path.split('/').last;
    final extension = name.contains('.') ? name.substring(name.lastIndexOf('.')) : '';
    final isMarkdown = _isMarkdownExtension(extension);
    
    return FileMetadata(
      path: path,
      name: name,
      sizeBytes: sizeBytes ?? 0,
      lastModified: lastModified ?? DateTime.now(),
      extension: extension,
      isMarkdownFile: isMarkdown,
    );
  }
  
  /// Check if the given extension is a markdown extension
  static bool _isMarkdownExtension(String extension) {
    final ext = extension.toLowerCase();
    return ext == '.md' || 
           ext == '.markdown' || 
           ext == '.mdown' || 
           ext == '.mkd' || 
           ext == '.mkdn';
  }
  
  /// Get human-readable file size
  String get formattedSize {
    const List<String> units = ['B', 'KB', 'MB', 'GB'];
    double size = sizeBytes.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }
  
  /// Get the file name without extension
  String get nameWithoutExtension {
    if (extension.isEmpty) return name;
    return name.substring(0, name.length - extension.length);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileMetadata && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() {
    return 'FileMetadata(path: $path, size: $formattedSize, isMarkdown: $isMarkdownFile)';
  }
}

/// Progress information for folder scanning operations
class FolderScanProgress {
  final String currentPath;
  final int processedFolders;
  final int totalFolders;
  final int foundFiles;
  final int foundMarkdownFiles;
  final FolderScanStatus status;
  final String? error;
  
  const FolderScanProgress({
    required this.currentPath,
    this.processedFolders = 0,
    this.totalFolders = 0,
    this.foundFiles = 0,
    this.foundMarkdownFiles = 0,
    this.status = FolderScanStatus.scanning,
    this.error,
  });

  /// Get the completion percentage (0.0 to 1.0)
  double get progress {
    if (totalFolders <= 0) return 0.0;
    return (processedFolders / totalFolders).clamp(0.0, 1.0);
  }
  
  /// Get the completion percentage as an integer (0 to 100)
  int get progressPercent => (progress * 100).round();
  
  /// Check if the scan is complete
  bool get isComplete => status == FolderScanStatus.completed;
  
  /// Check if there was an error
  bool get hasError => status == FolderScanStatus.error && error != null;
  
  /// Create a copy with updated values
  FolderScanProgress copyWith({
    String? currentPath,
    int? processedFolders,
    int? totalFolders,
    int? foundFiles,
    int? foundMarkdownFiles,
    FolderScanStatus? status,
    String? error,
  }) {
    return FolderScanProgress(
      currentPath: currentPath ?? this.currentPath,
      processedFolders: processedFolders ?? this.processedFolders,
      totalFolders: totalFolders ?? this.totalFolders,
      foundFiles: foundFiles ?? this.foundFiles,
      foundMarkdownFiles: foundMarkdownFiles ?? this.foundMarkdownFiles,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'FolderScanProgress(${progressPercent}%, $status, files: $foundFiles, markdown: $foundMarkdownFiles)';
  }
}

/// Status of folder scanning operations
enum FolderScanStatus {
  idle,
  starting,
  scanning,
  completed,
  cancelled,
  error,
}

extension FolderScanStatusExtension on FolderScanStatus {
  /// Get a human-readable name for the status
  String get displayName {
    switch (this) {
      case FolderScanStatus.idle:
        return 'Idle';
      case FolderScanStatus.starting:
        return 'Starting...';
      case FolderScanStatus.scanning:
        return 'Scanning...';
      case FolderScanStatus.completed:
        return 'Completed';
      case FolderScanStatus.cancelled:
        return 'Cancelled';
      case FolderScanStatus.error:
        return 'Error';
    }
  }
  
  /// Check if the status represents an active operation
  bool get isActive => this == FolderScanStatus.starting || this == FolderScanStatus.scanning;
  
  /// Check if the status represents a finished operation
  bool get isFinished => this == FolderScanStatus.completed || 
                        this == FolderScanStatus.cancelled || 
                        this == FolderScanStatus.error;
}