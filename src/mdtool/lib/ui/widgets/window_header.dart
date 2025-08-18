import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/file_service.dart';
import '../../core/models/app_state.dart';
import 'unified_chat_dialog.dart';

enum WindowType { editor, preview }

class WindowHeader extends ConsumerWidget {
  final WindowType windowType;
  final String? filePath;
  final VoidCallback? onClose;
  final VoidCallback? onOpenFile;
  final VoidCallback? onChat;
  final VoidCallback? onNewFile;
  final VoidCallback? onSave;
  final ActiveWindow activeWindowType;
  final VoidCallback? onTap;

  const WindowHeader({
    super.key,
    required this.windowType,
    required this.activeWindowType,
    this.filePath,
    this.onClose,
    this.onOpenFile,
    this.onChat,
    this.onNewFile,
    this.onSave,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final title = _getWindowTitle();
    final fileName = filePath?.split('/').last;
    final isActive = appState.activeWindow == activeWindowType;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: isActive 
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Icon(
              _getWindowIcon(),
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (fileName?.isNotEmpty == true)
                  Text(
                    fileName!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show New File button when no file is loaded
              if (filePath == null && onNewFile != null)
                IconButton(
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                  onPressed: onNewFile,
                  icon: Icon(
                    Icons.note_add,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'New file',
                ),
              // Show Save button when file is loaded (but not in preview windows)
              if (filePath != null && onSave != null && windowType != WindowType.preview)
                IconButton(
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                  onPressed: _shouldEnableSave(appState) ? onSave : null,
                  icon: Icon(
                    Icons.save,
                    size: 16,
                    color: _shouldEnableSave(appState) 
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  tooltip: _shouldEnableSave(appState) ? 'Save file' : 'No changes to save',
                ),
              if (onChat != null)
                IconButton(
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                  onPressed: onChat,
                  icon: Icon(
                    Icons.chat_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Chat with this file',
                ),
              if (onOpenFile != null)
                IconButton(
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                  onPressed: onOpenFile,
                  icon: Icon(
                    Icons.folder_open_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Open file',
                ),
              if (onClose != null)
                IconButton(
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Close',
                ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  String _getWindowTitle() {
    switch (windowType) {
      case WindowType.editor:
        return 'Editor';
      case WindowType.preview:
        return 'Preview';
    }
  }

  IconData _getWindowIcon() {
    switch (windowType) {
      case WindowType.editor:
        return Icons.edit_outlined;
      case WindowType.preview:
        return Icons.preview_outlined;
    }
  }

  bool _shouldEnableSave(AppState appState) {
    // Determine which window we're dealing with and check its dirty state
    switch (activeWindowType) {
      case ActiveWindow.primary:
        return appState.isDirty && appState.currentFile != null;
      case ActiveWindow.secondary:
        return appState.isSecondaryDirty && appState.secondaryFile != null;
      case ActiveWindow.preview:
        // Preview window can save the primary file if it has changes
        return appState.isDirty && appState.currentFile != null;
    }
  }
}

class WindowHeaderActions {
  static void createNewFile(WidgetRef ref, {bool isSecondary = false}) async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Create New Markdown File',
        fileName: 'untitled.md',
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown'],
      );

      if (outputFile != null) {
        final fileService = FileService();
        const initialContent = '# New Document\n\nStart writing your markdown here...\n';
        
        // Ensure the directory exists
        await fileService.ensureDirectoryExists(outputFile);
        // Write the initial content
        await fileService.writeFile(outputFile, initialContent);
        
        // Open the new file in the appropriate window
        if (isSecondary) {
          ref.read(appStateProvider.notifier).openSecondaryFile(outputFile, initialContent);
        } else {
          ref.read(appStateProvider.notifier).openFileInActiveWindow(outputFile, initialContent);
        }
      }
    } catch (e) {
      debugPrint('Failed to create file: $e');
    }
  }

  static void openFileDialog(WidgetRef ref, {bool isSecondary = false}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'mdown', 'mkd', 'mkdn'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileService = FileService();
        final content = await fileService.readFile(filePath);
        
        if (isSecondary) {
          ref.read(appStateProvider.notifier).openSecondaryFile(filePath, content);
        } else {
          ref.read(appStateProvider.notifier).openFileInActiveWindow(filePath, content);
        }
      }
    } catch (e) {
      debugPrint('Failed to open file: $e');
    }
  }

  static void openChatWithFile(BuildContext context, String? filePath) {
    if (filePath == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat with File'),
        content: Text('Starting chat with:\n${filePath.split('/').last}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void openChatWithoutFile(BuildContext context) {
    showDialog(
      context: context, 
      builder: (context) => const UnifiedChatDialog()
    );
  }
}