import 'package:equatable/equatable.dart';

class TabItem extends Equatable {
  final String id;
  final String? filePath;
  final String content;
  final String originalContent;
  final bool isDirty;
  final bool isPreview; // "preview" tab that gets replaced on next open (like VS Code italic tab)

  const TabItem({
    required this.id,
    this.filePath,
    this.content = '',
    this.originalContent = '',
    this.isDirty = false,
    this.isPreview = false,
  });

  String get displayName {
    if (filePath == null) return 'Untitled';
    return filePath!.split('/').last;
  }

  String get tooltip => filePath ?? 'Untitled';

  TabItem copyWith({
    String? id,
    String? filePath,
    String? content,
    String? originalContent,
    bool? isDirty,
    bool? isPreview,
  }) {
    return TabItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      originalContent: originalContent ?? this.originalContent,
      isDirty: isDirty ?? this.isDirty,
      isPreview: isPreview ?? this.isPreview,
    );
  }

  @override
  List<Object?> get props => [id, filePath, content, originalContent, isDirty, isPreview];
}
