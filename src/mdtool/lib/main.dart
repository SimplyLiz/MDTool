import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'ui/pages/main_page.dart';
import 'ui/pages/diff_comparison_page.dart';
import 'ui/themes/app_theme.dart';
import 'core/services/preferences_service.dart';
import 'core/providers/preferences_provider.dart';
import 'core/models/preferences.dart' as prefs;
import 'core/providers/app_state_provider.dart';
import 'core/services/file_service.dart';
import 'core/models/app_state.dart';

// Global container reference for accessing providers from method channel
ProviderContainer? _globalContainer;

// Queue for file open requests that arrive before the app is ready
String? _pendingFileToOpen;
bool _appIsReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize preferences service
  final preferencesService = await PreferencesService.getInstance();

  // Set up method channel for file opening
  const platform = MethodChannel('open_file_channel');
  platform.setMethodCallHandler((call) async {
    if (call.method == "openFile") {
      final filePath = call.arguments as String;
      print("DEBUG: Received file to open from Finder: $filePath");

      // If app isn't ready yet, queue the request
      if (!_appIsReady || _globalContainer == null) {
        print("DEBUG: App not ready, queuing file open request");
        _pendingFileToOpen = filePath;
        return;
      }

      await _openFileFromFinder(filePath);
    }
  });

  // Create provider container with global reference
  final container = ProviderContainer(
    overrides: [
      preferencesServiceProvider.overrideWithValue(preferencesService),
    ],
  );
  _globalContainer = container;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MDToolApp(),
    ),
  );
}

/// Opens a file from Finder in single-file preview mode
Future<void> _openFileFromFinder(String filePath) async {
  if (_globalContainer == null) {
    print("ERROR: Global container not initialized");
    return;
  }

  try {
    final fileService = FileService();
    final content = await fileService.readFile(filePath);

    // Open file in single-file mode (preview mode, no folder tree auto-expand)
    _globalContainer!.read(appStateProvider.notifier).openFileFromExternal(filePath, content);

    print("DEBUG: Successfully opened file in preview mode: $filePath");
  } catch (e) {
    print("ERROR: Failed to open file from Finder: $e");
  }
}

/// Called when the app is ready to process pending file open requests
void _onAppReady() {
  _appIsReady = true;

  // Process any pending file open request
  if (_pendingFileToOpen != null) {
    final filePath = _pendingFileToOpen!;
    _pendingFileToOpen = null;
    print("DEBUG: Processing queued file open request: $filePath");
    _openFileFromFinder(filePath);
  }
}

class MDToolApp extends ConsumerStatefulWidget {
  const MDToolApp({super.key});

  @override
  ConsumerState<MDToolApp> createState() => _MDToolAppState();
}

class _MDToolAppState extends ConsumerState<MDToolApp> {
  bool _hasSignaledReady = false;

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(preferencesProvider);

    // Signal app ready after first frame
    if (!_hasSignaledReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasSignaledReady) {
          _hasSignaledReady = true;
          _onAppReady();
        }
      });
    }
    
    return preferencesAsync.when(
      data: (preferences) {
        ThemeMode themeMode;
        switch (preferences.themeMode) {
          case prefs.ThemeMode.system:
            themeMode = ThemeMode.system;
            break;
          case prefs.ThemeMode.light:
            themeMode = ThemeMode.light;
            break;
          case prefs.ThemeMode.dark:
            themeMode = ThemeMode.dark;
            break;
        }
        
        return MaterialApp(
          title: 'MDTool',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: KeyboardShortcutsWrapper(child: const MainPage()),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/diff':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => DiffComparisonPage(
                    initialLeftFile: args?['leftFile'],
                    initialLeftContent: args?['leftContent'],
                    initialRightFile: args?['rightFile'],
                    initialRightContent: args?['rightContent'],
                  ),
                );
              default:
                return null;
            }
          },
          debugShowCheckedModeBanner: false,
        );
      },
      loading: () => MaterialApp(
        title: 'MDTool',
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
      error: (error, stack) => MaterialApp(
        title: 'MDTool',
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading preferences: $error'),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Intent classes for keyboard shortcuts
class SaveIntent extends Intent {
  const SaveIntent();
}

class KeyboardShortcutsWrapper extends ConsumerWidget {
  final Widget child;

  const KeyboardShortcutsWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Cmd+S on Mac, Ctrl+S on Windows/Linux
        LogicalKeySet(
          Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyS,
        ): const SaveIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (SaveIntent intent) => _handleSave(ref, context),
          ),
        },
        child: child,
      ),
    );
  }

  void _handleSave(WidgetRef ref, BuildContext context) async {
    final appState = ref.read(appStateProvider);
    bool didSave = false;
    
    // Determine which file to save based on active window
    switch (appState.activeWindow) {
      case ActiveWindow.primary:
        if (appState.currentFile != null && appState.isDirty) {
          await _saveFile(ref, context, appState.currentFile!, appState.content);
          didSave = true;
        } else if (appState.currentFile != null && !appState.isDirty) {
          _showNoChangesMessage(context, 'No changes to save');
        } else {
          _showNoFileMessage(context);
        }
        break;
      case ActiveWindow.secondary:
        if (appState.secondaryFile != null && appState.isSecondaryDirty) {
          await _saveSecondaryFile(ref, context, appState.secondaryFile!, appState.secondaryContent);
          didSave = true;
        } else if (appState.secondaryFile != null && !appState.isSecondaryDirty) {
          _showNoChangesMessage(context, 'No changes to save');
        } else {
          _showNoFileMessage(context);
        }
        break;
      case ActiveWindow.preview:
        // Preview window doesn't have editable content, save primary instead
        if (appState.currentFile != null && appState.isDirty) {
          await _saveFile(ref, context, appState.currentFile!, appState.content);
          didSave = true;
        } else if (appState.currentFile != null && !appState.isDirty) {
          _showNoChangesMessage(context, 'No changes to save');
        } else {
          _showNoFileMessage(context);
        }
        break;
    }
  }

  void _showNoChangesMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showNoFileMessage(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file is open to save'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _saveFile(WidgetRef ref, BuildContext context, String filePath, String content) async {
    try {
      final fileService = FileService();
      await fileService.writeFile(filePath, content);
      ref.read(appStateProvider.notifier).saveFile();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save file: $e')),
        );
      }
    }
  }

  Future<void> _saveSecondaryFile(WidgetRef ref, BuildContext context, String filePath, String content) async {
    try {
      final fileService = FileService();
      await fileService.writeFile(filePath, content);
      ref.read(appStateProvider.notifier).saveSecondaryFile();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secondary file saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save secondary file: $e')),
        );
      }
    }
  }
}