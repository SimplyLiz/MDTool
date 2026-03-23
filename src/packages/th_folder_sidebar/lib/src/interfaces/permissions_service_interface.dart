import 'dart:async';
import 'dart:io';

/// Abstract interface for handling directory and file permissions
/// This allows different implementations for various platforms and security requirements
abstract class PermissionsServiceInterface {
  /// Check if the app can access a specific directory
  Future<bool> canAccessDirectory(String directoryPath);
  
  /// Check if the app can access a specific file
  Future<bool> canAccessFile(String filePath);
  
  /// Request access to a directory (may show system permission dialog)
  Future<bool> requestAccessToDirectory(String directoryPath);
  
  /// Request access to a file (may show system permission dialog) 
  Future<bool> requestAccessToFile(String filePath);
  
  /// Pick one or more directories using system dialog
  Future<List<Directory>> pickDirectories({bool allowMultiple = false});
  
  /// Pick one or more files using system dialog
  Future<List<File>> pickFiles({bool allowMultiple = false, List<String>? allowedExtensions});
  
  /// Get a list of all directories the app has permission to access
  Future<List<String>> getAccessibleDirectories();
  
  /// Get a list of all files the app has permission to access
  Future<List<String>> getAccessibleFiles();
  
  /// Remove stored permission for a directory (if applicable)
  Future<void> revokeDirectoryAccess(String directoryPath);
  
  /// Remove stored permission for a file (if applicable)
  Future<void> revokeFileAccess(String filePath);
  
  /// Clear all stored permissions
  Future<void> clearAllPermissions();
  
  /// Check if the platform requires explicit permission requests
  bool get requiresExplicitPermissions;
  
  /// Check if permissions are persistent across app sessions
  bool get hasPersistedPermissions;
  
  /// Get information about permission status for a path
  Future<PermissionInfo> getPermissionInfo(String path);
  
  /// Stream of permission change events
  Stream<PermissionChangeEvent> get permissionChangeStream;
  
  /// Dispose any resources used by the service
  Future<void> dispose();
}

/// Information about permission status for a file or directory
class PermissionInfo {
  final String path;
  final bool canRead;
  final bool canWrite;
  final bool canExecute;
  final bool hasExplicitPermission;
  final PermissionSource source;
  final DateTime? grantedAt;
  final String? restrictions;
  
  const PermissionInfo({
    required this.path,
    required this.canRead,
    required this.canWrite,
    required this.canExecute,
    required this.hasExplicitPermission,
    required this.source,
    this.grantedAt,
    this.restrictions,
  });
  
  /// Check if the path has full access (read + write)
  bool get hasFullAccess => canRead && canWrite;
  
  /// Check if the path has any access at all
  bool get hasAnyAccess => canRead || canWrite || canExecute;
  
  /// Get a human-readable description of the permissions
  String get description {
    final permissions = <String>[];
    if (canRead) permissions.add('read');
    if (canWrite) permissions.add('write');
    if (canExecute) permissions.add('execute');
    
    if (permissions.isEmpty) return 'No access';
    return permissions.join(', ').capitalize();
  }
  
  /// Get the permission level as an enum
  PermissionLevel get level {
    if (!hasAnyAccess) return PermissionLevel.none;
    if (canRead && canWrite) return PermissionLevel.full;
    if (canRead) return PermissionLevel.readOnly;
    if (canWrite) return PermissionLevel.writeOnly;
    return PermissionLevel.limited;
  }
  
  @override
  String toString() {
    return 'PermissionInfo(path: $path, level: $level, source: $source)';
  }
}

/// Source of a permission grant
enum PermissionSource {
  /// Permission inherited from parent directory
  inherited,
  /// Permission explicitly granted by user
  explicit,
  /// Permission from system/OS
  system,
  /// Permission from security bookmark (macOS)
  bookmark,
  /// Unknown or default permission
  unknown,
}

