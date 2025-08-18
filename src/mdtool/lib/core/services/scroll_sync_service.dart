import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'block_index.dart';

enum SyncLeader { none, editorScroll, editorCaret, previewScroll }

class ScrollSyncService {
  static final ScrollSyncService _instance = ScrollSyncService._internal();
  factory ScrollSyncService() => _instance;
  ScrollSyncService._internal();

  ScrollController? _primaryEditorController;
  ScrollController? _secondaryEditorController;
  ScrollController? _previewController;
  BlockIndex? _blockIndex;
  bool _isSyncing = false;
  bool _isEnabled = true;
  bool _scrollSyncEnabled = false; // Disable scroll sync, keep cursor sync
  bool _caretSyncEnabled = true; // Enable caret/cursor sync by default
  Timer? _debounceTimer;
  
  // Leader state machine for caret-led sync
  SyncLeader _leader = SyncLeader.none;
  DateTime _until = DateTime(0);

  void registerPrimaryEditorController(ScrollController controller) {
    _primaryEditorController = controller;
    _primaryEditorController?.addListener(_onPrimaryEditorScroll);
  }

  void registerSecondaryEditorController(ScrollController controller) {
    _secondaryEditorController = controller;
    _secondaryEditorController?.addListener(_onSecondaryEditorScroll);
  }

  void registerPreviewController(ScrollController controller) {
    _previewController = controller;
    _previewController?.addListener(_onPreviewScroll);
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  void setScrollSyncEnabled(bool enabled) {
    _scrollSyncEnabled = enabled;
  }

  void setCaretSyncEnabled(bool enabled) {
    _caretSyncEnabled = enabled;
  }

  void initializeFromPreferences({bool? scrollSyncEnabled, bool? caretSyncEnabled}) {
    // Handle mutual exclusivity during initialization
    if (scrollSyncEnabled != null && caretSyncEnabled != null) {
      if (scrollSyncEnabled && caretSyncEnabled) {
        // Both enabled in saved preferences - prioritize caret sync (our new default)
        _scrollSyncEnabled = false;
        _caretSyncEnabled = true;
      } else {
        // Normal case - set as provided
        _scrollSyncEnabled = scrollSyncEnabled;
        _caretSyncEnabled = caretSyncEnabled;
      }
    } else {
      // Individual updates
      if (scrollSyncEnabled != null) {
        _scrollSyncEnabled = scrollSyncEnabled;
      }
      if (caretSyncEnabled != null) {
        _caretSyncEnabled = caretSyncEnabled;
      }
    }
  }

  void registerBlockIndex(BlockIndex blockIndex) {
    _blockIndex = blockIndex;
  }

  BlockIndex? get blockIndex => _blockIndex;
  
  ScrollController? get previewController => _previewController;
  
  bool get isEnabled => _isEnabled;
  
  bool get scrollSyncEnabled => _scrollSyncEnabled;
  
  bool get caretSyncEnabled => _caretSyncEnabled;
  
  bool get isSyncing => _isSyncing;
  
  void setSyncing(bool syncing) {
    _isSyncing = syncing;
  }

  void takeLead(SyncLeader leader, {int ms = 400}) {
    _leader = leader;
    _until = DateTime.now().add(Duration(milliseconds: ms));
  }

  bool get canFollow =>
      DateTime.now().isAfter(_until) && !_isSyncing && _isEnabled;

  SyncLeader get leader => _leader;
  
  // Callback for preview-to-editor caret positioning
  Function(int textOffset)? _onCaretPositionRequested;
  
  void setCaretPositionCallback(Function(int textOffset)? callback) {
    _onCaretPositionRequested = callback;
  }
  
  void requestCaretPosition(int textOffset) {
    if (_caretSyncEnabled) {
      _onCaretPositionRequested?.call(textOffset);
    }
  }
  
  // Callback for preview-to-editor positioning with exact height
  Function(int textOffset, double relY)? _onCaretPositionWithHeightRequested;
  
  void setCaretPositionWithHeightCallback(Function(int textOffset, double relY)? callback) {
    _onCaretPositionWithHeightRequested = callback;
  }
  
  void requestCaretPositionWithHeight(int textOffset, double relY) {
    if (_caretSyncEnabled) {
      _onCaretPositionWithHeightRequested?.call(textOffset, relY);
    }
  }
  
  /// Get the click's relative height (relY) in the source viewport
  static double tapRelYInViewport(BuildContext context, TapDownDetails details) {
    try {
      // The viewport is the nearest Scrollable's RenderBox
      final scrollable = Scrollable.maybeOf(context);
      if (scrollable == null) {
        // Fallback: use the widget's own RenderBox
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return 0.5; // Default to middle
        
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        return (localPosition.dy / renderBox.size.height).clamp(0.0, 1.0);
      }
      
      final rb = scrollable.context.findRenderObject() as RenderBox?;
      if (rb == null) return 0.5; // Default to middle

      final viewportTopLeft = rb.localToGlobal(Offset.zero);
      final tapGlobal = details.globalPosition;
      final dyInViewport = (tapGlobal.dy - viewportTopLeft.dy)
          .clamp(0.0, rb.size.height);
      return (dyInViewport / rb.size.height).clamp(0.0, 1.0);
    } catch (e) {
      // Fallback for any other errors
      return 0.5; // Default to middle of viewport
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _primaryEditorController?.removeListener(_onPrimaryEditorScroll);
    _secondaryEditorController?.removeListener(_onSecondaryEditorScroll);
    _previewController?.removeListener(_onPreviewScroll);
    _primaryEditorController = null;
    _secondaryEditorController = null;
    _previewController = null;
  }

  void _onPrimaryEditorScroll() {
    if (!_isEnabled || _isSyncing || !_scrollSyncEnabled) return;
    _debouncedSync(() => _syncFromController(_primaryEditorController!, 'primary'));
  }

  void _onSecondaryEditorScroll() {
    if (!_isEnabled || _isSyncing || !_scrollSyncEnabled) return;
    _debouncedSync(() => _syncFromController(_secondaryEditorController!, 'secondary'));
  }

  void _debouncedSync(VoidCallback syncCallback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (!_isSyncing) {
        syncCallback();
      }
    });
  }

