import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'editor_view.dart';
import 'markdown_preview.dart';
import 'window_header.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/file_service.dart';
import '../../core/services/scroll_sync_service.dart';
import '../../core/models/app_state.dart';
import 'toolbar.dart' show syncStateProvider;
import '../../core/providers/preferences_provider.dart';

class SplitScreenView extends ConsumerWidget {
  const SplitScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    
    // Sync scroll service with app state
    ScrollSyncService().setEnabled(appState.isScrollSyncEnabled);
    
    return Column(
      children: [
        // Toolbar
        _buildToolbar(context, ref, appState),
        // Main content
        Expanded(
          child: Row(
            children: [
              // Primary editor with header
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      WindowHeader(
                        windowType: WindowType.editor,
                        activeWindowType: ActiveWindow.primary,
                        filePath: appState.currentFile,
                        onOpenFile: () => WindowHeaderActions.openFileDialog(ref),
                        onNewFile: () => WindowHeaderActions.createNewFile(ref),
                        onChat: appState.currentFile != null 
                            ? () => WindowHeaderActions.openChatWithFile(context, appState.currentFile)
                            : null,
                        onClose: appState.currentFile != null
                            ? () => ref.read(appStateProvider.notifier).closeFile()
                            : null,
                        onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.primary),
                      ),
                      Expanded(
                        child: DragTarget<String>(
                          onAccept: (filePath) => _handlePrimaryPaneDrop(filePath, ref),
                          onWillAccept: (data) {
                            debugPrint('PRIMARY PANE onWillAccept: $data');
                            return data != null && data.isNotEmpty;
                          },
                          builder: (context, candidateData, rejectedData) {
                            return GestureDetector(
                              onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.primary),
                              child: Container(
                                decoration: candidateData.isNotEmpty
                                    ? BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        border: Border.all(
                                          color: Theme.of(context).primaryColor,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      )
                                    : null,
                                child: const EditorView(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right pane: Either secondary editor or preview with header
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.only(left: 8),
                  child: appState.isPreviewVisible 
                      ? Column(
                          children: [
                            WindowHeader(
                              windowType: WindowType.preview,
                              activeWindowType: ActiveWindow.preview,
                              filePath: appState.currentFile,
                              onOpenFile: () => WindowHeaderActions.openFileDialog(ref),
                              onNewFile: () => WindowHeaderActions.createNewFile(ref),
                              onChat: appState.currentFile != null 
                                  ? () => WindowHeaderActions.openChatWithFile(context, appState.currentFile)
                                  : null,
                              onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.preview),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.preview),
                                child: const MarkdownPreview(),
                              ),
                            ),
                          ],
                        )
                      : (appState.secondaryFile != null
                          ? Column(
                              children: [
                                WindowHeader(
                                  windowType: WindowType.editor,
                                  activeWindowType: ActiveWindow.secondary,
                                  filePath: appState.secondaryFile,
                                  onOpenFile: () => WindowHeaderActions.openFileDialog(ref, isSecondary: true),
                                  onNewFile: () => WindowHeaderActions.createNewFile(ref, isSecondary: true),
                                  onChat: appState.secondaryFile != null 
                                      ? () => WindowHeaderActions.openChatWithFile(context, appState.secondaryFile)
                                      : null,
                                  onClose: () => ref.read(appStateProvider.notifier).closeSecondaryFile(),
                                  onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.secondary),
                                ),
                                Expanded(
                                  child: DragTarget<String>(
                                    onAccept: (filePath) => _handleSecondaryPaneDrop(filePath, ref),
                                    onWillAccept: (data) {
                                      debugPrint('SECONDARY PANE onWillAccept: $data');
                                      return data != null && data.isNotEmpty;
                                    },
                                    builder: (context, candidateData, rejectedData) {
                                      return GestureDetector(
                                        onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.secondary),
                                        child: Container(
                                          decoration: candidateData.isNotEmpty
                                              ? BoxDecoration(
                                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                  border: Border.all(
                                                    color: Theme.of(context).primaryColor,
                                                    width: 2,
                                                  ),
                                                  borderRadius: BorderRadius.circular(4),
                                                )
                                              : null,
                                          child: SecondaryEditorView(
                                            filePath: appState.secondaryFile!,
                                            content: appState.secondaryContent,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                WindowHeader(
                                  windowType: WindowType.editor,
                                  activeWindowType: ActiveWindow.secondary,
                                  filePath: null,
                                  onOpenFile: () => WindowHeaderActions.openFileDialog(ref, isSecondary: true),
                                  onNewFile: () => WindowHeaderActions.createNewFile(ref, isSecondary: true),
                                  onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.secondary),
                                ),
                                Expanded(child: _buildSecondaryPlaceholder(context, ref)),
                              ],
                            )),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryPlaceholder(BuildContext context, WidgetRef ref) {
    return DragTarget<String>(
      onAccept: (filePath) => _handleSecondaryPaneDrop(filePath, ref),
      onWillAccept: (data) => data != null && data.isNotEmpty,
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: candidateData.isNotEmpty
              ? BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  candidateData.isNotEmpty 
                      ? Icons.file_upload 
                      : Icons.description_outlined,
                  size: 64,
                  color: candidateData.isNotEmpty 
                      ? Theme.of(context).primaryColor
                      : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  candidateData.isNotEmpty 
                      ? 'Drop file to open in secondary pane'
                      : 'Choose what to show in the right pane',
                  style: TextStyle(
                    fontSize: 18,
                    color: candidateData.isNotEmpty 
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                if (candidateData.isEmpty) ...[
                  // Open a file button
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: () => _openSecondaryFile(ref),
                      icon: const Icon(Icons.folder_open, size: 20),
                      label: const Text('Open a File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Create new file button
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: () => ref.read(appStateProvider.notifier).createNewSecondaryFile(),
                      icon: const Icon(Icons.note_add, size: 20),
                      label: const Text('Create New File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSecondaryFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'mdown', 'mkd', 'mkdn'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileService = FileService();
        final content = await fileService.readFile(filePath);
        ref.read(appStateProvider.notifier).openSecondaryFile(filePath, content);
      }
    } catch (e) {
      // Handle error - could show a dialog or snackbar
      debugPrint('Failed to open secondary file: $e');
    }
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref, AppState appState) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Split Screen: ${appState.isPreviewVisible ? 'Preview Mode' : 'Dual Editor Mode'}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          // Preview toggle
          IconButton(
            icon: Icon(
              appState.isPreviewVisible ? Icons.preview : Icons.visibility,
              size: 18,
              color: appState.isPreviewVisible
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () => ref.read(appStateProvider.notifier).togglePreviewVisibility(),
            tooltip: appState.isPreviewVisible ? 'Show Second File Editor' : 'Edit with Live Preview',
          ),
          // Sync controls (only show in preview mode)
          _buildSyncControls(context, ref, appState),
        ],
      ),
    );
  }

  Widget _buildSyncControls(BuildContext context, WidgetRef ref, AppState appState) {
    // Only show sync controls in preview mode (not in dual editor mode)
    if (!appState.isPreviewVisible) {
      return const SizedBox.shrink();
    }
    
    final syncState = ref.watch(syncStateProvider);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scroll sync toggle
        IconButton(
          icon: Icon(
            Icons.sync,
            size: 18,
            color: syncState.scrollSyncEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: () => _toggleScrollSync(ref),
          tooltip: syncState.scrollSyncEnabled ? 'Disable Scroll Sync' : 'Enable Scroll Sync',
        ),
        // Caret sync toggle
        IconButton(
          icon: Icon(
            Icons.center_focus_strong,
            size: 18,
            color: syncState.caretSyncEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: () => _toggleCaretSync(ref),
          tooltip: syncState.caretSyncEnabled ? 'Disable Caret Sync' : 'Enable Caret Sync',
        ),
      ],
    );
  }

  void _toggleScrollSync(WidgetRef ref) async {
    final syncStateNotifier = ref.read(syncStateProvider.notifier);
    final currentState = ref.read(syncStateProvider);
    final newState = !currentState.scrollSyncEnabled;
    
    // Update the service and local state (includes mutual exclusivity)
    syncStateNotifier.updateScrollSync(newState);
    
    // Update preferences (includes mutual exclusivity)
    final preferencesNotifier = ref.read(preferencesProvider.notifier);
    await preferencesNotifier.setScrollSyncEnabled(newState);
  }

  void _toggleCaretSync(WidgetRef ref) async {
    final syncStateNotifier = ref.read(syncStateProvider.notifier);
    final currentState = ref.read(syncStateProvider);
    final newState = !currentState.caretSyncEnabled;
    
    // Update the service and local state (includes mutual exclusivity)
    syncStateNotifier.updateCaretSync(newState);
    
    // Update preferences (includes mutual exclusivity)
    final preferencesNotifier = ref.read(preferencesProvider.notifier);
    await preferencesNotifier.setCaretSyncEnabled(newState);
  }

  Future<void> _handlePrimaryPaneDrop(String filePath, WidgetRef ref) async {
    debugPrint('PRIMARY PANE DROP: $filePath');
    try {
      // Set active window to primary first
      ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.primary);
      
      final fileService = FileService();
      final content = await fileService.readFile(filePath);
      ref.read(appStateProvider.notifier).openFile(filePath, content);
      debugPrint('PRIMARY PANE DROP: Successfully opened $filePath');
    } catch (e) {
      // Handle error
      debugPrint('Error opening file in primary pane: $e');
    }
  }

  Future<void> _handleSecondaryPaneDrop(String filePath, WidgetRef ref) async {
    debugPrint('SECONDARY PANE DROP: $filePath');
    try {
      // Set active window to secondary first  
      ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.secondary);
      
      final fileService = FileService();
      final content = await fileService.readFile(filePath);
      ref.read(appStateProvider.notifier).openSecondaryFile(filePath, content);
      debugPrint('SECONDARY PANE DROP: Successfully opened $filePath');
    } catch (e) {
      // Handle error
      debugPrint('Error opening file in secondary pane: $e');
    }
  }
}

class SecondaryEditorView extends ConsumerStatefulWidget {
  final String filePath;
  final String content;

  const SecondaryEditorView({
    super.key,
    required this.filePath,
    required this.content,
  });

  @override
  ConsumerState<SecondaryEditorView> createState() => _SecondaryEditorViewState();
}

class _SecondaryEditorViewState extends ConsumerState<SecondaryEditorView> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  late ScrollSyncService _scrollSyncService;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
    _scrollController = ScrollController();
    _scrollSyncService = ScrollSyncService();
    _scrollSyncService.registerSecondaryEditorController(_scrollController);
  }

  @override
  void didUpdateWidget(SecondaryEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _controller.text = widget.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: TextField(
          controller: _controller,
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
            hintText: 'Secondary editor...',
          ),
          onChanged: (value) {
            ref.read(appStateProvider.notifier).updateSecondaryContent(value);
          },
        ),
      ),
    );
  }
}