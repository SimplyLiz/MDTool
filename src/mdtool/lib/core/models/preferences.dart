import 'package:equatable/equatable.dart';
import 'recent_item.dart';
import 'favorite_item.dart';

enum ThemeMode { system, light, dark }

class Preferences extends Equatable {
  final double fontSize;
  final bool isDarkMode; // Keep for backward compatibility
  final ThemeMode themeMode;
  final bool wordWrap;
  final bool showLineNumbers;
  final String fontFamily;
  final double windowWidth;
  final double windowHeight;
  final String lastOpenedFile;
  final bool ollamaEnabled;
  final String ollamaBaseUrl;
  final String ollamaModel;
  final bool openaiEnabled;
  final String openaiApiKey;
  final String openaiModel;
  final String openaiBaseUrl;
  final bool filterDirectories;
  final bool autoNavigateToFileFolder;
  final bool previewAutoEdit;
  final bool defaultFolderSidebarVisible;
  final bool defaultScrollSyncEnabled;
  final bool defaultCaretSyncEnabled;
  final bool defaultEditMode;
  final List<RecentItem> recentItems;
  final List<FavoriteItem> favoriteItems;
  final bool webSearchEnabled;
  final String webSearchApiKey;
  final String webSearchEngineId;

  const Preferences({
    this.fontSize = 14.0,
    this.isDarkMode = false, // Keep for backward compatibility
    this.themeMode = ThemeMode.system,
    this.wordWrap = true,
    this.showLineNumbers = false,
    this.fontFamily = 'SF Pro Text',
    this.windowWidth = 1200.0,
    this.windowHeight = 800.0,
    this.lastOpenedFile = '',
    this.ollamaEnabled = false,
    this.ollamaBaseUrl = 'http://localhost:11434',
    this.ollamaModel = 'llama2',
    this.openaiEnabled = false,
    this.openaiApiKey = '',
    this.openaiModel = 'gpt-5',
    this.openaiBaseUrl = 'https://api.openai.com/v1',
    this.filterDirectories = false,
    this.autoNavigateToFileFolder = false,
    this.previewAutoEdit = true,
    this.defaultFolderSidebarVisible = false,
    this.defaultScrollSyncEnabled = false,
    this.defaultCaretSyncEnabled = true,
    this.defaultEditMode = false,
    this.recentItems = const [],
    this.favoriteItems = const [],
    this.webSearchEnabled = false,
    this.webSearchApiKey = '',
    this.webSearchEngineId = '',
  });

  Preferences copyWith({
    double? fontSize,
    bool? isDarkMode,
    ThemeMode? themeMode,
    bool? wordWrap,
    bool? showLineNumbers,
    String? fontFamily,
    double? windowWidth,
    double? windowHeight,
    String? lastOpenedFile,
    bool? ollamaEnabled,
    String? ollamaBaseUrl,
    String? ollamaModel,
    bool? openaiEnabled,
    String? openaiApiKey,
    String? openaiModel,
    String? openaiBaseUrl,
    bool? filterDirectories,
    bool? autoNavigateToFileFolder,
    bool? previewAutoEdit,
    bool? defaultFolderSidebarVisible,
    bool? defaultScrollSyncEnabled,
    bool? defaultCaretSyncEnabled,
    bool? defaultEditMode,
    List<RecentItem>? recentItems,
    List<FavoriteItem>? favoriteItems,
    bool? webSearchEnabled,
    String? webSearchApiKey,
    String? webSearchEngineId,
  }) {
    return Preferences(
      fontSize: fontSize ?? this.fontSize,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      themeMode: themeMode ?? this.themeMode,
      wordWrap: wordWrap ?? this.wordWrap,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      fontFamily: fontFamily ?? this.fontFamily,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      lastOpenedFile: lastOpenedFile ?? this.lastOpenedFile,
      ollamaEnabled: ollamaEnabled ?? this.ollamaEnabled,
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      openaiEnabled: openaiEnabled ?? this.openaiEnabled,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      openaiModel: openaiModel ?? this.openaiModel,
      openaiBaseUrl: openaiBaseUrl ?? this.openaiBaseUrl,
      filterDirectories: filterDirectories ?? this.filterDirectories,
      autoNavigateToFileFolder: autoNavigateToFileFolder ?? this.autoNavigateToFileFolder,
      previewAutoEdit: previewAutoEdit ?? this.previewAutoEdit,
      defaultFolderSidebarVisible: defaultFolderSidebarVisible ?? this.defaultFolderSidebarVisible,
      defaultScrollSyncEnabled: defaultScrollSyncEnabled ?? this.defaultScrollSyncEnabled,
      defaultCaretSyncEnabled: defaultCaretSyncEnabled ?? this.defaultCaretSyncEnabled,
      defaultEditMode: defaultEditMode ?? this.defaultEditMode,
      recentItems: recentItems ?? this.recentItems,
      favoriteItems: favoriteItems ?? this.favoriteItems,
      webSearchEnabled: webSearchEnabled ?? this.webSearchEnabled,
      webSearchApiKey: webSearchApiKey ?? this.webSearchApiKey,
      webSearchEngineId: webSearchEngineId ?? this.webSearchEngineId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'isDarkMode': isDarkMode,
      'themeMode': themeMode.name,
      'wordWrap': wordWrap,
      'showLineNumbers': showLineNumbers,
      'fontFamily': fontFamily,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'lastOpenedFile': lastOpenedFile,
      'ollamaEnabled': ollamaEnabled,
      'ollamaBaseUrl': ollamaBaseUrl,
      'ollamaModel': ollamaModel,
      'openaiEnabled': openaiEnabled,
      'openaiApiKey': openaiApiKey,
      'openaiModel': openaiModel,
      'openaiBaseUrl': openaiBaseUrl,
      'filterDirectories': filterDirectories,
      'autoNavigateToFileFolder': autoNavigateToFileFolder,
      'previewAutoEdit': previewAutoEdit,
      'defaultFolderSidebarVisible': defaultFolderSidebarVisible,
      'defaultScrollSyncEnabled': defaultScrollSyncEnabled,
      'defaultCaretSyncEnabled': defaultCaretSyncEnabled,
      'defaultEditMode': defaultEditMode,
      'recentItems': recentItems.map((item) => item.toJson()).toList(),
      'favoriteItems': favoriteItems.map((item) => item.toJson()).toList(),
      'webSearchEnabled': webSearchEnabled,
      'webSearchApiKey': webSearchApiKey,
      'webSearchEngineId': webSearchEngineId,
    };
  }

