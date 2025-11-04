import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenUsage {
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final double cost;
  final DateTime timestamp;
  final String provider;
  final String model;
  final String messageId;

  TokenUsage({
    required this.inputTokens,
    required this.outputTokens,
    required this.cost,
    required this.timestamp,
    required this.provider,
    required this.model,
    required this.messageId,
  }) : totalTokens = inputTokens + outputTokens;

  Map<String, dynamic> toJson() => {
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'totalTokens': totalTokens,
    'cost': cost,
    'timestamp': timestamp.toIso8601String(),
    'provider': provider,
    'model': model,
    'messageId': messageId,
  };

  factory TokenUsage.fromJson(Map<String, dynamic> json) => TokenUsage(
    inputTokens: json['inputTokens'] ?? 0,
    outputTokens: json['outputTokens'] ?? 0,
    cost: (json['cost'] ?? 0.0).toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
    provider: json['provider'] ?? 'unknown',
    model: json['model'] ?? 'unknown',
    messageId: json['messageId'] ?? '',
  );
}

class UsageLimits {
  final int dailyTokenLimit;
  final double dailyCostLimit;
  final int monthlyTokenLimit;
  final double monthlyCostLimit;
  final bool enableLimits;
  final bool disableWhenExceeded;

  const UsageLimits({
    this.dailyTokenLimit = 100000,
    this.dailyCostLimit = 5.0,
    this.monthlyTokenLimit = 1000000,
    this.monthlyCostLimit = 50.0,
    this.enableLimits = true,
    this.disableWhenExceeded = true,
  });

  Map<String, dynamic> toJson() => {
    'dailyTokenLimit': dailyTokenLimit,
    'dailyCostLimit': dailyCostLimit,
    'monthlyTokenLimit': monthlyTokenLimit,
    'monthlyCostLimit': monthlyCostLimit,
    'enableLimits': enableLimits,
    'disableWhenExceeded': disableWhenExceeded,
  };

  factory UsageLimits.fromJson(Map<String, dynamic> json) => UsageLimits(
    dailyTokenLimit: json['dailyTokenLimit'] ?? 100000,
    dailyCostLimit: (json['dailyCostLimit'] ?? 5.0).toDouble(),
    monthlyTokenLimit: json['monthlyTokenLimit'] ?? 1000000,
    monthlyCostLimit: (json['monthlyCostLimit'] ?? 50.0).toDouble(),
    enableLimits: json['enableLimits'] ?? true,
    disableWhenExceeded: json['disableWhenExceeded'] ?? true,
  );

  UsageLimits copyWith({
    int? dailyTokenLimit,
    double? dailyCostLimit,
    int? monthlyTokenLimit,
    double? monthlyCostLimit,
    bool? enableLimits,
    bool? disableWhenExceeded,
  }) => UsageLimits(
    dailyTokenLimit: dailyTokenLimit ?? this.dailyTokenLimit,
    dailyCostLimit: dailyCostLimit ?? this.dailyCostLimit,
    monthlyTokenLimit: monthlyTokenLimit ?? this.monthlyTokenLimit,
    monthlyCostLimit: monthlyCostLimit ?? this.monthlyCostLimit,
    enableLimits: enableLimits ?? this.enableLimits,
    disableWhenExceeded: disableWhenExceeded ?? this.disableWhenExceeded,
  );
}

class UsageSummary {
  final int totalTokensToday;
  final double totalCostToday;
  final int totalTokensThisMonth;
  final double totalCostThisMonth;
  final bool dailyLimitExceeded;
  final bool monthlyLimitExceeded;
  final bool isBlocked;
  final double dailyTokenPercentage;
  final double dailyCostPercentage;
  final double monthlyTokenPercentage;
  final double monthlyCostPercentage;

  UsageSummary({
    required this.totalTokensToday,
    required this.totalCostToday,
    required this.totalTokensThisMonth,
    required this.totalCostThisMonth,
    required this.dailyLimitExceeded,
    required this.monthlyLimitExceeded,
    required this.isBlocked,
    required this.dailyTokenPercentage,
    required this.dailyCostPercentage,
    required this.monthlyTokenPercentage,
    required this.monthlyCostPercentage,
  });
}

class MetricsService {
  static MetricsService? _instance;
  static MetricsService get instance {
    _instance ??= MetricsService._();
    return _instance!;
  }

  MetricsService._();

  final List<TokenUsage> _tokenUsages = [];
  UsageLimits _limits = const UsageLimits();
  bool _isInitialized = false;
  late SharedPreferences _prefs;

