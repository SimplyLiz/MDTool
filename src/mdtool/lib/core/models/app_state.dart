import 'package:equatable/equatable.dart';

enum ActiveWindow { primary, preview, secondary }

class AppState extends Equatable {
  final String? currentFile;
  final String content;
  final bool isEditMode;
  final bool isDirty;
  final bool isSplitScreenMode;
  final String? secondaryFile;
  final String secondaryContent;
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

  const AppState({
    this.currentFile,
    this.content = '',
    this.isEditMode = false,
    this.isDirty = false,
    this.isSplitScreenMode = false,
    this.secondaryFile,
    this.secondaryContent = '',
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
  });

  AppState copyWith({
    String? currentFile,
    String? content,
    bool? isEditMode,
    bool? isDirty,
    bool? isSplitScreenMode,
    String? secondaryFile,
    String? secondaryContent,
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
  }) {
    return AppState(
      currentFile: currentFile ?? this.currentFile,
      content: content ?? this.content,
      isEditMode: isEditMode ?? this.isEditMode,
      isDirty: isDirty ?? this.isDirty,
      isSplitScreenMode: isSplitScreenMode ?? this.isSplitScreenMode,
      secondaryFile: secondaryFile ?? this.secondaryFile,
      secondaryContent: secondaryContent ?? this.secondaryContent,
      isSecondaryDirty: isSecondaryDirty ?? this.isSecondaryDirty,
      isFolderSidebarVisible: isFolderSidebarVisible ?? this.isFolderSidebarVisible,
      isPreviewVisible: isPreviewVisible ?? this.isPreviewVisible,
      isScrollSyncEnabled: isScrollSyncEnabled ?? this.isScrollSyncEnabled,
      previousEditModeBeforePreview: previousEditModeBeforePreview ?? this.previousEditModeBeforePreview,
      scrollToHeading: scrollToHeading ?? this.scrollToHeading,
      scrollRequestId: scrollRequestId ?? this.scrollRequestId,
      folderPickerRequestId: folderPickerRequestId ?? this.folderPickerRequestId,
      droppedFolder: droppedFolder ?? this.droppedFolder,
      currentFolderRoot: currentFolderRoot ?? this.currentFolderRoot,
      activeWindow: activeWindow ?? this.activeWindow,
    );
  }

  @override
  List<Object?> get props => [
        currentFile,
        content,
        isEditMode,
        isDirty,
        isSplitScreenMode,
        secondaryFile,
        secondaryContent,
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
      ];
}