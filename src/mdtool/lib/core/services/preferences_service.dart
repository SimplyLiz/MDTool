import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/preferences.dart';

class PreferencesService {
  static const String _preferencesKey = 'md_tool_preferences';
  static PreferencesService? _instance;
  SharedPreferences? _prefs;

  PreferencesService._();

  static Future<PreferencesService> getInstance() async {
    _instance ??= PreferencesService._();
    _instance!._prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Load preferences from local storage
  Future<Preferences> loadPreferences() async {
    try {
      final prefsString = _prefs?.getString(_preferencesKey);
      if (prefsString != null) {
        final Map<String, dynamic> prefsMap = jsonDecode(prefsString);
        return Preferences.fromJson(prefsMap);
      }
    } catch (e) {
      // If there's an error loading preferences, return defaults
      print('Error loading preferences: $e');
    }
    
    // Return default preferences if none exist or error occurred
    return const Preferences();
  }

  /// Save preferences to local storage
  Future<void> savePreferences(Preferences preferences) async {
    try {
      final prefsString = jsonEncode(preferences.toJson());
      await _prefs?.setString(_preferencesKey, prefsString);
    } catch (e) {
      print('Error saving preferences: $e');
      throw Exception('Failed to save preferences: $e');
    }
  }

  /// Clear all preferences (reset to defaults)
  Future<void> clearPreferences() async {
    try {
      await _prefs?.remove(_preferencesKey);
    } catch (e) {
      print('Error clearing preferences: $e');
      throw Exception('Failed to clear preferences: $e');
    }
  }

  /// Save individual preference values for convenience
  Future<void> setFontSize(double fontSize) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(fontSize: fontSize));
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(isDarkMode: isDarkMode));
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(themeMode: themeMode));
  }

  Future<void> setWordWrap(bool wordWrap) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(wordWrap: wordWrap));
  }

  Future<void> setShowLineNumbers(bool showLineNumbers) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(showLineNumbers: showLineNumbers));
  }

  Future<void> setFontFamily(String fontFamily) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(fontFamily: fontFamily));
  }

  Future<void> setLastOpenedFile(String filePath) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(lastOpenedFile: filePath));
  }

  Future<void> setWindowSize(double width, double height) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(
      windowWidth: width,
      windowHeight: height,
    ));
  }

  Future<void> setOllamaEnabled(bool enabled) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(ollamaEnabled: enabled));
  }

  Future<void> setOllamaBaseUrl(String baseUrl) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(ollamaBaseUrl: baseUrl));
  }

  Future<void> setOllamaModel(String model) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(ollamaModel: model));
  }

  Future<void> setOpenaiEnabled(bool enabled) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(openaiEnabled: enabled));
  }

  Future<void> setOpenaiApiKey(String apiKey) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(openaiApiKey: apiKey));
  }

  Future<void> setOpenaiModel(String model) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(openaiModel: model));
  }

  Future<void> setOpenaiBaseUrl(String baseUrl) async {
    final prefs = await loadPreferences();
    await savePreferences(prefs.copyWith(openaiBaseUrl: baseUrl));
  }
}