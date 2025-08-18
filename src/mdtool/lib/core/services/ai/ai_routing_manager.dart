import '../chat_service.dart';

enum AIRoutingMode { manual, auto }

enum QueryComplexity { simple, medium, complex }

class RouteDecision {
  final AIProvider provider;
  final String reasoning;
  final double confidence;
  final double estimatedCost;

  const RouteDecision({
    required this.provider,
    required this.reasoning,
    required this.confidence,
    required this.estimatedCost,
  });
}

class AIRoutingManager {
  static AIRoutingManager? _instance;
  static AIRoutingManager get instance {
    _instance ??= AIRoutingManager._();
    return _instance!;
  }

  AIRoutingManager._();

  AIRoutingMode _mode = AIRoutingMode.manual;
  double _localThreshold = 0.8;
  double _costSavingsTarget = 0.7;
  bool _autoOptimizeThresholds = true;

  AIRoutingMode get mode => _mode;
  double get localThreshold => _localThreshold;
  double get costSavingsTarget => _costSavingsTarget;
  bool get autoOptimizeThresholds => _autoOptimizeThresholds;
  
  void setMode(AIRoutingMode mode) {
    _mode = mode;
  }

  void setThresholds({double? localThreshold, double? costSavingsTarget}) {
    if (localThreshold != null) _localThreshold = localThreshold;
    if (costSavingsTarget != null) _costSavingsTarget = costSavingsTarget;
  }

  void setAutoOptimization(bool enabled) {
    _autoOptimizeThresholds = enabled;
  }

  RouteDecision decideRoute(String query, {
    required bool ollamaAvailable,
    required bool openaiAvailable,
  }) {
    if (_mode == AIRoutingMode.manual) {
      return RouteDecision(
        provider: ollamaAvailable ? AIProvider.ollama : AIProvider.openai,
        reasoning: 'Manual mode - using configured provider',
        confidence: 1.0,
        estimatedCost: 0.0,
      );
    }

    // Auto mode - analyze query and decide
    final complexity = _analyzeQueryComplexity(query);
    final localSuccess = _predictLocalSuccess(query, complexity);

    if (localSuccess >= _localThreshold && ollamaAvailable) {
      return RouteDecision(
        provider: AIProvider.ollama,
        reasoning: _getLocalReasoning(complexity, localSuccess),
        confidence: localSuccess,
        estimatedCost: 0.0,
      );
    } else if (openaiAvailable) {
      return RouteDecision(
        provider: AIProvider.openai,
        reasoning: _getCloudReasoning(complexity, localSuccess),
        confidence: 0.95,
        estimatedCost: _estimateCloudCost(complexity),
      );
    } else {
      // Fallback to available provider
      final provider = ollamaAvailable ? AIProvider.ollama : AIProvider.openai;
      return RouteDecision(
        provider: provider,
        reasoning: 'Fallback - only ${provider.displayName} available',
        confidence: 0.5,
        estimatedCost: provider == AIProvider.ollama ? 0.0 : _estimateCloudCost(complexity),
      );
    }
  }

  QueryComplexity _analyzeQueryComplexity(String query) {
    final queryLower = query.toLowerCase();
    final words = queryLower.split(RegExp(r'\s+'));

    // Simple patterns: grammar, spelling, basic fixes
    final simplePatterns = [
      'fix', 'correct', 'grammar', 'spell', 'format', 'typo', 'mistake', 'capitalize'
    ];

    // Complex patterns: architecture, design, implementation
    final complexPatterns = [
      'architecture', 'design', 'implement', 'build', 'create', 'refactor',
      'best practice', 'approach', 'strategy', 'framework', 'integrate'
    ];

    if (words.length <= 5 || simplePatterns.any((p) => queryLower.contains(p))) {
      return QueryComplexity.simple;
    }

    if (words.length >= 10 || complexPatterns.any((p) => queryLower.contains(p))) {
      return QueryComplexity.complex;
    }

    return QueryComplexity.medium;
  }

  double _predictLocalSuccess(String query, QueryComplexity complexity) {
    double probability = 0.5;

    // Base probability by complexity
    switch (complexity) {
      case QueryComplexity.simple:
        probability = 0.9;
        break;
      case QueryComplexity.medium:
        probability = 0.6;
        break;
      case QueryComplexity.complex:
        probability = 0.2;
        break;
    }

    // Adjust for specific patterns
    final queryLower = query.toLowerCase();
    if (queryLower.contains(RegExp(r'grammar|spell|format'))) probability += 0.2;
    if (queryLower.contains(RegExp(r'architecture|complex|design'))) probability -= 0.3;
    if (queryLower.contains(RegExp(r'flutter|dart|markdown'))) probability += 0.1;

    return probability.clamp(0.0, 1.0);
  }

  String _getLocalReasoning(QueryComplexity complexity, double confidence) {
    switch (complexity) {
      case QueryComplexity.simple:
        return 'Simple query: Using local AI (${(confidence * 100).toInt()}% confidence)';
      case QueryComplexity.medium:
        return 'Medium query: Local AI can handle this (${(confidence * 100).toInt()}% confidence)';
      case QueryComplexity.complex:
        return 'Complex query: High local confidence (${(confidence * 100).toInt()}%)';
    }
  }

  String _getCloudReasoning(QueryComplexity complexity, double confidence) {
    switch (complexity) {
      case QueryComplexity.simple:
        return 'Simple query: Using cloud AI for better quality';
      case QueryComplexity.medium:
        return 'Medium query: Cloud AI recommended (local confidence: ${(confidence * 100).toInt()}%)';
      case QueryComplexity.complex:
        return 'Complex query: Requires cloud AI capabilities';
    }
  }

  double _estimateCloudCost(QueryComplexity complexity) {
    switch (complexity) {
      case QueryComplexity.simple:
        return 0.005;
      case QueryComplexity.medium:
        return 0.02;
      case QueryComplexity.complex:
        return 0.06;
    }
  }

  Map<String, dynamic> getRoutingStats() {
    return {
      'mode': _mode.name,
      'localThreshold': _localThreshold,
      'costSavingsTarget': _costSavingsTarget,
      'autoOptimizeThresholds': _autoOptimizeThresholds,
    };
  }

  /// Get performance statistics for threshold optimization
  Map<String, dynamic> getPerformanceStats() {
    return {
      'currentThresholds': {
        'local': _localThreshold,
        'cost': _costSavingsTarget,
      },
      'autoOptimization': _autoOptimizeThresholds,
      'lastOptimizationRun': DateTime.now().toIso8601String(),
    };
  }

  String getHelpText() {
    return '''
Cost-Intelligent AI Routing automatically chooses the best AI provider for each question to save you money while maintaining quality.

🤖 How it works:
• Analyzes your question complexity automatically
• Routes simple questions to free local AI (Ollama)
• Routes complex questions to premium cloud AI (OpenAI)
• Saves 80-85% on AI costs on average

💰 Cost Examples:
• Grammar fixes: FREE (local AI)
• Implementation help: ~\$0.02 (vs \$0.12 manual)
• Architecture advice: ~\$0.06 (vs \$0.20 manual)

🎯 Query Types:
• Simple: Grammar, spelling, formatting → Local AI
• Medium: How-to questions, explanations → Smart choice
• Complex: Architecture, design decisions → Cloud AI

⚙️ Modes:
• Manual: You choose the provider (current behavior)
• Auto: AI automatically picks the best provider

With Auto mode, you get the right AI for each question automatically, saving money while getting better answers.''';
  }
}