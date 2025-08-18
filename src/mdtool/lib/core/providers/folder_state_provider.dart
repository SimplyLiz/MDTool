import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../models/folder_metadata.dart';
import '../services/folder_index_service.dart';

/// Combined folder state including metadata and scanning status
class FolderState extends Equatable {
  final FolderMetadata? metadata;
  final bool isScanning;
  final FolderScanProgress? scanProgress;
  
  const FolderState({
    this.metadata,
    this.isScanning = false,
    this.scanProgress,
  });
  
  FolderState copyWith({
    FolderMetadata? metadata,
    bool? isScanning,
    FolderScanProgress? scanProgress,
  }) {
    return FolderState(
      metadata: metadata ?? this.metadata,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
    );
  }
  
  @override
  List<Object?> get props => [metadata?.path, metadata?.markdownFileCount, 
                              metadata?.subfolderCount, isScanning, scanProgress?.status];
}

/// Provider for folder metadata and scanning state
/// Combines cached metadata and scanning status into a single efficient stream
class FolderStateNotifier extends StateNotifier<Map<String, FolderState>> {
  FolderStateNotifier(this._folderIndexService) : super({}) {
    // Listen to scan progress for all folders
    _progressSubscription = _folderIndexService.progressStream.listen(_handleScanProgress);
    
    // Listen to cache invalidation events from watcher
    _invalidationSubscription = _folderIndexService.invalidationStream.listen(_handleInvalidation);
  }
  
  final FolderIndexService _folderIndexService;
  late final StreamSubscription<FolderScanProgress> _progressSubscription;
  late final StreamSubscription<String> _invalidationSubscription;
  
  // Debouncing for progress updates to prevent rebuild storms
  Timer? _debounceTimer;
  static const _debounceDelay = Duration(milliseconds: 50);
  
  // LRU management to prevent unbounded map growth
  static const _maxCachedFolders = 500;
  final List<String> _accessOrder = [];
  
  /// Get folder state for a specific path using canonical keys
  Future<FolderState> getFolderState(String folderPath) async {
    // Canonicalize path to prevent duplicate entries for symlinks/trailing slashes
    final canonicalPath = await _folderIndexService.canonicalizePath(folderPath);
    
    final metadata = await _folderIndexService.getCachedMetadata(folderPath);
    final isScanning = await _folderIndexService.isScanning(folderPath);
    
    final folderState = FolderState(
      metadata: metadata,
      isScanning: isScanning,
    );
    
    // Update state cache using canonical path as key with LRU management
    _updateStateWithLRU(canonicalPath, folderState);
    
    return folderState;
  }
  
  /// Handle scan progress updates using canonical paths
  void _handleScanProgress(FolderScanProgress progress) async {
    // Canonicalize progress path to match our state keys
    final canonicalPath = await _folderIndexService.canonicalizePath(progress.currentPath);
    final currentState = state[canonicalPath] ?? const FolderState();
    final updatedState = currentState.copyWith(
      scanProgress: progress,
      isScanning: progress.status == FolderScanStatus.scanning,
    );
    
    _emitDebounced(canonicalPath, updatedState);
  }
  
  /// Handle cache invalidation from filesystem watcher
  void _handleInvalidation(String invalidatedPath) async {
    // Remove invalidated entries from our state
    final canonicalPath = await _folderIndexService.canonicalizePath(invalidatedPath);
    final newState = Map<String, FolderState>.from(state);
    
    // Remove entries that are within the invalidated path
    newState.removeWhere((key, value) {
      try {
        return key == canonicalPath || 
               (canonicalPath.isNotEmpty && key.startsWith('$canonicalPath/'));
      } catch (e) {
        return false;
      }
    });
    
    // Update access order
    _accessOrder.removeWhere((path) => !newState.containsKey(path));
    
    state = newState;
  }
  
  /// Refresh folder state (typically after metadata changes)
  Future<void> refreshFolderState(String folderPath) async {
    await getFolderState(folderPath);
  }
  
  /// Debounced emit to prevent rebuild storms during rapid progress updates
  void _emitDebounced(String path, FolderState value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      _updateStateWithLRU(path, value);
    });
  }
  
  /// Update state with LRU management to prevent unbounded growth
  void _updateStateWithLRU(String canonicalPath, FolderState folderState) {
    // Remove from current position if exists
    _accessOrder.remove(canonicalPath);
    
    // Add to end (most recent)
    _accessOrder.add(canonicalPath);
    
    // Enforce LRU cap
    if (_accessOrder.length > _maxCachedFolders) {
      final oldestPath = _accessOrder.removeAt(0);
      final newState = Map<String, FolderState>.from(state);
      newState.remove(oldestPath);
      state = newState;
    } else {
      state = {...state, canonicalPath: folderState};
    }
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _progressSubscription.cancel();
    _invalidationSubscription.cancel();
    super.dispose();
  }
}

/// Provider for the folder state notifier
final folderStateProvider = StateNotifierProvider<FolderStateNotifier, Map<String, FolderState>>((ref) {
  return FolderStateNotifier(FolderIndexService.instance);
});

/// Provider for individual folder state with autoDispose to prevent memory leaks
final individualFolderStateProvider = FutureProvider.autoDispose.family<FolderState, String>((ref, folderPath) async {
  final notifier = ref.read(folderStateProvider.notifier);
  return await notifier.getFolderState(folderPath);
});