  factory Preferences.fromJson(Map<String, dynamic> json) {
    ThemeMode themeMode = ThemeMode.system;
    try {
      themeMode = ThemeMode.values.byName(json['themeMode'] as String? ?? 'system');
    } catch (e) {
      // Fall back to legacy isDarkMode if themeMode is not available
      final isDarkMode = json['isDarkMode'] as bool? ?? false;
      themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }

    return Preferences(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      themeMode: themeMode,
      wordWrap: json['wordWrap'] as bool? ?? true,
      showLineNumbers: json['showLineNumbers'] as bool? ?? false,
      fontFamily: json['fontFamily'] as String? ?? 'SF Pro Text',
      windowWidth: (json['windowWidth'] as num?)?.toDouble() ?? 1200.0,
      windowHeight: (json['windowHeight'] as num?)?.toDouble() ?? 800.0,
      lastOpenedFile: json['lastOpenedFile'] as String? ?? '',
      ollamaEnabled: json['ollamaEnabled'] as bool? ?? false,
      ollamaBaseUrl: json['ollamaBaseUrl'] as String? ?? 'http://localhost:11434',
      ollamaModel: json['ollamaModel'] as String? ?? 'llama2',
      openaiEnabled: json['openaiEnabled'] as bool? ?? false,
      openaiApiKey: json['openaiApiKey'] as String? ?? '',
      openaiModel: json['openaiModel'] as String? ?? 'gpt-5',
      openaiBaseUrl: json['openaiBaseUrl'] as String? ?? 'https://api.openai.com/v1',
      filterDirectories: json['filterDirectories'] as bool? ?? false,
      autoNavigateToFileFolder: json['autoNavigateToFileFolder'] as bool? ?? false,
      previewAutoEdit: json['previewAutoEdit'] as bool? ?? true,
      defaultFolderSidebarVisible: json['defaultFolderSidebarVisible'] as bool? ?? false,
      defaultScrollSyncEnabled: json['defaultScrollSyncEnabled'] as bool? ?? false,
      defaultCaretSyncEnabled: json['defaultCaretSyncEnabled'] as bool? ?? true,
      defaultEditMode: json['defaultEditMode'] as bool? ?? false,
      recentItems: (json['recentItems'] as List<dynamic>?)
          ?.map((item) => RecentItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      favoriteItems: (json['favoriteItems'] as List<dynamic>?)
          ?.map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      webSearchEnabled: json['webSearchEnabled'] as bool? ?? false,
      webSearchApiKey: json['webSearchApiKey'] as String? ?? '',
      webSearchEngineId: json['webSearchEngineId'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        fontSize,
        isDarkMode,
        themeMode,
        wordWrap,
        showLineNumbers,
        fontFamily,
        windowWidth,
        windowHeight,
        lastOpenedFile,
        ollamaEnabled,
        ollamaBaseUrl,
        ollamaModel,
        openaiEnabled,
        openaiApiKey,
        openaiModel,
        openaiBaseUrl,
        filterDirectories,
        autoNavigateToFileFolder,
        previewAutoEdit,
        defaultFolderSidebarVisible,
        defaultScrollSyncEnabled,
        defaultCaretSyncEnabled,
        defaultEditMode,
        recentItems,
        favoriteItems,
        webSearchEnabled,
        webSearchApiKey,
        webSearchEngineId,
      ];
}