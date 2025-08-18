import 'dart:async';

/// Result of context building operation
class ContextResult {
  final String content;
  final int tokenCount;
  final double estimatedCost;
  final List<String> filesUsed;
  final String strategyUsed;
  final String explanation;
  final DateTime generatedAt;

  const ContextResult({
    required this.content,
    required this.tokenCount,
    required this.estimatedCost,
    required this.filesUsed,
    required this.strategyUsed,
    required this.explanation,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'tokenCount': tokenCount,
      'estimatedCost': estimatedCost,
      'filesUsed': filesUsed,
      'strategyUsed': strategyUsed,
      'explanation': explanation,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory ContextResult.fromJson(Map<String, dynamic> json) {
    return ContextResult(
      content: json['content'] ?? '',
      tokenCount: json['tokenCount'] ?? 0,
      estimatedCost: (json['estimatedCost'] ?? 0.0).toDouble(),
      filesUsed: List<String>.from(json['filesUsed'] ?? []),
      strategyUsed: json['strategyUsed'] ?? '',
      explanation: json['explanation'] ?? '',
      generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Configuration for context strategy
class ContextStrategyConfig {
  final bool enabled;
  final Map<String, dynamic> settings;

  const ContextStrategyConfig({
    required this.enabled,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'settings': settings,
    };
  }

  factory ContextStrategyConfig.fromJson(Map<String, dynamic> json) {
    return ContextStrategyConfig(
      enabled: json['enabled'] ?? true,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }
}

/// Abstract base class for context building strategies
abstract class ContextStrategy {
  /// Human-readable name of the strategy
  String get name;

  /// Brief description of what this strategy does
  String get description;

  /// Detailed explanation for help documentation
  String get helpText;

  /// Current configuration for this strategy
  ContextStrategyConfig get config;

  /// Whether this strategy is currently available/enabled
  bool get isAvailable;

  /// Build context for the given query and available documents
  Future<ContextResult> buildContext({
    required String query,
    required List<String> availableFiles,
    required Map<String, String> fileContents,
    Map<String, dynamic>? additionalData,
  });

  /// Configure this strategy with new settings
  Future<void> configure(ContextStrategyConfig newConfig);

  /// Get default configuration for this strategy
  ContextStrategyConfig getDefaultConfig();

  /// Validate configuration settings
  bool validateConfig(Map<String, dynamic> settings);

  /// Get user-friendly explanation of current settings
  String getConfigExplanation();
}

/// Simple context strategy that uses current file only
class SimpleContextStrategy implements ContextStrategy {
  ContextStrategyConfig _config = ContextStrategyConfig(
    enabled: true,
    settings: {'maxTokens': 4000},
  );

  @override
  String get name => 'Simple Context';

  @override
  String get description => 'Uses only the current document for context';

  @override
  String get helpText => '''
Simple Context strategy provides AI with just the current document you're working on.

How it works:
• Takes your current markdown file
• Sends it as context to the AI
• Fast and predictable token usage
• Good for single-document questions

Best for:
• Grammar checking
• Formatting help
• Simple document-specific questions
• When you want predictable costs

Token usage: Varies by document size (typically 500-4000 tokens)
''';

  @override
  ContextStrategyConfig get config => _config;

  @override
  bool get isAvailable => true;

  @override
  Future<ContextResult> buildContext({
    required String query,
    required List<String> availableFiles,
    required Map<String, String> fileContents,
    Map<String, dynamic>? additionalData,
  }) async {
    final currentFile = additionalData?['currentFile'] as String?;
    
    if (currentFile == null || !fileContents.containsKey(currentFile)) {
      return ContextResult(
        content: 'No current document available.',
        tokenCount: 10,
        estimatedCost: 0.0,
        filesUsed: [],
        strategyUsed: name,
        explanation: 'No document currently open',
        generatedAt: DateTime.now(),
      );
    }

    final content = fileContents[currentFile]!;
    final tokenCount = _estimateTokens(content);
    final maxTokens = _config.settings['maxTokens'] as int;

    String finalContent = content;
    if (tokenCount > maxTokens) {
      finalContent = _truncateContent(content, maxTokens);
    }

    return ContextResult(
      content: finalContent,
      tokenCount: _estimateTokens(finalContent),
      estimatedCost: _estimateCost(_estimateTokens(finalContent)),
      filesUsed: [currentFile],
      strategyUsed: name,
      explanation: 'Using current document: ${_getFileName(currentFile)}',
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> configure(ContextStrategyConfig newConfig) async {
    _config = newConfig;
  }

  @override
  ContextStrategyConfig getDefaultConfig() {
    return ContextStrategyConfig(
      enabled: true,
      settings: {'maxTokens': 4000},
    );
  }

  @override
  bool validateConfig(Map<String, dynamic> settings) {
    final maxTokens = settings['maxTokens'];
    return maxTokens is int && maxTokens > 0 && maxTokens <= 10000;
  }

  @override
  String getConfigExplanation() {
    final maxTokens = _config.settings['maxTokens'];
    return 'Maximum tokens: $maxTokens (current document only)';
  }

  // Helper methods
  int _estimateTokens(String text) {
    // Rough estimation: 1 token ≈ 4 characters
    return (text.length / 4).ceil();
  }

  double _estimateCost(int tokens) {
    // Rough estimation: $0.01 per 1000 tokens
    return (tokens / 1000) * 0.01;
  }

  String _truncateContent(String content, int maxTokens) {
    final maxChars = maxTokens * 4;
    if (content.length <= maxChars) return content;
    
    return '${content.substring(0, maxChars)}\n\n[Content truncated due to token limit]';
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }
}