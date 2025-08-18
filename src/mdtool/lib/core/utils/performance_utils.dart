import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class PerformanceUtils {
  // Debounce utility for reducing API calls
  static Timer? _debounceTimer;
  
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  // Throttle utility for limiting function calls
  static DateTime? _lastThrottleTime;
  
  static bool throttle({Duration duration = const Duration(milliseconds: 100)}) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || now.difference(_lastThrottleTime!) > duration) {
      _lastThrottleTime = now;
      return true;
    }
    return false;
  }

  // Memory optimization - dispose resources
  static void disposeDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  // Performance monitoring
  static void measurePerformance(String label, VoidCallback function) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      function();
      stopwatch.stop();
      debugPrint('Performance [$label]: ${stopwatch.elapsedMilliseconds}ms');
    } else {
      function();
    }
  }

  // Async performance monitoring
  static Future<T> measureAsyncPerformance<T>(String label, Future<T> Function() function) async {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      final result = await function();
      stopwatch.stop();
      debugPrint('Async Performance [$label]: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } else {
      return await function();
    }
  }

  // Memory usage monitoring (debug only)
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      debugPrint('Memory usage at $context - Objects: ${WidgetsBinding.instance.platformDispatcher.views.length}');
    }
  }
}