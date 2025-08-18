import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'ui/pages/main_page.dart';
import 'ui/pages/diff_comparison_page.dart';
import 'ui/themes/app_theme.dart';
import 'core/services/preferences_service.dart';
import 'core/providers/preferences_provider.dart';
import 'core/models/preferences.dart' as prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize preferences service
  final preferencesService = await PreferencesService.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
      ],
      child: const MDToolApp(),
    ),
  );
}

class MDToolApp extends ConsumerWidget {
  const MDToolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(preferencesProvider);
    
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
          title: 'MD Tool',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const MainPage(),
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
        title: 'MD Tool',
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
      error: (error, stack) => MaterialApp(
        title: 'MD Tool',
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