  void _syncFromController(ScrollController sourceController, String source) {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    final sourceOffset = sourceController.offset;
    final sourceMaxOffset = sourceController.position.maxScrollExtent;
    
    if (sourceMaxOffset > 0) {
      final scrollRatio = sourceOffset / sourceMaxOffset;
      
      // Sync to preview if available
      if (_previewController != null && _previewController!.hasClients) {
        final previewMaxOffset = _previewController!.position.maxScrollExtent;
        if (previewMaxOffset > 0) {
          final targetOffset = scrollRatio * previewMaxOffset;
          _previewController!.animateTo(
            targetOffset.clamp(0.0, previewMaxOffset),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }
      
      // Sync to other editor if available and not the source
      if (source == 'primary' && _secondaryEditorController != null && _secondaryEditorController!.hasClients) {
        final secondaryMaxOffset = _secondaryEditorController!.position.maxScrollExtent;
        if (secondaryMaxOffset > 0) {
          final targetOffset = scrollRatio * secondaryMaxOffset;
          _secondaryEditorController!.animateTo(
            targetOffset.clamp(0.0, secondaryMaxOffset),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      } else if (source == 'secondary' && _primaryEditorController != null && _primaryEditorController!.hasClients) {
        final primaryMaxOffset = _primaryEditorController!.position.maxScrollExtent;
        if (primaryMaxOffset > 0) {
          final targetOffset = scrollRatio * primaryMaxOffset;
          _primaryEditorController!.animateTo(
            targetOffset.clamp(0.0, primaryMaxOffset),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }
    }
    
    // Reset syncing flag after animation completes
    Future.delayed(const Duration(milliseconds: 150), () {
      _isSyncing = false;
    });
  }

  void _onPreviewScroll() {
    if (!_isEnabled || _isSyncing || !_scrollSyncEnabled) return;
    _debouncedSync(() => _syncFromPreview());
  }

  void _syncFromPreview() {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    final previewOffset = _previewController!.offset;
    final previewMaxOffset = _previewController!.position.maxScrollExtent;
    
    if (previewMaxOffset > 0) {
      final scrollRatio = previewOffset / previewMaxOffset;
      
      // Sync to primary editor if available
      if (_primaryEditorController != null && _primaryEditorController!.hasClients) {
        final primaryMaxOffset = _primaryEditorController!.position.maxScrollExtent;
        if (primaryMaxOffset > 0) {
          final targetOffset = scrollRatio * primaryMaxOffset;
          _primaryEditorController!.animateTo(
            targetOffset.clamp(0.0, primaryMaxOffset),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }
      
      // Sync to secondary editor if available
      if (_secondaryEditorController != null && _secondaryEditorController!.hasClients) {
        final secondaryMaxOffset = _secondaryEditorController!.position.maxScrollExtent;
        if (secondaryMaxOffset > 0) {
          final targetOffset = scrollRatio * secondaryMaxOffset;
          _secondaryEditorController!.animateTo(
            targetOffset.clamp(0.0, secondaryMaxOffset),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }
    }
    
    // Reset syncing flag after animation completes
    Future.delayed(const Duration(milliseconds: 150), () {
      _isSyncing = false;
    });
  }

  void syncToPosition(double ratio) {
    if (!_isEnabled) return;
    
    _isSyncing = true;
    
    // Sync primary editor
    if (_primaryEditorController != null && _primaryEditorController!.hasClients) {
      final primaryMaxOffset = _primaryEditorController!.position.maxScrollExtent;
      if (primaryMaxOffset > 0) {
        final primaryTargetOffset = ratio * primaryMaxOffset;
        _primaryEditorController!.animateTo(
          primaryTargetOffset.clamp(0.0, primaryMaxOffset),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
    
    // Sync secondary editor
    if (_secondaryEditorController != null && _secondaryEditorController!.hasClients) {
      final secondaryMaxOffset = _secondaryEditorController!.position.maxScrollExtent;
      if (secondaryMaxOffset > 0) {
        final secondaryTargetOffset = ratio * secondaryMaxOffset;
        _secondaryEditorController!.animateTo(
          secondaryTargetOffset.clamp(0.0, secondaryMaxOffset),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
    
    // Sync preview
    if (_previewController != null && _previewController!.hasClients) {
      final previewMaxOffset = _previewController!.position.maxScrollExtent;
      if (previewMaxOffset > 0) {
        final previewTargetOffset = ratio * previewMaxOffset;
        _previewController!.animateTo(
          previewTargetOffset.clamp(0.0, previewMaxOffset),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
    
    Future.delayed(const Duration(milliseconds: 250), () {
      _isSyncing = false;
    });
  }
}