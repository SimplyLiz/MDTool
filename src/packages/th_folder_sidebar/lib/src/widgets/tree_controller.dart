import '../models/tree_item.dart';

/// Efficient tree controller for managing large hierarchical data structures
/// Supports lazy loading, virtualization, selection, and efficient updates
class TreeController {
  final List<TreeItem> _rootItems = [];
  final Map<String, TreeItem> _itemCache = {};
  final Set<String> _expandedPaths = {};
  final Set<String> _selectedPaths = {};
  
  // State tracking
  bool _isDisposed = false;
  int _version = 0;
  
  // Configuration
  final bool enableMultiSelection;
  final bool autoExpandOnSelect;
  final int maxCacheSize;
  
  TreeController({
    this.enableMultiSelection = false,
    this.autoExpandOnSelect = false,
    this.maxCacheSize = 1000,
  });
  
  /// Get the current version number (incremented on each change)
  int get version => _version;
  
  /// Check if the controller has been disposed
  bool get isDisposed => _isDisposed;
  
  /// Get all root items
  List<TreeItem> get rootItems => List.unmodifiable(_rootItems);
  
  /// Get the number of root items
  int get rootItemCount => _rootItems.length;
  
  /// Check if there are any items in the tree
  bool get isEmpty => _rootItems.isEmpty;
  
  /// Check if there are items in the tree
  bool get isNotEmpty => _rootItems.isNotEmpty;
  
  /// Get all expanded folder paths
  Set<String> get expandedPaths => Set.unmodifiable(_expandedPaths);
  
  /// Get all selected item paths
  Set<String> get selectedPaths => Set.unmodifiable(_selectedPaths);
  
  /// Get the currently selected item (first one if multiple selection is enabled)
  TreeItem? get selectedItem {
    if (_selectedPaths.isEmpty) return null;
    final path = _selectedPaths.first;
    return findItemByPath(path);
  }
  
  /// Get all currently selected items
  List<TreeItem> get selectedItems {
    return _selectedPaths
        .map((path) => findItemByPath(path))
        .where((item) => item != null)
        .cast<TreeItem>()
        .toList();
  }
  
  /// Set the root items (replaces all existing items)
  void setRootItems(List<TreeItem> items) {
    _checkDisposed();
    _rootItems.clear();
    _rootItems.addAll(items);
    _rebuildCache();
    _updateDepths();
    _incrementVersion();
  }
  
  /// Add a root item
  void addRootItem(TreeItem item) {
    _checkDisposed();
    item.depth = 0;
    _rootItems.add(item);
    _addToCache(item);
    _updateChildDepths(item);
    _incrementVersion();
  }
  
  /// Remove a root item
  bool removeRootItem(TreeItem item) {
    _checkDisposed();
    final removed = _rootItems.remove(item);
    if (removed) {
      _removeFromCache(item);
      _incrementVersion();
    }
    return removed;
  }
  
  /// Clear all items
  void clear() {
    _checkDisposed();
    _rootItems.clear();
    _itemCache.clear();
    _expandedPaths.clear();
    _selectedPaths.clear();
    _incrementVersion();
  }
  
  /// Toggle folder expansion state
  bool toggleExpansion(FolderTreeItem folder) {
    _checkDisposed();
    folder.isExpanded = !folder.isExpanded;
    
    if (folder.isExpanded) {
      _expandedPaths.add(folder.path);
    } else {
      _expandedPaths.remove(folder.path);
    }
    
    _incrementVersion();
    return folder.isExpanded;
  }
  
  /// Expand a folder
  void expand(FolderTreeItem folder) {
    _checkDisposed();
    if (!folder.isExpanded) {
      folder.isExpanded = true;
      _expandedPaths.add(folder.path);
      _incrementVersion();
    }
  }
  
  /// Collapse a folder
  void collapse(FolderTreeItem folder) {
    _checkDisposed();
    if (folder.isExpanded) {
      folder.isExpanded = false;
      _expandedPaths.remove(folder.path);
      _incrementVersion();
    }
  }
  
  /// Expand all folders
  void expandAll() {
    _checkDisposed();
    bool changed = false;
    
    void expandRecursively(List<TreeItem> items) {
      for (final item in items) {
        if (item is FolderTreeItem && !item.isExpanded) {
          item.isExpanded = true;
          _expandedPaths.add(item.path);
          changed = true;
          expandRecursively(item.children);
        }
      }
    }
    
    expandRecursively(_rootItems);
    if (changed) _incrementVersion();
  }
  
