import 'package:equatable/equatable.dart';

enum ActiveWindow { primary, preview, secondary }

enum AppMode { overview, project }

class AppState extends Equatable {
  final String? currentFile;
  final String content;
  final String originalContent; // Track original file content
  final bool isEditMode;
  final bool isDirty;
  final bool isSplitScreenMode;
  final String? secondaryFile;
  final String secondaryContent;
  final String originalSecondaryContent; // Track original secondary file content
  final bool isSecondaryDirty;
  final bool isFolderSidebarVisible;
  final bool isPreviewVisible;
  final bool isScrollSyncEnabled;
  final bool? previousEditModeBeforePreview;
  final String? scrollToHeading;
  final int? scrollRequestId;
  final int? folderPickerRequestId;
  final String? droppedFolder;
  final String? currentFolderRoot;
  final ActiveWindow activeWindow;
  final AppMode appMode;

  const AppState({
    this.currentFile,
    this.content = '',
    this.originalContent = '',
    this.isEditMode = false,
    this.isDirty = false,
    this.isSplitScreenMode = false,
    this.secondaryFile,
    this.secondaryContent = '',
    this.originalSecondaryContent = '',
    this.isSecondaryDirty = false,
    this.isFolderSidebarVisible = false,
    this.isPreviewVisible = false,
    this.isScrollSyncEnabled = true,
    this.previousEditModeBeforePreview,
    this.scrollToHeading,
    this.scrollRequestId,
    this.folderPickerRequestId,
    this.droppedFolder,
    this.currentFolderRoot,
    this.activeWindow = ActiveWindow.primary,
    this.appMode = AppMode.overview,
  });

  AppState copyWith({
    String? currentFile,
    String? content,
    String? originalContent,
    bool? isEditMode,
    bool? isDirty,
    bool? isSplitScreenMode,
    String? secondaryFile,
    String? secondaryContent,
    String? originalSecondaryContent,
    bool? isSecondaryDirty,
    bool? isFolderSidebarVisible,
    bool? isPreviewVisible,
    bool? isScrollSyncEnabled,
    bool? previousEditModeBeforePreview,
    String? scrollToHeading,
    int? scrollRequestId,
    int? folderPickerRequestId,
    String? droppedFolder,
    String? currentFolderRoot,
    ActiveWindow? activeWindow,
    AppMode? appMode,
    bool clearDroppedFolder = false,
  }) {
    return AppState(
      currentFile: currentFile ?? this.currentFile,
      content: content ?? this.content,
      originalContent: originalContent ?? this.originalContent,
      isEditMode: isEditMode ?? this.isEditMode,
      isDirty: isDirty ?? this.isDirty,
      isSplitScreenMode: isSplitScreenMode ?? this.isSplitScreenMode,
      secondaryFile: secondaryFile ?? this.secondaryFile,
      secondaryContent: secondaryContent ?? this.secondaryContent,
      originalSecondaryContent: originalSecondaryContent ?? this.originalSecondaryContent,
      isSecondaryDirty: isSecondaryDirty ?? this.isSecondaryDirty,
      isFolderSidebarVisible: isFolderSidebarVisible ?? this.isFolderSidebarVisible,
      isPreviewVisible: isPreviewVisible ?? this.isPreviewVisible,
      isScrollSyncEnabled: isScrollSyncEnabled ?? this.isScrollSyncEnabled,
      previousEditModeBeforePreview: previousEditModeBeforePreview ?? this.previousEditModeBeforePreview,
      scrollToHeading: scrollToHeading ?? this.scrollToHeading,
      scrollRequestId: scrollRequestId ?? this.scrollRequestId,
      folderPickerRequestId: folderPickerRequestId ?? this.folderPickerRequestId,
      droppedFolder: clearDroppedFolder ? null : (droppedFolder ?? this.droppedFolder),
      currentFolderRoot: currentFolderRoot ?? this.currentFolderRoot,
      activeWindow: activeWindow ?? this.activeWindow,
      appMode: appMode ?? this.appMode,
    );
  }

  @override
  List<Object?> get props => [
        currentFile,
        content,
        originalContent,
        isEditMode,
        isDirty,
        isSplitScreenMode,
        secondaryFile,
        secondaryContent,
        originalSecondaryContent,
        isSecondaryDirty,
        isFolderSidebarVisible,
        isPreviewVisible,
        isScrollSyncEnabled,
        previousEditModeBeforePreview,
        scrollToHeading,
        scrollRequestId,
        folderPickerRequestId,
        droppedFolder,
        currentFolderRoot,
        activeWindow,
        appMode,
      ];
}