  // Stream controllers for live updates
  final List<Function(UsageSummary)> _summaryListeners = [];
  final List<Function(TokenUsage)> _usageListeners = [];

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadUsageLimits();
    await _loadTokenUsages();
    _isInitialized = true;
  }

  // Token usage tracking
  Future<void> recordTokenUsage({
    required int inputTokens,
    required int outputTokens,
    required double cost,
    required String provider,
    required String model,
    required String messageId,
  }) async {
    await initialize();

    final usage = TokenUsage(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cost: cost,
      timestamp: DateTime.now(),
      provider: provider,
      model: model,
      messageId: messageId,
    );

    _tokenUsages.add(usage);
    await _saveTokenUsages();
    
    // Notify listeners
    _notifyUsageListeners(usage);
    _notifySummaryListeners();
  }

  // Get current usage summary
  UsageSummary getUsageSummary() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonth = DateTime(now.year, now.month, 1);

    // Calculate daily usage (only paid providers for limits)
    final dailyUsages = _tokenUsages.where(
      (usage) => usage.timestamp.isAfter(today)
    ).toList();
    
    final dailyPaidUsages = dailyUsages.where(
      (usage) => usage.provider != 'ollama'
    ).toList();
    
    final totalTokensToday = dailyPaidUsages.fold<int>(
      0, (sum, usage) => sum + usage.totalTokens
    );
    final totalCostToday = dailyPaidUsages.fold<double>(
      0.0, (sum, usage) => sum + usage.cost
    );

    // Calculate monthly usage (only paid providers for limits)
    final monthlyUsages = _tokenUsages.where(
      (usage) => usage.timestamp.isAfter(thisMonth)
    ).toList();
    
    final monthlyPaidUsages = monthlyUsages.where(
      (usage) => usage.provider != 'ollama'
    ).toList();
    
    final totalTokensThisMonth = monthlyPaidUsages.fold<int>(
      0, (sum, usage) => sum + usage.totalTokens
    );
    final totalCostThisMonth = monthlyPaidUsages.fold<double>(
      0.0, (sum, usage) => sum + usage.cost
    );

    // Check limits (use > not >= to allow using up to the limit)
    final dailyTokenLimitExceeded = _limits.enableLimits &&
        totalTokensToday > _limits.dailyTokenLimit;
    final dailyCostLimitExceeded = _limits.enableLimits &&
        totalCostToday > _limits.dailyCostLimit;
    final monthlyTokenLimitExceeded = _limits.enableLimits &&
        totalTokensThisMonth > _limits.monthlyTokenLimit;
    final monthlyCostLimitExceeded = _limits.enableLimits &&
        totalCostThisMonth > _limits.monthlyCostLimit;

    final dailyLimitExceeded = dailyTokenLimitExceeded || dailyCostLimitExceeded;
    final monthlyLimitExceeded = monthlyTokenLimitExceeded || monthlyCostLimitExceeded;

    final isBlocked = _limits.enableLimits && _limits.disableWhenExceeded && 
        (dailyLimitExceeded || monthlyLimitExceeded);

    // Calculate percentages
    final dailyTokenPercentage = _limits.dailyTokenLimit > 0 
        ? (totalTokensToday / _limits.dailyTokenLimit * 100).clamp(0.0, 100.0)
        : 0.0;
    final dailyCostPercentage = _limits.dailyCostLimit > 0 
        ? (totalCostToday / _limits.dailyCostLimit * 100).clamp(0.0, 100.0)
        : 0.0;
    final monthlyTokenPercentage = _limits.monthlyTokenLimit > 0 
        ? (totalTokensThisMonth / _limits.monthlyTokenLimit * 100).clamp(0.0, 100.0)
        : 0.0;
    final monthlyCostPercentage = _limits.monthlyCostLimit > 0 
        ? (totalCostThisMonth / _limits.monthlyCostLimit * 100).clamp(0.0, 100.0)
        : 0.0;

    return UsageSummary(
      totalTokensToday: totalTokensToday,
      totalCostToday: totalCostToday,
      totalTokensThisMonth: totalTokensThisMonth,
      totalCostThisMonth: totalCostThisMonth,
      dailyLimitExceeded: dailyLimitExceeded,
      monthlyLimitExceeded: monthlyLimitExceeded,
      isBlocked: isBlocked,
      dailyTokenPercentage: dailyTokenPercentage,
      dailyCostPercentage: dailyCostPercentage,
      monthlyTokenPercentage: monthlyTokenPercentage,
      monthlyCostPercentage: monthlyCostPercentage,
    );
  }

  // Check if usage is currently blocked for a specific provider
  bool isUsageBlocked({String? provider}) {
    // Ollama is always allowed since it's free and local
    if (provider == 'ollama') {
      return false;
    }

    final summary = getUsageSummary();

    // Debug logging
    print('DEBUG [MetricsService.isUsageBlocked]:');
    print('  Provider: $provider');
    print('  enableLimits: ${_limits.enableLimits}');
    print('  disableWhenExceeded: ${_limits.disableWhenExceeded}');
    print('  Daily token limit: ${_limits.dailyTokenLimit}');
    print('  Daily cost limit: \$${_limits.dailyCostLimit}');
    print('  Total tokens today: ${summary.totalTokensToday}');
    print('  Total cost today: \$${summary.totalCostToday}');
    print('  Daily limit exceeded: ${summary.dailyLimitExceeded}');
    print('  Monthly limit exceeded: ${summary.monthlyLimitExceeded}');
    print('  Is blocked: ${summary.isBlocked}');

    // Only apply limits to paid providers (OpenAI)
    if (provider == 'openai') {
      return summary.isBlocked;
    }

    // For general usage check, only block if using paid providers
    return summary.isBlocked;
  }

  // Usage limits management
  UsageLimits get limits => _limits;

  Future<void> updateLimits(UsageLimits newLimits) async {
    await initialize();
    _limits = newLimits;
    await _saveUsageLimits();
    _notifySummaryListeners();
  }

  // Get recent token usages
  List<TokenUsage> getRecentUsages({int? limit, DateTime? since}) {
    var usages = _tokenUsages.toList();
    
    if (since != null) {
      usages = usages.where((usage) => usage.timestamp.isAfter(since)).toList();
    }
    
    usages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null) {
      usages = usages.take(limit).toList();
    }
    
    return usages;
  }

  // Get usage for a specific message
  TokenUsage? getUsageForMessage(String messageId) {
    try {
      return _tokenUsages.firstWhere((usage) => usage.messageId == messageId);
    } catch (e) {
      return null;
    }
  }

  // Cleanup old data (keep last 30 days)
  Future<void> cleanupOldData() async {
    await initialize();
    
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    _tokenUsages.removeWhere((usage) => usage.timestamp.isBefore(cutoffDate));
    
    await _saveTokenUsages();
  }

  // Export data
  String exportUsageData() {
    return jsonEncode(_tokenUsages.map((usage) => usage.toJson()).toList());
  }

  // Clear all data
  Future<void> clearAllData() async {
    await initialize();
    _tokenUsages.clear();
    await _saveTokenUsages();
    _notifySummaryListeners();
  }

  // Event listeners
  void addSummaryListener(Function(UsageSummary) listener) {
    _summaryListeners.add(listener);
  }

  void removeSummaryListener(Function(UsageSummary) listener) {
    _summaryListeners.remove(listener);
  }

  void addUsageListener(Function(TokenUsage) listener) {
    _usageListeners.add(listener);
  }

  void removeUsageListener(Function(TokenUsage) listener) {
    _usageListeners.remove(listener);
  }

  void _notifySummaryListeners() {
    final summary = getUsageSummary();
    for (final listener in _summaryListeners) {
      try {
        listener(summary);
      } catch (e) {
        print('Error notifying summary listener: $e');
      }
    }
  }

  void _notifyUsageListeners(TokenUsage usage) {
    for (final listener in _usageListeners) {
      try {
        listener(usage);
      } catch (e) {
        print('Error notifying usage listener: $e');
      }
    }
  }

  // Private methods for persistence
  Future<void> _saveUsageLimits() async {
    final json = jsonEncode(_limits.toJson());
    await _prefs.setString('usage_limits', json);
  }

  Future<void> _loadUsageLimits() async {
    try {
      final json = _prefs.getString('usage_limits');
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        _limits = UsageLimits.fromJson(data);
      }
    } catch (e) {
      print('Error loading usage limits: $e');
      _limits = const UsageLimits();
    }
  }

  Future<void> _saveTokenUsages() async {
    try {
      final json = jsonEncode(_tokenUsages.map((u) => u.toJson()).toList());
      await _prefs.setString('token_usages', json);
    } catch (e) {
      print('Error saving token usages: $e');
    }
  }

  Future<void> _loadTokenUsages() async {
    try {
      final json = _prefs.getString('token_usages');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _tokenUsages.clear();
        _tokenUsages.addAll(data.map((item) => TokenUsage.fromJson(item)));
      }
    } catch (e) {
      print('Error loading token usages: $e');
    }
  }
}