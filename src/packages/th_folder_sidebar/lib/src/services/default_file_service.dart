import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../interfaces/file_service_interface.dart';
import '../models/file_operations.dart';

/// Default implementation of FileServiceInterface using dart:io
class DefaultFileService implements FileServiceInterface {
  final StreamController<FileOperationEvent> _operationController = StreamController.broadcast();
  
  @override
  Stream<FileOperationEvent> get operationStream => _operationController.stream;
  
  @override
  Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> directoryExists(String path) async {
    try {
      return await Directory(path).exists();
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<String> readFile(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.read,
        path: path,
        success: true,
      ));
      return content;
    } catch (e) {
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.read,
        path: path,
        success: false,
        error: e.toString(),
      ));
      rethrow;
    }
  }
  
  @override
  Future<void> writeFile(String path, String content) async {
    try {
      final file = File(path);
      await ensureDirectoryExists(path);
      await file.writeAsString(content);
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.update,
        path: path,
        success: true,
      ));
    } catch (e) {
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.update,
        path: path,
        success: false,
        error: e.toString(),
      ));
      rethrow;
    }
  }
  
  @override
  Future<FileOperationResult> createFile(String path, {String? content, String? templateContent}) async {
    try {
      final file = File(path);
      
      // Check if file already exists
      if (await file.exists()) {
        return FileOperationResult.failure(
          error: Exception('File already exists'),
          message: 'A file already exists at "$path"',
        );
      }
      
      await ensureDirectoryExists(path);
      
      final fileContent = content ?? templateContent ?? '';
      await file.writeAsString(fileContent);
      
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.create,
        path: path,
        success: true,
      ));
      
      return FileOperationResult.success(
        message: 'File created successfully',
        data: path,
      );
    } catch (e) {
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.create,
        path: path,
        success: false,
        error: e.toString(),
      ));
      
      return FileOperationResult.failure(
        error: e is Exception ? e : Exception(e.toString()),
        message: 'Failed to create file: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<FileOperationResult> createDirectory(String path, {bool recursive = true}) async {
    try {
      final directory = Directory(path);
      
      // Check if directory already exists
      if (await directory.exists()) {
        return FileOperationResult.failure(
          error: Exception('Directory already exists'),
          message: 'A directory already exists at "$path"',
        );
      }
      
      await directory.create(recursive: recursive);
      
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.create,
        path: path,
        success: true,
      ));
      
      return FileOperationResult.success(
        message: 'Directory created successfully',
        data: path,
      );
    } catch (e) {
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.create,
        path: path,
        success: false,
        error: e.toString(),
      ));
      
      return FileOperationResult.failure(
        error: e is Exception ? e : Exception(e.toString()),
        message: 'Failed to create directory: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<FileOperationResult> delete(String path, {bool moveToTrash = true, bool recursive = false}) async {
    try {
      final file = File(path);
      final directory = Directory(path);
      
      if (await file.exists()) {
        if (moveToTrash) {
          // Try to move to trash (platform-specific implementation would go here)
          // For now, just delete normally
          await file.delete();
        } else {
          await file.delete();
        }
      } else if (await directory.exists()) {
        if (moveToTrash) {
          // Try to move to trash (platform-specific implementation would go here)
          // For now, just delete normally
          await directory.delete(recursive: recursive);
        } else {
          await directory.delete(recursive: recursive);
        }
      } else {
        return FileOperationResult.failure(
          error: Exception('Path not found'),
          message: 'No file or directory found at "$path"',
        );
      }
      
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.delete,
        path: path,
        success: true,
      ));
      
      return FileOperationResult.success(
        message: moveToTrash ? 'Moved to trash successfully' : 'Deleted successfully',
      );
    } catch (e) {
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.delete,
        path: path,
        success: false,
        error: e.toString(),
      ));
      
      return FileOperationResult.failure(
        error: e is Exception ? e : Exception(e.toString()),
        message: 'Failed to delete: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<FileOperationResult> rename(String oldPath, String newPath) async {
    try {
      final file = File(oldPath);
      final directory = Directory(oldPath);
      
      // Check if target already exists
      if (await File(newPath).exists() || await Directory(newPath).exists()) {
        return FileOperationResult.failure(
          error: Exception('Target already exists'),
          message: 'A file or directory already exists at "$newPath"',
        );
      }
      
      if (await file.exists()) {
        await file.rename(newPath);
      } else if (await directory.exists()) {
        await directory.rename(newPath);
      } else {
        return FileOperationResult.failure(
          error: Exception('Source not found'),
          message: 'No file or directory found at "$oldPath"',
        );
      }
      
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.rename,
        path: oldPath,
        newPath: newPath,
        success: true,
      ));
      
      return FileOperationResult.success(
        message: 'Renamed successfully',
        data: newPath,
      );
    } catch (e) {
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.rename,
        path: oldPath,
        newPath: newPath,
        success: false,
        error: e.toString(),
      ));
      
      return FileOperationResult.failure(
        error: e is Exception ? e : Exception(e.toString()),
        message: 'Failed to rename: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<FileOperationResult> copy(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final sourceDirectory = Directory(sourcePath);
      
      if (await sourceFile.exists()) {
        await ensureDirectoryExists(destinationPath);
        await sourceFile.copy(destinationPath);
      } else if (await sourceDirectory.exists()) {
        // For directories, we need to copy recursively
        return FileOperationResult.failure(
          error: Exception('Directory copying not implemented'),
          message: 'Directory copying is not yet implemented',
        );
      } else {
        return FileOperationResult.failure(
          error: Exception('Source not found'),
          message: 'No file or directory found at "$sourcePath"',
        );
      }
      
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.copy,
        path: sourcePath,
        newPath: destinationPath,
        success: true,
      ));
      
      return FileOperationResult.success(
        message: 'Copied successfully',
        data: destinationPath,
      );
    } catch (e) {
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.copy,
        path: sourcePath,
        newPath: destinationPath,
        success: false,
        error: e.toString(),
      ));
      
      return FileOperationResult.failure(
        error: e is Exception ? e : Exception(e.toString()),
        message: 'Failed to copy: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<FileOperationResult> move(String sourcePath, String destinationPath) async {
    // Move is essentially a copy + delete operation
    final copyResult = await copy(sourcePath, destinationPath);
    if (copyResult.success) {
      final deleteResult = await delete(sourcePath, moveToTrash: false);
      if (deleteResult.success) {
        _emitEvent(FileOperationEvent(
          operation: FileOperationType.move,
          path: sourcePath,
          newPath: destinationPath,
          success: true,
        ));
        return FileOperationResult.success(
          message: 'Moved successfully',
          data: destinationPath,
        );
      } else {
        // Copy succeeded but delete failed - this is a problematic state
        return FileOperationResult.failure(
          error: Exception('Move partially failed'),
          message: 'File was copied but could not be deleted from source location',
        );
      }
    } else {
      return copyResult; // Return the copy failure
    }
  }
  
  @override
  Future<FileOperationResult> revealInFileManager(String path) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      } else if (Platform.isLinux) {
        // Try different file managers
        try {
          await Process.run('nautilus', ['--select', path]);
        } catch (_) {
          try {
            await Process.run('dolphin', ['--select', path]);
          } catch (_) {
            // Fallback to opening parent directory
            final parent = path.substring(0, path.lastIndexOf('/'));
            await Process.run('xdg-open', [parent]);
          }
        }
      } else {
        return FileOperationResult.failure(
          error: Exception('Platform not supported'),
          message: 'File manager reveal not supported on this platform',
        );
      }
      
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.reveal,
        path: path,
        success: true,
      ));
      
      return FileOperationResult.success(
        message: 'Revealed in file manager',
      );
    } catch (e) {
      _emitEvent(FileOperationEvent(
        operation: FileOperationType.reveal,
        path: path,
        success: false,
        error: e.toString(),
      ));
      
      return FileOperationResult.failure(
        error: e is Exception ? e : Exception(e.toString()),
        message: 'Failed to reveal in file manager: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<FileInfo?> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      final directory = Directory(filePath);
      
      if (await file.exists()) {
        final stat = await file.stat();
        return FileInfo.fromPath(
          filePath,
          isDirectory: false,
          sizeBytes: stat.size,
          lastModified: stat.modified,
          lastAccessed: stat.accessed,
        );
      } else if (await directory.exists()) {
        final stat = await directory.stat();
        return FileInfo.fromPath(
          filePath,
          isDirectory: true,
          lastModified: stat.modified,
          lastAccessed: stat.accessed,
        );
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<String>> getDirectoryContents(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) return [];
      
      final contents = <String>[];
      await for (final entity in directory.list()) {
        contents.add(entity.path);
      }
      
      return contents;
    } catch (e) {
      return [];
    }
  }
  
  @override
  bool isMarkdownFile(String path) {
    final ext = getFileExtension(path).toLowerCase();
    return ext == '.md' || ext == '.markdown' || ext == '.mdown' || ext == '.mkd' || ext == '.mkdn';
  }
  
  @override
  Future<String> getTemporaryPath({String? baseName, String? extension}) async {
    final tempDir = await getTemporaryDirectory();
    final name = baseName ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final ext = extension ?? '';
    return path.join(tempDir.path, '$name$ext');
  }
  
  @override
  Future<void> ensureDirectoryExists(String filePath) async {
    final directory = Directory(getParentDirectory(filePath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }
  
  @override
  Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      final stat = await file.stat();
      return stat.size;
    } catch (e) {
      return 0;
    }
  }
  
  @override
  Future<DateTime> getLastModified(String path) async {
    try {
      final file = File(path);
      final directory = Directory(path);
      
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.modified;
      } else if (await directory.exists()) {
        final stat = await directory.stat();
        return stat.modified;
      }
      
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }
  
  @override
  Future<bool> isDirectory(String path) async {
    return await Directory(path).exists();
  }
  
  @override
  Future<bool> isFile(String path) async {
    return await File(path).exists();
  }
  
  @override
  String getParentDirectory(String path) {
    return path.substring(0, path.lastIndexOf('/'));
  }
  
  @override
  String getFileName(String path) {
    return path.split('/').last;
  }
  
  @override
  String getFileExtension(String path) {
    final fileName = getFileName(path);
    if (fileName.contains('.')) {
      return fileName.substring(fileName.lastIndexOf('.'));
    }
    return '';
  }
  
  @override
  String joinPaths(List<String> components) {
    return path.joinAll(components);
  }
  
  @override
  String normalizePath(String path) {
    return path.replaceAll(RegExp(r'/{2,}'), '/');
  }
  
  @override
  Future<bool> canRead(String path) async {
    try {
      if (await isFile(path)) {
        final file = File(path);
        final contents = await file.readAsBytes();
        return contents.isNotEmpty || true; // Even empty files are readable
      } else if (await isDirectory(path)) {
        final directory = Directory(path);
        await directory.list().take(1).toList(); // Try to list one item
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> canWrite(String path) async {
    try {
      if (await isFile(path)) {
        final file = File(path);
        final stat = await file.stat();
        // On Unix-like systems, check if we can write
        // This is a simplified check
        return stat.mode & 0x80 != 0; // Owner write permission
      } else if (await isDirectory(path)) {
        // Try to create a temporary file in the directory
        final tempPath = joinPaths([path, '.temp_write_test_${DateTime.now().millisecondsSinceEpoch}']);
        try {
          await File(tempPath).writeAsString('test');
          await File(tempPath).delete();
          return true;
        } catch (_) {
          return false;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<void> dispose() async {
    await _operationController.close();
  }
  
  // Private methods
  
  void _emitEvent(FileOperationEvent event) {
    if (!_operationController.isClosed) {
      _operationController.add(event);
    }
  }
}