import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../utils/performance_utils.dart';
import 'file_service.dart';

class AutoSaveService {
  static const Duration _autoSaveInterval = Duration(seconds: 30);
  Timer? _autoSaveTimer;
  String? _lastSavedContent;
  final Ref _ref;
  final FileService _fileService = FileService();

  AutoSaveService(this._ref);

  void startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (timer) {
      _performAutoSave();
    });
  }

  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  void _performAutoSave() async {
    final appState = _ref.read(appStateProvider);
    
    // Only auto-save if there's a file open and content has changed
    if (appState.currentFile == null || 
        !appState.isDirty || 
        appState.content == _lastSavedContent) {
      return;
    }

    try {
      await PerformanceUtils.measureAsyncPerformance('auto-save', () async {
        await _fileService.writeFile(appState.currentFile!, appState.content);
      });
      
      _lastSavedContent = appState.content;
      _ref.read(appStateProvider.notifier).saveFile();
    } catch (e) {
      // Silent failure for auto-save - user can still manually save
      // Don't show user error for auto-save failures
      // The user can still manually save
    }
  }

  void resetLastSavedContent() {
    _lastSavedContent = null;
  }

  void dispose() {
    stopAutoSave();
  }
}

// Provider for auto-save service
final autoSaveServiceProvider = Provider<AutoSaveService>((ref) {
  final service = AutoSaveService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});