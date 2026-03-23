import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../interfaces/permissions_service_interface.dart';

/// Default implementation of PermissionsServiceInterface
/// Provides basic cross-platform permission handling
class DefaultPermissionsService implements PermissionsServiceInterface {
  final StreamController<PermissionChangeEvent> _permissionChangeController = StreamController.broadcast();
  final Set<String> _grantedDirectories = <String>{};
  final Set<String> _grantedFiles = <String>{};
  
  @override
  bool get requiresExplicitPermissions => Platform.isMacOS || Platform.isIOS;
  
  @override
  bool get hasPersistedPermissions => true; // We maintain our own cache
  
  @override
  Stream<PermissionChangeEvent> get permissionChangeStream => _permissionChangeController.stream;
  
  @override
  Future<bool> canAccessDirectory(String directoryPath) async {
    try {
      // Check if we've already granted permission
      if (_grantedDirectories.contains(directoryPath)) {
        return true;
      }
      
      // Try to access the directory
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return false;
      
      // Try to list contents
      await directory.list().take(1).toList();
      
      // If successful, add to granted directories
      _grantedDirectories.add(directoryPath);
      _emitPermissionEvent(PermissionChangeEvent(
        path: directoryPath,
        type: PermissionChangeType.granted,
        newLevel: PermissionLevel.full,
      ));
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> canAccessFile(String filePath) async {
    try {
      // Check if we've already granted permission
      if (_grantedFiles.contains(filePath)) {
        return true;
      }
      
      // Check if parent directory has permission
      final parentDir = filePath.substring(0, filePath.lastIndexOf('/'));
      if (_grantedDirectories.contains(parentDir)) {
        _grantedFiles.add(filePath);
        return true;
      }
      
      // Try to access the file
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      // Try to read file stats
      await file.stat();
      
      // If successful, add to granted files
      _grantedFiles.add(filePath);
      _emitPermissionEvent(PermissionChangeEvent(
        path: filePath,
        type: PermissionChangeType.granted,
        newLevel: PermissionLevel.readOnly,
      ));
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> requestAccessToDirectory(String directoryPath) async {
    try {
      // First check if we already have access
      if (await canAccessDirectory(directoryPath)) {
        return true;
      }
      
      // On platforms that don't require explicit permissions, try direct access
      if (!requiresExplicitPermissions) {
        return await canAccessDirectory(directoryPath);
      }
      
      // For platforms requiring explicit permissions, we would integrate with
      // platform-specific permission systems here. For now, simulate user dialog.
      
      // Try to access and if it works, grant permission
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        try {
          await directory.list().take(1).toList();
          _grantedDirectories.add(directoryPath);
          
          _emitPermissionEvent(PermissionChangeEvent(
            path: directoryPath,
            type: PermissionChangeType.granted,
            newLevel: PermissionLevel.full,
          ));
          
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
  Future<bool> requestAccessToFile(String filePath) async {
    try {
      // First check if we already have access
      if (await canAccessFile(filePath)) {
        return true;
      }
      
      // Try to request access to parent directory
      final parentDir = filePath.substring(0, filePath.lastIndexOf('/'));
      if (await requestAccessToDirectory(parentDir)) {
        _grantedFiles.add(filePath);
        
        _emitPermissionEvent(PermissionChangeEvent(
          path: filePath,
          type: PermissionChangeType.granted,
          newLevel: PermissionLevel.readOnly,
        ));
        
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<List<Directory>> pickDirectories({bool allowMultiple = false}) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Directory',
      );
      
      if (selectedDirectory != null) {
        final directory = Directory(selectedDirectory);
        if (await directory.exists()) {
          // Grant permission to the selected directory
          _grantedDirectories.add(selectedDirectory);
          
          _emitPermissionEvent(PermissionChangeEvent(
            path: selectedDirectory,
            type: PermissionChangeType.granted,
            newLevel: PermissionLevel.full,
          ));
          
          return [directory];
        }
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<File>> pickFiles({bool allowMultiple = false, List<String>? allowedExtensions}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );
      
      if (result != null) {
        final files = <File>[];
        
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await file.exists()) {
              files.add(file);
              
              // Grant permission to the file and its parent directory
              _grantedFiles.add(platformFile.path!);
              final parentDir = platformFile.path!.substring(0, platformFile.path!.lastIndexOf('/'));
              _grantedDirectories.add(parentDir);
              
              _emitPermissionEvent(PermissionChangeEvent(
                path: platformFile.path!,
                type: PermissionChangeType.granted,
                newLevel: PermissionLevel.readOnly,
              ));
            }
          }
        }
        
        return files;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<String>> getAccessibleDirectories() async {
    // Return all directories we have access to
    final accessible = <String>[];
    
    for (final dirPath in _grantedDirectories) {
      if (await Directory(dirPath).exists()) {
        accessible.add(dirPath);
      }
    }
    
    return accessible;
  }
  
  @override
  Future<List<String>> getAccessibleFiles() async {
    // Return all files we have access to
    final accessible = <String>[];
    
    for (final filePath in _grantedFiles) {
      if (await File(filePath).exists()) {
        accessible.add(filePath);
      }
    }
    
    return accessible;
  }
  
  @override
  Future<void> revokeDirectoryAccess(String directoryPath) async {
    final removed = _grantedDirectories.remove(directoryPath);
    if (removed) {
      // Also remove any files within this directory
      final filesToRemove = _grantedFiles.where((filePath) => filePath.startsWith(directoryPath)).toList();
      for (final filePath in filesToRemove) {
        _grantedFiles.remove(filePath);
      }
      
      _emitPermissionEvent(PermissionChangeEvent(
        path: directoryPath,
        type: PermissionChangeType.revoked,
        oldLevel: PermissionLevel.full,
        newLevel: PermissionLevel.none,
      ));
    }
  }
  
  @override
  Future<void> revokeFileAccess(String filePath) async {
    final removed = _grantedFiles.remove(filePath);
    if (removed) {
      _emitPermissionEvent(PermissionChangeEvent(
        path: filePath,
        type: PermissionChangeType.revoked,
        oldLevel: PermissionLevel.readOnly,
        newLevel: PermissionLevel.none,
      ));
    }
  }
  
  @override
  Future<void> clearAllPermissions() async {
    final hadPermissions = _grantedDirectories.isNotEmpty || _grantedFiles.isNotEmpty;
    
    _grantedDirectories.clear();
    _grantedFiles.clear();
    
    if (hadPermissions) {
      // Emit a general revoked event
      _emitPermissionEvent(PermissionChangeEvent(
        path: '',
        type: PermissionChangeType.revoked,
        oldLevel: PermissionLevel.full,
        newLevel: PermissionLevel.none,
      ));
    }
  }
  
  @override
  Future<PermissionInfo> getPermissionInfo(String path) async {
    final isDirectory = await Directory(path).exists();
    final isFile = !isDirectory && await File(path).exists();
    
    if (!isDirectory && !isFile) {
      return PermissionInfo(
        path: path,
        canRead: false,
        canWrite: false,
        canExecute: false,
        hasExplicitPermission: false,
        source: PermissionSource.unknown,
      );
    }
    
    final hasExplicitPermission = isDirectory 
        ? _grantedDirectories.contains(path)
        : _grantedFiles.contains(path);
    
    // Try to determine actual permissions
    bool canRead = false;
    bool canWrite = false;
    bool canExecute = false;
    
    try {
      if (isFile) {
        final file = File(path);
        final stat = await file.stat();
        canRead = true; // If we can stat it, we can probably read it
        canWrite = stat.mode & 0x80 != 0; // Owner write permission (simplified)
      } else if (isDirectory) {
        final directory = Directory(path);
        await directory.list().take(1).toList();
        canRead = true;
        canWrite = true; // Assume write permission if we can read
      }
    } catch (_) {
      // Permission denied or other error
    }
    
    return PermissionInfo(
      path: path,
      canRead: canRead,
      canWrite: canWrite,
      canExecute: canExecute,
      hasExplicitPermission: hasExplicitPermission,
      source: hasExplicitPermission ? PermissionSource.explicit : PermissionSource.system,
      grantedAt: hasExplicitPermission ? DateTime.now() : null,
    );
  }
  
  @override
  Future<void> dispose() async {
    await _permissionChangeController.close();
    _grantedDirectories.clear();
    _grantedFiles.clear();
  }
  
  // Private methods
  
  void _emitPermissionEvent(PermissionChangeEvent event) {
    if (!_permissionChangeController.isClosed) {
      _permissionChangeController.add(event);
    }
  }
  
  // Additional utility methods
  
  /// Check if a path is within any of the granted directories
  bool isWithinGrantedDirectory(String path) {
    for (final grantedDir in _grantedDirectories) {
      if (path.startsWith(grantedDir)) {
        return true;
      }
    }
    return false;
  }
  
  /// Get the most specific granted directory for a path
  String? getGrantedDirectoryForPath(String path) {
    String? mostSpecific;
    int maxLength = 0;
    
    for (final grantedDir in _grantedDirectories) {
      if (path.startsWith(grantedDir) && grantedDir.length > maxLength) {
        mostSpecific = grantedDir;
        maxLength = grantedDir.length;
      }
    }
    
    return mostSpecific;
  }
  
  /// Grant access to a directory programmatically (useful for testing)
  void grantDirectoryAccess(String directoryPath) {
    if (!_grantedDirectories.contains(directoryPath)) {
      _grantedDirectories.add(directoryPath);
      _emitPermissionEvent(PermissionChangeEvent(
        path: directoryPath,
        type: PermissionChangeType.granted,
        newLevel: PermissionLevel.full,
      ));
    }
  }
  
  /// Grant access to a file programmatically (useful for testing)
  void grantFileAccess(String filePath) {
    if (!_grantedFiles.contains(filePath)) {
      _grantedFiles.add(filePath);
      
      // Also grant access to parent directory if not already granted
      final parentDir = filePath.substring(0, filePath.lastIndexOf('/'));
      if (!_grantedDirectories.contains(parentDir)) {
        _grantedDirectories.add(parentDir);
      }
      
      _emitPermissionEvent(PermissionChangeEvent(
        path: filePath,
        type: PermissionChangeType.granted,
        newLevel: PermissionLevel.readOnly,
      ));
    }
  }
}