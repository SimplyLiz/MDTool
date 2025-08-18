import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestStoragePermission() async {
    if (Platform.isMacOS) {
      // macOS: No storage permission API; access is granted via folder picker
      return true;
    }
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<bool> hasStoragePermission() async {
    if (Platform.isMacOS) {
      // macOS: Always return true, permission_handler not applicable
      return true;
    }
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  Future<bool> requestDirectoryAccess(String directoryPath) async {
    if (Platform.isMacOS) {
      // macOS: Access is granted when user picks a folder
      // This should be handled via file_selector or similar
      return true;
    }
    // Non-macOS: check or request storage permission
    if (await hasStoragePermission()) return true;
    return await requestStoragePermission();
  }

  String getPermissionInstructions() {
    if (Platform.isMacOS) {
      return '''
On macOS there is no global Storage permission.
You must prompt the user to choose a folder (e.g. with file_selector) and then access files inside it.
If your app is sandboxed, enable "User Selected Read/Write" in entitlements and use security-scoped bookmarks.
''';
    }
    return 'Request Storage permission to access files on this platform.';
  }
}
