import 'package:flutter/services.dart';
import 'dart:io';

class QuickLookService {
  static const MethodChannel _channel = MethodChannel('quicklook_channel');
  
  /// Show QuickLook preview for the specified file path
  /// Returns true if successful, false if there was an error
  static Future<bool> showQuickLook(String filePath) async {
    try {
      // Verify file exists before attempting to preview
      final file = File(filePath);
      if (!await file.exists()) {
        print('QuickLook error: File does not exist: $filePath');
        return false;
      }

      await _channel.invokeMethod('showQuickLook', {'filePath': filePath});
      return true;
    } catch (e) {
      print('QuickLook error: $e');
      return false;
    }
  }
}