import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF007AFF);
  static const Color _backgroundColor = Color(0xFFF2F2F7);
  static const Color _darkBackgroundColor = Color(0xFF1C1C1E);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ).copyWith(
        surface: _backgroundColor,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      ).copyWith(
        surface: _darkBackgroundColor,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}