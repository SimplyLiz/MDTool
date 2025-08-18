import '../models/favorite_item.dart';

class FavoritesService {
  /// Add a favorite file to the list
  static List<FavoriteItem> addFavoriteFile(List<FavoriteItem> currentFavorites, String filePath) {
    return _addFavoriteItem(currentFavorites, FavoriteItem.file(filePath));
  }

  /// Add a favorite folder to the list
  static List<FavoriteItem> addFavoriteFolder(List<FavoriteItem> currentFavorites, String folderPath) {
    return _addFavoriteItem(currentFavorites, FavoriteItem.folder(folderPath));
  }

  /// Add a favorite item to the list, maintaining uniqueness
  static List<FavoriteItem> _addFavoriteItem(List<FavoriteItem> currentFavorites, FavoriteItem newItem) {
    final updatedFavorites = List<FavoriteItem>.from(currentFavorites);

    // Check if item already exists
    if (updatedFavorites.any((item) => item.path == newItem.path)) {
      return updatedFavorites; // Don't add duplicates
    }

    // Add new item at the beginning (most recently added first)
    updatedFavorites.insert(0, newItem);

    return updatedFavorites;
  }

  /// Remove a favorite item
  static List<FavoriteItem> removeFavoriteItem(List<FavoriteItem> currentFavorites, String path) {
    return currentFavorites.where((item) => item.path != path).toList();
  }

  /// Clear all favorite items
  static List<FavoriteItem> clearFavoriteItems() {
    return [];
  }

  /// Get favorite files only
  static List<FavoriteItem> getFavoriteFiles(List<FavoriteItem> favorites) {
    return favorites.where((item) => item.type == FavoriteItemType.file).toList();
  }

  /// Get favorite folders only
  static List<FavoriteItem> getFavoriteFolders(List<FavoriteItem> favorites) {
    return favorites.where((item) => item.type == FavoriteItemType.folder).toList();
  }

  /// Check if a path is in favorites
  static bool isFavorite(List<FavoriteItem> favorites, String path) {
    return favorites.any((item) => item.path == path);
  }

  /// Toggle favorite status for a path
  static List<FavoriteItem> toggleFavorite(List<FavoriteItem> currentFavorites, String path, FavoriteItemType type) {
    if (isFavorite(currentFavorites, path)) {
      return removeFavoriteItem(currentFavorites, path);
    } else {
      if (type == FavoriteItemType.file) {
        return addFavoriteFile(currentFavorites, path);
      } else {
        return addFavoriteFolder(currentFavorites, path);
      }
    }
  }
}