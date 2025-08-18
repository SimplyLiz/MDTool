import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_state.dart';
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
          isDirty: false,
          isFolderSidebarVisible: true,  // Automatically show sidebar when file is opened
          isEditMode: defaultEditMode,  // Respect user's default edit mode preference
        ));
        break;
      case ActiveWindow.secondary:
        if (state.isSplitScreenMode) {
          _safeSetState(state.copyWith(
            secondaryFile: filePath,
            secondaryContent: content,
            isSecondaryDirty: false,
          ));
        } else {
          // If not in split screen mode, open in primary window
          _safeSetState(state.copyWith(
            currentFile: filePath,
            content: content,
            isDirty: false,
            isFolderSidebarVisible: true,
            isEditMode: defaultEditMode,
          ));
        }
        break;
      case ActiveWindow.preview:
        // Preview window doesn't open files directly, fall back to primary
        _safeSetState(state.copyWith(
          currentFile: filePath,
          content: content,
          isDirty: false,
          isFolderSidebarVisible: true,
          isEditMode: defaultEditMode,
        ));
        break;
    }
    
    // Save last opened file to preferences and add to recent files
    _ref.read(preferencesProvider.notifier).setLastOpenedFile(filePath);
    _ref.read(preferencesProvider.notifier).addRecentFile(filePath);
  }

  void updateContent(String content) {
    _safeSetState(state.copyWith(
      content: content,
      isDirty: true,
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
      isDirty: false,
    ));
  }

  void closeFile() {
    _safeSetState(const AppState()); // This already sets isFolderSidebarVisible = false
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
      isSplitScreenMode: true,
      isSecondaryDirty: false,
      activeWindow: ActiveWindow.secondary,  // Set secondary window as active when opened
    ));
  }

  void updateSecondaryContent(String content) {
    _safeSetState(state.copyWith(
      secondaryContent: content,
      isSecondaryDirty: true,
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
      isSecondaryDirty: false,
    ));
  }

  void toggleFolderSidebar() {
    final newVisible = !state.isFolderSidebarVisible;
    _safeSetState(state.copyWith(
      isFolderSidebarVisible: newVisible,
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
    ));
  }

  void setActiveWindow(ActiveWindow window) {
    _safeSetState(state.copyWith(
      activeWindow: window,
    ));
  }
}