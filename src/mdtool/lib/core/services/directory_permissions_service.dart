import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class DirectoryPermissionsService {
  static const MethodChannel _channel = MethodChannel('md_tool/directory_permissions');
  static const String _bookmarksKey = 'directory_bookmarks';

  static DirectoryPermissionsService? _instance;
  static Future<DirectoryPermissionsService> getInstance() async {
    _instance ??= DirectoryPermissionsService._();
    await _instance!._initialize();
    return _instance!;
  }

  DirectoryPermissionsService._();

  late SharedPreferences _prefs;
  List<DirectoryAccess> _accessibleDirectories = [];

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedBookmarks();
  }

  List<DirectoryAccess> get accessibleDirectories => List.unmodifiable(_accessibleDirectories);

  Future<List<DirectoryAccess>> pickDirectories({bool allowMultiple = true}) async {
    try {
      print('DEBUG: DirectoryPermissionsService.pickDirectories() called with allowMultiple: $allowMultiple');
      print('DEBUG: Invoking method channel: ${_channel.name}');
      
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('pickDirectories', {'multiple': allowMultiple});
      print('DEBUG: Method channel returned result: $result');

      if (result == null) {
        print('DEBUG: Result is null, returning empty list');
        return [];
      }

      final directories = <DirectoryAccess>[];

      if (result.containsKey('directories')) {
        final directoriesData = result['directories'] as List<dynamic>;

        for (final dirData in directoriesData) {
          final dirMap = dirData as Map<Object?, Object?>;
          final path = dirMap['path'] as String;
          final bookmark = dirMap['bookmark'] as String?;

          final directoryAccess = DirectoryAccess(path: path, bookmark: bookmark, grantedAt: DateTime.now());

          directories.add(directoryAccess);

          // Add to accessible directories if not already present
          if (!_accessibleDirectories.any((d) => d.path == path)) {
            _accessibleDirectories.add(directoryAccess);
          }
        }

        await _saveBookmarks();
      }

      print('DEBUG: Returning ${directories.length} directories');
      return directories;
    } on PlatformException catch (e) {
      print('DEBUG: PlatformException in pickDirectories: ${e.message}');
      print('DEBUG: PlatformException code: ${e.code}');
      print('DEBUG: PlatformException details: ${e.details}');
      return [];
    } catch (e, stackTrace) {
      print('DEBUG: Unexpected error in pickDirectories: $e');
      print('DEBUG: Stack trace: $stackTrace');
      return [];
    }
  }

  Future<bool> requestAccessToDirectory(String path) async {
    if (_accessibleDirectories.any((d) => d.path == path)) {
      return await _startAccessingDirectory(path);
    }
    final directories = await pickDirectories(allowMultiple: false);
    return directories.any((d) => d.path == path);
  }

  Future<bool> _startAccessingDirectory(String path) async {
    try {
      final directory = _accessibleDirectories.firstWhere((d) => d.path == path);
      if (directory.bookmark == null) return false;

      final result = await _channel.invokeMethod<bool>('startAccessingDirectory', {'bookmark': directory.bookmark});

      return result ?? false;
    } catch (e) {
      print('Error starting access to directory: $e');
      return false;
    }
  }

  Future<void> stopAccessingDirectory(String path) async {
    try {
      await _channel.invokeMethod('stopAccessingDirectory', {'path': path});
    } catch (e) {
      print('Error stopping access to directory: $e');
    }
  }

  bool hasAccessToDirectory(String path) {
    return _accessibleDirectories.any((d) => _isPathAccessible(path, d.path));
  }

  bool _isPathAccessible(String filePath, String allowedPath) {
    return filePath.startsWith(allowedPath + '/') || filePath == allowedPath;
  }

  Future<bool> canAccessFile(String filePath) async {
    if (!Platform.isMacOS) return true;
    for (final directory in _accessibleDirectories) {
      if (_isPathAccessible(filePath, directory.path)) {
        return await _startAccessingDirectory(directory.path);
      }
    }
    return false;
  }

  Future<bool> canAccessDirectoryMacOS(String path) async {
    try {
      final dir = Directory(path);

      if (!await dir.exists()) {
        return false; // path doesn't exist
      }

      // Try reading just one entry
      await dir.list(followLinks: false).take(1).toList();

      return true; // access works
    } on FileSystemException catch (e) {
      print('macOS access check failed for $path: $e');
      return false;
    }
  }

  Future<bool> canAccessDirectory(String dirPath) async {
    if (!Platform.isMacOS) return true;

    // If we already have a bookmark that covers this path, use it
    for (final directory in _accessibleDirectories) {
      if (_isPathAccessible(dirPath, directory.path)) {
        return await _startAccessingDirectory(directory.path);
      }
    }

    // Otherwise just try to read the folder

    // Fallback: try listing a file to see if permission exists
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return false;
      await dir.list(followLinks: false).take(1).toList();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  Future<void> removeDirectoryAccess(String path) async {
    _accessibleDirectories.removeWhere((d) => d.path == path);
    await _saveBookmarks();
    await stopAccessingDirectory(path);
  }

  Future<void> _loadSavedBookmarks() async {
    try {
      final bookmarksJson = _prefs.getString(_bookmarksKey);
      if (bookmarksJson != null) {
        final bookmarksList = jsonDecode(bookmarksJson) as List<dynamic>;
        _accessibleDirectories = bookmarksList.map((json) => DirectoryAccess.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
      _accessibleDirectories = [];
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final bookmarksJson = jsonEncode(_accessibleDirectories.map((d) => d.toJson()).toList());
      await _prefs.setString(_bookmarksKey, bookmarksJson);
    } catch (e) {
      print('Error saving bookmarks: $e');
    }
  }

  Future<void> clearAllAccess() async {
    for (final directory in _accessibleDirectories) {
      await stopAccessingDirectory(directory.path);
    }
    _accessibleDirectories.clear();
    await _prefs.remove(_bookmarksKey);
  }
}

class DirectoryAccess {
  final String path;
  final String? bookmark;
  final DateTime grantedAt;

  const DirectoryAccess({required this.path, this.bookmark, required this.grantedAt});

  Map<String, dynamic> toJson() {
    return {'path': path, 'bookmark': bookmark, 'grantedAt': grantedAt.toIso8601String()};
  }

  factory DirectoryAccess.fromJson(Map<String, dynamic> json) {
    return DirectoryAccess(path: json['path'] as String, bookmark: json['bookmark'] as String?, grantedAt: DateTime.parse(json['grantedAt'] as String));
  }

  @override
  String toString() => 'DirectoryAccess(path: $path, grantedAt: $grantedAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DirectoryAccess && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
