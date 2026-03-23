import 'dart:async';
import '../models/file_operations.dart';

/// Abstract interface for file operations
/// This allows different implementations (default, custom, or platform-specific)
abstract class FileServiceInterface {
  /// Check if a file exists at the given path
  Future<bool> fileExists(String path);
  
  /// Check if a directory exists at the given path
  Future<bool> directoryExists(String path);
  
  /// Read content from a file
  Future<String> readFile(String path);
  
  /// Write content to a file
  Future<void> writeFile(String path, String content);
  
  /// Create a new file with optional content
  Future<FileOperationResult> createFile(String path, {String? content, String? templateContent});
  
  /// Create a new directory
  Future<FileOperationResult> createDirectory(String path, {bool recursive = true});
  
  /// Delete a file or directory
  Future<FileOperationResult> delete(String path, {bool moveToTrash = true, bool recursive = false});
  
  /// Rename a file or directory
  Future<FileOperationResult> rename(String oldPath, String newPath);
  
  /// Copy a file or directory
  Future<FileOperationResult> copy(String sourcePath, String destinationPath);
  
  /// Move a file or directory
  Future<FileOperationResult> move(String sourcePath, String destinationPath);
  
  /// Reveal a file or directory in the system file manager
  Future<FileOperationResult> revealInFileManager(String path);
  
  /// Get file metadata (size, modification time, etc.)
  Future<FileInfo?> getFileInfo(String path);
  
  /// Get directory contents
  Future<List<String>> getDirectoryContents(String path);
  
  /// Check if a file is a markdown file based on its extension
  bool isMarkdownFile(String path);
  
  /// Get a temporary file path for creating new files
  Future<String> getTemporaryPath({String? baseName, String? extension});
  
  /// Ensure that the parent directory of a file exists
  Future<void> ensureDirectoryExists(String filePath);
  
  /// Get the size of a file in bytes
  Future<int> getFileSize(String path);
  
  /// Get the last modified time of a file
  Future<DateTime> getLastModified(String path);
  
  /// Check if a path represents a directory
  Future<bool> isDirectory(String path);
  
  /// Check if a path represents a file
  Future<bool> isFile(String path);
  
  /// Get the parent directory of a path
  String getParentDirectory(String path);
  
  /// Get the filename from a path
  String getFileName(String path);
  
  /// Get the file extension from a path
  String getFileExtension(String path);
  
  /// Join path components
  String joinPaths(List<String> components);
  
  /// Normalize a path (resolve .. and . components)
  String normalizePath(String path);
  
  /// Check if the current process has read permission for a path
  Future<bool> canRead(String path);
  
  /// Check if the current process has write permission for a path
  Future<bool> canWrite(String path);
  
  /// Stream of file operation events
  Stream<FileOperationEvent> get operationStream;
  
  /// Dispose any resources used by the service
  Future<void> dispose();
}

/// Information about a file or directory
class FileInfo {
  final String path;
  final String name;
  final bool isDirectory;
  final bool isFile;
  final int sizeBytes;
  final DateTime lastModified;
  final DateTime lastAccessed;
  final String extension;
  final bool isHidden;
  final bool canRead;
  final bool canWrite;
  final bool canExecute;
  
  const FileInfo({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.isFile,
    required this.sizeBytes,
    required this.lastModified,
    required this.lastAccessed,
    required this.extension,
    this.isHidden = false,
    this.canRead = true,
    this.canWrite = true,
    this.canExecute = false,
  });
  
  /// Create FileInfo from basic properties
  factory FileInfo.fromPath(
    String path, {
    required bool isDirectory,
    int? sizeBytes,
    DateTime? lastModified,
    DateTime? lastAccessed,
    bool? isHidden,
    bool? canRead,
    bool? canWrite,
    bool? canExecute,
  }) {
    final name = path.split('/').last;
    final extension = !isDirectory && name.contains('.') 
        ? name.substring(name.lastIndexOf('.')) 
        : '';
    
    return FileInfo(
      path: path,
      name: name,
      isDirectory: isDirectory,
      isFile: !isDirectory,
      sizeBytes: sizeBytes ?? 0,
      lastModified: lastModified ?? DateTime.now(),
      lastAccessed: lastAccessed ?? DateTime.now(),
      extension: extension,
      isHidden: isHidden ?? false,
      canRead: canRead ?? true,
      canWrite: canWrite ?? true,
      canExecute: canExecute ?? false,
    );
  }
  
  /// Get human-readable file size
  String get formattedSize {
    if (isDirectory) return '';
    
    const List<String> units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = sizeBytes.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }
  
  /// Check if this is a markdown file
  bool get isMarkdownFile {
    final ext = extension.toLowerCase();
    return ext == '.md' || ext == '.markdown' || ext == '.mdown' || ext == '.mkd' || ext == '.mkdn';
  }
  
  /// Get the file name without extension
  String get nameWithoutExtension {
    if (extension.isEmpty) return name;
    return name.substring(0, name.length - extension.length);
  }
  
  /// Get a relative time string for last modified
  String get relativeModifiedTime {
    final now = DateTime.now();
    final difference = now.difference(lastModified);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return '${lastModified.day}/${lastModified.month}/${lastModified.year}';
    }
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileInfo && other.path == path;
  }
  
  @override
  int get hashCode => path.hashCode;
  
  @override
  String toString() {
    return 'FileInfo(path: $path, isDirectory: $isDirectory, size: $formattedSize)';
  }
}