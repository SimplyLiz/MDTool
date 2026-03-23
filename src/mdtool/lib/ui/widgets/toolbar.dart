import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:markdown/markdown.dart' as md_convert;
import '../../core/providers/app_state_provider.dart';
import '../../core/models/app_state.dart';
import '../../core/services/file_service.dart';
import '../../core/services/native_bridge_service.dart';
import '../../core/services/scroll_sync_service.dart';
import 'preferences_dialog.dart';
import '../dialogs/pdf_export_dialog.dart';
import '../dialogs/about_dialog.dart';
import 'loading_overlay.dart';
import 'unified_chat_dialog.dart';
import 'chat_dialog.dart';
import 'ollama_assistant_dialog.dart';
import '../../core/providers/preferences_provider.dart';

// Simple state class for sync controls
class SyncState {
  final bool scrollSyncEnabled;
  final bool caretSyncEnabled;
  
  const SyncState({
    required this.scrollSyncEnabled,
    required this.caretSyncEnabled,
  });
  
  SyncState copyWith({bool? scrollSyncEnabled, bool? caretSyncEnabled}) {
    return SyncState(
      scrollSyncEnabled: scrollSyncEnabled ?? this.scrollSyncEnabled,
      caretSyncEnabled: caretSyncEnabled ?? this.caretSyncEnabled,
    );
  }
}

// StateNotifier for sync controls
class SyncStateNotifier extends StateNotifier<SyncState> {
  SyncStateNotifier() : super(const SyncState(scrollSyncEnabled: false, caretSyncEnabled: true));
  
  void updateScrollSync(bool enabled) {
    ScrollSyncService().setScrollSyncEnabled(enabled);
    if (enabled) {
      // Disable caret sync when enabling scroll sync (mutually exclusive)
      ScrollSyncService().setCaretSyncEnabled(false);
      state = state.copyWith(scrollSyncEnabled: enabled, caretSyncEnabled: false);
    } else {
      state = state.copyWith(scrollSyncEnabled: enabled);
    }
  }
  
  void updateCaretSync(bool enabled) {
    ScrollSyncService().setCaretSyncEnabled(enabled);
    if (enabled) {
      // Disable scroll sync when enabling caret sync (mutually exclusive)
      ScrollSyncService().setScrollSyncEnabled(false);
      state = state.copyWith(caretSyncEnabled: enabled, scrollSyncEnabled: false);
    } else {
      state = state.copyWith(caretSyncEnabled: enabled);
    }
  }
  
  void initializeFromService() {
    final service = ScrollSyncService();
    var scrollEnabled = service.scrollSyncEnabled;
    var caretEnabled = service.caretSyncEnabled;
    
    // Enforce mutual exclusivity during initialization
    if (scrollEnabled && caretEnabled) {
      // Both enabled - prioritize caret sync (our new default)
      scrollEnabled = false;
      caretEnabled = true;
      // Update the service to match
      service.setScrollSyncEnabled(false);
      service.setCaretSyncEnabled(true);
    }
    
    state = SyncState(
      scrollSyncEnabled: scrollEnabled,
      caretSyncEnabled: caretEnabled,
    );
  }
}

// Provider for sync state
final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  final notifier = SyncStateNotifier();
  notifier.initializeFromService();
  return notifier;
});

