import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'ai_routing_manager.dart';
import '../chat_service.dart';

class AIUsageMetrics {
  final DateTime timestamp;
  final AIProvider provider;
  final String model;
  final QueryComplexity complexity;
  final double actualCost;
  final double estimatedSavings;
  final bool wasAutoRouted;
  final double confidence;
  final String queryType;
  final int tokenCount;

  AIUsageMetrics({
    required this.timestamp,
    required this.provider,
    required this.model,
    required this.complexity,
    required this.actualCost,
    required this.estimatedSavings,
    required this.wasAutoRouted,
    required this.confidence,
    required this.queryType,
    required this.tokenCount,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'provider': provider.name,
    'model': model,
    'complexity': complexity.name,
    'actualCost': actualCost,
    'estimatedSavings': estimatedSavings,
    'wasAutoRouted': wasAutoRouted,
    'confidence': confidence,
    'queryType': queryType,
    'tokenCount': tokenCount,
  };

  factory AIUsageMetrics.fromJson(Map<String, dynamic> json) => AIUsageMetrics(
    timestamp: DateTime.parse(json['timestamp']),
    provider: AIProvider.values.firstWhere((p) => p.name == json['provider']),
    model: json['model'],
    complexity: QueryComplexity.values.firstWhere((c) => c.name == json['complexity']),
    actualCost: json['actualCost'].toDouble(),
    estimatedSavings: json['estimatedSavings'].toDouble(),
    wasAutoRouted: json['wasAutoRouted'],
    confidence: json['confidence'].toDouble(),
    queryType: json['queryType'],
    tokenCount: json['tokenCount'],
  );
}

class CostSavingsAnalysis {
  final double totalCostSaved;
  final double totalSpent;
  final double totalEstimatedWithoutRouting;
  final int totalQueries;
  final int autoRoutedQueries;
  final int localQueries;
  final int cloudQueries;
  final double averageSavingsPercentage;
  final double weeklyTrend;
  final Map<QueryComplexity, int> queriesByComplexity;
  final Map<String, double> costByProvider;

  CostSavingsAnalysis({
    required this.totalCostSaved,
    required this.totalSpent,
    required this.totalEstimatedWithoutRouting,
    required this.totalQueries,
    required this.autoRoutedQueries,
    required this.localQueries,
    required this.cloudQueries,
    required this.averageSavingsPercentage,
    required this.weeklyTrend,
    required this.queriesByComplexity,
    required this.costByProvider,
  });
}

class ThresholdOptimization {
  final double recommendedLocalThreshold;
  final double currentLocalThreshold;
  final double recommendedCostTarget;
  final double currentCostTarget;
  final String reasoning;
  final double confidenceScore;
  final int sampleSize;

  ThresholdOptimization({
    required this.recommendedLocalThreshold,
    required this.currentLocalThreshold,
    required this.recommendedCostTarget,
    required this.currentCostTarget,
    required this.reasoning,
    required this.confidenceScore,
    required this.sampleSize,
  });
}

class AIAnalyticsService {
  static AIAnalyticsService? _instance;
  static AIAnalyticsService get instance {
    _instance ??= AIAnalyticsService._();
    return _instance!;
  }

  AIAnalyticsService._();

  final List<AIUsageMetrics> _metrics = [];
  late final String _dataFilePath;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Get app data directory
    final homeDir = Platform.environment['HOME'] ?? '';
    final appDataDir = path.join(homeDir, '.mdtool');
    await Directory(appDataDir).create(recursive: true);
    _dataFilePath = path.join(appDataDir, 'ai_analytics.json');

    await _loadMetrics();
    _isInitialized = true;
  }

  Future<void> recordUsage({
    required AIProvider provider,
    required String model,
    required String query,
    required QueryComplexity complexity,
    required double actualCost,
    required bool wasAutoRouted,
    required double confidence,
    required int tokenCount,
  }) async {
    await initialize();

    // Calculate estimated cost without routing
    final estimatedCostWithoutRouting = _estimateManualCost(complexity);
    final estimatedSavings = estimatedCostWithoutRouting - actualCost;

    final queryType = _classifyQueryType(query);

    final metric = AIUsageMetrics(
      timestamp: DateTime.now(),
      provider: provider,
      model: model,
      complexity: complexity,
      actualCost: actualCost,
      estimatedSavings: estimatedSavings,
      wasAutoRouted: wasAutoRouted,
      confidence: confidence,
      queryType: queryType,
      tokenCount: tokenCount,
    );

    _metrics.add(metric);
    await _saveMetrics();

    // Auto-optimize thresholds if we have enough data
    if (_metrics.length % 10 == 0) {
      await _autoOptimizeThresholds();
    }
  }