  /// Collapse all folders
  void collapseAll() {
    _checkDisposed();
    bool changed = false;
    
    void collapseRecursively(List<TreeItem> items) {
      for (final item in items) {
        if (item is FolderTreeItem && item.isExpanded) {
          item.isExpanded = false;
          _expandedPaths.remove(item.path);
          changed = true;
          collapseRecursively(item.children);
        }
      }
    }
    
    collapseRecursively(_rootItems);
    if (changed) _incrementVersion();
  }
  
  /// Select an item (clears previous selection unless multi-selection is enabled)
  void selectItem(TreeItem item) {
    _checkDisposed();
    
    if (!enableMultiSelection) {
      _selectedPaths.clear();
    }
    
    _selectedPaths.add(item.path);
    
    // Auto-expand parent folders if enabled
    if (autoExpandOnSelect) {
      final parent = findParentOf(item);
      if (parent is FolderTreeItem && !parent.isExpanded) {
        expand(parent);
      }
    }
    
    _incrementVersion();
  }
  
  /// Add an item to the selection (multi-selection mode)
  void addToSelection(TreeItem item) {
    _checkDisposed();
    if (enableMultiSelection) {
      _selectedPaths.add(item.path);
      _incrementVersion();
    } else {
      selectItem(item);
    }
  }
  
  /// Remove an item from the selection
  void removeFromSelection(TreeItem item) {
    _checkDisposed();
    final removed = _selectedPaths.remove(item.path);
    if (removed) _incrementVersion();
  }
  
  /// Clear all selections
  void clearSelection() {
    _checkDisposed();
    if (_selectedPaths.isNotEmpty) {
      _selectedPaths.clear();
      _incrementVersion();
    }
  }
  
  /// Check if an item is selected
  bool isSelected(TreeItem item) {
    return _selectedPaths.contains(item.path);
  }
  
  /// Check if a folder is expanded
  bool isExpanded(FolderTreeItem folder) {
    return folder.isExpanded;
  }
  
  /// Find an item by its path
  TreeItem? findItemByPath(String path) {
    return _itemCache[path];
  }
  
  /// Find the parent of an item
  TreeItem? findParentOf(TreeItem item) {
    TreeItem? findParentRecursively(List<TreeItem> items) {
      for (final currentItem in items) {
        if (currentItem is FolderTreeItem) {
          for (final child in currentItem.children) {
            if (child.path == item.path) {
              return currentItem;
            }
          }
          final found = findParentRecursively(currentItem.children);
          if (found != null) return found;
        }
      }
      return null;
    }
    
    return findParentRecursively(_rootItems);
  }
  
  /// Find all children of a folder (direct children only)
  List<TreeItem> getChildren(FolderTreeItem folder) {
    return List.unmodifiable(folder.children);
  }
  
  /// Find all descendants of a folder (recursive)
  List<TreeItem> getDescendants(FolderTreeItem folder) {
    return folder.getAllDescendants();
  }
  
  /// Get flattened list of only visible items for virtualization
  List<TreeItem> getFlattenedVisibleItems() {
    final result = <TreeItem>[];
    _flattenVisible(_rootItems, result, 0);
    return result;
  }
  
  /// Get all items in the tree (flattened)
  List<TreeItem> getAllItems() {
    final result = <TreeItem>[];
    _flattenAll(_rootItems, result);
    return result;
  }
  
  /// Get items at a specific depth level
  List<TreeItem> getItemsAtDepth(int depth) {
    return getAllItems().where((item) => item.depth == depth).toList();
  }
  
  /// Get the maximum depth in the tree
  int getMaxDepth() {
    int maxDepth = 0;
    for (final item in getAllItems()) {
      if (item.depth > maxDepth) {
        maxDepth = item.depth;
      }
    }
    return maxDepth;
  }
  
  /// Get tree statistics
  TreeStatistics getStatistics() {
    final allItems = getAllItems();
    final folders = allItems.whereType<FolderTreeItem>().toList();
    final files = allItems.whereType<FileTreeItem>().toList();
    
    return TreeStatistics(
      totalItems: allItems.length,
      totalFolders: folders.length,
      totalFiles: files.length,
      expandedFolders: folders.where((f) => f.isExpanded).length,
      selectedItems: _selectedPaths.length,
      maxDepth: getMaxDepth(),
      cacheSize: _itemCache.length,
    );
  }
  
