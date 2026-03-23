/// Base class for tree items in the folder sidebar
abstract class TreeItem {
  final String name;
  final String path;
  int depth;
  TreeItemType get type;
  
  TreeItem({
    required this.name,
    required this.path,
    this.depth = 0,
  });

  /// Get the display name for this item
  String get displayName => name;
  
  /// Get the file extension (for files) or empty string (for folders)
  String get extension {
    if (type == TreeItemType.file && name.contains('.')) {
      return name.substring(name.lastIndexOf('.'));
    }
    return '';
  }
}

/// Folder tree item with lazy loading support
class FolderTreeItem extends TreeItem {
  bool isExpanded;
  bool isLoaded;
  bool isLoading;
  int fileCount;
  final List<TreeItem> children = [];
  
  @override
  TreeItemType get type => TreeItemType.folder;
  
  FolderTreeItem({
    required super.name,
    required super.path,
    super.depth,
    this.isExpanded = false,
    this.isLoaded = false,
    this.isLoading = false,
    this.fileCount = 0,
  });

  /// Check if this folder has any children
  bool get hasChildren => children.isNotEmpty || (!isLoaded && fileCount > 0);
  
  /// Check if this folder can be expanded
  bool get canExpand => hasChildren && !isLoading;
  
  /// Get all descendant items recursively
  List<TreeItem> getAllDescendants() {
    final List<TreeItem> descendants = [];
    
    void collectDescendants(List<TreeItem> items) {
      for (final item in items) {
        descendants.add(item);
        if (item is FolderTreeItem && item.isExpanded) {
          collectDescendants(item.children);
        }
      }
    }
    
    collectDescendants(children);
    return descendants;
  }
  
  /// Add a child item and update its depth
  void addChild(TreeItem child) {
    child.depth = depth + 1;
    children.add(child);
    
    // Update child depths recursively for folders
    if (child is FolderTreeItem) {
      _updateChildDepths(child, child.depth);
    }
  }
  
  /// Add multiple children and update their depths
  void addChildren(List<TreeItem> newChildren) {
    for (final child in newChildren) {
      addChild(child);
    }
  }
  
  /// Remove a child item
  bool removeChild(TreeItem child) {
    return children.remove(child);
  }
  
  /// Clear all children
  void clearChildren() {
    children.clear();
  }
  
  /// Find a child by path
  TreeItem? findChild(String path) {
    for (final child in children) {
      if (child.path == path) {
        return child;
      }
    }
    return null;
  }
  
  /// Recursively update depths for all child items
  void _updateChildDepths(FolderTreeItem folder, int depth) {
    for (final child in folder.children) {
      child.depth = depth + 1;
      if (child is FolderTreeItem) {
        _updateChildDepths(child, child.depth);
      }
    }
  }
}

/// File tree item
class FileTreeItem extends TreeItem {
  final DateTime? lastModified;
  final int? sizeBytes;
  
  @override
  TreeItemType get type => TreeItemType.file;
  
  FileTreeItem({
    required super.name,
    required super.path,
    super.depth,
    this.lastModified,
    this.sizeBytes,
  });
  
  /// Get human-readable file size
  String get formattedSize {
    if (sizeBytes == null) return '';
    
    const List<String> units = ['B', 'KB', 'MB', 'GB'];
    double size = sizeBytes!.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }
  
  /// Check if this is a markdown file
  bool get isMarkdownFile {
    final ext = extension.toLowerCase();
    return ext == '.md' || ext == '.markdown' || ext == '.mdown' || ext == '.mkd' || ext == '.mkdn';
  }
  
  /// Get the file name without extension
  String get nameWithoutExtension {
    if (extension.isEmpty) return name;
    return name.substring(0, name.length - extension.length);
  }
}

/// Types of tree items
enum TreeItemType { 
  folder, 
  file 
}

/// Extension methods for TreeItemType
extension TreeItemTypeExtension on TreeItemType {
  /// Get a human-readable name for the type
  String get displayName {
    switch (this) {
      case TreeItemType.folder:
        return 'Folder';
      case TreeItemType.file:
        return 'File';
    }
  }
  
  /// Check if this type represents a container
  bool get isContainer => this == TreeItemType.folder;
}