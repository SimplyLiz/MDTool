import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/preferences.dart';
import '../models/favorite_item.dart';
import '../services/preferences_service.dart';
import '../services/recent_items_service.dart';
import '../services/favorites_service.dart';
import '../services/directory_permissions_service.dart';
import 'package:path/path.dart' as path;

// Provider for PreferencesService
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('PreferencesService must be overridden');
});

// StateNotifier for managing preferences
class PreferencesNotifier extends StateNotifier<AsyncValue<Preferences>> {
  final PreferencesService _preferencesService;

  PreferencesNotifier(this._preferencesService) : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final preferences = await _preferencesService.loadPreferences();
      state = AsyncValue.data(preferences);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update a preference and save to storage
  Future<void> updatePreferences(Preferences preferences) async {
    try {
      await _preferencesService.savePreferences(preferences);
      state = AsyncValue.data(preferences);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Convenience methods for updating individual preferences
  Future<void> setFontSize(double fontSize) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(fontSize: fontSize));
    }
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(isDarkMode: isDarkMode));
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(themeMode: themeMode));
    }
  }

  Future<void> setWordWrap(bool wordWrap) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(wordWrap: wordWrap));
    }
  }

  Future<void> setShowLineNumbers(bool showLineNumbers) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(showLineNumbers: showLineNumbers));
    }
  }

  Future<void> setFontFamily(String fontFamily) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(fontFamily: fontFamily));
    }
  }

  Future<void> setLastOpenedFile(String filePath) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(lastOpenedFile: filePath));
    }
  }

  Future<void> setWindowSize(double width, double height) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(
        windowWidth: width,
        windowHeight: height,
      ));
    }
  }

  Future<void> setOllamaEnabled(bool enabled) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(ollamaEnabled: enabled));
    }
  }

  Future<void> setOllamaBaseUrl(String baseUrl) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(ollamaBaseUrl: baseUrl));
    }
  }

  Future<void> setOllamaModel(String model) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(ollamaModel: model));
    }
  }

  Future<void> setOpenaiEnabled(bool enabled) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(openaiEnabled: enabled));
    }
  }

  Future<void> setOpenaiApiKey(String apiKey) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(openaiApiKey: apiKey));
    }
  }

  Future<void> setOpenaiModel(String model) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(openaiModel: model));
    }
  }

  Future<void> setOpenaiBaseUrl(String baseUrl) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(openaiBaseUrl: baseUrl));
    }
  }

  Future<void> setFilterDirectories(bool filterDirectories) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(filterDirectories: filterDirectories));
    }
  }

  Future<void> setAutoNavigateToFileFolder(bool autoNavigate) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(autoNavigateToFileFolder: autoNavigate));
    }
  }

  Future<void> setPreviewAutoEdit(bool previewAutoEdit) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(previewAutoEdit: previewAutoEdit));
    }
  }

  Future<void> setDefaultFolderSidebarVisible(bool visible) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(defaultFolderSidebarVisible: visible));
    }
  }

  Future<void> setDefaultScrollSyncEnabled(bool enabled) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(defaultScrollSyncEnabled: enabled));
    }
  }

  Future<void> setDefaultEditMode(bool editMode) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(defaultEditMode: editMode));
    }
  }


  /// Add a recent file to the list
  Future<void> addRecentFile(String filePath) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      final updatedItems = RecentItemsService.addRecentFile(currentPrefs.recentItems, filePath);
      await updatePreferences(currentPrefs.copyWith(recentItems: updatedItems));
      
      // Also ensure we have permission for the parent directory
      try {
        final parentDir = _getParentDirectory(filePath);
        final dirService = await _getDirectoryPermissionsService();
        
        // Check if we already have access to this directory
        if (!dirService.hasAccessToDirectory(parentDir)) {
          print('DEBUG: File was opened but parent directory not bookmarked: $parentDir');
          // We could try to add it, but without user interaction this might not work
          // The user will be prompted when they try to reopen from recent files
        }
      } catch (e) {
        print('DEBUG: Error checking directory permissions for recent file: $e');
      }
    }
  }

  /// Add a recent folder to the list
  Future<void> addRecentFolder(String folderPath) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      final updatedItems = RecentItemsService.addRecentFolder(currentPrefs.recentItems, folderPath);
      await updatePreferences(currentPrefs.copyWith(recentItems: updatedItems));
    }
  }

  /// Remove a recent item
  Future<void> removeRecentItem(String path) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      final updatedItems = RecentItemsService.removeRecentItem(currentPrefs.recentItems, path);
      await updatePreferences(currentPrefs.copyWith(recentItems: updatedItems));
    }
  }

  /// Clear all recent items
  Future<void> clearRecentItems() async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      final updatedItems = RecentItemsService.clearRecentItems();
      await updatePreferences(currentPrefs.copyWith(recentItems: updatedItems));
    }
  }

  /// Add a favorite file
  Future<void> addFavoriteFile(String filePath) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      final updatedFavorites = FavoritesService.addFavoriteFile(currentPrefs.favoriteItems, filePath);
      await updatePreferences(currentPrefs.copyWith(favoriteItems: updatedFavorites));
    }
  }

  /// Add a favorite folder
  Future<void> addFavoriteFolder(String folderPath) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      final updatedFavorites = FavoritesService.addFavoriteFolder(currentPrefs.favoriteItems, folderPath);
      await updatePreferences(currentPrefs.copyWith(favoriteItems: updatedFavorites));
    }
  }

  /// Remove a favorite item
  Future<void> removeFavoriteItem(String path) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      final updatedFavorites = FavoritesService.removeFavoriteItem(currentPrefs.favoriteItems, path);
      await updatePreferences(currentPrefs.copyWith(favoriteItems: updatedFavorites));
    }
  }

  /// Toggle favorite status for a path
  Future<void> toggleFavorite(String path, FavoriteItemType type) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      final updatedFavorites = FavoritesService.toggleFavorite(currentPrefs.favoriteItems, path, type);
      await updatePreferences(currentPrefs.copyWith(favoriteItems: updatedFavorites));
    }
  }

  /// Clear all favorite items
  Future<void> clearFavoriteItems() async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      final updatedFavorites = FavoritesService.clearFavoriteItems();
      await updatePreferences(currentPrefs.copyWith(favoriteItems: updatedFavorites));
    }
  }

  /// Check if a path is in favorites
  bool isFavorite(String path) {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      return FavoritesService.isFavorite(currentPrefs.favoriteItems, path);
    }
    return false;
  }

  /// Reset preferences to defaults
  Future<void> resetToDefaults() async {
    try {
      await _preferencesService.clearPreferences();
      const defaultPrefs = Preferences();
      await _preferencesService.savePreferences(defaultPrefs);
      state = const AsyncValue.data(defaultPrefs);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setScrollSyncEnabled(bool enabled) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      if (enabled) {
        // Disable caret sync when enabling scroll sync (mutually exclusive)
        await updatePreferences(currentPrefs.copyWith(
          defaultScrollSyncEnabled: enabled,
          defaultCaretSyncEnabled: false,
        ));
      } else {
        await updatePreferences(currentPrefs.copyWith(defaultScrollSyncEnabled: enabled));
      }
    }
  }

  Future<void> setCaretSyncEnabled(bool enabled) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      if (enabled) {
        // Disable scroll sync when enabling caret sync (mutually exclusive)
        await updatePreferences(currentPrefs.copyWith(
          defaultCaretSyncEnabled: enabled,
          defaultScrollSyncEnabled: false,
        ));
      } else {
        await updatePreferences(currentPrefs.copyWith(defaultCaretSyncEnabled: enabled));
      }
    }
  }

  Future<void> setWebSearchEnabled(bool enabled) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(webSearchEnabled: enabled));
    }
  }

  Future<void> setWebSearchApiKey(String apiKey) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(webSearchApiKey: apiKey));
    }
  }

  Future<void> setWebSearchEngineId(String engineId) async {
    final currentPrefs = state.valueOrNull;
    if (currentPrefs != null) {
      await updatePreferences(currentPrefs.copyWith(webSearchEngineId: engineId));
    }
  }

  // Helper methods
  String _getParentDirectory(String filePath) {
    return path.dirname(filePath);
  }
  
  Future<DirectoryPermissionsService> _getDirectoryPermissionsService() async {
    return await DirectoryPermissionsService.getInstance();
  }
}

// Provider for preferences state
final preferencesProvider = StateNotifierProvider<PreferencesNotifier, AsyncValue<Preferences>>((ref) {
  final preferencesService = ref.watch(preferencesServiceProvider);
  return PreferencesNotifier(preferencesService);
});