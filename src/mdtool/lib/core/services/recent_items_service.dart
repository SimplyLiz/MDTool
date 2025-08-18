import '../models/recent_item.dart';

class RecentItemsService {
  static const int maxRecentItems = 10;

  /// Add a recent file to the list
  static List<RecentItem> addRecentFile(List<RecentItem> currentItems, String filePath) {
    return _addRecentItem(currentItems, RecentItem.file(filePath));
  }

  /// Add a recent folder to the list
  static List<RecentItem> addRecentFolder(List<RecentItem> currentItems, String folderPath) {
    return _addRecentItem(currentItems, RecentItem.folder(folderPath));
  }

  /// Add a recent item to the list, maintaining uniqueness and order
  static List<RecentItem> _addRecentItem(List<RecentItem> currentItems, RecentItem newItem) {
    final updatedItems = List<RecentItem>.from(currentItems);

    // Remove existing item with same path if it exists
    updatedItems.removeWhere((item) => item.path == newItem.path);

    // Add new item at the beginning
    updatedItems.insert(0, newItem);

    // Keep only the most recent items
    if (updatedItems.length > maxRecentItems) {
      updatedItems.removeRange(maxRecentItems, updatedItems.length);
    }

    return updatedItems;
  }

  /// Remove an item from recent items
  static List<RecentItem> removeRecentItem(List<RecentItem> currentItems, String path) {
    return currentItems.where((item) => item.path != path).toList();
  }

  /// Clear all recent items
  static List<RecentItem> clearRecentItems() {
    return [];
  }

  /// Get recent files only
  static List<RecentItem> getRecentFiles(List<RecentItem> items) {
    return items.where((item) => item.type == RecentItemType.file).toList();
  }

  /// Get recent folders only
  static List<RecentItem> getRecentFolders(List<RecentItem> items) {
    return items.where((item) => item.type == RecentItemType.folder).toList();
  }

  /// Check if a path exists in recent items
  static bool hasRecentItem(List<RecentItem> items, String path) {
    return items.any((item) => item.path == path);
  }
}