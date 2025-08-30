import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_state.dart';
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
        ));
        break;
    }
    
    // Save last opened file to preferences and add to recent files
    _ref.read(preferencesProvider.notifier).setLastOpenedFile(filePath);
    _ref.read(preferencesProvider.notifier).addRecentFile(filePath);
  }

  void updateContent(String content) {
    // Compare with original content to determine if file is actually dirty
    final isDirty = content != state.originalContent;
    _safeSetState(state.copyWith(
      content: content,
      isDirty: isDirty,
    ));
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
}