/// Level of permission access
enum PermissionLevel {
  /// No access permissions
  none,
  /// Read-only access
  readOnly,
  /// Write-only access (unusual)
  writeOnly,
  /// Full read-write access
  full,
  /// Limited access (execute only, etc.)
  limited,
}

extension PermissionLevelExtension on PermissionLevel {
  /// Get a human-readable name for the permission level
  String get displayName {
    switch (this) {
      case PermissionLevel.none:
        return 'No Access';
      case PermissionLevel.readOnly:
        return 'Read Only';
      case PermissionLevel.writeOnly:
        return 'Write Only';
      case PermissionLevel.full:
        return 'Full Access';
      case PermissionLevel.limited:
        return 'Limited Access';
    }
  }
  
  /// Check if this level allows reading
  bool get allowsRead => this == PermissionLevel.readOnly || this == PermissionLevel.full;
  
  /// Check if this level allows writing
  bool get allowsWrite => this == PermissionLevel.writeOnly || this == PermissionLevel.full;
  
  /// Check if this level provides any access
  bool get hasAccess => this != PermissionLevel.none;
}

/// Event representing a change in permission status
class PermissionChangeEvent {
  final String path;
  final PermissionChangeType type;
  final PermissionLevel? oldLevel;
  final PermissionLevel newLevel;
  final DateTime timestamp;
  
  PermissionChangeEvent({
    required this.path,
    required this.type,
    this.oldLevel,
    required this.newLevel,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Get the item name from the path
  String get itemName => path.split('/').last;
  
  /// Check if this represents a permission upgrade
  bool get isUpgrade => oldLevel != null && newLevel.index > oldLevel!.index;
  
  /// Check if this represents a permission downgrade
  bool get isDowngrade => oldLevel != null && newLevel.index < oldLevel!.index;
  
  /// Get a human-readable description of the change
  String get description {
    switch (type) {
      case PermissionChangeType.granted:
        return 'Permission granted for $itemName';
      case PermissionChangeType.revoked:
        return 'Permission revoked for $itemName';
      case PermissionChangeType.updated:
        if (isUpgrade) {
          return 'Permission upgraded for $itemName';
        } else if (isDowngrade) {
          return 'Permission downgraded for $itemName';
        } else {
          return 'Permission updated for $itemName';
        }
    }
  }
  
  @override
  String toString() {
    return 'PermissionChangeEvent($description, level: $newLevel)';
  }
}

/// Type of permission change
enum PermissionChangeType {
  /// Permission was granted
  granted,
  /// Permission was revoked
  revoked,
  /// Permission level was updated
  updated,
}

/// Configuration for permission requests
class PermissionRequestConfig {
  /// Message to show to user when requesting permissions
  final String? requestMessage;
  
  /// Whether to remember the permission for future use
  final bool persistPermission;
  
  /// Timeout for permission request dialogs
  final Duration timeout;
  
  /// Whether to show detailed permission explanations
  final bool showDetailedExplanation;
  
  const PermissionRequestConfig({
    this.requestMessage,
    this.persistPermission = true,
    this.timeout = const Duration(minutes: 2),
    this.showDetailedExplanation = false,
  });
  
  /// Create config for file access requests
  factory PermissionRequestConfig.forFile(String fileName) {
    return PermissionRequestConfig(
      requestMessage: 'This app needs permission to access "$fileName".',
      persistPermission: true,
      showDetailedExplanation: false,
    );
  }
  
  /// Create config for directory access requests
  factory PermissionRequestConfig.forDirectory(String directoryName) {
    return PermissionRequestConfig(
      requestMessage: 'This app needs permission to access the "$directoryName" folder.',
      persistPermission: true,
      showDetailedExplanation: true,
    );
  }
  
  @override
  String toString() {
    return 'PermissionRequestConfig(persist: $persistPermission, timeout: ${timeout.inSeconds}s)';
  }
}

/// Extension to add capitalize method to String
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}