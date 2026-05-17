import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/markdown.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/providers/ai_intent_provider.dart';
import '../../core/utils/undo_redo_controller.dart';
import '../../core/services/auto_save_service.dart';
import '../../core/services/search_service.dart';
import '../../core/services/markdown_shortcuts_service.dart';
import '../../core/services/scroll_sync_service.dart';
import '../../core/services/quicklook_service.dart';
import 'find_dialog.dart';
import 'ai/selection_detector.dart';
import 'ai/ai_action.dart';

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class FindIntent extends Intent {
  const FindIntent();
}

class _CloseDialogIntent extends Intent {
  const _CloseDialogIntent();
}

class _ToggleModeIntent extends Intent {
  const _ToggleModeIntent();
}

class _ToggleDarkModeIntent extends Intent {
  const _ToggleDarkModeIntent();
}

// Markdown formatting intents
class BoldIntent extends Intent {
  const BoldIntent();
}

class ItalicIntent extends Intent {
  const ItalicIntent();
}

class CodeIntent extends Intent {
  const CodeIntent();
}

class LinkIntent extends Intent {
  const LinkIntent();
}

class HeaderIntent extends Intent {
  final int level;
  const HeaderIntent(this.level);
}

class QuickLookIntent extends Intent {
  const QuickLookIntent();
}

class MarkdownEditor extends ConsumerStatefulWidget {
  const MarkdownEditor({super.key});

  @override
  ConsumerState<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends ConsumerState<MarkdownEditor> {
  late CodeController _codeController;
  late UndoRedoTextEditingController _textController;
  late ScrollController _scrollController;
  late ScrollSyncService _scrollSyncService;
  bool _isInitialized = false;
  bool _showFindDialog = false;
  List<SearchMatch> _searchMatches = [];
  int _currentMatchIndex = -1;
  int? _lastScrollRequestId;
  
  // Anchor-based sync variables
  double? _lastPreviewTarget; // preview pixel target
  double _gain = 0.35;        // < 1.0 = slower/softer catching up
  int _minPixelsDelta = 8;    // ignore tiny jitter
  
  // Caret-led sync variables
  late int _lastBaseOffset = -1;
  int? _lastCaretBlockStart;
  Timer? _caretDebounce;
  
  // Line start offsets cache for precision
  List<int> _lineStartOffsets = [];
  
  // Editor-leader lock for scroll sync
  bool get _isEditorLeader => true;
  
  // Track vertical scroll position to detect horizontal vs vertical scrolling
  double _lastVerticalScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollSyncService = ScrollSyncService();
    _initializeController();
    
    // Listen to caret/selection changes for caret-led sync
    _codeController.addListener(_onSelectionOrTextChanged);
    
    // Register callback for preview-to-editor caret positioning
    _scrollSyncService.setCaretPositionCallback(_onCaretPositionRequested);
    _scrollSyncService.setCaretPositionWithHeightCallback(_onCaretPositionWithHeightRequested);
  }