class MDToolbar extends ConsumerWidget implements PreferredSizeWidget {
  const MDToolbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final appStateNotifier = ref.read(appStateProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 800;
    final isVeryNarrow = screenWidth < 600;

    return AppBar(
      title: Text(appState.currentFile != null ? _getFileName(appState.currentFile!) : 'MD Tool'),
      leading: IconButton(
        icon: Icon(appState.isFolderSidebarVisible ? Icons.folder_open : Icons.folder, color: appState.isFolderSidebarVisible ? Colors.orange : null),
        onPressed: () => appStateNotifier.toggleFolderSidebar(),
        tooltip: appState.isFolderSidebarVisible ? 'Hide Folder Sidebar' : 'Show Folder Sidebar',
      ),
      actions: [
        // AI Chat button - always visible
        Consumer(
          builder: (context, ref, child) {
            final preferences = ref.watch(preferencesProvider).valueOrNull;
            final hasAIProvider = (preferences?.ollamaEnabled ?? false) || 
                                 ((preferences?.openaiEnabled ?? false) && (preferences?.openaiApiKey.isNotEmpty ?? false));

            return IconButton(
              icon: Icon(Icons.auto_awesome, color: hasAIProvider ? Theme.of(context).colorScheme.primary : null),
              onPressed: () => _showUnifiedAIAssistant(context, ref),
              tooltip: 'AI Chat',
            );
          },
        ),
        if (appState.currentFile != null) ...[
          // Preview toggle - hide on narrow screens
          if (!isNarrow) IconButton(
            icon: Icon(appState.isPreviewVisible ? Icons.preview : Icons.preview_outlined, color: appState.isPreviewVisible ? Theme.of(context).colorScheme.primary : null),
            onPressed: () => _togglePreview(ref),
            tooltip: appState.isPreviewVisible ? 'Hide Preview' : 'Edit with Live Preview',
          ),
          // Split screen - hide on narrow screens
          if (!isNarrow) IconButton(
            icon: Icon(appState.isSplitScreenMode && !appState.isPreviewVisible ? Icons.call_merge : Icons.call_split, color: appState.isSplitScreenMode && !appState.isPreviewVisible ? Theme.of(context).colorScheme.primary : null),
            onPressed: () => _openSplitScreen(context, ref),
            tooltip: appState.isSplitScreenMode && !appState.isPreviewVisible ? 'Exit Split Screen' : 'Open Second File',
          ),
        ],
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More options',
          onSelected: (value) {
            switch (value) {
              case 'close_folder':
                _closeFolder(context, ref);
                break;
              case 'preferences':
                _showPreferences(context);
                break;
              case 'about':
                _showAbout(context);
                break;
              case 'export_pdf':
                _exportToPDF(context, ref);
                break;
              case 'diff_comparison':
                _openDiffComparison(context, ref);
                break;
              case 'show_html':
                _showHTMLInBrowser(context, ref);
                break;
              case 'show_finder':
                _showInFinder(context, ref);
                break;
            }
          },
          itemBuilder: (context) => [
            // Show Close Folder option only in project mode
            if (appState.appMode == AppMode.project) ...[
              const PopupMenuItem(
                value: 'close_folder',
                child: Row(children: [Icon(Icons.close), SizedBox(width: 8), Text('Close Folder')]),
              ),
              const PopupMenuDivider(),
            ],
            const PopupMenuItem(
              value: 'diff_comparison',
              child: Row(children: [Icon(Icons.compare_arrows), SizedBox(width: 8), Text('Text Diff Comparison')]),
            ),
            if (appState.currentFile != null) ...[
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(children: [Icon(Icons.picture_as_pdf), SizedBox(width: 8), Text('Export PDF')]),
              ),
              const PopupMenuItem(
                value: 'show_html',
                child: Row(children: [Icon(Icons.web), SizedBox(width: 8), Text('Show HTML in Browser')]),
              ),
              const PopupMenuItem(
                value: 'show_finder',
                child: Row(children: [Icon(Icons.folder), SizedBox(width: 8), Text('Show in Finder')]),
              ),
              const PopupMenuDivider(),
            ],
            const PopupMenuItem(
              value: 'preferences',
              child: Row(children: [Icon(Icons.settings), SizedBox(width: 8), Text('Preferences')]),
            ),
            const PopupMenuItem(
              value: 'about',
              child: Row(children: [Icon(Icons.info), SizedBox(width: 8), Text('About MD Tool')]),
            ),
          ],
        ),
      ],
    );
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  void _newFile(BuildContext context, WidgetRef ref) async {
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
        // Open the new file
        ref.read(appStateProvider.notifier).openFile(outputFile, initialContent);

        if (context.mounted) {
          SuccessSnackBar.show(context, 'New file created successfully');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ErrorSnackBar.show(context, 'Failed to create file: $e', onRetry: () => _newFile(context, ref));
      }
    }
  }


  void _saveFile(BuildContext context, WidgetRef ref) async {
    final appState = ref.read(appStateProvider);
    if (appState.currentFile == null) return;

    try {
      final fileService = FileService();
      await fileService.writeFile(appState.currentFile!, appState.content);
      ref.read(appStateProvider.notifier).saveFile();

      SuccessSnackBar.show(context, 'File saved successfully');
    } catch (e) {
      ErrorSnackBar.show(context, 'Failed to save file: $e', onRetry: () => _saveFile(context, ref));
    }
  }

  void _exportToPDF(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => const PDFExportDialog());
  }

  void _showPreferences(BuildContext context) {
    showDialog(context: context, builder: (context) => const PreferencesDialog());
  }

  void _showAbout(BuildContext context) {
    showDialog(context: context, builder: (context) => const AboutAppDialog());
  }

  void _showUnifiedAIAssistant(BuildContext context, WidgetRef ref) {
    // TODO: Get selected text from editor when available
    showDialog(context: context, builder: (context) => const UnifiedChatDialog());
  }

  void _showDocumentChat(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => const ChatDialog());
  }

  void _showOllamaAssistant(BuildContext context, WidgetRef ref) {
    // TODO: Get selected text from editor when available
    showDialog(context: context, builder: (context) => const OllamaAssistantDialog());
  }

  void _showHTMLInBrowser(BuildContext context, WidgetRef ref) async {
    final appState = ref.read(appStateProvider);
    if (appState.currentFile == null) return;

    try {
      final tempDir = Directory.systemTemp;
      final htmlPath = '${tempDir.path}/mdtool_preview.html';

      // Generate HTML from current content
      final content = appState.content;
      final htmlContent = '''<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;line-height:1.6;max-width:800px;margin:0 auto;padding:20px;}
code{background:#f5f5f5;padding:2px 4px;border-radius:3px;}pre{background:#f5f5f5;padding:10px;border-radius:4px;overflow-x:auto;}</style>
</head><body>${md_convert.markdownToHtml(content, extensionSet: md_convert.ExtensionSet.gitHubFlavored)}</body></html>''';
      await File(htmlPath).writeAsString(htmlContent);

      await NativeBridgeService.showQuickLook(htmlPath);

      if (context.mounted) {
        SuccessSnackBar.show(context, 'Opening HTML viewer in browser');
      }
    } catch (e) {
      if (context.mounted) {
        ErrorSnackBar.show(context, 'Failed to open HTML viewer: $e');
      }
    }
  }

  void _showInFinder(BuildContext context, WidgetRef ref) async {
    final appState = ref.read(appStateProvider);
    if (appState.currentFile == null) return;

    try {
      // Use the native bridge to show the file in Finder
      await NativeBridgeService.showInFinder(appState.currentFile!);

      if (context.mounted) {
        SuccessSnackBar.show(context, 'File revealed in Finder');
      }
    } catch (e) {
      if (context.mounted) {
        ErrorSnackBar.show(context, 'Failed to show in Finder: $e');
      }
    }
  }

  void _openFolder(BuildContext context, WidgetRef ref) async {
    try {
      final appStateNotifier = ref.read(appStateProvider.notifier);
      final appState = ref.read(appStateProvider);

      // If sidebar not visible, show it first
      if (!appState.isFolderSidebarVisible) {
        appStateNotifier.toggleFolderSidebar();
        
        // Wait a bit for the sidebar to appear before triggering folder picker
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Request the sidebar to open its folder picker
      // This will use the proper DirectoryPermissionsService with security bookmarks
      appStateNotifier.requestFolderPicker();

    } catch (e) {
      if (context.mounted) {
        ErrorSnackBar.show(context, 'Failed to open folder: $e', onRetry: () => _openFolder(context, ref));
      }
    }
  }

  void _togglePreview(WidgetRef ref) async {
    final appStateNotifier = ref.read(appStateProvider.notifier);
    final appState = ref.read(appStateProvider);
    
    // Get the preference setting
    final preferencesAsync = ref.read(preferencesProvider);
    final preferences = preferencesAsync.valueOrNull;
    final shouldAutoEdit = preferences?.previewAutoEdit ?? true;
    
    if (appState.isPreviewVisible) {
      // Restore previous edit mode if we have it stored and auto-edit is enabled
      if (shouldAutoEdit && appState.previousEditModeBeforePreview != null) {
        if (appState.previousEditModeBeforePreview! != appState.isEditMode) {
          appStateNotifier.toggleMode();
        }
      }
      
      // Hide preview and clear stored mode
      appStateNotifier.togglePreviewVisibilityWithModeStorage(null);
      if (appState.secondaryFile == null) {
        appStateNotifier.toggleSplitScreen();
      }
    } else {
      // Show preview and enable split screen
      if (!appState.isSplitScreenMode) {
        appStateNotifier.toggleSplitScreen();
      }
      
      // Store current edit mode and switch to edit if auto-edit is enabled and we're in preview
      if (shouldAutoEdit && !appState.isEditMode) {
        appStateNotifier.togglePreviewVisibilityWithModeStorage(appState.isEditMode);
        appStateNotifier.toggleMode(); // Switch to edit mode
      } else if (shouldAutoEdit) {
        // Already in edit mode, store that we want to return to edit mode
        appStateNotifier.togglePreviewVisibilityWithModeStorage(true);
      } else {
        appStateNotifier.togglePreviewVisibility();
      }
    }
  }

  void _openSplitScreen(BuildContext context, WidgetRef ref) {
    final appStateNotifier = ref.read(appStateProvider.notifier);
    final appState = ref.read(appStateProvider);
    
    // Get the preference setting
    final preferencesAsync = ref.read(preferencesProvider);
    final preferences = preferencesAsync.valueOrNull;
    final shouldAutoEdit = preferences?.previewAutoEdit ?? true;
    
    if (appState.isSplitScreenMode && !appState.isPreviewVisible) {
      // Exit split screen mode
      appStateNotifier.toggleSplitScreen();
    } else {
      // Enable split screen mode and hide preview if active
      if (appState.isPreviewVisible) {
        // Restore previous edit mode if we have it stored and auto-edit is enabled
        if (shouldAutoEdit && appState.previousEditModeBeforePreview != null) {
          if (appState.previousEditModeBeforePreview! != appState.isEditMode) {
            appStateNotifier.toggleMode();
          }
        }
        
        // Hide preview and clear stored mode
        appStateNotifier.togglePreviewVisibilityWithModeStorage(null);
      }
      if (!appState.isSplitScreenMode) {
        appStateNotifier.toggleSplitScreen();
      }
    }
  }

  void _openDiffComparison(BuildContext context, WidgetRef ref) {
    final appState = ref.read(appStateProvider);
    
    // Prepare arguments for diff page
    final args = <String, dynamic>{};
    
    if (appState.currentFile != null) {
      args['leftFile'] = appState.currentFile;
      args['leftContent'] = appState.content;
      
      // If we have a secondary file in split screen mode, use it as right file
      if (appState.isSplitScreenMode && appState.secondaryFile != null) {
        args['rightFile'] = appState.secondaryFile;
        args['rightContent'] = appState.secondaryContent;
      } else {
        // For now, duplicate the current file as right file to see the diff properly
        // User can load different file once in diff view
        args['rightFile'] = appState.currentFile;
        args['rightContent'] = appState.content;
      }
    }
    
    Navigator.of(context).pushNamed('/diff', arguments: args);
  }

  void _closeFolder(BuildContext context, WidgetRef ref) {
    final appStateNotifier = ref.read(appStateProvider.notifier);
    appStateNotifier.closeFolderAndReturnToOverview();
  }

}
