import 'dart:io';
import 'package:path/path.dart' as path;

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// Check if the file is a supported Markdown file
  bool isMarkdownFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.md', '.markdown', '.mdown', '.mkd', '.mkdn'].contains(extension);
  }

  /// Read file content as string
  Future<String> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  /// Write content to file
  Future<void> writeFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
    } catch (e) {
      throw Exception('Failed to write file: $e');
    }
  }

  /// Get file name from path
  String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Get file extension
  String getFileExtension(String filePath) {
    return path.extension(filePath);
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// Create parent directories if they don't exist
  Future<void> ensureDirectoryExists(String filePath) async {
    final directory = Directory(path.dirname(filePath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// Save file with dialog
  Future<String?> saveFileDialog() async {
    // This would typically use file_picker, but we'll handle it in the UI layer
    return null;
  }

  /// Create a new directory
  Future<void> createDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        throw Exception('Directory already exists: $directoryPath');
      }
      await directory.create(recursive: true);
    } catch (e) {
      throw Exception('Failed to create directory: $e');
    }
  }
}