  CostSavingsAnalysis getCostSavingsAnalysis({DateTime? since}) {
    final relevantMetrics = since != null 
        ? _metrics.where((m) => m.timestamp.isAfter(since)).toList()
        : _metrics;

    if (relevantMetrics.isEmpty) {
      return CostSavingsAnalysis(
        totalCostSaved: 0.0,
        totalSpent: 0.0,
        totalEstimatedWithoutRouting: 0.0,
        totalQueries: 0,
        autoRoutedQueries: 0,
        localQueries: 0,
        cloudQueries: 0,
        averageSavingsPercentage: 0.0,
        weeklyTrend: 0.0,
        queriesByComplexity: {},
        costByProvider: {},
      );
    }

    final totalSpent = relevantMetrics.fold(0.0, (sum, m) => sum + m.actualCost);
    final totalEstimatedWithoutRouting = relevantMetrics.fold(0.0, (sum, m) => sum + m.actualCost + m.estimatedSavings);
    final totalSaved = totalEstimatedWithoutRouting - totalSpent;
    
    final autoRoutedQueries = relevantMetrics.where((m) => m.wasAutoRouted).length;
    final localQueries = relevantMetrics.where((m) => m.provider == AIProvider.ollama).length;
    final cloudQueries = relevantMetrics.where((m) => m.provider == AIProvider.openai).length;

    final averageSavingsPercentage = totalEstimatedWithoutRouting > 0 
        ? (totalSaved / totalEstimatedWithoutRouting) * 100 
        : 0.0;

    final weeklyTrend = _calculateWeeklyTrend(relevantMetrics);

    final queriesByComplexity = <QueryComplexity, int>{};
    for (final complexity in QueryComplexity.values) {
      queriesByComplexity[complexity] = relevantMetrics.where((m) => m.complexity == complexity).length;
    }

    final costByProvider = <String, double>{
      'Ollama': relevantMetrics.where((m) => m.provider == AIProvider.ollama).fold(0.0, (sum, m) => sum + m.actualCost),
      'OpenAI': relevantMetrics.where((m) => m.provider == AIProvider.openai).fold(0.0, (sum, m) => sum + m.actualCost),
    };

    return CostSavingsAnalysis(
      totalCostSaved: totalSaved,
      totalSpent: totalSpent,
      totalEstimatedWithoutRouting: totalEstimatedWithoutRouting,
      totalQueries: relevantMetrics.length,
      autoRoutedQueries: autoRoutedQueries,
      localQueries: localQueries,
      cloudQueries: cloudQueries,
      averageSavingsPercentage: averageSavingsPercentage,
      weeklyTrend: weeklyTrend,
      queriesByComplexity: queriesByComplexity,
      costByProvider: costByProvider,
    );
  }

  ThresholdOptimization getThresholdOptimization() {
    if (_metrics.length < 20) {
      return ThresholdOptimization(
        recommendedLocalThreshold: 0.8,
        currentLocalThreshold: AIRoutingManager.instance.mode == AIRoutingMode.auto ? 0.8 : 0.0,
        recommendedCostTarget: 0.7,
        currentCostTarget: 0.7,
        reasoning: 'Not enough data for optimization (need at least 20 queries)',
        confidenceScore: 0.0,
        sampleSize: _metrics.length,
      );
    }

    final recentMetrics = _metrics.where(
      (m) => DateTime.now().difference(m.timestamp).inDays <= 30
    ).toList();

    // Analyze local AI success rate by complexity
    final localMetrics = recentMetrics.where((m) => m.provider == AIProvider.ollama).toList();
    final cloudMetrics = recentMetrics.where((m) => m.provider == AIProvider.openai).toList();

    // Calculate optimal threshold based on cost-benefit analysis
    double optimalThreshold = 0.8;
    double maxBenefit = 0.0;

    for (double threshold = 0.5; threshold <= 0.95; threshold += 0.05) {
      final wouldUseLocal = recentMetrics.where((m) => m.confidence >= threshold).length;
      final wouldUseCloud = recentMetrics.length - wouldUseLocal;
      
      // Estimate cost with this threshold
      final estimatedLocalCost = wouldUseLocal * 0.0; // Ollama is free
      final estimatedCloudCost = wouldUseCloud * 0.03; // Average cloud cost
      final totalEstimatedCost = estimatedLocalCost + estimatedCloudCost;
      
      // Calculate benefit (lower cost is better)
      final benefit = 1.0 / (totalEstimatedCost + 0.001); // Avoid division by zero
      
      if (benefit > maxBenefit) {
        maxBenefit = benefit;
        optimalThreshold = threshold;
      }
    }

    final actualSavings = getCostSavingsAnalysis(since: DateTime.now().subtract(const Duration(days: 30)));
    final currentThreshold = AIRoutingManager.instance.mode == AIRoutingMode.auto ? 0.8 : 0.0;
    
    String reasoning;
    if (optimalThreshold > currentThreshold + 0.1) {
      reasoning = 'Increase threshold to ${optimalThreshold.toStringAsFixed(2)} to reduce cloud costs';
    } else if (optimalThreshold < currentThreshold - 0.1) {
      reasoning = 'Decrease threshold to ${optimalThreshold.toStringAsFixed(2)} for better quality';
    } else {
      reasoning = 'Current threshold is optimal';
    }

    return ThresholdOptimization(
      recommendedLocalThreshold: optimalThreshold,
      currentLocalThreshold: currentThreshold,
      recommendedCostTarget: 0.7,
      currentCostTarget: 0.7,
      reasoning: reasoning,
      confidenceScore: recentMetrics.length >= 50 ? 0.9 : 0.6,
      sampleSize: recentMetrics.length,
    );
  }

