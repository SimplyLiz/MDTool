import 'package:flutter/services.dart';

class NativeBridgeService {
  static const MethodChannel _channel = MethodChannel('quicklook_channel');

  /// Shows Quick Look preview for the specified file path
  static Future<void> showQuickLook(String filePath) async {
    try {
      await _channel.invokeMethod('showQuickLook', {'filePath': filePath});
    } catch (e) {
      print('🔍 QuickLook failed: $e');
    }
  }

  /// Shows the specified file in Finder
  static Future<void> showInFinder(String filePath) async {
    try {
      await _channel.invokeMethod('showInFinder', {'filePath': filePath});
    } catch (e) {
      print('📁 Show in Finder failed: $e');
    }
  }
}