  /// Refresh the tree by rebuilding cache and updating depths
  void refresh() {
    _checkDisposed();
    _rebuildCache();
    _updateDepths();
    _incrementVersion();
  }
  
  /// Dispose the controller and clean up resources
  void dispose() {
    if (!_isDisposed) {
      _rootItems.clear();
      _itemCache.clear();
      _expandedPaths.clear();
      _selectedPaths.clear();
      _isDisposed = true;
    }
  }
  
  // Private methods
  
  void _checkDisposed() {
    if (_isDisposed) {
      throw StateError('TreeController has been disposed');
    }
  }
  
  void _incrementVersion() {
    _version++;
  }
  
  void _flattenVisible(List<TreeItem> items, List<TreeItem> result, int depth) {
    for (final item in items) {
      item.depth = depth;
      result.add(item);
      
      if (item is FolderTreeItem && item.isExpanded) {
        _flattenVisible(item.children, result, depth + 1);
      }
    }
  }
  
  void _flattenAll(List<TreeItem> items, List<TreeItem> result) {
    for (final item in items) {
      result.add(item);
      if (item is FolderTreeItem) {
        _flattenAll(item.children, result);
      }
    }
  }
  
  void _updateDepths() {
    _updateItemDepths(_rootItems, 0);
  }
  
  void _updateItemDepths(List<TreeItem> items, int depth) {
    for (final item in items) {
      item.depth = depth;
      if (item is FolderTreeItem) {
        _updateItemDepths(item.children, depth + 1);
      }
    }
  }
  
  void _updateChildDepths(TreeItem item) {
    if (item is FolderTreeItem) {
      _updateItemDepths(item.children, item.depth + 1);
    }
  }
  
  void _rebuildCache() {
    _itemCache.clear();
    _addAllToCache(_rootItems);
  }
  
  void _addAllToCache(List<TreeItem> items) {
    for (final item in items) {
      _addToCache(item);
      if (item is FolderTreeItem) {
        _addAllToCache(item.children);
      }
    }
  }
  
  void _addToCache(TreeItem item) {
    _itemCache[item.path] = item;
    
    // Maintain cache size limit
    if (_itemCache.length > maxCacheSize) {
      _trimCache();
    }
  }
  
  void _removeFromCache(TreeItem item) {
    _itemCache.remove(item.path);
    if (item is FolderTreeItem) {
      for (final child in item.children) {
        _removeFromCache(child);
      }
    }
  }
  
  void _trimCache() {
    // Remove oldest items from cache (simple FIFO approach)
    if (_itemCache.length > maxCacheSize) {
      final excess = _itemCache.length - maxCacheSize;
      final keysToRemove = _itemCache.keys.take(excess).toList();
      for (final key in keysToRemove) {
        _itemCache.remove(key);
      }
    }
  }
}

/// Statistics about the tree structure
class TreeStatistics {
  final int totalItems;
  final int totalFolders;
  final int totalFiles;
  final int expandedFolders;
  final int selectedItems;
  final int maxDepth;
  final int cacheSize;
  
  const TreeStatistics({
    required this.totalItems,
    required this.totalFolders,
    required this.totalFiles,
    required this.expandedFolders,
    required this.selectedItems,
    required this.maxDepth,
    required this.cacheSize,
  });
  
  /// Get the percentage of expanded folders
  double get expansionRatio {
    if (totalFolders == 0) return 0.0;
    return expandedFolders / totalFolders;
  }
  
  /// Get the percentage of selected items
  double get selectionRatio {
    if (totalItems == 0) return 0.0;
    return selectedItems / totalItems;
  }
  
  /// Get the average items per folder
  double get averageItemsPerFolder {
    if (totalFolders == 0) return 0.0;
    return totalFiles / totalFolders;
  }
  
  @override
  String toString() {
    return 'TreeStatistics(items: $totalItems, folders: $totalFolders, files: $totalFiles, '
           'expanded: $expandedFolders, selected: $selectedItems, depth: $maxDepth, cache: $cacheSize)';
  }
}