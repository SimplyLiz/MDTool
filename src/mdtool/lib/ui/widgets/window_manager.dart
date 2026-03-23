import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/models/app_state.dart';
import '../../core/services/file_service.dart';
import '../widgets/editor_view.dart';
import '../widgets/markdown_preview.dart';
import '../widgets/split_screen_view.dart';
import '../widgets/window_header.dart';
import '../widgets/window_layout.dart';
import '../widgets/window_pane.dart';
import '../widgets/toolbar.dart';

class WindowManager extends ConsumerWidget {
  const WindowManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    
    if (appState.isSplitScreenMode) {
      return _buildSplitScreen(context, ref, appState);
    } else {
      return _buildSinglePane(context, ref, appState);
    }
  }

  Widget _buildSinglePane(BuildContext context, WidgetRef ref, AppState appState) {
    final paneConfig = WindowPaneConfig(
      type: WindowPaneType.editor,
      activeWindow: ActiveWindow.primary,
      filePath: appState.currentFile,
      isActive: appState.activeWindow == ActiveWindow.primary,
      onOpenFile: () => WindowHeaderActions.openFileDialog(ref),
      onNewFile: () => WindowHeaderActions.createNewFile(ref),
      onChat: appState.currentFile != null 
          ? () => WindowHeaderActions.openChatWithFile(context, appState.currentFile)
          : null,
      onSave: () => _saveFile(ref, context),
      onClose: appState.currentFile != null
          ? () => _closeFileWithConfirmation(context, ref)
          : null,
      onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.primary),
      placeholder: appState.currentFile == null ? _buildPrimaryPlaceholder(context, ref) : null,
    );

    final layoutConfig = WindowLayoutConfig(
      mode: LayoutMode.single,
      panes: [paneConfig],
    );

    return WindowLayout(
      config: layoutConfig,
      paneWidgets: {
        paneConfig: const EditorView(),
      },
    );
  }

  Widget _buildSplitScreen(BuildContext context, WidgetRef ref, AppState appState) {
    final primaryPane = WindowPaneConfig(
      type: WindowPaneType.editor,
      activeWindow: ActiveWindow.primary,
      filePath: appState.currentFile,
      isActive: appState.activeWindow == ActiveWindow.primary,
      onOpenFile: () => WindowHeaderActions.openFileDialog(ref),
      onNewFile: () => WindowHeaderActions.createNewFile(ref),
      onChat: appState.currentFile != null 
          ? () => WindowHeaderActions.openChatWithFile(context, appState.currentFile)
          : null,
      onSave: () => _saveFile(ref, context),
      onClose: appState.currentFile != null
          ? () => _closeFileWithConfirmation(context, ref)
          : null,
      onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.primary),
    );

    final secondaryPane = _buildSecondaryPane(context, ref, appState);

    final layoutConfig = WindowLayoutConfig(
      mode: LayoutMode.split,
      panes: [primaryPane, secondaryPane],
      toolbar: _buildSplitScreenToolbar(context, ref, appState),
    );

    final paneWidgets = <WindowPaneConfig, Widget>{
      primaryPane: _buildDragTargetEditor(
        child: const EditorView(),
        onDrop: (filePath) => _handlePrimaryPaneDrop(filePath, ref),
      ),
      secondaryPane: _buildSecondaryPaneWidget(context, ref, appState),
    };

    return WindowLayout(
      config: layoutConfig,
      paneWidgets: paneWidgets,
    );
  }

  WindowPaneConfig _buildSecondaryPane(BuildContext context, WidgetRef ref, AppState appState) {
    if (appState.isPreviewVisible) {
      return WindowPaneConfig(
        type: WindowPaneType.preview,
        activeWindow: ActiveWindow.preview,
        filePath: appState.currentFile,
        isActive: appState.activeWindow == ActiveWindow.preview,
        onOpenFile: () => WindowHeaderActions.openFileDialog(ref),
        onNewFile: () => WindowHeaderActions.createNewFile(ref),
        onChat: appState.currentFile != null 
            ? () => WindowHeaderActions.openChatWithFile(context, appState.currentFile)
            : null,
        onSave: () => _saveFile(ref, context),
        onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.preview),
      );
    } else {
      return WindowPaneConfig(
        type: WindowPaneType.secondaryEditor,
        activeWindow: ActiveWindow.secondary,
        filePath: appState.secondaryFile,
        content: appState.secondaryContent,
        isActive: appState.activeWindow == ActiveWindow.secondary,
        onOpenFile: () => WindowHeaderActions.openFileDialog(ref, isSecondary: true),
        onNewFile: () => WindowHeaderActions.createNewFile(ref, isSecondary: true),
        onChat: appState.secondaryFile != null 
            ? () => WindowHeaderActions.openChatWithFile(context, appState.secondaryFile)
            : null,
        onSave: () => _saveSecondaryFile(ref, context),
        onClose: appState.secondaryFile != null
            ? () => _closeSecondaryFileWithConfirmation(context, ref)
            : null,
        onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.secondary),
        placeholder: _buildSecondaryPlaceholder(context, ref),
      );
    }
  }

  Widget _buildSecondaryPaneWidget(BuildContext context, WidgetRef ref, AppState appState) {
    if (appState.isPreviewVisible) {
      return GestureDetector(
        onTap: () => ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.preview),
        child: const MarkdownPreview(),
      );
    } else if (appState.secondaryFile != null) {
      return _buildDragTargetEditor(
        child: SecondaryEditorView(
          filePath: appState.secondaryFile!,
          content: appState.secondaryContent,
        ),
        onDrop: (filePath) => _handleSecondaryPaneDrop(filePath, ref),
      );
    } else {
      return _buildSecondaryPlaceholder(context, ref);
    }
  }

  Widget _buildSplitScreenToolbar(BuildContext context, WidgetRef ref, AppState appState) {
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
          if (appState.isPreviewVisible) _buildSyncControls(context, ref),
        ],
      ),
    );
  }

  Widget _buildSyncControls(BuildContext context, WidgetRef ref) {
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

  Widget _buildDragTargetEditor({required Widget child, required Function(String) onDrop}) {
    return DragTarget<String>(
      onAccept: onDrop,
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
          child: child,
        );
      },
    );
  }

  Widget _buildPrimaryPlaceholder(BuildContext context, WidgetRef ref) {
    return DragTarget<String>(
      onAccept: (filePath) => _handlePrimaryPaneDrop(filePath, ref),
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
                      ? 'Drop file to open'
                      : 'Open a file to get started',
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
                      onPressed: () => WindowHeaderActions.openFileDialog(ref),
                      icon: const Icon(Icons.folder_open, size: 20),
                      label: const Text('Open File'),
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
                      onPressed: () => WindowHeaderActions.createNewFile(ref),
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
      debugPrint('Failed to open secondary file: $e');
    }
  }

  Future<void> _handlePrimaryPaneDrop(String filePath, WidgetRef ref) async {
    try {
      ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.primary);
      final fileService = FileService();
      final content = await fileService.readFile(filePath);
      ref.read(appStateProvider.notifier).openFile(filePath, content);
    } catch (e) {
      debugPrint('Error opening file in primary pane: $e');
    }
  }

  Future<void> _handleSecondaryPaneDrop(String filePath, WidgetRef ref) async {
    try {
      ref.read(appStateProvider.notifier).setActiveWindow(ActiveWindow.secondary);
      final fileService = FileService();
      final content = await fileService.readFile(filePath);
      ref.read(appStateProvider.notifier).openSecondaryFile(filePath, content);
    } catch (e) {
      debugPrint('Error opening file in secondary pane: $e');
    }
  }

  void _closeFileWithConfirmation(BuildContext context, WidgetRef ref) async {
    await ref.read(appStateProvider.notifier).closeFileWithConfirmation(context);
  }

  void _closeSecondaryFileWithConfirmation(BuildContext context, WidgetRef ref) async {
    await ref.read(appStateProvider.notifier).closeSecondaryFileWithConfirmation(context);
  }

  void _saveFile(WidgetRef ref, BuildContext context) async {
    final appState = ref.read(appStateProvider);
    if (appState.currentFile == null) return;

    try {
      final fileService = FileService();
      await fileService.writeFile(appState.currentFile!, appState.content);
      ref.read(appStateProvider.notifier).saveFile();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save file: $e')),
        );
      }
    }
  }

  void _saveSecondaryFile(WidgetRef ref, BuildContext context) async {
    final appState = ref.read(appStateProvider);
    if (appState.secondaryFile == null) return;

    try {
      final fileService = FileService();
      await fileService.writeFile(appState.secondaryFile!, appState.secondaryContent);
      ref.read(appStateProvider.notifier).saveSecondaryFile();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secondary file saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save secondary file: $e')),
        );
      }
    }
  }

  void _toggleScrollSync(WidgetRef ref) async {
    final syncStateNotifier = ref.read(syncStateProvider.notifier);
    final currentState = ref.read(syncStateProvider);
    final newState = !currentState.scrollSyncEnabled;
    
    syncStateNotifier.updateScrollSync(newState);
    
    final preferencesNotifier = ref.read(preferencesProvider.notifier);
    await preferencesNotifier.setScrollSyncEnabled(newState);
  }

  void _toggleCaretSync(WidgetRef ref) async {
    final syncStateNotifier = ref.read(syncStateProvider.notifier);
    final currentState = ref.read(syncStateProvider);
    final newState = !currentState.caretSyncEnabled;
    
    syncStateNotifier.updateCaretSync(newState);
    
    final preferencesNotifier = ref.read(preferencesProvider.notifier);
    await preferencesNotifier.setCaretSyncEnabled(newState);
  }
}