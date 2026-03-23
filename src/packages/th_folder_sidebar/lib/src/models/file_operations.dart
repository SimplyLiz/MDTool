// Required imports
import 'package:flutter/material.dart';

/// Represents different types of file operations that can be performed
enum FileOperationType {
  create,
  read,
  update,
  delete,
  rename,
  copy,
  move,
  reveal,
}

/// Base class for file operations
abstract class FileOperation {
  final FileOperationType type;
  final String path;
  final DateTime timestamp;
  
  FileOperation({
    required this.type,
    required this.path,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Get a human-readable description of the operation
  String get description;
  
  /// Execute the operation (to be implemented by concrete classes)
  Future<FileOperationResult> execute();
}

/// Operation to create a new file
class CreateFileOperation extends FileOperation {
  final String content;
  final String? templateContent;
  
  CreateFileOperation({
    required super.path,
    this.content = '',
    this.templateContent,
    super.timestamp,
  }) : super(type: FileOperationType.create);
  
  @override
  String get description => 'Create file: ${path.split('/').last}';
  
  @override
  Future<FileOperationResult> execute() async {
    // Implementation will be provided by the file service
    throw UnimplementedError('Execute method should be implemented by file service');
  }
}

/// Operation to create a new folder
class CreateFolderOperation extends FileOperation {
  final bool recursive;
  
  CreateFolderOperation({
    required super.path,
    this.recursive = true,
    super.timestamp,
  }) : super(type: FileOperationType.create);
  
  @override
  String get description => 'Create folder: ${path.split('/').last}';
  
  @override
  Future<FileOperationResult> execute() async {
    throw UnimplementedError('Execute method should be implemented by file service');
  }
}

/// Operation to rename a file or folder
class RenameOperation extends FileOperation {
  final String newPath;
  final String newName;
  
  RenameOperation({
    required super.path,
    required this.newPath,
    super.timestamp,
  }) : newName = newPath.split('/').last,
       super(type: FileOperationType.rename);
  
  @override
  String get description => 'Rename ${path.split('/').last} to $newName';
  
  @override
  Future<FileOperationResult> execute() async {
    throw UnimplementedError('Execute method should be implemented by file service');
  }
}

/// Operation to delete a file or folder
class DeleteOperation extends FileOperation {
  final bool moveToTrash;
  final bool recursive;
  
  DeleteOperation({
    required super.path,
    this.moveToTrash = true,
    this.recursive = false,
    super.timestamp,
  }) : super(type: FileOperationType.delete);
  
  @override
  String get description => 'Delete: ${path.split('/').last}${moveToTrash ? ' (to trash)' : ' (permanent)'}';
  
  @override
  Future<FileOperationResult> execute() async {
    throw UnimplementedError('Execute method should be implemented by file service');
  }
}

/// Operation to reveal a file or folder in the system file manager
class RevealOperation extends FileOperation {
  RevealOperation({
    required super.path,
    super.timestamp,
  }) : super(type: FileOperationType.reveal);
  
  @override
  String get description => 'Reveal in file manager: ${path.split('/').last}';
  
  @override
  Future<FileOperationResult> execute() async {
    throw UnimplementedError('Execute method should be implemented by file service');
  }
}

/// Operation to read file content
class ReadOperation extends FileOperation {
  ReadOperation({
    required super.path,
    super.timestamp,
  }) : super(type: FileOperationType.read);
  
  @override
  String get description => 'Read file: ${path.split('/').last}';
  
  @override
  Future<FileOperationResult> execute() async {
    throw UnimplementedError('Execute method should be implemented by file service');
  }
}

/// Result of a file operation
class FileOperationResult {
  final bool success;
  final String? message;
  final Object? data;
  final Exception? error;
  final DateTime timestamp;
  
  FileOperationResult.success({
    this.message,
    this.data,
  }) : success = true,
       error = null,
       timestamp = DateTime.now();
  
  FileOperationResult.failure({
    required this.error,
    this.message,
  }) : success = false,
       data = null,
       timestamp = DateTime.now();
  
  /// Check if the operation failed
  bool get failed => !success;
  
  /// Get the error message if available
  String get errorMessage {
    if (message != null) return message!;
    if (error != null) return error.toString();
    return 'Unknown error';
  }
  
  /// Get the success message or error message
  String get displayMessage => success ? (message ?? 'Operation completed successfully') : errorMessage;
  
  @override
  String toString() {
    return 'FileOperationResult(success: $success, message: ${message ?? 'none'})';
  }
}

/// Context menu item configuration
class ContextMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isDanger;
  final bool isDivider;
  final List<ContextMenuItem>? submenu;
  
  const ContextMenuItem({
    required this.label,
    this.icon,
    this.onTap,
    this.isEnabled = true,
    this.isDanger = false,
    this.isDivider = false,
    this.submenu,
  });
  
  /// Create a divider menu item
  const ContextMenuItem.divider()
    : label = '',
      icon = null,
      onTap = null,
      isEnabled = false,
      isDanger = false,
      isDivider = true,
      submenu = null;
  
  /// Create a danger menu item (typically for delete operations)
  ContextMenuItem.danger({
    required this.label,
    this.icon,
    this.onTap,
    this.isEnabled = true,
  }) : isDanger = true,
       isDivider = false,
       submenu = null;
  
  /// Check if this item has a submenu
  bool get hasSubmenu => submenu != null && submenu!.isNotEmpty;
  
  /// Check if this item is actionable (not a divider and has an action)
  bool get isActionable => !isDivider && onTap != null && isEnabled;
}

/// Event data for file operations
class FileOperationEvent {
  final FileOperationType operation;
  final String path;
  final String? newPath;
  final bool success;
  final String? error;
  final DateTime timestamp;
  
  FileOperationEvent({
    required this.operation,
    required this.path,
    this.newPath,
    required this.success,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Get the item name from the path
  String get itemName => path.split('/').last;
  
  /// Get the new item name if applicable
  String? get newItemName => newPath?.split('/').last;
  
  /// Check if this is a rename operation
  bool get isRename => operation == FileOperationType.rename && newPath != null;
  
  /// Get a human-readable description
  String get description {
    final name = itemName;
    
    switch (operation) {
      case FileOperationType.create:
        return 'Created $name';
      case FileOperationType.delete:
        return 'Deleted $name';
      case FileOperationType.rename:
        return isRename ? 'Renamed $name to $newItemName' : 'Renamed $name';
      case FileOperationType.reveal:
        return 'Revealed $name in file manager';
      case FileOperationType.read:
        return 'Opened $name';
      case FileOperationType.copy:
        return 'Copied $name';
      case FileOperationType.move:
        return 'Moved $name';
      case FileOperationType.update:
        return 'Updated $name';
    }
  }
  
  @override
  String toString() {
    return 'FileOperationEvent($description, success: $success)';
  }
}

