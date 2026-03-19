import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_state.dart';
import '../models/tab_item.dart';
import '../services/file_service.dart';
import '../../ui/dialogs/save_changes_dialog.dart';
import 'preferences_provider.dart';

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;

  AppStateNotifier(this._ref) : super(const AppState()) {
    _initializeFromPreferences();
  }

  /// Initialize app state from saved preferences
  void _initializeFromPreferences() {
    final preferencesAsync = _ref.read(preferencesProvider);
    preferencesAsync.whenData((preferences) {
      _safeSetState(state.copyWith(
        isScrollSyncEnabled: preferences.defaultScrollSyncEnabled,
        isEditMode: preferences.defaultEditMode,
      ));
    });
  }


  void _safeSetState(AppState newState) {
    // Use try-catch to handle disposal safely
    try {
      if (!mounted) return;
      state = newState;
    } catch (e) {
      // Ignore state updates after disposal
    }
  }

  void openFile(String filePath, String content) {
    openFileInActiveWindow(filePath, content);
  }

  /// Open file from external source (Finder, URL scheme) in single-file preview mode
  /// This shows the file in preview mode without auto-expanding the folder tree
  void openFileFromExternal(String filePath, String content) {
    _safeSetState(state.copyWith(
      currentFile: filePath,
      content: content,
      originalContent: content,
      isDirty: false,
      isEditMode: false, // Always open in preview mode from external
      isFolderSidebarVisible: true, // Show sidebar
      isSingleFileMode: true, // Don't auto-expand folder tree
      appMode: AppMode.project, // Switch to project mode
      // Don't set currentFolderRoot - user will opt-in to see folder
    ));

    // Save last opened file to preferences and add to recent files
    _ref.read(preferencesProvider.notifier).setLastOpenedFile(filePath);
    _ref.read(preferencesProvider.notifier).addRecentFile(filePath);

    // Sync to tab bar as preview tab
    openFileAsPreview(filePath, content);
  }

  /// Exit single file mode and show the full folder tree
  void expandToFolder() {
    if (state.currentFile == null) return;

    final file = File(state.currentFile!);
    final parentDirectory = file.parent.path;

    _safeSetState(state.copyWith(
      isSingleFileMode: false,
      currentFolderRoot: parentDirectory,
    ));
  }

  void openFileInActiveWindow(String filePath, String content) {
    // Get user's default edit mode preference
    final preferencesAsync = _ref.read(preferencesProvider);
    final defaultEditMode = preferencesAsync.value?.defaultEditMode ?? false;
    
    
    switch (state.activeWindow) {
      case ActiveWindow.primary:
        _safeSetState(state.copyWith(
          currentFile: filePath,
          content: content,
          originalContent: content, // Store original content
          isDirty: false,
          isFolderSidebarVisible: true,  // Automatically show sidebar when file is opened
          isEditMode: defaultEditMode,  // Respect user's default edit mode preference
          appMode: AppMode.project,  // Switch to project mode when file is opened
          isSingleFileMode: false,  // Clear single file mode when opening normally
        ));
        break;
      case ActiveWindow.secondary:
        if (state.isSplitScreenMode) {
          _safeSetState(state.copyWith(
            secondaryFile: filePath,
            secondaryContent: content,
            originalSecondaryContent: content, // Store original secondary content
            isSecondaryDirty: false,
          ));
        } else {
          // If not in split screen mode, open in primary window
          _safeSetState(state.copyWith(
            currentFile: filePath,
            content: content,
            originalContent: content, // Store original content
            isDirty: false,
            isFolderSidebarVisible: true,
            isEditMode: defaultEditMode,
            appMode: AppMode.project,  // Switch to project mode when file is opened
            isSingleFileMode: false,  // Clear single file mode when opening normally
          ));
        }
        break;
      case ActiveWindow.preview:
        // Preview window doesn't open files directly, fall back to primary
        _safeSetState(state.copyWith(
          currentFile: filePath,
          content: content,
          originalContent: content, // Store original content
          isDirty: false,
          isFolderSidebarVisible: true,
          isEditMode: defaultEditMode,
          appMode: AppMode.project,  // Switch to project mode when file is opened
          isSingleFileMode: false,  // Clear single file mode when opening normally
        ));
        break;
    }
    
    // Save last opened file to preferences and add to recent files
    _ref.read(preferencesProvider.notifier).setLastOpenedFile(filePath);
    _ref.read(preferencesProvider.notifier).addRecentFile(filePath);

    // Sync to tab bar
    _syncFileToTabs(filePath, content);
  }

  void updateContent(String content) {
    // Compare with original content to determine if file is actually dirty
    final isDirty = content != state.originalContent;
    _safeSetState(state.copyWith(
      content: content,
      isDirty: isDirty,
    ));

    // Keep tab content in sync
    if (state.activeTabId != null) {
      updateTabContent(state.activeTabId!, content);
    }
  }

  void toggleMode() {
    final newEditMode = !state.isEditMode;
    _safeSetState(state.copyWith(
      isEditMode: newEditMode,
    ));
    
    // Save as default preference
    _ref.read(preferencesProvider.notifier).setDefaultEditMode(newEditMode);
  }

  void saveFile() {
    _safeSetState(state.copyWith(
      originalContent: state.content, // Update original content to current content
      isDirty: false,
    ));

    // Keep tab in sync
    if (state.activeTabId != null) {
      saveTab(state.activeTabId!);
    }
  }

  void closeFile() {
    _safeSetState(state.copyWith(
      currentFile: null,
      content: '',
      originalContent: '',
      isDirty: false,
      // If we're in split screen but only have preview visible, turn off split screen
      isSplitScreenMode: (state.isSplitScreenMode && state.isPreviewVisible && state.secondaryFile == null) ? false : state.isSplitScreenMode,
      // Turn off preview if it was visible (since we're closing the file it was previewing)
      isPreviewVisible: false,
      // Keep the current app mode, folder sidebar state, and folder root
      // This allows staying in project mode with an empty workspace
    ));
  }

  /// Close file with save confirmation dialog if there are unsaved changes
  Future<bool> closeFileWithConfirmation(BuildContext context) async {
    if (!state.isDirty) {
      closeFile();
      return true;
    }

    final action = await SaveChangesDialog.show(
      context,
      fileName: state.currentFile,
      isUntitled: state.currentFile == null || state.currentFile!.startsWith('Untitled-'),
    );

    switch (action) {
      case SaveChangesAction.save:
        try {
          await _saveCurrentFile();
          closeFile();
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save file: $e')),
            );
          }
          return false;
        }
      case SaveChangesAction.discard:
        closeFile();
        return true;
      case SaveChangesAction.cancel:
      case null:
        return false;
    }
  }

  /// Close secondary file with save confirmation dialog if there are unsaved changes
  Future<bool> closeSecondaryFileWithConfirmation(BuildContext context) async {
    if (!state.isSecondaryDirty) {
      closeSecondaryFile();
      return true;
    }

    final action = await SaveChangesDialog.show(
      context,
      fileName: state.secondaryFile,
      isUntitled: state.secondaryFile == null || state.secondaryFile!.startsWith('Untitled-'),
    );

    switch (action) {
      case SaveChangesAction.save:
        try {
          await _saveSecondaryFile();
          closeSecondaryFile();
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save file: $e')),
            );
          }
          return false;
        }
      case SaveChangesAction.discard:
        closeSecondaryFile();
        return true;
      case SaveChangesAction.cancel:
      case null:
        return false;
    }
  }

  /// Open file with save confirmation dialog if current file has unsaved changes
  Future<bool> openFileWithConfirmation(BuildContext context, String filePath, String content) async {
    if (!state.isDirty) {
      openFile(filePath, content);
      return true;
    }

    final action = await SaveChangesDialog.show(
      context,
      fileName: state.currentFile,
      isUntitled: state.currentFile == null || state.currentFile!.startsWith('Untitled-'),
    );

    switch (action) {
      case SaveChangesAction.save:
        try {
          await _saveCurrentFile();
          openFile(filePath, content);
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save file: $e')),
            );
          }
          return false;
        }
      case SaveChangesAction.discard:
        openFile(filePath, content);
        return true;
      case SaveChangesAction.cancel:
      case null:
        return false;
    }
  }

  /// Internal method to save the current file
  Future<void> _saveCurrentFile() async {
    if (state.currentFile == null) return;
    
    final fileService = FileService();
    await fileService.writeFile(state.currentFile!, state.content);
    saveFile();
  }

  /// Internal method to save the secondary file
  Future<void> _saveSecondaryFile() async {
    if (state.secondaryFile == null) return;
    
    final fileService = FileService();
    await fileService.writeFile(state.secondaryFile!, state.secondaryContent);
    saveSecondaryFile();
  }

  void toggleSplitScreen() {
    final newSplitScreen = !state.isSplitScreenMode;
    _safeSetState(state.copyWith(
      isSplitScreenMode: newSplitScreen,
    ));
  }

  void openSecondaryFile(String filePath, String content) {
    _safeSetState(state.copyWith(
      secondaryFile: filePath,
      secondaryContent: content,
      originalSecondaryContent: content, // Store original secondary content
      isSplitScreenMode: true,
      isSecondaryDirty: false,
      activeWindow: ActiveWindow.secondary,  // Set secondary window as active when opened
    ));
  }

  void updateSecondaryContent(String content) {
    // Compare with original secondary content to determine if file is actually dirty
    final isSecondaryDirty = content != state.originalSecondaryContent;
    _safeSetState(state.copyWith(
      secondaryContent: content,
      isSecondaryDirty: isSecondaryDirty,
    ));
  }

  void closeSecondaryFile() {
    _safeSetState(state.copyWith(
      isSplitScreenMode: false,
      secondaryFile: null,
      secondaryContent: '',
      isSecondaryDirty: false,
    ));
  }

  void saveSecondaryFile() {
    _safeSetState(state.copyWith(
      originalSecondaryContent: state.secondaryContent, // Update original secondary content to current content
      isSecondaryDirty: false,
    ));
  }

  void toggleFolderSidebar() {
    final newVisible = !state.isFolderSidebarVisible;
    _safeSetState(state.copyWith(
      isFolderSidebarVisible: newVisible,
      // Switch to project mode when showing sidebar
      appMode: newVisible ? AppMode.project : state.appMode,
    ));
    
    // Save as default preference
    _ref.read(preferencesProvider.notifier).setDefaultFolderSidebarVisible(newVisible);
  }

  void requestScrollToHeading(String heading) {
    // Generate a unique request ID to ensure state change is detected
    final requestId = DateTime.now().millisecondsSinceEpoch;
    _safeSetState(state.copyWith(
      scrollToHeading: heading,
      scrollRequestId: requestId,
    ));
  }

  void clearScrollRequest() {
    _safeSetState(state.copyWith(
      scrollToHeading: null,
      scrollRequestId: null,
    ));
  }

  /// Track when a folder is opened for scanning
  void addRecentFolder(String folderPath) {
    _ref.read(preferencesProvider.notifier).addRecentFolder(folderPath);
  }

  /// Request folder picker to be triggered from sidebar
  void requestFolderPicker() {
    // This will be used to communicate between toolbar and sidebar
    // The sidebar will listen for this state change and trigger its folder picker
    final requestId = DateTime.now().millisecondsSinceEpoch;
    _safeSetState(state.copyWith(
      // We'll add a new field for this
      folderPickerRequestId: requestId,
    ));
  }

  void setDroppedFolder(String folderPath) {
    // Signal to the sidebar that a folder was dropped and should be scanned
    _safeSetState(state.copyWith(
      droppedFolder: folderPath,
    ));
  }

  void clearDroppedFolder() {
    // Clear the dropped folder state by setting it to null
    _safeSetState(state.copyWith(
      clearDroppedFolder: true,
    ));
  }

  void togglePreviewVisibility() {
    _safeSetState(state.copyWith(
      isPreviewVisible: !state.isPreviewVisible,
    ));
  }

  void togglePreviewVisibilityWithModeStorage(bool? currentEditMode) {
    _safeSetState(state.copyWith(
      isPreviewVisible: !state.isPreviewVisible,
      previousEditModeBeforePreview: currentEditMode,
    ));
  }

  void toggleScrollSync() {
    final newSyncEnabled = !state.isScrollSyncEnabled;
    _safeSetState(state.copyWith(
      isScrollSyncEnabled: newSyncEnabled,
    ));
    
    // Save as default preference
    _ref.read(preferencesProvider.notifier).setDefaultScrollSyncEnabled(newSyncEnabled);
  }

  void createNewSecondaryFile() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _safeSetState(state.copyWith(
      isSplitScreenMode: true,
      secondaryFile: 'Untitled-$timestamp.md',
      secondaryContent: '# New Document\n\nStart writing your markdown here...',
      isSecondaryDirty: true,
    ));
  }

  void setCurrentFolderRoot(String folderRoot) {
    _safeSetState(state.copyWith(
      currentFolderRoot: folderRoot,
      appMode: AppMode.project,  // Switch to project mode when folder is set
    ));
  }

  void setActiveWindow(ActiveWindow window) {
    _safeSetState(state.copyWith(
      activeWindow: window,
    ));
  }

  void setAppMode(AppMode mode) {
    _safeSetState(state.copyWith(
      appMode: mode,
    ));
  }

  void closeFolderAndReturnToOverview() {
    _safeSetState(const AppState(
      appMode: AppMode.overview,
      isEditMode: true,
    ));
  }

  // ─── Tab Management ────────────────────────────────────────────────

  String _nextTabId() => 'tab_${DateTime.now().microsecondsSinceEpoch}';

  /// Ensure the current file is represented in the tab list.
  /// Called internally after openFile / openFileInActiveWindow.
  void _syncFileToTabs(String filePath, String content) {
    final tabs = List<TabItem>.from(state.openTabs);

    // Check if file is already open in a tab
    final existingIndex = tabs.indexWhere((t) => t.filePath == filePath);
    if (existingIndex >= 0) {
      // Activate existing tab, promote from preview if needed
      final tab = tabs[existingIndex].copyWith(
        content: content,
        originalContent: content,
        isDirty: false,
        isPreview: false,
      );
      tabs[existingIndex] = tab;
      _safeSetState(state.copyWith(openTabs: tabs, activeTabId: tab.id));
      return;
    }

    // Replace any existing preview tab with the new file
    final previewIndex = tabs.indexWhere((t) => t.isPreview);
    final newTab = TabItem(
      id: _nextTabId(),
      filePath: filePath,
      content: content,
      originalContent: content,
      isPreview: false,
    );

    if (previewIndex >= 0) {
      tabs[previewIndex] = newTab;
    } else {
      tabs.add(newTab);
    }

    _safeSetState(state.copyWith(openTabs: tabs, activeTabId: newTab.id));
  }

  /// Open a file as a preview tab (single-click in sidebar, like VS Code italic tab)
  void openFileAsPreview(String filePath, String content) {
    final tabs = List<TabItem>.from(state.openTabs);

    // If already open, just activate it
    final existingIndex = tabs.indexWhere((t) => t.filePath == filePath);
    if (existingIndex >= 0) {
      _safeSetState(state.copyWith(activeTabId: tabs[existingIndex].id));
      // Also update current file for backward compat
      _safeSetState(state.copyWith(
        currentFile: filePath,
        content: content,
        originalContent: content,
        isDirty: false,
        appMode: AppMode.project,
      ));
      return;
    }

    // Replace any existing preview tab
    final previewIndex = tabs.indexWhere((t) => t.isPreview);
    final newTab = TabItem(
      id: _nextTabId(),
      filePath: filePath,
      content: content,
      originalContent: content,
      isPreview: true,
    );

    if (previewIndex >= 0) {
      tabs[previewIndex] = newTab;
    } else {
      tabs.add(newTab);
    }

    _safeSetState(state.copyWith(
      openTabs: tabs,
      activeTabId: newTab.id,
      currentFile: filePath,
      content: content,
      originalContent: content,
      isDirty: false,
      appMode: AppMode.project,
    ));
  }

  /// Pin a preview tab (double-click promotes it to a permanent tab)
  void pinTab(String tabId) {
    final tabs = List<TabItem>.from(state.openTabs);
    final index = tabs.indexWhere((t) => t.id == tabId);
    if (index >= 0) {
      tabs[index] = tabs[index].copyWith(isPreview: false);
      _safeSetState(state.copyWith(openTabs: tabs));
    }
  }

  /// Switch to a tab by id
  void switchToTab(String tabId) {
    final tab = state.openTabs.where((t) => t.id == tabId).firstOrNull;
    if (tab == null) return;

    _safeSetState(state.copyWith(
      activeTabId: tabId,
      currentFile: tab.filePath,
      content: tab.content,
      originalContent: tab.originalContent,
      isDirty: tab.isDirty,
    ));
  }

  /// Close a tab by id. Returns false if cancelled by user.
  Future<bool> closeTab(String tabId, BuildContext context) async {
    final tabs = List<TabItem>.from(state.openTabs);
    final index = tabs.indexWhere((t) => t.id == tabId);
    if (index < 0) return true;

    final tab = tabs[index];

    // Prompt save if dirty
    if (tab.isDirty) {
      final action = await SaveChangesDialog.show(
        context,
        fileName: tab.filePath,
        isUntitled: tab.filePath == null || tab.filePath!.startsWith('Untitled-'),
      );

      switch (action) {
        case SaveChangesAction.save:
          if (tab.filePath != null && !tab.filePath!.startsWith('Untitled-')) {
            final fileService = FileService();
            await fileService.writeFile(tab.filePath!, tab.content);
          }
          break;
        case SaveChangesAction.discard:
          break;
        case SaveChangesAction.cancel:
        case null:
          return false;
      }
    }

    tabs.removeAt(index);

    // Determine new active tab
    String? newActiveId;
    if (tabs.isNotEmpty) {
      if (state.activeTabId == tabId) {
        // Activate the tab at the same position or the last one
        final newIndex = index.clamp(0, tabs.length - 1);
        newActiveId = tabs[newIndex].id;
      } else {
        newActiveId = state.activeTabId;
      }
    }

    final newActiveTab = newActiveId != null
        ? tabs.where((t) => t.id == newActiveId).firstOrNull
        : null;

    _safeSetState(state.copyWith(
      openTabs: tabs,
      activeTabId: newActiveId,
      currentFile: newActiveTab?.filePath,
      content: newActiveTab?.content ?? '',
      originalContent: newActiveTab?.originalContent ?? '',
      isDirty: newActiveTab?.isDirty ?? false,
    ));

    // If no tabs left, might close the file view
    if (tabs.isEmpty) {
      closeFile();
    }

    return true;
  }

  /// Reorder tabs (drag and drop)
  void reorderTabs(int oldIndex, int newIndex) {
    final tabs = List<TabItem>.from(state.openTabs);
    final tab = tabs.removeAt(oldIndex);
    tabs.insert(newIndex, tab);
    _safeSetState(state.copyWith(openTabs: tabs));
  }

  /// Update a tab's content (called when editing)
  void updateTabContent(String tabId, String content) {
    final tabs = List<TabItem>.from(state.openTabs);
    final index = tabs.indexWhere((t) => t.id == tabId);
    if (index < 0) return;

    final tab = tabs[index];
    final isDirty = content != tab.originalContent;
    tabs[index] = tab.copyWith(content: content, isDirty: isDirty);
    _safeSetState(state.copyWith(openTabs: tabs));
  }

  /// Mark a tab as saved
  void saveTab(String tabId) {
    final tabs = List<TabItem>.from(state.openTabs);
    final index = tabs.indexWhere((t) => t.id == tabId);
    if (index < 0) return;

    tabs[index] = tabs[index].copyWith(
      originalContent: tabs[index].content,
      isDirty: false,
    );
    _safeSetState(state.copyWith(openTabs: tabs));
  }
}