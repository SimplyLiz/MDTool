import 'dart:async';
import 'context_strategy.dart';
import 'progressive_context_strategy.dart';
import 'enhanced_progressive_context_strategy.dart';

/// Manages different context building strategies
class ContextStrategyManager {
  static ContextStrategyManager? _instance;
  static ContextStrategyManager get instance {
    _instance ??= ContextStrategyManager._();
    return _instance!;
  }

  ContextStrategyManager._() {
    _initializeStrategies();
  }

  final Map<String, ContextStrategy> _strategies = {};
  late ContextStrategy _activeStrategy;
  final StreamController<ContextStrategy> _activeStrategyController = StreamController<ContextStrategy>.broadcast();

  /// Stream of active strategy changes
  Stream<ContextStrategy> get activeStrategyStream => _activeStrategyController.stream;

  void _initializeStrategies() {
    // Register built-in strategies
    registerStrategy(SimpleContextStrategy());
    registerStrategy(ProgressiveContextStrategy());
    registerStrategy(EnhancedProgressiveContextStrategy());
    
    // Load active strategy from preferences
    _loadActiveStrategy();
  }

  /// Register a new context strategy
  void registerStrategy(ContextStrategy strategy) {
    _strategies[strategy.name] = strategy;
    
    // If no active strategy set, use this one
    if (!_isInitialized()) {
      _activeStrategy = strategy;
    }
  }

  /// Get all available strategies
  List<ContextStrategy> get availableStrategies => _strategies.values.toList();

  /// Get currently active strategy
  ContextStrategy get activeStrategy => _activeStrategy;

  /// Set the active strategy by name
  Future<void> setActiveStrategy(String strategyName) async {
    if (_strategies.containsKey(strategyName)) {
      _activeStrategy = _strategies[strategyName]!;
      await _saveActiveStrategy();
      _activeStrategyController.add(_activeStrategy);
    } else {
      throw ArgumentError('Strategy "$strategyName" not found');
    }
  }

  /// Get strategy by name
  ContextStrategy? getStrategy(String name) {
    return _strategies[name];
  }

  /// Build context using the active strategy
  Future<ContextResult> buildContext({
    required String query,
    required List<String> availableFiles,
    required Map<String, String> fileContents,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      return await _activeStrategy.buildContext(
        query: query,
        availableFiles: availableFiles,
        fileContents: fileContents,
        additionalData: additionalData,
      );
    } catch (e) {
      // Fallback to simple strategy if active strategy fails
      final fallbackStrategy = _strategies['Simple Context'];
      if (fallbackStrategy != null && fallbackStrategy != _activeStrategy) {
        return await fallbackStrategy.buildContext(
          query: query,
          availableFiles: availableFiles,
          fileContents: fileContents,
          additionalData: additionalData,
        );
      }
      
      // If all else fails, return error result
      return ContextResult(
        content: 'Error building context: $e',
        tokenCount: 0,
        estimatedCost: 0.0,
        filesUsed: [],
        strategyUsed: _activeStrategy.name,
        explanation: 'Context building failed',
        generatedAt: DateTime.now(),
      );
    }
  }

  /// Configure a specific strategy
  Future<void> configureStrategy(String strategyName, ContextStrategyConfig config) async {
    final strategy = _strategies[strategyName];
    if (strategy != null) {
      await strategy.configure(config);
      await _saveStrategyConfig(strategyName, config);
    }
  }

  /// Get configuration for a specific strategy
  ContextStrategyConfig? getStrategyConfig(String strategyName) {
    return _strategies[strategyName]?.config;
  }

  /// Get statistics about context usage
  Map<String, dynamic> getUsageStatistics() {
    // This could be enhanced to track actual usage statistics
    return {
      'activeStrategy': _activeStrategy.name,
      'availableStrategies': _strategies.keys.toList(),
      'strategyCount': _strategies.length,
      'isActive': _activeStrategy.isAvailable,
    };
  }

  /// Reset all strategies to default configurations
  Future<void> resetToDefaults() async {
    for (final strategy in _strategies.values) {
      await strategy.configure(strategy.getDefaultConfig());
    }
    
    // Set default active strategy
    final defaultStrategy = _strategies['Enhanced Progressive Context'] ?? 
                           _strategies['Progressive Context'] ?? 
                           _strategies.values.first;
    await setActiveStrategy(defaultStrategy.name);
  }

  /// Validate configuration for a strategy
  bool validateStrategyConfig(String strategyName, Map<String, dynamic> settings) {
    final strategy = _strategies[strategyName];
    return strategy?.validateConfig(settings) ?? false;
  }

  /// Get help text for a specific strategy
  String getStrategyHelp(String strategyName) {
    final strategy = _strategies[strategyName];
    return strategy?.helpText ?? 'No help available for this strategy.';
  }

  /// Get user-friendly explanation of current configuration
  String getConfigurationSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Active Strategy: ${_activeStrategy.name}');
    buffer.writeln('Configuration: ${_activeStrategy.getConfigExplanation()}');
    buffer.writeln();
    
    buffer.writeln('Available Strategies:');
    for (final strategy in _strategies.values) {
      final indicator = strategy == _activeStrategy ? '● ' : '○ ';
      buffer.writeln('$indicator${strategy.name}: ${strategy.description}');
    }
    
    return buffer.toString();
  }

  // Private methods for persistence

  Future<void> _loadActiveStrategy() async {
    try {
      // TODO: Access preferences service properly when available
      // For now, use default strategy
      const strategyName = null; // prefs.getString('active_context_strategy');
      
      if (strategyName != null && _strategies.containsKey(strategyName)) {
        _activeStrategy = _strategies[strategyName]!;
      } else {
        // Default to Enhanced Progressive Context if available, otherwise Progressive Context
        _activeStrategy = _strategies['Enhanced Progressive Context'] ?? 
                         _strategies['Progressive Context'] ?? 
                         _strategies.values.first;
      }
      
      // Load configurations for all strategies
      await _loadStrategyConfigs();
    } catch (e) {
      // Fallback to first available strategy
      _activeStrategy = _strategies.values.first;
    }
  }

  Future<void> _saveActiveStrategy() async {
    try {
      // TODO: Save to preferences when available
      // final prefs = PreferencesService.instance;
      // await prefs.setString('active_context_strategy', _activeStrategy.name);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _loadStrategyConfigs() async {
    try {
      // TODO: Load from preferences when available
      // final prefs = PreferencesService.instance;
      
      // for (final strategy in _strategies.values) {
      //   final configKey = 'context_strategy_config_${strategy.name}';
      //   final configJson = prefs.getString(configKey);
      //   
      //   if (configJson != null) {
      //     final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      //     final config = ContextStrategyConfig.fromJson(configMap);
      //     await strategy.configure(config);
      //   }
      // }
    } catch (e) {
      // Silently fail and use defaults
    }
  }

  Future<void> _saveStrategyConfig(String strategyName, ContextStrategyConfig config) async {
    try {
      // TODO: Save to preferences when available
      // final prefs = PreferencesService.instance;
      // final configKey = 'context_strategy_config_$strategyName';
      // final configJson = jsonEncode(config.toJson());
      // await prefs.setString(configKey, configJson);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  bool _isInitialized() {
    try {
      // This will throw if _activeStrategy is not initialized
      _activeStrategy.toString(); // Force evaluation
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _activeStrategyController.close();
  }
}