  List<AIUsageMetrics> getRecentMetrics({int? limit, DateTime? since}) {
    var metrics = _metrics;
    
    if (since != null) {
      metrics = metrics.where((m) => m.timestamp.isAfter(since)).toList();
    }
    
    metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null) {
      metrics = metrics.take(limit).toList();
    }
    
    return metrics;
  }

  Future<void> applyThresholdOptimization(ThresholdOptimization optimization) async {
    if (optimization.confidenceScore >= 0.7) {
      AIRoutingManager.instance.setThresholds(
        localThreshold: optimization.recommendedLocalThreshold,
        costSavingsTarget: optimization.recommendedCostTarget,
      );
    }
  }

  Future<void> _autoOptimizeThresholds() async {
    final optimization = getThresholdOptimization();
    if (optimization.confidenceScore >= 0.8) {
      await applyThresholdOptimization(optimization);
    }
  }

  double _estimateManualCost(QueryComplexity complexity) {
    // Estimate what the cost would be if user manually chose expensive provider
    switch (complexity) {
      case QueryComplexity.simple:
        return 0.01; // User would likely choose expensive option for simple tasks
      case QueryComplexity.medium:
        return 0.03; // Medium cost for medium tasks
      case QueryComplexity.complex:
        return 0.06; // Would definitely use expensive option for complex tasks
    }
  }

  String _classifyQueryType(String query) {
    final queryLower = query.toLowerCase();
    
    if (queryLower.contains(RegExp(r'fix|correct|grammar|spell'))) {
      return 'correction';
    } else if (queryLower.contains(RegExp(r'how|what|explain|describe'))) {
      return 'question';
    } else if (queryLower.contains(RegExp(r'implement|build|create|develop'))) {
      return 'implementation';
    } else if (queryLower.contains(RegExp(r'review|analyze|evaluate'))) {
      return 'analysis';
    } else {
      return 'general';
    }
  }

  double _calculateWeeklyTrend(List<AIUsageMetrics> metrics) {
    if (metrics.length < 14) return 0.0;

    final now = DateTime.now();
    final thisWeek = metrics.where((m) => now.difference(m.timestamp).inDays <= 7).toList();
    final lastWeek = metrics.where((m) {
      final daysDiff = now.difference(m.timestamp).inDays;
      return daysDiff > 7 && daysDiff <= 14;
    }).toList();

    if (thisWeek.isEmpty || lastWeek.isEmpty) return 0.0;

    final thisWeekSavings = thisWeek.fold(0.0, (sum, m) => sum + m.estimatedSavings);
    final lastWeekSavings = lastWeek.fold(0.0, (sum, m) => sum + m.estimatedSavings);

    if (lastWeekSavings == 0) return 0.0;
    return ((thisWeekSavings - lastWeekSavings) / lastWeekSavings) * 100;
  }

  Future<void> _loadMetrics() async {
    try {
      final file = File(_dataFilePath);
      if (await file.exists()) {
        final jsonData = await file.readAsString();
        final List<dynamic> metricsJson = jsonDecode(jsonData);
        _metrics.clear();
        _metrics.addAll(metricsJson.map((json) => AIUsageMetrics.fromJson(json)));
      }
    } catch (e) {
      print('Error loading AI analytics: $e');
    }
  }

  Future<void> _saveMetrics() async {
    try {
      final file = File(_dataFilePath);
      final metricsJson = _metrics.map((m) => m.toJson()).toList();
      await file.writeAsString(jsonEncode(metricsJson));
    } catch (e) {
      print('Error saving AI analytics: $e');
    }
  }

  Future<void> clearAnalytics() async {
    _metrics.clear();
    await _saveMetrics();
  }

  String exportAnalyticsAsJson() {
    return jsonEncode(_metrics.map((m) => m.toJson()).toList());
  }
}