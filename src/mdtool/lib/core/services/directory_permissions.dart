import 'package:flutter/services.dart';

class DirectoryPermissionResult {
  final String path;
  final String bookmark; // base64

  DirectoryPermissionResult({required this.path, required this.bookmark});

  factory DirectoryPermissionResult.fromMap(Map m) => DirectoryPermissionResult(path: (m['path'] ?? '') as String, bookmark: (m['bookmark'] ?? '') as String);
}

class DirectoryPermissions {
  static const _channel = MethodChannel('mdtool/directory_permissions');

  static Future<List<DirectoryPermissionResult>> pick({bool multiple = true}) async {
    final res = await _channel.invokeMethod('pickDirectories', {'multiple': multiple});
    if (res == null) return [];
    
    // Handle the response format from Swift (with 'directories' key)
    if (res is Map && res.containsKey('directories')) {
      final directories = res['directories'] as List;
      return directories.cast<Map>().map(DirectoryPermissionResult.fromMap).toList();
    }
    
    // Fallback for direct array response
    return (res as List).cast<Map>().map(DirectoryPermissionResult.fromMap).toList();
  }

  static Future<List<DirectoryPermissionResult>> resolve(List<String> base64Bookmarks) async {
    final res = await _channel.invokeMethod('resolveBookmarks', base64Bookmarks);
    if (res == null) return [];
    return (res as List).cast<Map>().map(DirectoryPermissionResult.fromMap).toList();
  }
}