  void _initializeController() {
    final appState = ref.read(appStateProvider);
    
    _textController = UndoRedoTextEditingController(text: appState.content);
    _codeController = CodeController(
      text: appState.content,
      language: markdown,
    );

    // Listen to text changes and update app state
    _codeController.addListener(() {
      if (_isInitialized && mounted) {
        try {
          _textController.text = _codeController.text;
          // Defer provider update to avoid modifying during build
          Future(() => ref.read(appStateProvider.notifier).updateContent(_codeController.text));
          _updateLineStartOffsets(_codeController.text);
        } catch (e) {
          // Ignore updates after disposal
        }
      }
    });

    // Start auto-save when editor is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autoSaveServiceProvider).startAutoSave();
    });
    
    // Initialize line start offsets cache
    _updateLineStartOffsets(appState.content);

    _isInitialized = true;
  }

  @override
  void dispose() {
    try {
      ref.read(autoSaveServiceProvider).stopAutoSave();
    } catch (e) {
      // Ignore disposal errors - widget is already unmounted
    }
    _caretDebounce?.cancel();
    _scrollSyncService.setCaretPositionCallback(null);
    _scrollSyncService.setCaretPositionWithHeightCallback(null);
    _scrollController.dispose();
    _codeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _showFind() {
    setState(() {
      _showFindDialog = true;
    });
  }

  void _closeFind() {
    setState(() {
      _showFindDialog = false;
      _searchMatches.clear();
      _currentMatchIndex = -1;
    });
  }

  void _onSearch(String query, bool matchCase, bool wholeWord) {
    final matches = SearchService.findMatches(
      _codeController.text,
      query,
      matchCase: matchCase,
      wholeWord: wholeWord,
    );

    setState(() {
      _searchMatches = matches;
      _currentMatchIndex = matches.isNotEmpty ? 0 : -1;
    });

    // Scroll to the first match if any matches found
    if (matches.isNotEmpty) {
      final firstMatch = matches[0];
      _codeController.selection = TextSelection(
        baseOffset: firstMatch.start,
        extentOffset: firstMatch.end,
      );
    }

    // Match count will be updated in the dialog directly
  }

  void _navigateMatch(bool forward) {
    if (_searchMatches.isEmpty) return;

    final newIndex = SearchService.getNextMatchIndex(
      _currentMatchIndex,
      _searchMatches.length,
      forward,
    );

    if (newIndex >= 0) {
      setState(() {
        _currentMatchIndex = newIndex;
      });

      // Scroll to the current match by setting selection
      final currentMatch = _searchMatches[newIndex];
      _codeController.selection = TextSelection(
        baseOffset: currentMatch.start,
        extentOffset: currentMatch.end,
      );
    }
  }

  void _applyMarkdownOperation(MarkdownOperation operation) {
    _codeController.text = operation.newText;
    _codeController.selection = operation.newSelection;
    _textController.text = operation.newText;
    
    ref.read(appStateProvider.notifier).updateContent(operation.newText);
  }


  void _handleScrollRequest(String? heading, int? requestId) {
    if (heading == null || requestId == null || _lastScrollRequestId == requestId) {
      return;
    }
    
    _lastScrollRequestId = requestId;
    print('Editor: Handling scroll request for heading: $heading');
    
    // Clear the scroll request after handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStateProvider.notifier).clearScrollRequest();
    });
    
    _scrollToHeadingInEditor(heading);
  }

  void _scrollToHeadingInEditor(String heading) {
    if (!_scrollController.hasClients) return;
    
    final content = _codeController.text;
    final lines = content.split('\n');
    
    int targetLine = 0;
    bool found = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      // Check for markdown headings that contain our target text
      if (line.startsWith('#') && 
          line.toLowerCase().contains(heading.toLowerCase())) {
        targetLine = i;
        found = true;
        print('Editor: Found heading "$heading" at line $targetLine');
        break;
      }
    }
    
    if (found) {
      // Estimate scroll position based on line number
      final estimatedHeight = targetLine * 20.0; // Approximate line height in editor
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetScroll = (estimatedHeight).clamp(0.0, maxScroll);
      
      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      
      // Also move cursor to that line if possible
      try {
        int cursorPosition = 0;
        for (int i = 0; i < targetLine; i++) {
          cursorPosition += lines[i].length + 1; // +1 for newline
        }
        _codeController.selection = TextSelection.collapsed(offset: cursorPosition);
      } catch (e) {
        print('Editor: Could not move cursor: $e');
      }
      
      print('Editor: Scrolling to estimated position: $targetScroll');
    } else {
      print('Editor: Heading "$heading" not found in content');
    }
  }

  double get _lineExtent {
    // Approximate line height (monospace): fontSize * height
    final preferencesAsync = ref.read(preferencesProvider);
    if (!preferencesAsync.hasValue) return 21.0; // fallback
    
    final preferences = preferencesAsync.value!;
    return preferences.fontSize * 1.5; // matches textStyle height
  }

  Future<void> _syncPreviewToEditorTop(ScrollMetrics metrics) async {
    final blockIndex = _scrollSyncService.blockIndex;
    final previewController = _scrollSyncService.previewController;

    if (!_isEditorLeader ||
        !_scrollSyncService.scrollSyncEnabled ||
        blockIndex == null ||
        previewController == null ||
        !previewController.hasClients) return;

    final topLine = (metrics.pixels / _lineExtent).floor();
    final block = blockIndex.blockForLine(topLine);
    if (block == null || block.key.currentContext == null) return;

    final ro = block.key.currentContext!.findRenderObject() as RenderBox?;
    if (ro == null) return;

    final viewport = RenderAbstractViewport.of(ro);
    final reveal = viewport?.getOffsetToReveal(ro, 0.0).offset ?? 0.0;

    _scrollSyncService.setSyncing(true);
    await previewController.animateTo(
      reveal,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
    _scrollSyncService.setSyncing(false);
  }


  Future<void> _anchorToTopBlock(ScrollMetrics metrics) async {
    final svc = _scrollSyncService;
    if (!svc.canFollow || svc.leader == SyncLeader.previewScroll) return;

    final preview = svc.previewController;
    final index = svc.blockIndex;
    if (preview == null || !preview.hasClients || index == null || index.blocks.isEmpty) return;

    // Estimate top visible line in editor
    final topLine = (metrics.pixels / _lineExtent).floor().clamp(0, 1 << 30);

    // Find the topmost visible block
    final topBlock = index.blockForLine(topLine);
    if (topBlock?.key.currentContext == null) return;

    final ro = topBlock!.key.currentContext!.findRenderObject();
    final viewport = RenderAbstractViewport.of(ro!);
    if (viewport == null) return;

    // Gently anchor to the top of the preview viewport
    final target = viewport.getOffsetToReveal(ro, 0.0).offset
        .clamp(0.0, preview.position.maxScrollExtent);

    svc.setSyncing(true);
    await preview.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
    svc.setSyncing(false);
  }

  Future<void> _onEditorTap(TapDownDetails details) async {
    // Check if caret sync is enabled
    if (!_scrollSyncService.caretSyncEnabled) return;
    
    final relY = ScrollSyncService.tapRelYInViewport(context, details);

    // Let CodeField update selection first
    await Future.microtask(() {});

    final caretLine = _offsetToLine(_codeController.selection.baseOffset);
    final b = _scrollSyncService.blockIndex?.blockForLine(caretLine);
    final preview = _scrollSyncService.previewController;
    
    if (b?.key.currentContext == null || preview == null || !preview.hasClients) return;

    final ro = b!.key.currentContext!.findRenderObject();
    final vp = RenderAbstractViewport.of(ro!);
    if (vp == null) return;

    // Reveal at the exact same relative height
    final target = vp.getOffsetToReveal(ro, relY).offset
        .clamp(0.0, preview.position.maxScrollExtent);

    _scrollSyncService.takeLead(SyncLeader.editorCaret, ms: 300);
    _scrollSyncService.setSyncing(true);
    await preview.animateTo(
      target,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
    );
    _scrollSyncService.setSyncing(false);
  }

  void _onCaretPositionRequested(int textOffset) {
    if (!mounted) return;
    
    // Set the caret position in the editor
    final clampedOffset = textOffset.clamp(0, _codeController.text.length);
    _codeController.selection = TextSelection.collapsed(offset: clampedOffset);
    
    // Take lead to trigger caret sync back to preview (completing the loop)
    _scrollSyncService.takeLead(SyncLeader.editorCaret, ms: 300);
  }

  Future<void> _onCaretPositionWithHeightRequested(int textOffset, double relY) async {
    if (!mounted) return;
    
    // Set the caret position in the editor
    final clampedOffset = textOffset.clamp(0, _codeController.text.length);
    _codeController.selection = TextSelection.collapsed(offset: clampedOffset);
    
    // Get the line for this offset
    final line = _offsetToLine(clampedOffset);
    
    // Try to get editor's scroll position (may fail due to CodeField limitations)
    try {
      final scrollable = Scrollable.of(context);
      final editorPos = scrollable?.position;
      if (editorPos != null) {
        final editorViewportRb = scrollable!.context.findRenderObject() as RenderBox;
        final editorViewportH = editorViewportRb.size.height;
        
        // Calculate target scroll position to show this line at the same relY
        final targetPixels = line * _lineExtent - relY * editorViewportH;
        final clamped = targetPixels.clamp(0.0, editorPos.maxScrollExtent);

        _scrollSyncService.takeLead(SyncLeader.editorCaret, ms: 300);
        _scrollSyncService.setSyncing(true);
        await editorPos.animateTo(
          clamped,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
        );
        _scrollSyncService.setSyncing(false);
      }
    } catch (e) {
      // If we can't scroll the editor (CodeField limitations), just set caret
      _scrollSyncService.takeLead(SyncLeader.editorCaret, ms: 300);
    }
  }

  void _onSelectionOrTextChanged() {
    // Fire on caret move (and text change). We'll filter below.
    if (!mounted) return;
    _scheduleCaretSync();
  }

  void _scheduleCaretSync() {
    final sel = _codeController.selection;
    if (!sel.isValid) return;
    
    final line = _offsetToLine(sel.baseOffset);
    final b = _scrollSyncService.blockIndex?.blockForLine(line);
    final blockChanged = (b?.startLine != _lastCaretBlockStart);
    
    // Only sync when caret moves to different block (not while typing in same block)
    if (!blockChanged) return;

    _lastCaretBlockStart = b?.startLine;
    _caretDebounce?.cancel();
    _caretDebounce = Timer(const Duration(milliseconds: 10), () {
      _syncPreviewToCaret(sel.baseOffset);
    });
  }

  int _offsetToLine(int offset) {
    final text = _codeController.text;
    final o = offset.clamp(0, text.length);
    var line = 0;
    for (int i = 0; i < o; i++) {
      if (text.codeUnitAt(i) == 10) line++; // '\n' = 10
    }
    return line;
  }

  void _updateLineStartOffsets(String content) {
    _lineStartOffsets.clear();
    _lineStartOffsets.add(0); // First line starts at offset 0
    
    for (int i = 0; i < content.length; i++) {
      if (content.codeUnitAt(i) == 10) { // '\n' = 10
        _lineStartOffsets.add(i + 1); // Next line starts after the newline
      }
    }
  }

  int _lineToTextOffset(int line) {
    if (line < 0 || line >= _lineStartOffsets.length) {
      return _codeController.text.length;
    }
    return _lineStartOffsets[line];
  }


  Future<void> _syncPreviewToCaret(int baseOffset) async {
    final svc = _scrollSyncService;
    if (!svc.canFollow || svc.leader == SyncLeader.previewScroll || !svc.caretSyncEnabled) return;

    svc.takeLead(SyncLeader.editorCaret, ms: 250);

    final preview = svc.previewController;
    final index = svc.blockIndex;
    if (preview == null || !preview.hasClients || index == null || index.blocks.isEmpty) return;

    // 1) caret line
    final caretLine = _offsetToLine(baseOffset);

    // 2) find the preview block for that caret line
    final b = index.blockForLine(caretLine);
    if (b?.key.currentContext == null) return;

    final ro = b!.key.currentContext!.findRenderObject();
    final viewport = RenderAbstractViewport.of(ro!);
    if (viewport == null) return;

    // Since we can't access CodeField's internal scroll position,
    // we'll use a simplified approach: align the block containing the caret
    // to a reasonable position (slightly below top for better visibility)
    final alignment = 0.2; // Place block 20% from top of preview viewport

    final target = viewport.getOffsetToReveal(ro, alignment).offset
        .clamp(0.0, preview.position.maxScrollExtent);

    // 3) smooth follow
    svc.setSyncing(true);
    await preview.animateTo(
      target,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
    );
    svc.setSyncing(false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final preferencesAsync = ref.watch(preferencesProvider);
    
    // Update editor content when app state changes
    if (_codeController.text != appState.content) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _codeController.text = appState.content;
          _textController.text = appState.content;
        }
      });
      
      // Re-anchor after content changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _syncPreviewToEditorTop(_scrollController.position);
        }
      });
    }
    
    // Handle scroll requests
    _handleScrollRequest(appState.scrollToHeading, appState.scrollRequestId);

    return preferencesAsync.when(
      data: (preferences) => Column(
        children: [
          if (_showFindDialog)
            FindDialog(
              initialText: '',
              onSearch: _onSearch,
              onClose: _closeFind,
              onNavigate: _navigateMatch,
            ),
          Expanded(
            child: Shortcuts(
              shortcuts: {
                // Basic operations
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ): const UndoIntent(),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): const RedoIntent(),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyY): const RedoIntent(),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF): const FindIntent(),
                LogicalKeySet(LogicalKeyboardKey.escape): const _CloseDialogIntent(),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyR): const _ToggleModeIntent(),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyD): const _ToggleDarkModeIntent(),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyY): const QuickLookIntent(),
                
                // Markdown formatting
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyB): const BoldIntent(),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyI): const ItalicIntent(),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyE): const CodeIntent(),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const LinkIntent(),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit1): const HeaderIntent(1),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit2): const HeaderIntent(2),
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit3): const HeaderIntent(3),
              },
              child: Actions(
                actions: {
                  UndoIntent: CallbackAction<UndoIntent>(
                    onInvoke: (intent) {
                      _textController.undo();
                      _codeController.text = _textController.text;
                      return null;
                    },
                  ),
                  RedoIntent: CallbackAction<RedoIntent>(
                    onInvoke: (intent) {
                      _textController.redo();
                      _codeController.text = _textController.text;
                      return null;
                    },
                  ),
                  FindIntent: CallbackAction<FindIntent>(
                    onInvoke: (intent) {
                      _showFind();
                      return null;
                    },
                  ),
                  _CloseDialogIntent: CallbackAction<_CloseDialogIntent>(
                    onInvoke: (intent) {
                      if (_showFindDialog) {
                        _closeFind();
                      }
                      return null;
                    },
                  ),
                  _ToggleModeIntent: CallbackAction<_ToggleModeIntent>(
                    onInvoke: (intent) {
                      ref.read(appStateProvider.notifier).toggleMode();
                      return null;
                    },
                  ),
                  _ToggleDarkModeIntent: CallbackAction<_ToggleDarkModeIntent>(
                    onInvoke: (intent) {
                      final prefs = ref.read(preferencesProvider).value;
                      if (prefs != null) {
                        ref.read(preferencesProvider.notifier).setDarkMode(!prefs.isDarkMode);
                      }
                      return null;
                    },
                  ),
                  // Markdown formatting actions
                  BoldIntent: CallbackAction<BoldIntent>(
                    onInvoke: (intent) {
                      final currentSelection = _codeController.selection;
                      final operation = MarkdownShortcutsService.makeBold(
                        _codeController.text,
                        currentSelection,
                      );
                      _applyMarkdownOperation(operation);
                      return null;
                    },
                  ),
                  ItalicIntent: CallbackAction<ItalicIntent>(
                    onInvoke: (intent) {
                      final currentSelection = _codeController.selection;
                      final operation = MarkdownShortcutsService.makeItalic(
                        _codeController.text,
                        currentSelection,
                      );
                      _applyMarkdownOperation(operation);
                      return null;
                    },
                  ),
                  CodeIntent: CallbackAction<CodeIntent>(
                    onInvoke: (intent) {
                      final currentSelection = _codeController.selection;
                      final operation = MarkdownShortcutsService.makeCode(
                        _codeController.text,
                        currentSelection,
                      );
                      _applyMarkdownOperation(operation);
                      return null;
                    },
                  ),
                  LinkIntent: CallbackAction<LinkIntent>(
                    onInvoke: (intent) {
                      final currentSelection = _codeController.selection;
                      final operation = MarkdownShortcutsService.makeLink(
                        _codeController.text,
                        currentSelection,
                      );
                      _applyMarkdownOperation(operation);
                      return null;
                    },
                  ),
                  HeaderIntent: CallbackAction<HeaderIntent>(
                    onInvoke: (intent) {
                      final currentSelection = _codeController.selection;
                      final operation = MarkdownShortcutsService.insertHeader(
                        _codeController.text,
                        currentSelection,
                        intent.level,
                      );
                      _applyMarkdownOperation(operation);
                      return null;
                    },
                  ),
                  QuickLookIntent: CallbackAction<QuickLookIntent>(
                    onInvoke: (intent) {
                      final appState = ref.read(appStateProvider);
                      if (appState.currentFile != null) {
                        QuickLookService.showQuickLook(appState.currentFile!);
                      }
                      return null;
                    },
                  ),
                },
                child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        final isUpdate = n is ScrollUpdateNotification;
                        final isUser = n is UserScrollNotification && n.direction != ScrollDirection.idle;

                        if (!(isUpdate || isUser)) return false;

                        // Only respond to vertical scrolling - ignore horizontal scrolling
                        final metrics = n.metrics;
                        final currentVerticalPosition = metrics.pixels;
                        
                        // Check if the vertical position actually changed
                        final verticalChanged = (currentVerticalPosition - _lastVerticalScrollPosition).abs() > 0.1;
                        
                        if (!verticalChanged) {
                          return false; // No vertical movement, likely horizontal scroll
                        }
                        
                        // Update tracked position
                        _lastVerticalScrollPosition = currentVerticalPosition;
                        
                        // Ensure there's vertical content to scroll
                        if (metrics.maxScrollExtent <= 0) return false;
                        
                        // For UserScrollNotification, also check direction
                        if (n is UserScrollNotification) {
                          if (n.direction != ScrollDirection.forward && n.direction != ScrollDirection.reverse) {
                            return false; // Ignore non-vertical directions
                          }
                        }

                        if (_isEditorLeader && _scrollSyncService.scrollSyncEnabled) {
                          _syncPreviewToEditorTop(n.metrics);
                        }
                        return false;
                      },
                      child: SelectionDetector(
                        controller: _codeController,
                        onAction: (AIIntent intent) =>
                            ref.read(aiIntentProvider.notifier).state = intent,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (details) => _onEditorTap(details),
                          child: CodeField(
                            controller: _codeController,
                            textStyle: TextStyle(
                              fontFamily: preferences.fontFamily,
                              fontSize: preferences.fontSize,
                              height: 1.5,
                            ),
                            decoration: const BoxDecoration(),
                            padding: const EdgeInsets.all(16),
                            expands: true,
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading preferences: $error'),
      ),
    );
  }
}